import XCTest
@testable import FinanceFlow

final class TransactionViewModelTests: XCTestCase {
    var coreDataManager: CoreDataManager!
    
    override func setUp() {
        super.setUp()
        coreDataManager = CoreDataManager.shared
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    // MARK: - Transaction Creation Tests
    func testCreateExpenseTransaction() {
        let transaction = coreDataManager.createTransaction(
            title: "Grocery Shopping",
            amount: 45.99,
            category: .food,
            type: .expense,
            currency: "USD"
        )
        
        XCTAssertNotNil(transaction.id)
        XCTAssertEqual(transaction.title, "Grocery Shopping")
        XCTAssertEqual(transaction.amount, 45.99)
        XCTAssertEqual(transaction.transactionCategory, .food)
        XCTAssertEqual(transaction.transactionType, .expense)
        XCTAssertTrue(transaction.isExpense)
        XCTAssertFalse(transaction.isIncome)
    }
    
    func testCreateIncomeTransaction() {
        let transaction = coreDataManager.createTransaction(
            title: "Freelance Payment",
            amount: 1500.00,
            category: .freelance,
            type: .income
        )
        
        XCTAssertTrue(transaction.isIncome)
        XCTAssertEqual(transaction.amount, 1500.00)
    }
    
    // MARK: - Formatted Amount Tests
    func testFormattedAmountUSD() {
        let transaction = coreDataManager.createTransaction(
            title: "Test",
            amount: 1234.56,
            category: .other,
            type: .expense,
            currency: "USD"
        )
        
        XCTAssertTrue(transaction.formattedAmount.contains("1,234.56"))
    }
    
    // MARK: - Category Tests
    func testAllCategoriesHaveIcons() {
        for category in TransactionCategory.allCases {
            XCTAssertFalse(category.icon.isEmpty, "\(category.rawValue) should have an icon")
        }
    }
    
    func testAllCategoriesHaveColors() {
        for category in TransactionCategory.allCases {
            XCTAssertFalse(category.color.isEmpty, "\(category.rawValue) should have a color")
        }
    }
    
    func testIncomeCategoriesIdentified() {
        let incomeCategories: [TransactionCategory] = [.salary, .freelance, .investment, .gift]
        for category in incomeCategories {
            XCTAssertTrue(category.isIncome, "\(category.rawValue) should be identified as income")
        }
    }
    
    func testExpenseCategoriesIdentified() {
        let expenseCategories: [TransactionCategory] = [.food, .transportation, .entertainment, .shopping]
        for category in expenseCategories {
            XCTAssertFalse(category.isIncome, "\(category.rawValue) should not be identified as income")
        }
    }
    
    // MARK: - Fetch Tests
    func testFetchTransactionsByCategory() {
        // Create test transactions
        _ = coreDataManager.createTransaction(title: "Lunch", amount: 15, category: .food, type: .expense)
        _ = coreDataManager.createTransaction(title: "Uber", amount: 25, category: .transportation, type: .expense)
        _ = coreDataManager.createTransaction(title: "Dinner", amount: 35, category: .food, type: .expense)
        
        let foodTransactions = coreDataManager.fetchTransactions(for: .food)
        XCTAssertTrue(foodTransactions.count >= 2)
        XCTAssertTrue(foodTransactions.allSatisfy { $0.category == TransactionCategory.food.rawValue })
    }
    
    // MARK: - Monthly Report Tests
    func testMonthlyReportCalculation() {
        let calendar = Calendar.current
        let month = calendar.component(.month, from: Date())
        let year = calendar.component(.year, from: Date())
        
        let report = coreDataManager.calculateMonthlyReport(month: month, year: year)
        
        XCTAssertEqual(report.month, month)
        XCTAssertEqual(report.year, year)
        XCTAssertEqual(report.netSavings, report.totalIncome - report.totalExpenses)
    }
    
    // MARK: - Budget Tests
    func testBudgetCreation() {
        let calendar = Calendar.current
        let month = calendar.component(.month, from: Date())
        let year = calendar.component(.year, from: Date())
        
        let budget = coreDataManager.createBudget(
            category: .food,
            limit: 500,
            month: month,
            year: year,
            alertThreshold: 0.8
        )
        
        XCTAssertEqual(budget.limit, 500)
        XCTAssertEqual(budget.spent, 0)
        XCTAssertEqual(budget.remaining, 500)
        XCTAssertEqual(budget.progress, 0)
        XCTAssertFalse(budget.isOverBudget)
        XCTAssertFalse(budget.isNearLimit)
    }
    
    func testBudgetProgressCalculation() {
        let calendar = Calendar.current
        let budget = coreDataManager.createBudget(
            category: .entertainment,
            limit: 200,
            month: calendar.component(.month, from: Date()),
            year: calendar.component(.year, from: Date())
        )
        
        budget.spent = 160  // 80%
        XCTAssertEqual(budget.progress, 0.8)
        XCTAssertTrue(budget.isNearLimit)
        XCTAssertFalse(budget.isOverBudget)
        
        budget.spent = 250  // 125%
        XCTAssertTrue(budget.isOverBudget)
        XCTAssertEqual(budget.remaining, 0)
    }
}
