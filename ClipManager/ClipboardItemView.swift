import SwiftUI
import AppKit

struct ClipboardItemView: View {
    let item: ClipboardItem
    let onPin: () -> Void
    let onDelete: () -> Void
    
    @State private var isHovering = false
    @State private var isExpanded = false
    
    @AppStorage("showFullFilePath") private var showFullFilePath: Bool = false
    
    private var displayText: String {
        if item.type == .file, let url = item.fileURL, showFullFilePath {
            return url.path //full url path
        }
        return item.text
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            
            //icon based on what user copied
            Image(systemName: iconName(for: item.type))
                .foregroundColor(iconColor(for: item.type))
                .font(.system(size: 14))
                .padding(.top, 2)
            
            VStack(alignment: .leading, spacing: 4) {
                
                //shows either image preview or text
                if item.type == .image, let img = item.image {
                    Image(nsImage: img)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 70)
                        .cornerRadius(4)
                        .padding(.vertical, 2)
                } else if item.type == .colour {
                    //colour preview
                    HStack {
                        Circle()
                            .fill(colorFromHex(item.text))
                            .frame(width: 16, height: 16)
                            .overlay(Circle().stroke(Color.primary.opacity(0.2), lineWidth: 1))
                        Text(item.text)
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(.primary)
                    }
                } else if item.type == .file {
                    HStack(spacing: 12) {
                        //macos default preview thumbnail
                        if let img = item.image {
                            Image(nsImage: img)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 32, height: 32)
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(displayText) 
                                .lineLimit(isExpanded ? nil : 3)
                                .multilineTextAlignment(.leading)
                                .foregroundColor(.primary)
                                .font(isExpanded ? .system(.body, design: .monospaced) : .body)
                        }
                    }
                } else {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(displayText)
                            .lineLimit(isExpanded ? nil : 3) 
                            .multilineTextAlignment(.leading)
                            .foregroundColor(.primary)
                            // font modifier when expanding
                            .font(isExpanded ? .system(.body, design: .monospaced) : .body)
                        
                        //only show the button if text is long enough to need it
                        if displayText.count > 100 || item.text.filter({ $0 == "\n" }).count > 2 {
                            Button(action: {
                                withAnimation(.snappy) {
                                    isExpanded.toggle()
                                }
                            }) {
                                Text(isExpanded ? "Show Less" : "Show More")
                                    .font(.caption2)
                                    .foregroundColor(.blue)
                                    .padding(.top, 2)
                            }
                            .buttonStyle(.plain) 
                        }
                    }
                }
                
                //updates every second automatically
                TimelineView(.periodic(from: .now, by: 1.0)) { context in
                    Text(timeAgo(from: item.date, relativeTo: context.date))
                        .font(.caption2)
                        .foregroundColor(.secondary.opacity(0.8))
                }
            }
            
            Spacer(minLength: 10)
            
            HStack(spacing: 8) {
                //delete button
                Button(action: {
                    onDelete()
                }) {
                    Image(systemName: "trash")
                        .foregroundColor(.secondary.opacity(0.4))
                        .font(.system(size: 14))
                        .padding(.top, 2)
                }
                .buttonStyle(.plain)
                //on show if hovering
                .opacity(isHovering ? 1.0 : 0.0) 
                
                //pin button
                Button(action: {
                    onPin()
                }) {
                    Image(systemName: item.isPinned ? "pin.fill" : "pin")
                        .foregroundColor(item.isPinned ? .yellow : .secondary.opacity(0.4))
                        .font(.system(size: 14))
                        .padding(.top, 2)
                }
                .buttonStyle(.plain)
                //show if pinned or if hovering
                .opacity(item.isPinned || isHovering ? 1.0 : 0.0)
            }
        }
        .padding(10)
        .background(Color.primary.opacity(0.05))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.primary.opacity(0.1), lineWidth: 1)
        )
        .onHover { hovering in
            isHovering = hovering
        }
    }
    
    // MARK: - Helpers
    
    //right icon
    private func iconName(for type: ClipType) -> String {
        switch type {
        case .text: return "doc.text"
        case .image: return "photo"
        case .file: return "folder.fill"
        case .colour: return "paintpalette.fill" // NEW
        }
    }

    private func iconColor(for type: ClipType) -> Color {
        switch type {
        case .text: return .secondary
        case .image: return .blue
        case .file: return .orange
        case .colour: return .purple
        }
    }
    
    //hex string to swift colour
    func colorFromHex(_ hex: String) -> Color {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0
        Scanner(string: hexSanitized).scanHexInt64(&rgb)

        let r = Double((rgb & 0xFF0000) >> 16) / 255.0
        let g = Double((rgb & 0x00FF00) >> 8) / 255.0
        let b = Double(rgb & 0x0000FF) / 255.0

        return Color(red: r, green: g, blue: b)
    }
    
    //used to calculate "...m ago"
    func timeAgo(from date: Date, relativeTo current: Date) -> String {
        let diff = current.timeIntervalSince(date)
        
        if diff < 2 {
            return "Just now"
        }
        
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: current)
    }
}
