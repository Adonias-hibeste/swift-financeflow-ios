import SwiftUI
import Combine
import CoreData

/// Dashboard ViewModel — aggregates financial data for the main overview screen.
/// Uses Combine publishers to reactively update the UI when transactions change.
@MainActor
final class DashboardViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var totalBalance: Double = 0
    @Published var monthlyIncome: Double = 0
    @Published var monthlyExpenses: Double = 0
    @Published var recentTransactions: [TransactionEntity] = []
    @Published var spendingByCategory: [CategorySpending] = []
    @Published var weeklySpending: [DailySpending] = []
    @Published var isLoading = false
    @Published var selectedTimeRange: TimeRange = .month
    
    // MARK: - Dependencies
    private let coreDataManager: CoreDataManager
    private var cancellables = Set<AnyCancellable>()
    
    init(coreDataManager: CoreDataManager = .shared) {
        self.coreDataManager = coreDataManager
        observeTransactionChanges()
    }
    
    // MARK: - Data Loading
    func loadDashboardData() async {
        isLoading = true
        defer { isLoading = false }
        
        let context = coreDataManager.viewContext
        let calendar = Calendar.current
        let now = Date()
        
        // Calculate date range based on selected time range
        let startDate: Date
        switch selectedTimeRange {
        case .week:
            startDate = calendar.date(byAdding: .day, value: -7, to: now) ?? now
        case .month:
            startDate = calendar.date(byAdding: .month, value: -1, to: now) ?? now
        case .quarter:
            startDate = calendar.date(byAdding: .month, value: -3, to: now) ?? now
        case .year:
            startDate = calendar.date(byAdding: .year, value: -1, to: now) ?? now
        }
        
        // Fetch transactions in date range
        let request = TransactionEntity.fetchRequest
        request.predicate = NSPredicate(format: "date >= %@", startDate as NSDate)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \TransactionEntity.date, ascending: false)]
        
        do {
            let transactions = try context.fetch(request)
            
            // Calculate totals
            monthlyIncome = transactions.filter { $0.isIncome }.reduce(0) { $0 + $1.amount }
            monthlyExpenses = transactions.filter { $0.isExpense }.reduce(0) { $0 + $1.amount }
            totalBalance = monthlyIncome - monthlyExpenses
            
            // Recent transactions (top 5)
            recentTransactions = Array(transactions.prefix(5))
            
            // Spending by category
            spendingByCategory = calculateCategorySpending(transactions.filter { $0.isExpense })
            
            // Weekly spending trend
            weeklySpending = calculateWeeklySpending(transactions.filter { $0.isExpense })
            
        } catch {
            print("❌ Failed to fetch transactions: \(error)")
        }
    }
    
    // MARK: - Category Spending Calculation
    private func calculateCategorySpending(_ transactions: [TransactionEntity]) -> [CategorySpending] {
        var categoryTotals: [String: Double] = [:]
        
        for transaction in transactions {
            categoryTotals[transaction.category, default: 0] += transaction.amount
        }
        
        let totalSpending = categoryTotals.values.reduce(0, +)
        
        return categoryTotals.map { category, amount in
            CategorySpending(
                category: TransactionCategory(rawValue: category) ?? .other,
                amount: amount,
                percentage: totalSpending > 0 ? amount / totalSpending * 100 : 0
            )
        }
        .sorted { $0.amount > $1.amount }
    }
    
    // MARK: - Weekly Spending Calculation
    private func calculateWeeklySpending(_ transactions: [TransactionEntity]) -> [DailySpending] {
        let calendar = Calendar.current
        var dailyTotals: [Date: Double] = [:]
        
        for i in 0..<7 {
            let date = calendar.date(byAdding: .day, value: -i, to: Date()) ?? Date()
            let startOfDay = calendar.startOfDay(for: date)
            dailyTotals[startOfDay] = 0
        }
        
        for transaction in transactions {
            let startOfDay = calendar.startOfDay(for: transaction.date)
            if dailyTotals.keys.contains(startOfDay) {
                dailyTotals[startOfDay, default: 0] += transaction.amount
            }
        }
        
        return dailyTotals.map { date, amount in
            DailySpending(date: date, amount: amount)
        }
        .sorted { $0.date < $1.date }
    }
    
    // MARK: - Observe Changes
    private func observeTransactionChanges() {
        NotificationCenter.default.publisher(for: .NSManagedObjectContextDidSave)
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                Task { await self?.loadDashboardData() }
            }
            .store(in: &cancellables)
    }
}

// MARK: - Supporting Types
struct CategorySpending: Identifiable {
    let id = UUID()
    let category: TransactionCategory
    let amount: Double
    let percentage: Double
}

struct DailySpending: Identifiable {
    let id = UUID()
    let date: Date
    let amount: Double
    
    var dayName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }
}

enum TimeRange: String, CaseIterable {
    case week = "7D"
    case month = "1M"
    case quarter = "3M"
    case year = "1Y"
}
