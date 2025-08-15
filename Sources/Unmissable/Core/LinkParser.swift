import Foundation
import OSLog

class LinkParser {
  private let logger = Logger(subsystem: "com.unmissable.app", category: "LinkParser")

  static let shared = LinkParser()

  private init() {}

  // MARK: - Google Meet Link Detection (Simplified)

  func extractGoogleMeetLinks(from text: String) -> [URL] {
    var meetLinks: [URL] = []

    // Use NSDataDetector to find URLs
    guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
    else {
      logger.error("Failed to create URL detector")
      return meetLinks
    }

    let matches = detector.matches(
      in: text, options: [], range: NSRange(location: 0, length: text.utf16.count))

    for match in matches {
      guard let url = match.url else { continue }

      if isGoogleMeetURL(url) {
        meetLinks.append(url)
      }
    }

    // Remove duplicates
    return Array(Set(meetLinks))
  }

  func isGoogleMeetURL(_ url: URL) -> Bool {
    let urlString = url.absoluteString.lowercased()
    let host = url.host?.lowercased() ?? ""

    return host.contains("meet.google.com") || urlString.contains("meet.google.com")
  }

  func extractGoogleMeetID(from url: URL) -> String? {
    let path = url.path

    // Google Meet format: https://meet.google.com/abc-defg-hij
    if let lastComponent = path.components(separatedBy: "/").last,
      !lastComponent.isEmpty,
      lastComponent.contains("-")
    {
      return lastComponent
    }

    return nil
  }
}
