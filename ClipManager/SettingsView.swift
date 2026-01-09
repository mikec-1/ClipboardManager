import SwiftUI
import ServiceManagement

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    
    @State private var settingsWindow: NSWindow?
    
    var body: some View {
        VStack(spacing: 0) {
            
            // Primary Content Area
            TabView {
                GeneralSettingsView()
                    .tabItem {
                        Label("General", systemImage: "gear")
                    }
                
                AboutSettingsView()
                    .tabItem {
                        Label("About", systemImage: "info.circle")
                    }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Fixed Footer
            ZStack {
                Color(NSColor.windowBackgroundColor)
                    .shadow(radius: 0.5)
                
                HStack {
                    Spacer()
                    Button("Done") {
                        dismiss()
                    }
                    .keyboardShortcut(.defaultAction)
                }
                .padding(.horizontal, 10)
            }
            .frame(height: 50)
        }
        .frame(width: 450, height: 250)
        
        // --- UPDATED WINDOW LOGIC ---
        .background(WindowAccessor { window in
            // Capture the window once when created
            self.settingsWindow = window
            applyWindowSettings(window)
        })
        // This listens for when the window becomes active (re-opened)
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.didBecomeKeyNotification)) { notification in
            if let window = notification.object as? NSWindow, window == settingsWindow {
                // Re-apply the settings every time the window wakes up!
                applyWindowSettings(window)
            }
        }
        .onAppear {
            NSApp.activate(ignoringOtherApps: true)
        }
    }
    
    // Helper function to apply the "Always on Top" settings
    private func applyWindowSettings(_ window: NSWindow) {
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.orderFrontRegardless()
    }
}

// MARK: - Window Accessor Helper
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

// MARK: - General Settings Tab
struct GeneralSettingsView: View {
    @AppStorage("historyLimit") private var storedLimit: Int = 20
    @State private var selectedLimit: Int = 20
    @State private var launchAtLogin: Bool = SMAppService.mainApp.status == .enabled
    
    @AppStorage("appTheme") private var appTheme: String = "system"
    
    private let labelWidth: CGFloat = 100
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center) {
                Text("Appearance:")
                    .frame(width: labelWidth, alignment: .trailing)
                
                Picker("", selection: $appTheme) {
                    Text("System").tag("system")
                    Text("Light").tag("light")
                    Text("Dark").tag("dark")
                }
                .pickerStyle(.segmented)
                .frame(width: 200)
                .padding(.leading, -1.5)
            }
            .padding(.bottom, 5)
//            .padding(.top, 30)
            
            Divider().padding(.vertical, 2)
            
            // Startup Toggle
            HStack(alignment: .center) {
                Text("Startup:")
                    .frame(width: labelWidth, alignment: .trailing)
                
                Toggle("Launch at login", isOn: $launchAtLogin)
                    .toggleStyle(.switch)
                    .onChange(of: launchAtLogin) { oldValue, newValue in
                        if newValue {
                            try? SMAppService.mainApp.register()
                        } else {
                            try? SMAppService.mainApp.unregister()
                        }
                    }
                    .padding(.leading, 5)
            }
            
            Divider().padding(.vertical, 2)
            
            // History Limit
            HStack(alignment: .center) {
                Text("History Size:")
                    .frame(width: labelWidth, alignment: .trailing)
                
                Picker("", selection: $selectedLimit) {
                    Text("10 items").tag(10)
                    Text("20 items").tag(20)
                    Text("50 items").tag(50)
                    Text("100 items").tag(100)
                }
                .labelsHidden()
                .frame(width: 120)
                .padding(.leading, -1.5)
                
                // Moved Button here to the right
                Button("Save Limit") {
                    storedLimit = selectedLimit
                }
                .padding(.leading, 10) // Add a little space between picker and button
            }
            
            Text("Older items will automatically be removed if limit is reached.")
                .font(.caption)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.leading, labelWidth + 13)
                .padding(.trailing, 20)
            
//            Spacer()
        }
        
        .onAppear {
            // Sync the local state with the stored value when view loads
            selectedLimit = storedLimit
        }
    }
}

// MARK: - About Tab
struct AboutSettingsView: View {
    var body: some View {
        VStack(spacing: 15) {
            let imageName = "cat_white_full"
            Image(imageName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 60, height: 60)
                .foregroundColor(.accentColor)
                .padding(.top, 20)
            
            Text("A simple, private clipboard history tool.\nMade with SwiftUI.")
                .font(.body)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal)
            
            VStack {
                Text("copycat")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Version 1.0.0")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text("© 2026 Mikey")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
}
