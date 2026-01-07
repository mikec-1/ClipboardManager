//
//  ClipManagerApp.swift
//  ClipManager
//
//  Created by Michael Cole on 07.01.26.
//

import SwiftUI

@main
struct ClipManagerApp: App {
    @StateObject private var watcher = ClipboardWatcher()
    
    var body: some Scene {
        MenuBarExtra("Clipboard Manager", systemImage: "doc.on.clipboard") {
            
            // --- HEADER SECTION ---
            // A clearer header showing the state
            VStack(alignment: .leading, spacing: 0) {
                Text("Clipboard Manager")
                    .font(.headline) // Makes it bold/larger
                
                // Dynamic text showing status
                if watcher.isMonitoring {
                    Text("● Monitoring On")
                        .font(.caption)
                        .foregroundColor(.green)
                } else {
                    Text("○ Paused")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            .padding(.horizontal) // Adds a little breathing room if rendered as a view, but in standard menu it's ignored (standard menus are rigid).
            
            Divider()
            
            // --- GROUP 1: Controls ---
            // Enable/Disable Button
            Button(watcher.isMonitoring ? "Disable Monitoring" : "Enable Monitoring") {
                watcher.isMonitoring.toggle()
            }
            
            Button("Clear History") {
                watcher.history.removeAll()
            }
            .disabled(watcher.history.isEmpty) // Greys out if list is already empty
            
            Divider()
            
            // --- THE LIST ---
            // We verify the list isn't empty before showing items
            if watcher.history.isEmpty {
                Text("No items copied yet")
                    .italic()
                    .foregroundColor(.gray)
            } else {
                ForEach(watcher.history, id: \.self) { item in
                    Button(action: {
                        copyToClipboard(item)
                    }) {
                        // Truncate text
                        Text(item.prefix(40) + (item.count > 40 ? "..." : ""))
                    }
                }
            }
            
            Divider()
            
            // --- GROUP 2: System ---
            
            SettingsLink {
                Text("Settings...")
            }
            .keyboardShortcut(",", modifiers: .command)
            
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q") // Cmd + q
        }
        // --- NEW SCENE ---
        // This defines the window that opens when "showSettingsWindow:" is called
        Settings {
            SettingsView()
        }
    }
    
    func copyToClipboard(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }
}
