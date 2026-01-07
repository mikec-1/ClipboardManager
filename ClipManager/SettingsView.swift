import SwiftUI
import ServiceManagement

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            
            // --- TOP CONTENT AREA (Flexible Height) ---
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
            // This forces the TabView to take up all available space,
            // pushing the Footer to the bottom.
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // --- BOTTOM FOOTER (Fixed Height) ---
            // This sits outside the TabView, so it never jumps around.
            ZStack {
                // Background color for footer (optional, matches system)
                Color(NSColor.windowBackgroundColor)
                    .shadow(radius: 0.5) // Subtle separator line
                
                HStack {
                    Spacer()
                    Button("Done") {
                        dismiss()
                    }
                    .keyboardShortcut(.defaultAction)
                }
                .padding(.horizontal, 10)
            }
            .frame(height: 50) // 🔒 FIXED HEIGHT: The button can never move.
        }
        .frame(width: 450, height: 250)
        
        .onAppear {
            // This command forces the app to jump to the front of the screen
            NSApp.activate(ignoringOtherApps: true)
        }
    }
}

// --- GENERAL SETTINGS ---

struct GeneralSettingsView: View {
    @AppStorage("historyLimit") private var storedLimit: Int = 20
    @State private var selectedLimit: Int = 20
    @State private var launchAtLogin: Bool = SMAppService.mainApp.status == .enabled
    
    // Constant width for labels to ensure perfect vertical alignment
    let labelWidth: CGFloat = 100
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) { // Reduced spacing to 12 (was 20)
            
            // --- ROW 1: STARTUP ---
            HStack(alignment: .center) {
                Text("Startup:")
                    .frame(width: labelWidth, alignment: .trailing)
                
                Toggle("Launch at login", isOn: $launchAtLogin)
                    .toggleStyle(.switch)
                    // UPDATED SYNTAX: We now accept two parameters (oldValue, newValue)
                    .onChange(of: launchAtLogin) { oldValue, newValue in
                        if newValue {
                            try? SMAppService.mainApp.register()
                        } else {
                            try? SMAppService.mainApp.unregister()
                        }
                    }
                    .padding(.leading, 5)
            }
            
            // --- DIVIDER (Tight spacing) ---
            Divider()
//                .padding(.leading, labelWidth)
                .padding(.vertical, 2) // Very small vertical padding to bring rows closer
            
            // --- ROW 2: HISTORY SIZE ---
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
            }
            
            // --- ROW 3: SAVE BUTTON ---
            HStack {
                Color.clear.frame(width: labelWidth, height: 1) // Spacer
                
                Button("Save Limit") {
                    storedLimit = selectedLimit
                }
                .padding(.leading, 5)
            }
            
            // --- ROW 4: DESCRIPTION ---
            Text("The app will automatically remove older items when this limit is reached.")
                .font(.caption)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.leading, labelWidth + 13)
                .padding(.trailing, 20)
            
            Spacer() // Pushes everything to the top
        }
        .padding(.top, 25)
    }
}

// --- ABOUT SETTINGS ---

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
                
                Text("Version 1.0")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Text("A simple, private clipboard history tool.\nMade with SwiftUI.")
                .font(.body)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal)
            
//            Spacer()
        }
    }
}
