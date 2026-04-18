import SwiftUI

@main
struct FinanceFlowApp: App {
    @StateObject private var coreDataManager = CoreDataManager.shared
    @StateObject private var themeManager = ThemeManager()
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    
    init() {
        configureAppearance()
        NotificationManager.shared.requestAuthorization()
    }
    
    var body: some Scene {
        WindowGroup {
            if hasCompletedOnboarding {
                MainTabView()
                    .environment(\.managedObjectContext, coreDataManager.viewContext)
                    .environmentObject(themeManager)
                    .onAppear {
                        BiometricManager.shared.authenticateIfEnabled()
                    }
            } else {
                OnboardingView(hasCompleted: $hasCompletedOnboarding)
                    .environmentObject(themeManager)
            }
        }
    }
    
    private func configureAppearance() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .systemBackground
        appearance.titleTextAttributes = [.foregroundColor: UIColor.label]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.label]
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
    }
}

// MARK: - Main Tab View
struct MainTabView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "chart.pie.fill")
                }
                .tag(0)
            
            TransactionListView()
                .tabItem {
                    Label("Transactions", systemImage: "list.bullet.rectangle.fill")
                }
                .tag(1)
            
            BudgetOverviewView()
                .tabItem {
                    Label("Budget", systemImage: "chart.bar.fill")
                }
                .tag(2)
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(3)
        }
        .tint(.accentColor)
    }
}

// MARK: - Onboarding View
struct OnboardingView: View {
    @Binding var hasCompleted: Bool
    @State private var currentPage = 0
    
    private let pages: [(icon: String, title: String, subtitle: String)] = [
        ("chart.pie.fill", "Track Your Spending", "Get a clear picture of where your money goes with beautiful charts and insights."),
        ("dollarsign.circle.fill", "Set Smart Budgets", "Create monthly budgets and receive alerts before you overspend."),
        ("lock.shield.fill", "Secure & Private", "Your financial data stays on your device, protected by Face ID.")
    ]
    
    var body: some View {
        VStack(spacing: 40) {
            TabView(selection: $currentPage) {
                ForEach(0..<pages.count, id: \.self) { index in
                    VStack(spacing: 24) {
                        Image(systemName: pages[index].icon)
                            .font(.system(size: 80))
                            .foregroundStyle(.accent)
                            .symbolEffect(.bounce, value: currentPage)
                        
                        Text(pages[index].title)
                            .font(.title.bold())
                            .multilineTextAlignment(.center)
                        
                        Text(pages[index].subtitle)
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            
            Button {
                if currentPage < pages.count - 1 {
                    withAnimation { currentPage += 1 }
                } else {
                    hasCompleted = true
                }
            } label: {
                Text(currentPage < pages.count - 1 ? "Next" : "Get Started")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.accent)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }
}
