import SwiftUI
import ServiceManagement
import UniformTypeIdentifiers
import Combine
import Carbon

// MARK: - Keyboard Shortcut Logic
struct KeyboardShortcut: Codable, Equatable {
    let keyCode: UInt32
    let modifiers: UInt32
    
    var displayString: String {
        var result = ""
        
        if modifiers & UInt32(controlKey) != 0 { result += "⌃" }
        if modifiers & UInt32(optionKey) != 0 { result += "⌥" }
        if modifiers & UInt32(shiftKey) != 0 { result += "⇧" }
        if modifiers & UInt32(cmdKey) != 0 { result += "⌘" }
        
        //convert key code to character
        result += keyCodeToString(keyCode)
        
        return result
    }
    
    private func keyCodeToString(_ code: UInt32) -> String {
        let keyMap: [UInt32: String] = [
            0: "A", 1: "S", 2: "D", 3: "F", 4: "H", 5: "G", 6: "Z", 7: "X",
            8: "C", 9: "V", 11: "B", 12: "Q", 13: "W", 14: "E", 15: "R",
            16: "Y", 17: "T", 31: "O", 32: "U", 34: "I", 35: "P",
            37: "L", 38: "J", 40: "K", 45: "N", 46: "M",
            18: "1", 19: "2", 20: "3", 21: "4", 23: "5", 22: "6", 26: "7",
            28: "8", 25: "9", 29: "0",
            36: "↩︎", 48: "⇥", 49: "Space", 51: "⌫", 53: "⎋"
        ]
        return keyMap[code] ?? "?"
    }
    
    static var defaultShortcut: KeyboardShortcut {
        KeyboardShortcut(keyCode: 7, modifiers: UInt32(cmdKey + shiftKey)) // cmd shift x
    }
}

// MARK: - Shortcut Manager
class ShortcutManager: ObservableObject {
    static let shared = ShortcutManager()
    
    @Published var currentShortcut: KeyboardShortcut {
        didSet {
            saveShortcut()
        }
    }
    
    var onShortcutChanged: ((KeyboardShortcut) -> Void)?
    
    private init() {
        //load saved shortcut or use default
        if let data = UserDefaults.standard.data(forKey: "globalShortcut"),
           let shortcut = try? JSONDecoder().decode(KeyboardShortcut.self, from: data) {
            self.currentShortcut = shortcut
        } else {
            self.currentShortcut = .defaultShortcut
        }
    }
    
    private func saveShortcut() {
        if let data = try? JSONEncoder().encode(currentShortcut) {
            UserDefaults.standard.set(data, forKey: "globalShortcut")
        }
        onShortcutChanged?(currentShortcut)
    }
}

// MARK: - Shortcut Recorder View
struct ShortcutRecorderView: View {
    @ObservedObject var manager = ShortcutManager.shared
    @State private var showSheet = false
    
    var body: some View {
        HStack {
            Text(manager.currentShortcut.displayString)
                .font(.system(.body, design: .monospaced))
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.primary.opacity(0.1))
                .cornerRadius(6)
            
            Button("Edit") { 
                showSheet = true }
                .buttonStyle(.bordered)
        }
        .sheet(isPresented: $showSheet) {
            ShortcutRecorderSheet(isPresented: $showSheet)
        }
    }
}

