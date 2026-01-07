//
//  ClipboardWatcher.swift
//  ClipManager
//
//  Created by Michael Cole on 07.01.26.
//
import SwiftUI
import AppKit
internal import Combine

class ClipboardWatcher: ObservableObject {
    
    // Read the setting (defaults to 20 if not found)
    @AppStorage("historyLimit") private var historyLimit: Int = 20
    
    @Published var isMonitoring: Bool = true {
        didSet {
            if isMonitoring { lastChangeCount = pasteboard.changeCount }
        }
    }
    
    @Published var history: [String] = [] {
        didSet {
            UserDefaults.standard.set(history, forKey: "ClipboardHistory")
        }
    }
    
    private let pasteboard = NSPasteboard.general
    private var lastChangeCount: Int
    private var timer: Timer?
    
    init() {
        if let savedHistory = UserDefaults.standard.stringArray(forKey: "ClipboardHistory") {
            self.history = savedHistory
        }
        self.lastChangeCount = pasteboard.changeCount
        startWatching()
    }
    
    func startWatching() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.checkClipboard()
        }
    }
    
    private func checkClipboard() {
        guard isMonitoring else { return }
        
        if pasteboard.changeCount != lastChangeCount {
            lastChangeCount = pasteboard.changeCount
            
            if let newString = pasteboard.string(forType: .string) {
                if let index = history.firstIndex(of: newString) {
                    history.remove(at: index)
                }
                history.insert(newString, at: 0)
                
                // --- USE THE SETTING HERE ---
                // Use the 'historyLimit' variable instead of hardcoded '20'
                if history.count > historyLimit {
                    history.removeLast()
                }
            }
        }
    }
}
