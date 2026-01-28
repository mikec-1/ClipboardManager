import SwiftUI
import AppKit
import Combine
import Foundation

struct ClipboardItem: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    let text: String
    let date: Date
}

struct IgnoredApp: Identifiable, Codable, Hashable {
    var id: String { bundleID }
    let bundleID: String
    let name: String
}

class ClipboardWatcher: ObservableObject {
    
    //limits the number of items stored
    @AppStorage("historyLimit") private var historyLimit: Int = 20
    @AppStorage("ignorePasswordManagers") var ignorePasswordManagers: Bool = true
    @AppStorage("ignoreCustomApps") var ignoreCustomApps: Bool = true
    
    private let pasteboard = NSPasteboard.general
    private var lastChangeCount: Int
    private var timer: Timer?
    
    @Published var ignoredApps: [IgnoredApp] = [] {
        didSet {
            if let encoded = try? JSONEncoder().encode(ignoredApps) {
                UserDefaults.standard.set(encoded, forKey: "customIgnoredApps")
            }
        }
    }
    
    @Published var isMonitoring: Bool = true {
        didSet {
            //stops app from adding copied items after unpaused
            if isMonitoring { lastChangeCount = pasteboard.changeCount }
        }
    }
    
    @Published var history: [ClipboardItem] = [] {
        didSet {
            saveHistory()
        }
    }
    
    //restricted apps
    private let builtInRestrictedApps: Set<String> = [
        "com.agilebits.onepassword7",
        "com.1password.1password",
        "com.lastpass.LastPass",
        "com.apple.keychainaccess",
        "com.apple.Passwords",
        "com.dashlane.Dashlane",
        "com.dashlane.DashlaneAgent",
        "com.bitwarden.desktop",
        "org.keepassxc.keepassxc"
    ]
    
    init() {
        //load on startup
        self.lastChangeCount = pasteboard.changeCount
        loadHistory()
        loadIgnoredApps()
        startWatching()
    }
    
    func startWatching() {
        //every 0.5s check
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.checkClipboard()
        }
    }
    
    func updateHistorySize(_ size: Int) {
        historyLimit = size
        if history.count > historyLimit {
            history = Array(history.prefix(historyLimit))
        }
    }
    
    private func checkClipboard() {
        guard isMonitoring else { return }
        
        if pasteboard.changeCount != lastChangeCount {
            lastChangeCount = pasteboard.changeCount
            
            //security app check
            if let frontApp = NSWorkspace.shared.frontmostApplication,
               let bundleID = frontApp.bundleIdentifier {
                
                if ignorePasswordManagers && builtInRestrictedApps.contains(bundleID) { return }
                if ignoreCustomApps && ignoredApps.contains(where: { $0.bundleID == bundleID }) { return }
            }
            
            //saves item
            if let newString = pasteboard.string(forType: .string) {
                //if exists do nothing
                if history.contains(where: { $0.text == newString }) {
                    return
                }
                
                //if not then add to top
                let newItem = ClipboardItem(text: newString, date: Date())
                history.insert(newItem, at: 0)
                
                if history.count > historyLimit {
                    history.removeLast()
                }
            }
        }
    }
    //saves history
    private func saveHistory() {
        if let encoded = try? JSONEncoder().encode(history) {
            UserDefaults.standard.set(encoded, forKey: "ClipboardHistoryItems")
        }
    }
    //loads history
    private func loadHistory() {
        if let data = UserDefaults.standard.data(forKey: "ClipboardHistoryItems"),
           let decoded = try? JSONDecoder().decode([ClipboardItem].self, from: data) {
            self.history = decoded
        }
    }
    //check for custom apps
    private func loadIgnoredApps() {
        if let data = UserDefaults.standard.data(forKey: "customIgnoredApps"),
           let decoded = try? JSONDecoder().decode([IgnoredApp].self, from: data) {
            self.ignoredApps = decoded
        }
    }
}
