import SwiftUI
import AppKit
import Combine
import Foundation

// MARK: - Data Models
enum ClipType: String, Codable {
    case text
    case image
    case file
    case colour
}

struct ClipboardItem: Identifiable, Codable, Equatable, Hashable {
    var id: UUID = UUID()
    let text: String
    let type: ClipType
    let imageData: Data?
    let fileURL: URL?
    let rtfData: Data?
    var isPinned: Bool = false
    let date: Date
    
    var image: NSImage? {
        imageData.flatMap(NSImage.init(data:))
    }
}

struct IgnoredApp: Identifiable, Codable, Hashable {
    var id: String { bundleID }
    let bundleID: String
    let name: String
}

class ClipboardWatcher: ObservableObject {
    
    //default value is 50
    @AppStorage("historyLimit") private var historyLimit: Int = 50
    @AppStorage("ignorePasswordManagers") var ignorePasswordManagers: Bool = true
    @AppStorage("ignoreCustomApps") var ignoreCustomApps: Bool = true
    
    private let pasteboard = NSPasteboard.general
    private var lastChangeCount: Int
    private var timer: Timer?
    
    @Published var ignoredApps: [IgnoredApp] = [] {
        didSet {
            if let encoded = try? JSONEncoder().encode(ignoredApps) {
                UserDefaults.standard.set(encoded, forKey: "customIgnoredApps")
            }
        }
    }
    
    @Published var isMonitoring: Bool = true {
        didSet {
            //stops app from adding copied items after unpaused
            if isMonitoring { lastChangeCount = pasteboard.changeCount }
        }
    }
    
    @Published var history: [ClipboardItem] = [] {
        didSet {
            saveHistory()
        }
    }
    
    //restricted apps
    private let builtInRestrictedApps: Set<String> = [
        "com.agilebits.onepassword7",
        "com.1password.1password",
        "com.lastpass.LastPass",
        "com.apple.keychainaccess",
        "com.apple.Passwords",
        "com.dashlane.Dashlane",
        "com.dashlane.DashlaneAgent",
        "com.bitwarden.desktop",
        "org.keepassxc.keepassxc"
    ]
    
    init() {
        //load on startup
        self.lastChangeCount = pasteboard.changeCount
        loadHistory()
        loadIgnoredApps()
        startWatching()
        
        // clear history on quit if user enabled it
        NotificationCenter.default.addObserver(forName: NSApplication.willTerminateNotification, object: nil, queue: .main) { [weak self] _ in
            if UserDefaults.standard.bool(forKey: "clearOnQuit") {
                self?.history.removeAll { !$0.isPinned }
                self?.saveHistory()
            }
        }
    }
    
