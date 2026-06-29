import Foundation

public enum VersionCompare {
  public static func isUpdateRequired(
    serverVersion: String,
    installedVersion: String
  ) -> Bool {
    let server = serverVersion.trimmingCharacters(in: .whitespacesAndNewlines)
    if server.isEmpty {
      return false
    }
    let installed = installedVersion.trimmingCharacters(in: .whitespacesAndNewlines)
    return server != installed
  }
}
