import SwiftUI
import Carbon

@main
struct ClipManagerApp: App {
    @StateObject private var watcher = ClipboardWatcher()
    @StateObject private var appState = AppState()
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    @State private var showControls = true
    @State private var searchText = ""

    var filteredHistory: [ClipboardItem] {
        if searchText.isEmpty {
            return watcher.history
        } else {
            return watcher.history.filter { item in
                item.text.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some Scene {
        MenuBarExtra {
            VStack(spacing: 0) {
                
                //header
                VStack(alignment: .leading, spacing: 4) {
                    Text("copycat")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    if watcher.isMonitoring {
                        Text("● Monitoring On")
//                            .font(.caption).bold()
                            .font(.headline)
                            .foregroundColor(.green)
                    } else {
                        Text("○ Monitoring Off")
//                            .font(.caption).bold()
                            .font(.headline)
                            .foregroundColor(.red)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading) //header fills the full width
                .padding(12)
                .background(Color(nsColor: .windowBackgroundColor))    
                
                Divider()
                
                if showControls {
                    VStack(spacing: 0) {
                        //controls
                        HStack(spacing: 12) {
                            //pause button
                            Button(action: {
                                watcher.isMonitoring.toggle()
                            }) {
                                Label(watcher.isMonitoring ? "Pause" : "Resume", systemImage: watcher.isMonitoring ? "pause.fill" : "play.fill")
                                    .frame(maxWidth: .infinity)
                            }
                            
                            //clear button warning
                            Button(action: {
                                showClearWarning()
                            }) {
                                Label("Clear", systemImage: "trash")
                                    .frame(maxWidth: .infinity)
                            }
                            .disabled(watcher.history.filter {
                                !$0.isPinned
                            }.isEmpty)
                        }
                        .controlSize(.regular)
                        .padding(10)
                        
                        //search Bar
                        HStack(spacing: 6) {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.secondary)
                                .font(.system(size: 12))
                            
                            TextField("Search history...", text: $searchText)
                                .textFieldStyle(.plain)
                                .font(.callout)
                            
                            if !searchText.isEmpty {
                                Button(action: { searchText = "" }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.secondary)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(6)
                        .background(Color.primary.opacity(0.05))
                        .cornerRadius(6)
                        .padding(.horizontal, 10)
                        .padding(.bottom, 8)
                        
                    }
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
                
                ZStack {
                    Divider() //adding a line
                    
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showControls.toggle()
                        }
                    }) {
                        //up and down arrow
                        Image(systemName: showControls ? "chevron.up" : "chevron.down")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.secondary.opacity(1.5))
                            .frame(width: 20, height: 12)
                            .background(Color(nsColor: .windowBackgroundColor)) // put line behind the arrow
                    }
                    .buttonStyle(.plain)
                }
                .padding(.bottom, -2)
                
                //the list
                ScrollView {
                    LazyVStack(spacing: 8) {
                        //check filteredHistory instead of watcher.history
                        if filteredHistory.isEmpty {
                            VStack(spacing: 10) {
                                //dynamic empty state
                                Image(systemName: searchText.isEmpty ? "doc.on.clipboard" : "magnifyingglass")
                                    .font(.largeTitle)
                                    .foregroundColor(.secondary.opacity(0.5))
                                
                                Text(searchText.isEmpty ? "No items copied yet" : "No results found")
                                    .font(.callout)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.top, 30)
                            .frame(maxWidth: .infinity)
                        } else {
                            // loop through filtered search
                            ForEach(filteredHistory) { item in
                                Button {
                                    //check if option is pressed
                                    let isOptionPressed = NSEvent.modifierFlags.contains(.option)
                                    copyToClipboard(item, plainText: isOptionPressed)
                                } label: {
                                    ClipboardItemView(
                                        item: item,
                                        //pin logic
                                        onPin: {
                                            watcher.togglePin(for: item)
                                        },
                                        //delete logic
                                        onDelete: {
                                            withAnimation(.easeInOut(duration: 0.2)) {
                                                watcher.history.removeAll {
                                                    $0.id == item.id
                                                }
                                            }
                                        }
                                    )                                
                                }
                                .buttonStyle(.plain)
                                //right click menu logic (same as above)
                                .contextMenu {
                                    Button(item.isPinned ? "Unpin" : "Pin Item") {
                                        watcher.togglePin(for: item)
                                    }
                                    
                                    if item.type == .text {
                                        Button("Copy as Plain Text") {
                                            copyToClipboard(item, plainText: true)
                                        }
                                    }
                                    
                                    //if copied item is image
                                    if item.type == .image {
                                        Button("Open in Preview") {
                                            if let url = item.fileURL {
                                                NSWorkspace.shared.open(url)
                                            } else if let imageData = item.imageData { //if file does not exist yet - like a screenshot
                                                let tempDir = FileManager.default.temporaryDirectory
                                                //create a temperary image
                                                let tempURL = tempDir.appendingPathComponent("copycat_\(item.id.uuidString).png")
                                                do {
                                                    //saves to disk
                                                    try imageData.write(to: tempURL)
                                                    NSWorkspace.shared.open(tempURL)
                                                } catch {
                                                    print("Could not save temporary image: \(error)")
                                                }
                                            }
                                        }
                                    }
                                    
                                    //if file
                                    if let url = item.fileURL {
                                        if item.type != .image {
                                            Button("Open File") {
                                                NSWorkspace.shared.open(url)
                                            }
                                        }
                                        
                                        Button("Copy File Path") {
                                            let pasteboard = NSPasteboard.general
                                            pasteboard.clearContents()
                                            pasteboard.setString(url.path, forType: .string)
                                            watcher.ignoreCurrentPasteboardChange() //stops duplicates
                                        }
                                        
                                        Button("Show in Finder") {
                                            NSWorkspace.shared.activateFileViewerSelecting([url])
                                        }
                                    }
                                    
                                    Divider()
                                    
                                    //delete button
                                    Button("Delete", role: .destructive) {
                                        watcher.history.removeAll {
                                            $0.id == item.id
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding(10)
                }
                .frame(maxHeight: .infinity)
                
                Divider()
                
                //footer
                HStack {
                    SettingsLink {
                        Label("Settings", systemImage: "gear")
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.secondary)
                    .font(.footnote)
                    .keyboardShortcut(",", modifiers: .command)
                    
                    Spacer()
                    
                    Button {
                        NSApplication.shared.terminate(nil)
                    } label: {
                        Label("Quit", systemImage: "power")
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.secondary)
                    .font(.footnote)
                    .keyboardShortcut("q")
                }
                .padding(10)
            }
            .frame(width: 360, height: 500)
        } label: {
            HStack(spacing: 4) {
                let imageName = watcher.isMonitoring ? "catnew" : "cat_asleep"
                
                //switch image
                switch appState.menuBarStyle {
                    case .iconAndText:
                        Image(imageName)
                        Text(watcher.isMonitoring ? "Monitoring" : "Asleep")
                            .font(.body)
                        
                    case .iconOnly:
                        Image(imageName)
                        
                    case .symbolOnly:
                        Image(systemName: watcher.isMonitoring ? "clipboard.fill" : "clipboard")
                }
            }
        }
        .menuBarExtraStyle(.window)
        
        //settings
        Settings {
            SettingsView(appState: appState, clipboardWatcher: watcher)
                .preferredColorScheme(appState.appearance.colorScheme)
        }
    }
    
    //shows warning before clearing history
    func showClearWarning() {
        let alert = NSAlert()
        alert.messageText = "Clear History?"
        alert.informativeText = "This will delete all unpinned copied items. This action cannot be undone."
        alert.addButton(withTitle: "Clear All")
        alert.addButton(withTitle: "Cancel")
        alert.alertStyle = .warning
        
        NSApp.activate(ignoringOtherApps: true)
        let response = alert.runModal()
        
        if response == .alertFirstButtonReturn {
            watcher.history.removeAll { !$0.isPinned }
        }
    }
    
    func copyToClipboard(_ item: ClipboardItem, plainText: Bool = false) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        
        switch item.type {
            case .text, .colour:
                if plainText {
                    //option key used so plain text copied 
                    let cleanText = item.text.trimmingCharacters(in: .whitespacesAndNewlines)
                    pasteboard.setString(cleanText, forType: .string)
                    print("Copied as plain text: \(cleanText)")
                } else {
                    //normal click and checks for rich text
                    if let rtf = item.rtfData {
                        pasteboard.setData(rtf, forType: .rtf)
                        pasteboard.setString(item.text, forType: .string)
                        print("Copied with RTF formatting")
                    } else {
                        pasteboard.setString(item.text, forType: .string)
                        print("Copied as standard text")
                    }
                }
            case .image:
                if let img = item.image { 
                    pasteboard.writeObjects([img])
                    print("Copied image")
                }
            case .file:
                if let url = item.fileURL { 
                    pasteboard.writeObjects([url as NSURL])
                    print("Copied file: \(url.lastPathComponent)")
                }
        }
        
        watcher.ignoreCurrentPasteboardChange()
    }
}

// MARK: - Hotkey Manager
class HotkeyManager {
    static let shared = HotkeyManager()
    
    private var eventMonitor: Any?
    weak var appDelegate: AppDelegate?
    
    //start listening for the hotkey
    func start(shortcut: KeyboardShortcut, appDelegate: AppDelegate) {
        self.appDelegate = appDelegate
        stop()
        
        //checks accessibility permissions
        if !hasAccessibilityPermissions() {
            print("Need accessibility permissions for global hotkeys")
            requestAccessibilityPermissions()
            return
        }
        
        //listen for key presses anywhere on the system
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self = self else { return }
            
            //is the key = shortcut
            if self.isMatch(event: event, shortcut: shortcut) {
                print("Hotkey pressed!")
                self.appDelegate?.openMenuBar()
            }
        }
        
        print("Hotkey active: \(shortcut.displayString)")
    }
    
    //stop listening
    func stop() {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
    }
    
    //does pressed keys match shortcut
    private func isMatch(event: NSEvent, shortcut: KeyboardShortcut) -> Bool {
        //check key code
        if UInt32(event.keyCode) != shortcut.keyCode {
            return false
        }
        
        //convert modifier flags to Carbon format
        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        var eventModifiers: UInt32 = 0
        
        if flags.contains(.command) { eventModifiers |= UInt32(cmdKey) }
        if flags.contains(.shift) { eventModifiers |= UInt32(shiftKey) }
        if flags.contains(.option) { eventModifiers |= UInt32(optionKey) }
        if flags.contains(.control) { eventModifiers |= UInt32(controlKey) }
        
        //check if modifiers match
        return eventModifiers == shortcut.modifiers
    }
    
    //checks accessibility permissions
    private func hasAccessibilityPermissions() -> Bool {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: false]
        return AXIsProcessTrustedWithOptions(options)
    }
    
    //asks for accessibility permissions
    private func requestAccessibilityPermissions() {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        AXIsProcessTrustedWithOptions(options)
        
        //the alert asking for permission
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = "Accessibility Permission Required"
            alert.informativeText = "copycat needs accessibility permission to use global keyboard shortcuts.\n\nPlease:\n1. Click 'Open System Settings'\n2. Add copycat to the list and enable it\n3. Restart copycat"
            alert.alertStyle = .informational
            alert.addButton(withTitle: "Open System Settings")
            alert.addButton(withTitle: "Later")
            
            let response = alert.runModal()
            
            if response == .alertFirstButtonReturn {
                //opens settings to accessibility
                let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
                NSWorkspace.shared.open(url)
            }
        }
    }
}

// MARK: - App Delegate
class AppDelegate: NSObject, NSApplicationDelegate {    
    var statusBarButton: NSStatusBarButton?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        //Find the status bar button after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.findStatusBarButton()
        }
        
        //Register the initial hotkey
        let currentShortcut = ShortcutManager.shared.currentShortcut
        HotkeyManager.shared.start(shortcut: currentShortcut, appDelegate: self)
        
        //listen for shortcut changes
        ShortcutManager.shared.onShortcutChanged = { [weak self] newShortcut in
            guard let self = self else { return }
            HotkeyManager.shared.start(shortcut: newShortcut, appDelegate: self)
            print("Hotkey updated to: \(newShortcut.displayString)")
        }
        
        //escape key to cloe
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == 53 {
                if let keyWindow = NSApp.keyWindow,
                   !keyWindow.styleMask.contains(.titled) {
                    self?.openMenuBar()
                    return nil
                }
            }
            return event
        }
    }
    
    func findStatusBarButton() {
        for window in NSApp.windows {
            if let button = searchForButton(in: window.contentView) {
                self.statusBarButton = button
                print("Found menu button!")
                return
            }
        }
        print("Menu button not found")
    }
    
    func searchForButton(in view: NSView?) -> NSStatusBarButton? {
        guard let view = view else { return nil }
        
        if let button = view as? NSStatusBarButton {
            return button
        }
        
        for subview in view.subviews {
            if let button = searchForButton(in: subview) {
                return button
            }
        }
        
        return nil
    }
    
    func openMenuBar() {
        print("Opening menu bar")
        
        if statusBarButton == nil {
            findStatusBarButton()
        }
        
        if let button = statusBarButton {
            button.performClick(nil)
            print("Menu opened")
        }
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        HotkeyManager.shared.stop()
        
        if UserDefaults.standard.bool(forKey: "clearOnQuit") {
            print("Clearing unpinned history on quit")
        }
    }
}
