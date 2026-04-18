import Foundation
import UserNotifications

/// Notification Manager — handles push notification permissions and scheduling
/// for budget alerts and recurring transaction reminders.
final class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    
    @Published var isAuthorized = false
    
    private init() {}
    
    // MARK: - Authorization
    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            DispatchQueue.main.async {
                self.isAuthorized = granted
            }
            if let error = error {
                print("❌ Notification auth error: \(error)")
            }
        }
    }
    
    // MARK: - Budget Alerts
    func scheduleBudgetAlert(
        category: TransactionCategory,
        spent: Double,
        limit: Double,
        type: BudgetAlertType
    ) {
        let content = UNMutableNotificationContent()
        
        switch type {
        case .approaching:
            content.title = "⚠️ Budget Alert"
            content.body = "You've spent \(spent.currencyFormatted) of your \(limit.currencyFormatted) \(category.rawValue) budget. You're getting close to the limit!"
            content.sound = .default
            
        case .exceeded:
            content.title = "🚨 Budget Exceeded!"
            content.body = "Your \(category.rawValue) spending (\(spent.currencyFormatted)) has exceeded the \(limit.currencyFormatted) budget."
            content.sound = .defaultCritical
        }
        
        content.categoryIdentifier = "BUDGET_ALERT"
        content.userInfo = ["category": category.rawValue]
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "budget-\(category.rawValue)-\(type.rawValue)",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Failed to schedule notification: \(error)")
            }
        }
    }
    
    // MARK: - Recurring Transaction Reminder
    func scheduleRecurringReminder(title: String, amount: Double, dayOfMonth: Int) {
        let content = UNMutableNotificationContent()
        content.title = "💰 Recurring Payment"
        content.body = "\(title) — \(amount.currencyFormatted) is due today."
        content.sound = .default
        content.categoryIdentifier = "RECURRING_REMINDER"
        
        var dateComponents = DateComponents()
        dateComponents.day = dayOfMonth
        dateComponents.hour = 9
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(
            identifier: "recurring-\(title.lowercased().replacingOccurrences(of: " ", with: "-"))",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    // MARK: - Remove All
    func removeAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
    }
}

// MARK: - Alert Types
enum BudgetAlertType: String {
    case approaching
    case exceeded
}

// MARK: - Biometric Authentication Manager
import LocalAuthentication

final class BiometricManager: ObservableObject {
    static let shared = BiometricManager()
    
    @Published var isAuthenticated = false
    @Published var biometricType: LABiometryType = .none
    
    private let context = LAContext()
    
    private init() {
        checkBiometricAvailability()
    }
    
    func checkBiometricAvailability() {
        var error: NSError?
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            biometricType = context.biometryType
        }
    }
    
    func authenticateIfEnabled() {
        guard UserDefaults.standard.bool(forKey: "biometricEnabled") else {
            isAuthenticated = true
            return
        }
        
        let reason = "Authenticate to access your financial data"
        
        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, error in
            DispatchQueue.main.async {
                self.isAuthenticated = success
                if let error = error {
                    print("❌ Biometric auth failed: \(error.localizedDescription)")
                }
            }
        }
    }
    
    var biometricName: String {
        switch biometricType {
        case .faceID: return "Face ID"
        case .touchID: return "Touch ID"
        case .opticID: return "Optic ID"
        default: return "Biometric"
        }
    }
}

// MARK: - Theme Manager
final class ThemeManager: ObservableObject {
    @Published var accentColor: String {
        didSet { UserDefaults.standard.set(accentColor, forKey: "accentColor") }
    }
    @Published var useDarkMode: Bool {
        didSet { UserDefaults.standard.set(useDarkMode, forKey: "useDarkMode") }
    }
    
    init() {
        self.accentColor = UserDefaults.standard.string(forKey: "accentColor") ?? "#007AFF"
        self.useDarkMode = UserDefaults.standard.bool(forKey: "useDarkMode")
    }
}
