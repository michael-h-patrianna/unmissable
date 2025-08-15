import Foundation

struct CalendarInfo: Identifiable, Codable {
  let id: String
  let name: String
  let description: String?
  let isSelected: Bool
  let isPrimary: Bool
  let colorHex: String?
  let lastSyncAt: Date?
  let createdAt: Date
  let updatedAt: Date

  init(
    id: String,
    name: String,
    description: String? = nil,
    isSelected: Bool = false,
    isPrimary: Bool = false,
    colorHex: String? = nil,
    lastSyncAt: Date? = nil,
    createdAt: Date = Date(),
    updatedAt: Date = Date()
  ) {
    self.id = id
    self.name = name
    self.description = description
    self.isSelected = isSelected
    self.isPrimary = isPrimary
    self.colorHex = colorHex
    self.lastSyncAt = lastSyncAt
    self.createdAt = createdAt
    self.updatedAt = updatedAt
  }
}