// MARK: - Shortcut Recorder Sheet
struct ShortcutRecorderSheet: View {
    @Binding var isPresented: Bool
    @ObservedObject var manager = ShortcutManager.shared
    @State private var isRecording = false
    @State private var recordedShortcut: KeyboardShortcut?
    @State private var eventMonitor: Any?
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Record Keyboard Shortcut").font(.title2).bold()
            Text("Press your desired key combination").foregroundColor(.secondary)
            
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(isRecording ? Color.blue.opacity(0.1) : Color.gray.opacity(0.1))
                    .frame(height: 100)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(isRecording ? Color.blue : Color.gray, lineWidth: 2))
                
                if let shortcut = recordedShortcut {
                    Text(shortcut.displayString).font(.system(size: 32, design: .monospaced)).bold()
                } else if isRecording {
                    Text("Waiting for input...").foregroundColor(.secondary).italic()
                } else {
                    Text(manager.currentShortcut.displayString).font(.system(size: 32, design: .monospaced)).bold().foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 40)
            
            HStack(spacing: 12) {
                Button("Cancel") { stopRecording(); isPresented = false }
                    .keyboardShortcut(.cancelAction)
                
                if isRecording {
                    Button("Stop Recording") {
                        stopRecording()
                    }
                    .buttonStyle(.bordered)
                } else {
                    Button("Start Recording") {
                        startRecording()
                    }
                    .buttonStyle(.borderedProminent)
                }
                
                if let shortcut = recordedShortcut {
                    Button("Save") {
                        manager.currentShortcut = shortcut
                        stopRecording()
                        isPresented = false
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            
            Text("⚠️ Make sure to use modifier keys (⌘, ⇧, ⌥, ⌃)")
                .font(.caption)
                .foregroundColor(.orange)
        }
        .padding(30)
        .frame(width: 450, height: 300)
        .onDisappear {
            stopRecording()
        }
    }
    
    func startRecording() {
        isRecording = true
        recordedShortcut = nil
        
        //monitor key events
        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            let modifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            
            //convert NSEvent modifiers to Carbon modifiers
            var carbonModifiers: UInt32 = 0
            if modifiers.contains(.command) { carbonModifiers |= UInt32(cmdKey) }
            if modifiers.contains(.shift) { carbonModifiers |= UInt32(shiftKey) }
            if modifiers.contains(.option) { carbonModifiers |= UInt32(optionKey) }
            if modifiers.contains(.control) { carbonModifiers |= UInt32(controlKey) }
            
            //accept if at least one modifier is pressed
            if carbonModifiers != 0 {
                recordedShortcut = KeyboardShortcut(
                    keyCode: UInt32(event.keyCode),
                    modifiers: carbonModifiers)
            }
            
            return nil //consume event
        }
    }
    
    func stopRecording() {
        isRecording = false
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
    }
}


// MARK: - Settings View
struct SettingsView: View {
    @ObservedObject var appState: AppState
    @ObservedObject var clipboardWatcher: ClipboardWatcher
    
    var body: some View {
        TabView {
            GeneralSettingsView(appState: appState, clipboardWatcher: clipboardWatcher)
                .tabItem {
                    Label("General", systemImage: "gear")
                }
            
            PrivacySettingsView(clipboardWatcher: clipboardWatcher)
                .tabItem {
                    Label("Privacy", systemImage: "hand.raised.fill")
                }
            
            AboutView()
                .tabItem {
                    Label("About", systemImage: "info.circle")
                }
        }
        .frame(width: 500, height: 500)
        .preferredColorScheme(appState.appearance.colorScheme)
        
        //toggles the dock icon if settings window appears/disappears
        .onAppear {
            NSApp.setActivationPolicy(.regular) //show dock icon
            NSApp.activate(ignoringOtherApps: true) //bring to front
        }
        .onDisappear {
            NSApp.setActivationPolicy(.accessory) //hide dock icon
            NSApp.hide(nil)
        }
    }
}

// MARK: - General Settings View
struct GeneralSettingsView: View {
    @ObservedObject var appState: AppState
    @ObservedObject var clipboardWatcher: ClipboardWatcher
    
    @AppStorage("historyLimit") private var storedLimit: Int = 20
    @State private var selectedLimit: Int = 20
    @State private var launchAtLogin: Bool = SMAppService.mainApp.status == .enabled
    
