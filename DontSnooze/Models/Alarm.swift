import Foundation

struct Alarm: Equatable, Identifiable, Hashable, Codable {
  var id: UUID
  var title: String = "Title"
  var time: Date
  var repeatDays: [Weekday]
  var isEnabled: Bool
  var soundName: String
  var snoozeEnabled: Bool
  var snoozeDuration: Int // in minutes
  var vibrationEnabled: Bool
  var volume: Float // Optional, range from 0.0 to 1.0
  
  enum Weekday: Int, Codable {
    case sunday = 1, monday, tuesday, wednesday, thursday, friday, saturday
  }
}
