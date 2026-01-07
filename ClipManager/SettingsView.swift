import SwiftUI
import ServiceManagement

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            
            // Primary Content Area
            // We use a TabView to organize settings into distinct categories.
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
            // Forces the TabView to expand and fill all available vertical space,
            // pushing the footer to the bottom of the window.
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Fixed Footer
            // Located outside the TabView to ensure it remains stationary
            ZStack {
                Color(NSColor.windowBackgroundColor)
                    .shadow(radius: 0.5) // Adds a subtle separator line
                
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
        
        // Window Management
        // Forces the Settings window to become the active foreground window when opened,
        // preventing it from appearing behind other applications.
        .onAppear {
            NSApp.activate(ignoringOtherApps: true)
        }
    }
}

// MARK: - General Settings Tab

struct GeneralSettingsView: View {
    @AppStorage("historyLimit") private var storedLimit: Int = 20
    @State private var selectedLimit: Int = 20
    @State private var launchAtLogin: Bool = SMAppService.mainApp.status == .enabled
    
    // Fixed width for labels to create a consistent "column" effect
    private let labelWidth: CGFloat = 100
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            
            // Startup Toggle Section
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
            
            Divider()
                .padding(.vertical, 2)
            
            // History Limit Section
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
                .padding(.leading, -1.5) // Micro-adjustment for visual alignment
            }
            
            // Save Button
            HStack {
                // Spacer matches label width to align button with controls above
                Color.clear.frame(width: labelWidth, height: 1)
                
                Button("Save Limit") {
                    storedLimit = selectedLimit
                }
                .padding(.leading, 5)
            }
            
            // Explanatory Text
            Text("The app will automatically remove older items when this limit is reached.")
                .font(.caption)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.leading, labelWidth + 13)
                .padding(.trailing, 20)
            
            Spacer()
        }
        .padding(.top, 25)
    }
}

// MARK: - About Tab

struct AboutSettingsView: View {
    var body: some View {
        VStack(spacing: 15) {
            Image(systemName: "doc.on.clipboard")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 60, height: 60)
                .foregroundColor(.accentColor)
                .padding(.top, 20)
            
            VStack {
                Text("Clipboard Manager")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Version 1.0 - Michael Cole")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Text("A simple, private clipboard history tool.\nMade with SwiftUI.")
                .font(.body)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal)
        }
    }
}
