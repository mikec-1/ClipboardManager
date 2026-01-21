import SwiftUI
import ServiceManagement

// MARK: - Settings View
struct SettingsView: View {
    @ObservedObject var appState: AppState
    @ObservedObject var clipboardWatcher: ClipboardWatcher
    
    //window float
    @State private var settingsWindow: NSWindow?
    
    var body: some View {
        TabView {
            GeneralSettingsView(appState: appState)
                .tabItem {
                    Label("General", systemImage: "gear")
                }
            
            PrivacySettingsView()
                .tabItem {
                    Label("Privacy", systemImage: "hand.raised.fill")
                }
            
            AboutView()
                .tabItem {
                    Label("About", systemImage: "info.circle")
                }
        }
        .frame(width: 500, height: 400)
        .preferredColorScheme(appState.appearance.colorScheme)
        
        //floating
        .background(WindowAccessor { window in
            self.settingsWindow = window
            configureSettingsWindow(window)
        })
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.didBecomeKeyNotification)) { notification in
            if let window = notification.object as? NSWindow, window == settingsWindow {
                configureSettingsWindow(window)
            }
        }
    }
    
    private func configureSettingsWindow(_ window: NSWindow) {
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        
        window.titlebarAppearsTransparent = false
        window.titleVisibility = .visible
        window.styleMask.insert(.fullSizeContentView)
        
        window.orderFrontRegardless()
        window.standardWindowButton(.miniaturizeButton)?.isHidden = true
        window.standardWindowButton(.zoomButton)?.isHidden = true
    }
}

// MARK: - General Settings View
struct GeneralSettingsView: View {
    @ObservedObject var appState: AppState
    
    //connect to UserDefaults direct and its shared with ClipboardWatcher
    @AppStorage("historyLimit") private var storedLimit: Int = 20
    
    @State private var selectedLimit: Int = 20
    @State private var launchAtLogin: Bool = SMAppService.mainApp.status == .enabled
    
    var body: some View {
        Form {
            Section {
                Picker("Appearance", selection: $appState.appearance) {
                    ForEach(AppState.AppearanceMode.allCases, id: \.self) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
            } header: {
                Text("Appearance")
            }
            
            Section {
                Toggle("Launch at Login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { oldValue, newValue in
                        if newValue {
                            try? SMAppService.mainApp.register()
                        } else {
                            try? SMAppService.mainApp.unregister()
                        }
                    }
            } header: {
                Text("Startup")
            }
            
            Section {
                HStack(alignment: .firstTextBaseline) {
                    Text("History Size")
                    Spacer()
                    Picker("", selection: $selectedLimit) {
                        Text("10 items").tag(10)
                        Text("20 items").tag(20)
                        Text("50 items").tag(50)
                        Text("100 items").tag(100)
                    }
                    .frame(width: 120)
                    
                    Button("Save Limit") {
                        storedLimit = selectedLimit
                    }
                }
                Text("Older items will automatically be removed if limit is reached.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } header: {
                Text("Clipboard History")
            }
            
            Section {
                VStack(alignment: .leading, spacing: 6) {
                    ShortcutRow(keys: "⌘⇧V", desc: "Open clipboard menu")
                    ShortcutRow(keys: "⇧+Click", desc: "Paste as plain text")
                    ShortcutRow(keys: "⌘+Click", desc: "Pin/Unpin item")
                    ShortcutRow(keys: "↑↓", desc: "Navigate items")
                    ShortcutRow(keys: "⏎", desc: "Paste selected item")
                }
                .padding(.vertical, 4)
            } header: {
                Text("Keyboard Shortcuts")
            }
        }
        .formStyle(.grouped)
        .padding()
        .onAppear {
            selectedLimit = storedLimit
        }
    }
}

// MARK: - Privacy Settings View
struct PrivacySettingsView: View {
    @AppStorage("ignorePasswordManagers") private var ignorePasswordManagers: Bool = true
    
    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "shield.checkered")
                            .font(.title2)
                            .foregroundColor(.green)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Password Manager Protection")
                                .font(.headline)
                            Text("Copycat automatically ignores clipboard content from password managers to keep your passwords secure.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Toggle("Ignore Password Managers", isOn: $ignorePasswordManagers)
                        .padding(.top, 4)
                    
                    Divider()
                    
                    Text("Protected Apps:")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Label("1Password", systemImage: "checkmark.circle.fill").foregroundColor(.green)
                        Label("LastPass", systemImage: "checkmark.circle.fill").foregroundColor(.green)
                        Label("macOS Keychain", systemImage: "checkmark.circle.fill").foregroundColor(.green)
                        Label("Dashlane", systemImage: "checkmark.circle.fill").foregroundColor(.green)
                    }
                    .font(.caption)
                }
                .padding(.vertical, 8)
            } header: {
                Text("Privacy & Security")
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

// MARK: - About View
struct AboutView: View {
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image("cat_white_full")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .shadow(radius: 5)
            
            VStack(spacing: 8) {
                Text("Copycat")
                    .font(.largeTitle)
                    .bold()
                
                Text("Version 1.0.0")
                    .font(.title3)
                    .foregroundColor(.secondary)
                
                Text("© 2026 Mikey")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Helper Views

struct ShortcutRow: View {
    let keys: String
    let desc: String
    
    var body: some View {
        HStack {
            Text(keys)
                .font(.system(.caption, design: .monospaced))
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.primary.opacity(0.1))
                .cornerRadius(4)
            
            Text(desc)
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
        }
    }
}

struct WindowAccessor: NSViewRepresentable {
    var callback: (NSWindow) -> Void

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            if let window = view.window {
                self.callback(window)
            }
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}
