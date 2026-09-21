import AppKit
import SwiftUI

struct MenuBarIcon: View {
    var body: some View {
        Image(nsImage: Self.image)
            .accessibilityLabel("Task Tracker")
    }

    private static let image: NSImage = {
        let size = NSSize(width: 18, height: 18)
        let image = NSImage(size: size, flipped: false) { rect in
            NSColor.black.setStroke()
            let circle = NSBezierPath(ovalIn: rect.insetBy(dx: 1.4, dy: 1.4))
            circle.lineWidth = 1.5
            circle.stroke()

            let center = NSPoint(x: rect.midX, y: rect.midY)
            let hands = NSBezierPath()
            hands.lineWidth = 1.4
            hands.lineCapStyle = .round
            hands.move(to: center)
            hands.line(to: NSPoint(x: rect.midX, y: rect.maxY - 3.4))
            hands.move(to: center)
            hands.line(to: NSPoint(x: rect.maxX - 4.4, y: rect.midY + 0.6))
            hands.stroke()
            return true
        }
        image.isTemplate = true
        return image
    }()
}
