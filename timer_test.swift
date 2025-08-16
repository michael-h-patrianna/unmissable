import Foundation

// Quick test of the timer formatting logic
func formatTimeLeft(_ timeInterval: TimeInterval) -> String {
  guard timeInterval > 0 else {
    return "Starting"
  }

  let totalMinutes = Int(timeInterval / 60)

  if totalMinutes < 1 {
    return "< 1 min"
  } else if totalMinutes < 60 {
    return "\(totalMinutes) min"
  } else if totalMinutes < 1440 {  // Less than 24 hours
    let hours = totalMinutes / 60
    let minutes = totalMinutes % 60
    return String(format: "%d:%02d h", hours, minutes)
  } else {
    let days = totalMinutes / 1440
    return "\(days) d"
  }
}

// Test cases
print("Timer Format Tests:")
print("30 seconds: \(formatTimeLeft(30))")  // < 1 min
print("1 minute: \(formatTimeLeft(60))")  // 1 min
print("5 minutes: \(formatTimeLeft(300))")  // 5 min
print("52 minutes: \(formatTimeLeft(3120))")  // 52 min
print("1 hour 30 min: \(formatTimeLeft(5400))")  // 1:30 h
print("22 hours 43 min: \(formatTimeLeft(81780))")  // 22:43 h
print("24 hours: \(formatTimeLeft(86400))")  // 1 d
print("48 hours: \(formatTimeLeft(172800))")  // 2 d

// Test truncation
func truncateMeetingName(_ name: String) -> String {
  if name.count <= 12 {
    return name
  }
  let truncated = String(name.prefix(9))
  return "\(truncated)..."
}

print("\nName Truncation Tests:")
print("Short: \(truncateMeetingName("Team Call"))")
print("Exact 12: \(truncateMeetingName("Team Meeting"))")
print("Long: \(truncateMeetingName("Very Long Meeting Title Name"))")
