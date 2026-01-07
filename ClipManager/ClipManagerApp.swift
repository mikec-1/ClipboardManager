import SwiftUI

@main
struct ClipManagerApp: App {
    
    // The central state object that monitors clipboard changes.
    // We use @StateObject here to ensure the watcher instance lives for the entire app lifecycle.
    @StateObject private var watcher = ClipboardWatcher()
    
    var body: some Scene {
        
        // Defines the app as a Menu Bar Extra (tray icon) rather than a windowed app.
        MenuBarExtra("Clipboard Manager", systemImage: "doc.on.clipboard") {
            
            // Header View: Displays the app title and current monitoring status
            VStack(alignment: .leading, spacing: 0) {
                Text("Clipboard Manager")
                    .font(.headline)
                
                if watcher.isMonitoring {
                    Text("● Monitoring On")
                        .font(.headline)
                        .foregroundColor(.green)
                } else {
                    Text("○ Paused")
                        .font(.headline)
                        .foregroundColor(.red)
                }
            }
            .padding(.horizontal)
            
            Divider()
            
            // Primary Controls
            Button(watcher.isMonitoring ? "Disable Monitoring" : "Enable Monitoring") {
                watcher.isMonitoring.toggle()
            }
            
            Button("Clear History") {
                watcher.history.removeAll()
            }
            .disabled(watcher.history.isEmpty)
            
            Divider()
            
            // History List
            // Displays the most recent clipboard items as clickable buttons
            if watcher.history.isEmpty {
                Text("No items copied yet")
                    .italic()
                    .foregroundColor(.gray)
            } else {
                ForEach(watcher.history, id: \.self) { item in
                    Button(action: {
                        copyToClipboard(item)
                    }) {
                        // Truncate long text to keep the menu width reasonable
                        Text(item.prefix(40) + (item.count > 40 ? "..." : ""))
                    }
                }
            }
            
            Divider()
            
            // System Actions
            // SettingsLink automatically connects to the Settings scene defined below
            SettingsLink {
                Text("Settings...")
            }
            .keyboardShortcut(",", modifiers: .command)
            
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q")
        }
        
        // The Settings Scene
        // This handles the window that appears when Cmd+, is pressed
        Settings {
            SettingsView()
        }
    }
    
    // Helper function to write text back to the system clipboard
    func copyToClipboard(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }
}
