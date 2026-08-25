import SwiftUI

struct TouchSurfaceView: View {
    let contacts: [TouchContact]

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                RoundedRectangle(cornerRadius: proxy.size.width * 0.22)
                    .fill(.quaternary)
                    .overlay {
                        RoundedRectangle(cornerRadius: proxy.size.width * 0.22)
                            .stroke(.secondary.opacity(0.45), lineWidth: 1)
                    }

                ForEach(contacts) { contact in
                    Circle()
                        .fill(.blue.opacity(0.72))
                        .overlay(Circle().stroke(.white.opacity(0.8), lineWidth: 1))
                        .frame(
                            width: max(18, contact.majorAxis * 2.3),
                            height: max(18, contact.minorAxis * 2.3)
                        )
                        .position(
                            x: contact.position.x * proxy.size.width,
                            y: (1 - contact.position.y) * proxy.size.height
                        )
                }

                if contacts.isEmpty {
                    Text(L10n.text("touch_instruction"))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .aspectRatio(1.55, contentMode: .fit)
        .accessibilityLabel(L10n.text("touch_surface_accessibility"))
    }
}
