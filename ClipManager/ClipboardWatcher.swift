import SwiftUI
import AppKit
import Combine

class ClipboardWatcher: ObservableObject {
    
    // Limits the number of items stored. Persisted via AppStorage.
    @AppStorage("historyLimit") private var historyLimit: Int = 20
    
    @Published var isMonitoring: Bool = true {
        didSet {
            // When resuming, sync the change count immediately.
            // This prevents the app from "catching up" on items copied while paused.
            if isMonitoring { lastChangeCount = pasteboard.changeCount }
        }
    }
    
    @Published var history: [String] = [] {
        didSet {
            // Auto-save changes to UserDefaults whenever the history array is modified
            UserDefaults.standard.set(history, forKey: "ClipboardHistory")
        }
    }
    
    private let pasteboard = NSPasteboard.general
    private var lastChangeCount: Int
    private var timer: Timer?
    
    init() {
        // Load saved history from disk on startup
        if let savedHistory = UserDefaults.standard.stringArray(forKey: "ClipboardHistory") {
            self.history = savedHistory
        }
        
        self.lastChangeCount = pasteboard.changeCount
        startWatching()
    }
    
    func startWatching() {
        // Poll the clipboard every 0.5 seconds to check for changes
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.checkClipboard()
        }
    }
    
    private func checkClipboard() {
        guard isMonitoring else { return }
        
        // Use changeCount to detect updates efficiently without reading the full string data every time
        if pasteboard.changeCount != lastChangeCount {
            lastChangeCount = pasteboard.changeCount
            
            if let newString = pasteboard.string(forType: .string) {
                
                // If the item already exists, remove it first so we can move it to the top (bubble up)
                if let index = history.firstIndex(of: newString) {
                    history.remove(at: index)
                }
                
                history.insert(newString, at: 0)
                
                // Enforce the user-defined history limit
                if history.count > historyLimit {
                    history.removeLast()
                }
            }
        }
    }
}
