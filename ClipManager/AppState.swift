import SwiftUI
import Combine

class AppState: ObservableObject {
    @AppStorage("menuBarStyle") var menuBarStyle: MenuBarStyle = .iconOnly
    
    @Published var appearance: AppearanceMode {
        didSet {
            UserDefaults.standard.set(appearance.rawValue, forKey: "appTheme")
        }
    }
    
    enum AppearanceMode: String, CaseIterable {
        case system = "System"
        case light = "Light"
        case dark = "Dark"
        
        var colorScheme: ColorScheme? {
            switch self {
            case .system: return nil
            case .light: return .light
            case .dark: return .dark
            }
        }
    }
    
    init() {
        let savedTheme = UserDefaults.standard.string(forKey: "appTheme") ?? "System"
        self.appearance = AppearanceMode(rawValue: savedTheme) ?? .system
    }
    
    enum MenuBarStyle: String, CaseIterable, Identifiable {
            case iconAndText = "Icon & Text"
            case iconOnly = "Icon Only"
            case symbolOnly = "Symbol Only"
            
        var id: String {
            self.rawValue
        }
    }
}
