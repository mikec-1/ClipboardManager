import SwiftUI

struct ClipboardItemView: View {
    let item: ClipboardItem
    
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            //icon
            Image(systemName: "doc.text")
                .foregroundColor(.secondary)
                .font(.system(size: 12))
                .padding(.top, 2)
            
            VStack(alignment: .leading, spacing: 4) {
                //the copied text
                Text(item.text)
//                    .font(.system(.body, design: .monospaced))
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
                    .foregroundColor(.primary)
                
                //updates every second automatically
                TimelineView(.periodic(from: .now, by: 1.0)) { context in
                    Text(timeAgo(from: item.date, relativeTo: context.date))
                        .font(.caption2)
                        .foregroundColor(.secondary.opacity(0.8))
                }
            }
            
            Spacer()
        }
        .padding(10)
        .background(Color.primary.opacity(0.05))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.primary.opacity(0.1), lineWidth: 1)
        )
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
