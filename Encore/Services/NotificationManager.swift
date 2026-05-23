import Foundation
import UserNotifications

class NotificationManager {
    static let shared = NotificationManager()
    
    private init() {}
    
    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Notification authorization error: \(error.localizedDescription)")
            } else {
                print("Notification authorization granted: \(granted)")
            }
        }
    }
    
    func scheduleNotification(for concert: Concert) {
        // Calculate the notification date: 8:00 AM on the day of the concert
        var calendar = Calendar.current
        calendar.timeZone = TimeZone.current
        
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: concert.date)
        var notificationComponents = DateComponents()
        notificationComponents.year = dateComponents.year
        notificationComponents.month = dateComponents.month
        notificationComponents.day = dateComponents.day
        notificationComponents.hour = 8
        notificationComponents.minute = 0
        
        guard let notificationDate = calendar.date(from: notificationComponents) else { return }
        
        // Only schedule if the date is in the future
        if notificationDate > Date() {
            let content = UNMutableNotificationContent()
            content.title = "It's concert day! 🎸"
            
            // Format the concert time
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            let timeString = formatter.string(from: concert.date)
            
            let name = concert.title.isEmpty ? concert.headliner : concert.title
            content.body = "\(name) is today at \(timeString)!"
            content.sound = .default
            
            let trigger = UNCalendarNotificationTrigger(dateMatching: notificationComponents, repeats: false)
            
            let request = UNNotificationRequest(identifier: concert.id, content: content, trigger: trigger)
            
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("Error scheduling notification for \(concert.title): \(error.localizedDescription)")
                } else {
                    print("Successfully scheduled notification for \(concert.title) on \(notificationDate)")
                }
            }
        } else {
            // Cancel it just in case they edited a concert to be in the past
            removeNotification(for: concert.id)
        }
    }
    
    func removeNotification(for concertId: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [concertId])
        print("Removed pending notification for concert: \(concertId)")
    }
}
