import Foundation
import CoreData

// MARK: - Budget Entity
@objc(BudgetEntity)
public class BudgetEntity: NSManagedObject, Identifiable {
    @NSManaged public var id: UUID
    @NSManaged public var category: String
    @NSManaged public var limit: Double
    @NSManaged public var spent: Double
    @NSManaged public var month: Int16
    @NSManaged public var year: Int16
    @NSManaged public var alertThreshold: Double // 0.0 to 1.0 (percentage)
    @NSManaged public var isActive: Bool
    @NSManaged public var createdAt: Date
}

extension BudgetEntity {
    static var fetchRequest: NSFetchRequest<BudgetEntity> {
        NSFetchRequest<BudgetEntity>(entityName: "BudgetEntity")
    }
    
    var remaining: Double { max(limit - spent, 0) }
    var progress: Double { min(spent / limit, 1.0) }
    var isOverBudget: Bool { spent > limit }
    var isNearLimit: Bool { progress >= alertThreshold }
    
    var budgetCategory: TransactionCategory {
        TransactionCategory(rawValue: category) ?? .other
    }
    
    var statusColor: String {
        if isOverBudget { return "red" }
        if isNearLimit { return "orange" }
        return "green"
    }
    
    var formattedLimit: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        return formatter.string(from: NSNumber(value: limit)) ?? "$\(limit)"
    }
    
    var formattedSpent: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        return formatter.string(from: NSNumber(value: spent)) ?? "$\(spent)"
    }
    
    var formattedRemaining: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        return formatter.string(from: NSNumber(value: remaining)) ?? "$\(remaining)"
    }
}

// MARK: - Budget Summary
struct BudgetSummary {
    let totalBudget: Double
    let totalSpent: Double
    let totalRemaining: Double
    let categoryBreakdown: [CategoryBudget]
    
    var overallProgress: Double {
        guard totalBudget > 0 else { return 0 }
        return min(totalSpent / totalBudget, 1.0)
    }
    
    struct CategoryBudget: Identifiable {
        let id = UUID()
        let category: TransactionCategory
        let limit: Double
        let spent: Double
        let progress: Double
    }
}

// MARK: - Monthly Report
struct MonthlyReport: Identifiable {
    let id = UUID()
    let month: Int
    let year: Int
    let totalIncome: Double
    let totalExpenses: Double
    let netSavings: Double
    let topCategories: [(category: TransactionCategory, amount: Double)]
    
    var savingsRate: Double {
        guard totalIncome > 0 else { return 0 }
        return netSavings / totalIncome * 100
    }
    
    var monthName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        var dateComponents = DateComponents()
        dateComponents.month = month
        dateComponents.year = year
        let date = Calendar.current.date(from: dateComponents) ?? Date()
        return formatter.string(from: date)
    }
}