    var body: some View {
        Form {
            Section(header: Text("Appearance")) {
                Picker("Appearance", selection: $appState.appearance) {
                    ForEach(AppState.AppearanceMode.allCases, id: \.self) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                
                Picker("Menu Bar Style", selection: $appState.menuBarStyle) {
                    ForEach(AppState.MenuBarStyle.allCases, id: \.self) { style in
                        Text(style.rawValue).tag(style)
                    }
                }
                .pickerStyle(.menu)
            }
            
            Section(header: Text("Startup")) {
                Toggle("Launch at Login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { _, newValue in
                        if newValue {
                            try? SMAppService.mainApp.register()
                        } else {
                            try? SMAppService.mainApp.unregister()
                        }
                    }
            }
            
            Section(header: Text("Clipboard History")) {
                HStack {
                    Text("History Size")
                    Spacer()
                    Picker("", selection: $selectedLimit) {
                        Text("10 items").tag(10)
                        Text("20 items").tag(20)
                        Text("50 items").tag(50)
                        Text("100 items").tag(100)
                    }
                    .labelsHidden()
                    .frame(width: 120)
                    Button("Save Limit") {
                        clipboardWatcher.updateHistorySize(selectedLimit)
                    }
                }
                Text("Older items will automatically be removed if limit is reached.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Section(header: Text("Keyboard Shortcuts")) {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Toggle Menu:")
                            .padding(.top, -10)
                        Spacer()
                        ShortcutRecorderView()
                    }
                    
                    Text("This shortcut opens the copycat menu from anywhere.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
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
    @AppStorage("ignoreCustomApps") private var ignoreCustomApps: Bool = true
    
    @ObservedObject var clipboardWatcher: ClipboardWatcher
    
    var body: some View {
        Form {
            Section(header: Text("Auto-Detection")) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 8) {
                        Image(systemName: "shield.checkered")
                            .font(.title2)
                            .foregroundColor(.green)
                        
                        Text("Password Manager Protection")
                            .font(.headline)
                    }
                    
                    Text("copycat automatically ignores clipboard content from password managers to keep your passwords secure.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    
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
                        Label("Apple Passwords", systemImage: "checkmark.circle.fill").foregroundColor(.green)
                        Label("Dashlane", systemImage: "checkmark.circle.fill").foregroundColor(.green)
                    }
                    .opacity(ignorePasswordManagers ? 1.0 : 0.5)
                    .font(.caption)
                }
                .padding(.vertical, 8)
            }
            
            Section(header: Text("Custom Rules"), footer: Text("copycat will stop recording your Clipboard in added Apps.")) {
                VStack(alignment: .leading, spacing: 10) {
                    Toggle("Ignore Custom Applications", isOn: $ignoreCustomApps)
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Divider()
                        
                        if clipboardWatcher.ignoredApps.isEmpty {
                            Text("No custom apps added.")
                                .foregroundColor(.secondary)
                                .italic()
                                .padding(.vertical, 4)
                        } else {
                            ForEach(clipboardWatcher.ignoredApps) { app in
                                HStack {
                                    Image(nsImage: NSWorkspace.shared.icon(forFile: NSWorkspace.shared.urlForApplication(withBundleIdentifier: app.bundleID)?.path ?? ""))
                                        .resizable()
                                        .frame(width: 16, height: 16)
                                    
                                    Text(app.name)
                                    Spacer()
                                    Button(action: {
                                        deleteApp(app)
                                    }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.secondary)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        
                        Button("Add Application...") {
                            selectApp()
                        }
                    }
                    .opacity(ignoreCustomApps ? 1.0 : 0.5)
                    .disabled(!ignoreCustomApps)
                }
                .padding(.vertical, 4)
            }
        }
        .formStyle(.grouped)
        .padding()
    }
    
    private func deleteApp(_ app: IgnoredApp) {
        if let index = clipboardWatcher.ignoredApps.firstIndex(of: app) {
            clipboardWatcher.ignoredApps.remove(at: index)
        }
    }
    
    private func selectApp() {
        let panel = NSOpenPanel()
        panel.level = .modalPanel
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.allowedContentTypes = [.application]
        panel.prompt = "Add App"
        
        NSApp.activate(ignoringOtherApps: true)
        
        panel.begin { response in
            if response == .OK, let url = panel.url {
                if let bundle = Bundle(url: url),
                   let bundleID = bundle.bundleIdentifier {
                    
                    let name = (bundle.infoDictionary?["CFBundleName"] as? String) ?? url.deletingPathExtension().lastPathComponent
                    let newApp = IgnoredApp(bundleID: bundleID, name: name)
                    
                    DispatchQueue.main.async {
                        if !clipboardWatcher.ignoredApps.contains(where: { $0.bundleID == bundleID }) {
                            clipboardWatcher.ignoredApps.append(newApp)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - About View
struct AboutView: View {
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
//            Image(systemName: "doc.on.clipboard")
            Image("cat_white_full")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
            
            //@Environment(\.colorScheme) var colorScheme
            // apply a color filter based on the mode
            // light Mode -> turn icon black
            // dark Mode -> icon white
//            .foregroundColor(colorScheme == .light ? .black : .white)
            // Since App Icons are usually not templates, we use .colorMultiply or .renderingMode
//            .colorMultiply(colorScheme == .light ? .black : .white)
//            .shadow(radius: 5)
            
            
            VStack(spacing: 8) {
                Text("copycat")
                    .font(.largeTitle)
                    .bold()
                
                Text("Version 2.1.0")
                    .font(.title3)
                    .foregroundColor(.secondary)
                
                Text("© 2026 Mikey")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Link(destination: URL(string: "https://github.com/mikec-1/copycat")!) {
                HStack(spacing: 6) {
                    Image(systemName: "lightbulb.fill")
                    Text("Github - Feedback or Ideas")
                }
                .foregroundColor(.blue)
            }
            .buttonStyle(.plain)
            .onHover { inside in
                if inside {
                    NSCursor.pointingHand.push()
                }
                else {
                    NSCursor.pop()
                }
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