    func startWatching() {
        //every 0.5s check
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.checkClipboard()
        }
    }
    
    func ignoreCurrentPasteboardChange() {
        self.lastChangeCount = NSPasteboard.general.changeCount
    }
    
    func updateHistorySize(_ size: Int) {
        historyLimit = size
        enforceHistoryLimit()
    }
    
    private func checkClipboard() {
        guard isMonitoring, pasteboard.changeCount != lastChangeCount else { return }
        lastChangeCount = pasteboard.changeCount
        
        // check restricted apps
        if let frontApp = NSWorkspace.shared.frontmostApplication, let bundleID = frontApp.bundleIdentifier {
            if ignorePasswordManagers && builtInRestrictedApps.contains(bundleID) { return }
            if ignoreCustomApps && ignoredApps.contains(where: { $0.bundleID == bundleID }) { return }
        }
        
        var newItem: ClipboardItem?
        
        // files
        if let types = pasteboard.types, types.contains(.fileURL),
           let urls = pasteboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL], let firstURL = urls.first {
            
            let ext = firstURL.pathExtension.lowercased()
            if ["png", "jpg", "jpeg", "gif", "tiff", "heic"].contains(ext), let img = NSImage(contentsOf: firstURL) {
                newItem = ClipboardItem(text: firstURL.lastPathComponent, type: .image, imageData: pngData(from: img), fileURL: firstURL, rtfData: nil, date: Date())
            } else {
                let fileIcon = NSWorkspace.shared.icon(forFile: firstURL.path)
                fileIcon.size = NSSize(width: 128, height: 128)
                newItem = ClipboardItem(text: firstURL.lastPathComponent, type: .file, imageData: pngData(from: fileIcon), fileURL: firstURL, rtfData: nil, date: Date())
            }
        }
        // just images
        else if let img = pasteboard.readObjects(forClasses: [NSImage.self], options: nil)?.first as? NSImage {
            newItem = ClipboardItem(text: "Image copied", type: .image, imageData: pngData(from: img), fileURL: nil, rtfData: nil, date: Date())
        }
        
        // text & colours
        else if let newString = pasteboard.string(forType: .string) {
            let trimmed = newString.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                let hexRegex = "^#?[0-9A-Fa-f]{6}$"
                if trimmed.range(of: hexRegex, options: .regularExpression) != nil {
                    newItem = ClipboardItem(text: trimmed.uppercased(), type: .colour, imageData: nil, fileURL: nil, rtfData: nil, date: Date())
                } else {
                    newItem = ClipboardItem(text: newString, type: .text, imageData: nil, fileURL: nil, rtfData: extractRTF(from: pasteboard), date: Date())
                }
            }
        }
        
        guard let item = newItem else { return }
        
        //ignore duplicates based on content type
        let isDuplicate: (ClipboardItem) -> Bool = { existing in
            switch item.type {
                case .text, .colour: 
                    return existing.text == item.text
                case .file: 
                    return existing.fileURL == item.fileURL
                case .image: 
                    return existing.imageData == item.imageData
            }
        }
        
        if history.contains(where: { isDuplicate($0) && $0.isPinned }) { return }
        history.removeAll(where: { isDuplicate($0) && !$0.isPinned })
        
        history.insert(item, at: 0)
        enforceHistoryLimit()
        sortHistory()
    }
    
    private func enforceHistoryLimit() {
        let unpinnedCount = history.filter { !$0.isPinned }.count
        let itemsToRemove = unpinnedCount - historyLimit
        
        if itemsToRemove > 0 {
            for _ in 0..<itemsToRemove {
                if let lastUnpinnedIndex = history.lastIndex(where: { !$0.isPinned }) {
                    history.remove(at: lastUnpinnedIndex)
                }
            }
        }
    }
    
    func togglePin(for item: ClipboardItem) {
        guard let index = history.firstIndex(where: { $0.id == item.id }) else { return }
        
        var updatedHistory = history
        updatedHistory[index].isPinned.toggle()
        
        updatedHistory.sort {
            if $0.isPinned == $1.isPinned {
                return $0.date > $1.date
            }
            return $0.isPinned && !$1.isPinned
        }
        
        self.history = updatedHistory
    }
    
    //sort history with pinned items in mind
    private func sortHistory() {
        history.sort {
            if $0.isPinned == $1.isPinned { return $0.date > $1.date }
            return $0.isPinned && !$1.isPinned
        }
    }
    //saves history
    private func saveHistory() {
        if let encoded = try? JSONEncoder().encode(history) {
            UserDefaults.standard.set(encoded, forKey: "ClipboardHistoryItems")
        }
    }
    //loads history
    private func loadHistory() {
        if let data = UserDefaults.standard.data(forKey: "ClipboardHistoryItems"),
           let decoded = try? JSONDecoder().decode([ClipboardItem].self, from: data) {
            self.history = decoded
        }
    }
    //check for custom apps
    private func loadIgnoredApps() {
        if let data = UserDefaults.standard.data(forKey: "customIgnoredApps"),
           let decoded = try? JSONDecoder().decode([IgnoredApp].self, from: data) {
            self.ignoredApps = decoded
        }
    }
    
    // MARK: - Helpers
    //get data from png (image.toPNG() substitute)
    private func pngData(from image: NSImage) -> Data? {
        guard let tiff = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiff) else { return nil }
        return bitmap.representation(using: .png, properties: [:])
    }
    
    //convert text to rtf and get rtf format back
    private func extractRTF(from pasteboard: NSPasteboard) -> Data? {
        guard let attrStr = pasteboard.readObjects(forClasses: [NSAttributedString.self], options: nil)?.first as? NSAttributedString else { return nil }
        return try? attrStr.data(
            from: NSRange(location: 0, length: attrStr.length),
            documentAttributes: [.documentType: NSAttributedString.DocumentType.rtf]
        )
    }
}
