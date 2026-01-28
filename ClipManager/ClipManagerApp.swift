import SwiftUI
import Carbon

@main
struct ClipManagerApp: App {
    @StateObject private var watcher = ClipboardWatcher()
    @StateObject private var appState = AppState()
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
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
                
                //controls
                HStack(spacing: 12) {
                    Button(action: {
                        watcher.isMonitoring.toggle()
                    }) {
                        Label(watcher.isMonitoring ? "Pause" : "Resume", systemImage: watcher.isMonitoring ? "pause.fill" : "play.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .controlSize(.small)
                    
                    Button(action: {
                        watcher.history.removeAll()
                    }) {
                        Label("Clear", systemImage: "trash")
                            .frame(maxWidth: .infinity)
                    }
                    .controlSize(.small)
                    .disabled(watcher.history.isEmpty)
                }
                .padding(10)
                
                Divider()
                
                //the list
                ScrollView {
                    LazyVStack(spacing: 8) {
                        if watcher.history.isEmpty {
                            VStack(spacing: 10) {
                                Image(systemName: "doc.on.clipboard")
                                    .font(.largeTitle)
                                    .foregroundColor(.secondary.opacity(0.5))
                                Text("No items copied yet")
                                    .font(.callout)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.top, 30)
                            .frame(maxWidth: .infinity)
                        } else {
                            //loop through ClipboardItem objects
                            ForEach(watcher.history) { item in
                                Button {
                                    copyToClipboard(item.text)
                                } label: {
                                    ClipboardItemView(item: item) //pass the full item
                                }
                                .buttonStyle(.plain)
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
                .background(Color(nsColor: .windowBackgroundColor))
            }
            .frame(width: 320, height: 450)
            
        } label: {
            let imageName = watcher.isMonitoring ? "cat_white_small" : "cat_asleep"
            let word = watcher.isMonitoring ? " Monitoring" : " Asleep"
            Text(word)
            Image(imageName)
        }
        .menuBarExtraStyle(.window)
        
        //settings
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

//open menu with hotkey
class AppDelegate: NSObject, NSApplicationDelegate {
    var eventMonitor: Any?
    var statusBarButton: NSStatusBarButton?
    var hotKeyRef: EventHotKeyRef?
    var eventHandler: EventHandlerRef?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        //Find the status bar button after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now()) {
            self.findStatusBarButton()
        }
        
        //Register the initial hotkey
        registerHotkey(ShortcutManager.shared.currentShortcut)
        
        //listen for shortcut changes
        ShortcutManager.shared.onShortcutChanged = { [weak self] newShortcut in
            self?.unregisterHotkey()
            self?.registerHotkey(newShortcut)
            print("Hotkey updated to: \(newShortcut.displayString)")
        }
        
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == 53 {
                if let keyWindow = NSApp.keyWindow {
                    if keyWindow.styleMask.contains(.titled) {
                        return event
                    }
                    
                    //if no title bar it's the menu bar item and should be closed
                    self?.openMenuBar()
                    return nil
                }
            }
            return event
        }
    }
    
    func registerHotkey(_ shortcut: KeyboardShortcut) {
        unregisterHotkey()
        
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            //convert NSEvent modifiers to Carbon format for comparison
            let eventModifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            var carbonModifiers: UInt32 = 0
            
            if eventModifiers.contains(.command) { carbonModifiers |= UInt32(cmdKey) }
            if eventModifiers.contains(.shift) { carbonModifiers |= UInt32(shiftKey) }
            if eventModifiers.contains(.option) { carbonModifiers |= UInt32(optionKey) }
            if eventModifiers.contains(.control) { carbonModifiers |= UInt32(controlKey) }
            
            //check if keyCode and modifiers match
            if carbonModifiers == shortcut.modifiers && UInt32(event.keyCode) == shortcut.keyCode {
                print("Hotkey pressed: \(shortcut.displayString)")
                self?.openMenuBar()
            }
        }
        
        print("Hotkey registered: \(shortcut.displayString)")
    }
    
    func unregisterHotkey() {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
    }
    
    func findStatusBarButton() {
        for window in NSApp.windows {
            if let button = self.searchForButton(in: window.contentView) {
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
            DispatchQueue.main.async {
                button.performClick(nil)
                print("Menu opened")
            }
        } else {
            print("Didn't find menu button")
        }
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        unregisterHotkey()
    }
}
