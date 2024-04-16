import Foundation

struct Alarm: Equatable, Identifiable, Hashable, Codable {
  var id: UUID
  var title: String = "Title"
  //var time: Date = Date.now
  var time: [String] = ["12", "00", "AM"]
  var repeatDays: [Weekday] = []
  var isEnabled: Bool = true
  var soundName: String = "god-monkey"
  var snoozeEnabled: Bool = true
  var snoozeDuration: Int = 5 // in minutes
  var vibrationEnabled: Bool = true
  var volume: Float = 1.0 // Optional, range from 0.0 to 1.0
  
  enum Weekday: Int, Codable {
    case sunday = 1, monday, tuesday, wednesday, thursday, friday, saturday
  }
}

extension Alarm {
  static let mock = Self(id: UUID())
  static let mock2 = Self(id: UUID())
}
