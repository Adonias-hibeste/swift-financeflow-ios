import Foundation
import CoreData

/// Core Data Stack Manager — handles persistent container setup, context management,
/// and provides CRUD operations for transaction and budget entities.
final class CoreDataManager: ObservableObject {
    static let shared = CoreDataManager()
    
    // MARK: - Persistent Container
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "FinanceFlow")
        
        // Enable lightweight migration
        let description = container.persistentStoreDescriptions.first
        description?.shouldMigrateStoreAutomatically = true
        description?.shouldInferMappingModelAutomatically = true
        
        // Enable persistent history tracking for widget sync
        description?.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        description?.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        
        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                fatalError("❌ Core Data failed to load: \(error), \(error.userInfo)")
            }
        }
        
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        return container
    }()
    
    var viewContext: NSManagedObjectContext {
        persistentContainer.viewContext
    }
    
    // MARK: - Background Context
    func newBackgroundContext() -> NSManagedObjectContext {
        let context = persistentContainer.newBackgroundContext()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return context
    }
    
    // MARK: - Save Context
    func save(context: NSManagedObjectContext? = nil) {
        let ctx = context ?? viewContext
        guard ctx.hasChanges else { return }
        
        do {
            try ctx.save()
        } catch {
            let nsError = error as NSError
            print("❌ Core Data save error: \(nsError), \(nsError.userInfo)")
        }
    }
    
    // MARK: - Transaction CRUD
    func createTransaction(
        title: String,
        amount: Double,
        category: TransactionCategory,
        type: TransactionType,
        date: Date = Date(),
        currency: String = "USD",
        note: String? = nil,
        isRecurring: Bool = false,
        context: NSManagedObjectContext? = nil
    ) -> TransactionEntity {
        let ctx = context ?? viewContext
        let transaction = TransactionEntity(context: ctx)
        transaction.id = UUID()
        transaction.title = title
        transaction.amount = amount
        transaction.category = category.rawValue
        transaction.type = type.rawValue
        transaction.date = date
        transaction.currency = currency
        transaction.note = note
        transaction.isRecurring = isRecurring
        transaction.createdAt = Date()
        transaction.updatedAt = Date()
        
        save(context: ctx)
        
        // Check budget alerts
        Task {
            await BudgetAlertManager.shared.checkBudgetAlert(for: category)
        }
        
        return transaction
    }
    
    func deleteTransaction(_ transaction: TransactionEntity) {
        viewContext.delete(transaction)
        save()
    }
    
    func fetchTransactions(
        for category: TransactionCategory? = nil,
        from startDate: Date? = nil,
        to endDate: Date? = nil,
        type: TransactionType? = nil,
        limit: Int? = nil
    ) -> [TransactionEntity] {
        let request = TransactionEntity.fetchRequest
        var predicates: [NSPredicate] = []
        
        if let category = category {
            predicates.append(NSPredicate(format: "category == %@", category.rawValue))
        }
        if let startDate = startDate {
            predicates.append(NSPredicate(format: "date >= %@", startDate as NSDate))
        }
        if let endDate = endDate {
            predicates.append(NSPredicate(format: "date <= %@", endDate as NSDate))
        }
        if let type = type {
            predicates.append(NSPredicate(format: "type == %@", type.rawValue))
        }
        
        if !predicates.isEmpty {
            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        }
        
        request.sortDescriptors = [NSSortDescriptor(keyPath: \TransactionEntity.date, ascending: false)]
        
        if let limit = limit {
            request.fetchLimit = limit
        }
        
        do {
            return try viewContext.fetch(request)
        } catch {
            print("❌ Fetch error: \(error)")
            return []
        }
    }
    
    // MARK: - Budget CRUD
    func createBudget(
        category: TransactionCategory,
        limit: Double,
        month: Int,
        year: Int,
        alertThreshold: Double = 0.8
    ) -> BudgetEntity {
        let budget = BudgetEntity(context: viewContext)
        budget.id = UUID()
        budget.category = category.rawValue
        budget.limit = limit
        budget.spent = 0
        budget.month = Int16(month)
        budget.year = Int16(year)
        budget.alertThreshold = alertThreshold
        budget.isActive = true
        budget.createdAt = Date()
        
        save()
        return budget
    }
    
    func fetchBudgets(for month: Int, year: Int) -> [BudgetEntity] {
        let request = BudgetEntity.fetchRequest
        request.predicate = NSPredicate(
            format: "month == %d AND year == %d AND isActive == YES",
            month, year
        )
        request.sortDescriptors = [NSSortDescriptor(keyPath: \BudgetEntity.category, ascending: true)]
        
        do {
            return try viewContext.fetch(request)
        } catch {
            print("❌ Budget fetch error: \(error)")
            return []
        }
    }
    
    // MARK: - Statistics
    func calculateMonthlyReport(month: Int, year: Int) -> MonthlyReport {
        let calendar = Calendar.current
        var components = DateComponents()
        components.month = month
        components.year = year
        
        guard let startDate = calendar.date(from: components),
              let endDate = calendar.date(byAdding: .month, value: 1, to: startDate) else {
            return MonthlyReport(month: month, year: year, totalIncome: 0, totalExpenses: 0, netSavings: 0, topCategories: [])
        }
        
        let transactions = fetchTransactions(from: startDate, to: endDate)
        
        let totalIncome = transactions.filter { $0.isIncome }.reduce(0) { $0 + $1.amount }
        let totalExpenses = transactions.filter { $0.isExpense }.reduce(0) { $0 + $1.amount }
        
        // Calculate top spending categories
        var categoryTotals: [TransactionCategory: Double] = [:]
        for t in transactions.filter({ $0.isExpense }) {
            categoryTotals[t.transactionCategory, default: 0] += t.amount
        }
        
        let topCategories = categoryTotals
            .sorted { $0.value > $1.value }
            .prefix(5)
            .map { ($0.key, $0.value) }
        
        return MonthlyReport(
            month: month,
            year: year,
            totalIncome: totalIncome,
            totalExpenses: totalExpenses,
            netSavings: totalIncome - totalExpenses,
            topCategories: topCategories
        )
    }
}

// MARK: - Budget Alert Manager
actor BudgetAlertManager {
    static let shared = BudgetAlertManager()
    
    func checkBudgetAlert(for category: TransactionCategory) {
        let calendar = Calendar.current
        let month = calendar.component(.month, from: Date())
        let year = calendar.component(.year, from: Date())
        
        let budgets = CoreDataManager.shared.fetchBudgets(for: month, year: year)
        
        guard let budget = budgets.first(where: { $0.category == category.rawValue }) else { return }
        
        if budget.isNearLimit && !budget.isOverBudget {
            NotificationManager.shared.scheduleBudgetAlert(
                category: category,
                spent: budget.spent,
                limit: budget.limit,
                type: .approaching
            )
        } else if budget.isOverBudget {
            NotificationManager.shared.scheduleBudgetAlert(
                category: category,
                spent: budget.spent,
                limit: budget.limit,
                type: .exceeded
            )
        }
    }
}
