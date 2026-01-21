import SwiftUI

@main
struct ClipManagerApp: App {
    @StateObject private var watcher = ClipboardWatcher()
    @StateObject private var appState = AppState()
    
    var body: some Scene {
        
        MenuBarExtra {
            //heaer
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
            
            Button(watcher.isMonitoring ? "Disable Monitoring" : "Enable Monitoring") {
                watcher.isMonitoring.toggle()
            }
            
            Button("Clear History") {
                watcher.history.removeAll()
            }
            .disabled(watcher.history.isEmpty)
            
            Divider()
            
            if watcher.history.isEmpty {
                Text("No items copied yet")
                    .italic()
                    .foregroundColor(.gray)
            } else {
                ForEach(watcher.history, id: \.self) { item in
                    Button(action: {
                        copyToClipboard(item)
                    }) {
                        Text(item.prefix(40) + (item.count > 40 ? "..." : ""))
                    }
                }
            }
            
            Divider()
            
            //footer
            SettingsLink {
                Text("Settings...")
            }
            .keyboardShortcut(",", modifiers: .command)
            
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q")
            
        } label: {
            let imageName = watcher.isMonitoring ? "cat_white_small" : "cat_asleep"
            Image(imageName)
        }
        
        // Settings window
        Settings {
            SettingsView(appState: appState, clipboardWatcher: watcher)
                .preferredColorScheme(appState.appearance.colorScheme)
        }
    }
    
    func copyToClipboard(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }
}
