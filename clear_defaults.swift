import Foundation
if let domain = Bundle.main.bundleIdentifier {
    UserDefaults.standard.removePersistentDomain(forName: domain)
} else {
    // Just find the generic one
    let all = UserDefaults.standard.dictionaryRepresentation()
    if all.keys.contains("LastProjectID") {
        UserDefaults.standard.removeObject(forKey: "LastProjectID")
    }
}
