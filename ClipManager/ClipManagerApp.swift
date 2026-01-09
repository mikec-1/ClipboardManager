import SwiftUI

@main
struct ClipManagerApp: App {
    
    // The central state object that monitors clipboard changes.
    // We use @StateObject here to ensure the watcher instance lives for the entire app lifecycle.
    @StateObject private var watcher = ClipboardWatcher()
    @AppStorage("appTheme") private var appTheme: String = "system"
    
    var body: some Scene {
        
        // Defines the app as a Menu Bar Extra (tray icon) rather than a windowed app.
        MenuBarExtra {
            
            // Header View: Displays the app title and current monitoring status
            VStack(alignment: .leading, spacing: 0) {
                Text("copycat")
                    .font(.headline)
                
                if watcher.isMonitoring {
                    Text("● Monitoring On")
                        .font(.headline)
                        .foregroundColor(.green)
                } else {
                    Text("○ Monitoring Off")
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
            .preferredColorScheme(selectedScheme)
        } label: {
            let imageName = watcher.isMonitoring ? "cat_white_small" : "cat_asleep"
            Image(imageName)
        }
        
        // The Settings Scene
        // This handles the window that appears when Cmd+, is pressed
        Settings {
            SettingsView()
            .preferredColorScheme(selectedScheme)
        }
    }
    
    // 4. Helper Logic to convert the String to a ColorScheme
    var selectedScheme: ColorScheme? {
        switch appTheme {
        case "light": return .light
        case "dark": return .dark
        default: return nil // 'nil' means System default
        }
    }
    
    // Helper function to write text back to the system clipboard
    func copyToClipboard(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }
}
