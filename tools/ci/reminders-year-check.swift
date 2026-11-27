// Checks the Reminders year fix (branch fix/reminders-year) the way a Thai-calendar iPhone sees it.
// Run: swift tools/ci/reminders-year-check.swift
import Foundation

let now = Date()
let parts: Set<Calendar.Component> = [.year, .month, .day, .hour, .minute]
let gregorian = Calendar(identifier: .gregorian)
let buddhist = Calendar(identifier: .buddhist)      // Calendar.current on a Thai-calendar iPhone

// Old code: Calendar.current.dateComponents(...) handed to Reminders, which reads it as Gregorian.
let old = buddhist.dateComponents(parts, from: now)
let oldAsReminders = gregorian.date(from: old)!
print("old: year \(old.year!) -> Reminders reads \(gregorian.component(.year, from: oldAsReminders)) CE")

// New code (AppleReminders.makeReminder).
var due = gregorian.dateComponents(parts, from: now)
due.calendar = gregorian
let newAsReminders = gregorian.date(from: due)!
print("new: year \(due.year!) -> Reminders reads \(gregorian.component(.year, from: newAsReminders)) CE")

precondition(old.year! - due.year! == 543, "the old code should be 543 years ahead")
precondition(due.year == gregorian.component(.year, from: now), "new year must be today's Gregorian year")
precondition(abs(due.date!.timeIntervalSince(now)) < 60, "new date must be now (to the minute)")
precondition(due.hour == gregorian.component(.hour, from: now), "hour must be local time")
print("REMINDERS YEAR CHECK: PASSED")
