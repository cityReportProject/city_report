import SwiftUI

struct UrgencyBadge: View {
    let urgency: UrgencyLevel

    var body: some View {
        Text(urgency.label)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(urgencyColor(urgency).opacity(0.15))
            .foregroundStyle(urgencyColor(urgency))
            .clipShape(Capsule())
    }
}

struct StatusBadge: View {
    let status: ReportStatus

    private var color: Color {
        switch status {
        case .open: return .blue
        case .resolved: return .green
        }
    }

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: status.icon)
            Text(status.label)
        }
        .font(.caption2.weight(.semibold))
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.15))
        .foregroundStyle(color)
        .clipShape(Capsule())
    }
}
