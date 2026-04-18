import SwiftUI
import Charts

/// Main Dashboard View — displays financial overview with interactive charts and recent transactions.
struct DashboardView: View {
    @StateObject private var viewModel = DashboardViewModel()
    @Environment(\.colorScheme) private var colorScheme
    @Namespace private var animation
    
    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 24) {
                    // Balance Card
                    balanceCard
                    
                    // Time Range Picker
                    timeRangePicker
                    
                    // Income & Expense Summary
                    incomeExpenseSummary
                    
                    // Spending Chart
                    if !viewModel.weeklySpending.isEmpty {
                        spendingChart
                    }
                    
                    // Category Breakdown
                    if !viewModel.spendingByCategory.isEmpty {
                        categoryBreakdown
                    }
                    
                    // Recent Transactions
                    if !viewModel.recentTransactions.isEmpty {
                        recentTransactionsSection
                    }
                }
                .padding()
            }
            .navigationTitle("Dashboard")
            .refreshable {
                await viewModel.loadDashboardData()
            }
            .task {
                await viewModel.loadDashboardData()
            }
        }
    }
    
    // MARK: - Balance Card
    private var balanceCard: some View {
        VStack(spacing: 12) {
            Text("Total Balance")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            Text(viewModel.totalBalance.currencyFormatted)
                .font(.system(size: 42, weight: .bold, design: .rounded))
                .foregroundStyle(viewModel.totalBalance >= 0 ? .primary : .red)
                .contentTransition(.numericText(value: viewModel.totalBalance))
                .animation(.spring(response: 0.3), value: viewModel.totalBalance)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .background {
            RoundedRectangle(cornerRadius: 24)
                .fill(.ultraThinMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(
                            LinearGradient(
                                colors: [.accentColor.opacity(0.5), .clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                }
        }
    }
    
    // MARK: - Time Range Picker
    private var timeRangePicker: some View {
        HStack(spacing: 0) {
            ForEach(TimeRange.allCases, id: \.self) { range in
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        viewModel.selectedTimeRange = range
                    }
                    Task { await viewModel.loadDashboardData() }
                } label: {
                    Text(range.rawValue)
                        .font(.caption.bold())
                        .foregroundStyle(viewModel.selectedTimeRange == range ? .white : .secondary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background {
                            if viewModel.selectedTimeRange == range {
                                Capsule()
                                    .fill(.accent)
                                    .matchedGeometryEffect(id: "timeRange", in: animation)
                            }
                        }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(Capsule().fill(.ultraThinMaterial))
    }
    
    // MARK: - Income & Expense Summary
    private var incomeExpenseSummary: some View {
        HStack(spacing: 16) {
            SummaryCard(
                title: "Income",
                amount: viewModel.monthlyIncome,
                icon: "arrow.down.circle.fill",
                color: .green
            )
            
            SummaryCard(
                title: "Expenses",
                amount: viewModel.monthlyExpenses,
                icon: "arrow.up.circle.fill",
                color: .red
            )
        }
    }
    
    // MARK: - Spending Chart
    private var spendingChart: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Spending Trend")
                .font(.headline)
            
            Chart(viewModel.weeklySpending) { spending in
                BarMark(
                    x: .value("Day", spending.dayName),
                    y: .value("Amount", spending.amount)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [.accentColor, .accentColor.opacity(0.5)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .cornerRadius(8)
            }
            .frame(height: 200)
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisValueLabel {
                        if let amount = value.as(Double.self) {
                            Text(amount.compactCurrencyFormatted)
                                .font(.caption2)
                        }
                    }
                }
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 20).fill(.ultraThinMaterial))
    }
    
    // MARK: - Category Breakdown
    private var categoryBreakdown: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Top Categories")
                .font(.headline)
            
            ForEach(viewModel.spendingByCategory.prefix(5)) { spending in
                HStack(spacing: 12) {
                    Image(systemName: spending.category.icon)
                        .font(.title3)
                        .foregroundStyle(Color(hex: spending.category.color))
                        .frame(width: 40, height: 40)
                        .background(Color(hex: spending.category.color).opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(spending.category.rawValue)
                            .font(.subheadline.bold())
                        
                        GeometryReader { geometry in
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color(hex: spending.category.color).opacity(0.3))
                                .frame(width: geometry.size.width)
                                .overlay(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color(hex: spending.category.color))
                                        .frame(width: geometry.size.width * spending.percentage / 100)
                                }
                        }
                        .frame(height: 6)
                    }
                    
                    Text(spending.amount.currencyFormatted)
                        .font(.subheadline.bold())
                        .monospacedDigit()
                }
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 20).fill(.ultraThinMaterial))
    }
    
    // MARK: - Recent Transactions
    private var recentTransactionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Recent Transactions")
                    .font(.headline)
                Spacer()
                NavigationLink("See All") {
                    TransactionListView()
                }
                .font(.subheadline)
            }
            
            ForEach(viewModel.recentTransactions) { transaction in
                TransactionRowView(transaction: transaction)
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 20).fill(.ultraThinMaterial))
    }
}

// MARK: - Summary Card Component
struct SummaryCard: View {
    let title: String
    let amount: Double
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Text(amount.currencyFormatted)
                .font(.title2.bold())
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(RoundedRectangle(cornerRadius: 16).fill(.ultraThinMaterial))
    }
}

// MARK: - Transaction Row View
struct TransactionRowView: View {
    let transaction: TransactionEntity
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: transaction.transactionCategory.icon)
                .font(.title3)
                .foregroundStyle(Color(hex: transaction.transactionCategory.color))
                .frame(width: 44, height: 44)
                .background(Color(hex: transaction.transactionCategory.color).opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(transaction.title)
                    .font(.subheadline.bold())
                Text(transaction.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Text("\(transaction.isExpense ? "-" : "+")\(transaction.formattedAmount)")
                .font(.subheadline.bold())
                .monospacedDigit()
                .foregroundStyle(transaction.isExpense ? .red : .green)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Extensions
extension Double {
    var currencyFormatted: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: self)) ?? "$\(self)"
    }
    
    var compactCurrencyFormatted: String {
        if self >= 1000 {
            return "$\(Int(self / 1000))K"
        }
        return currencyFormatted
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

#Preview {
    DashboardView()
}
