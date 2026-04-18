import Foundation
import CoreData

// MARK: - Transaction Entity
@objc(TransactionEntity)
public class TransactionEntity: NSManagedObject, Identifiable {
    @NSManaged public var id: UUID
    @NSManaged public var amount: Double
    @NSManaged public var title: String
    @NSManaged public var note: String?
    @NSManaged public var category: String
    @NSManaged public var type: String // "income" or "expense"
    @NSManaged public var date: Date
    @NSManaged public var currency: String
    @NSManaged public var isRecurring: Bool
    @NSManaged public var createdAt: Date
    @NSManaged public var updatedAt: Date
}

extension TransactionEntity {
    static var fetchRequest: NSFetchRequest<TransactionEntity> {
        NSFetchRequest<TransactionEntity>(entityName: "TransactionEntity")
    }
    
    var transactionType: TransactionType {
        TransactionType(rawValue: type) ?? .expense
    }
    
    var transactionCategory: TransactionCategory {
        TransactionCategory(rawValue: category) ?? .other
    }
    
    var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        return formatter.string(from: NSNumber(value: amount)) ?? "$\(amount)"
    }
    
    var isExpense: Bool { type == "expense" }
    var isIncome: Bool { type == "income" }
}

// MARK: - Transaction Type
enum TransactionType: String, CaseIterable, Codable {
    case income
    case expense
    
    var icon: String {
        switch self {
        case .income: return "arrow.down.circle.fill"
        case .expense: return "arrow.up.circle.fill"
        }
    }
    
    var color: String {
        switch self {
        case .income: return "green"
        case .expense: return "red"
        }
    }
}

// MARK: - Transaction Category
enum TransactionCategory: String, CaseIterable, Codable, Identifiable {
    case food = "Food & Dining"
    case transportation = "Transportation"
    case entertainment = "Entertainment"
    case shopping = "Shopping"
    case utilities = "Utilities"
    case health = "Health & Fitness"
    case education = "Education"
    case travel = "Travel"
    case salary = "Salary"
    case freelance = "Freelance"
    case investment = "Investment"
    case gift = "Gift"
    case other = "Other"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .food: return "fork.knife"
        case .transportation: return "car.fill"
        case .entertainment: return "gamecontroller.fill"
        case .shopping: return "bag.fill"
        case .utilities: return "bolt.fill"
        case .health: return "heart.fill"
        case .education: return "book.fill"
        case .travel: return "airplane"
        case .salary: return "banknote.fill"
        case .freelance: return "laptopcomputer"
        case .investment: return "chart.line.uptrend.xyaxis"
        case .gift: return "gift.fill"
        case .other: return "ellipsis.circle.fill"
        }
    }
    
    var color: String {
        switch self {
        case .food: return "#FF6B6B"
        case .transportation: return "#4ECDC4"
        case .entertainment: return "#45B7D1"
        case .shopping: return "#96CEB4"
        case .utilities: return "#FFEAA7"
        case .health: return "#DDA0DD"
        case .education: return "#98D8C8"
        case .travel: return "#F7DC6F"
        case .salary: return "#82E0AA"
        case .freelance: return "#85C1E9"
        case .investment: return "#AF7AC5"
        case .gift: return "#F1948A"
        case .other: return "#ABB2B9"
        }
    }
    
    var isIncome: Bool {
        switch self {
        case .salary, .freelance, .investment, .gift: return true
        default: return false
        }
    }
}

// MARK: - Transaction DTO (for API/Export)
struct TransactionDTO: Codable, Identifiable {
    let id: UUID
    let amount: Double
    let title: String
    let note: String?
    let category: TransactionCategory
    let type: TransactionType
    let date: Date
    let currency: String
    let isRecurring: Bool
    
    init(from entity: TransactionEntity) {
        self.id = entity.id
        self.amount = entity.amount
        self.title = entity.title
        self.note = entity.note
        self.category = entity.transactionCategory
        self.type = entity.transactionType
        self.date = entity.date
        self.currency = entity.currency
        self.isRecurring = entity.isRecurring
    }
}
