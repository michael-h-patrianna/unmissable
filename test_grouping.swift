#!/usr/bin/env swift

import Foundation

// Test the date grouping logic
let calendar = Calendar.current
let today = Date()
let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!

print(
  "Today: \(calendar.component(.weekday, from: today)) (\(DateFormatter.localizedString(from: today, dateStyle: .full, timeStyle: .none)))"
)
print(
  "Tomorrow: \(calendar.component(.weekday, from: tomorrow)) (\(DateFormatter.localizedString(from: tomorrow, dateStyle: .full, timeStyle: .none)))"
)

// Test weekend logic
if calendar.component(.weekday, from: tomorrow) == 7 {
  let monday = calendar.date(byAdding: .day, value: 2, to: tomorrow)!
  print(
    "Tomorrow is Saturday, so we'll also show Monday: \(DateFormatter.localizedString(from: monday, dateStyle: .full, timeStyle: .none))"
  )
} else {
  print("Tomorrow is not Saturday, so no Monday events needed")
}

// Test date comparison
let testDate1 = today
let testDate2 = calendar.date(byAdding: .hour, value: 5, to: today)!
let testDate3 = tomorrow

print("Is testDate1 same day as today? \(calendar.isDate(testDate1, inSameDayAs: today))")
print("Is testDate2 same day as today? \(calendar.isDate(testDate2, inSameDayAs: today))")
print("Is testDate3 same day as today? \(calendar.isDate(testDate3, inSameDayAs: today))")
print("Is testDate3 same day as tomorrow? \(calendar.isDate(testDate3, inSameDayAs: tomorrow))")
