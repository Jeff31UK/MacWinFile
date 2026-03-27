import Cocoa

class WinFileButton: NSButton {
    var isPressed = false

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        self.isBordered = false
        self.wantsLayer = true
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.isBordered = false
        self.wantsLayer = true
    }

    override func draw(_ dirtyRect: NSRect) {
        let bounds = self.bounds

        // Button face
        WinFileColors.buttonFace.setFill()
        bounds.fill()

        // 3D border
        if isHighlighted || isPressed {
            WinFileTheme.drawSunkenBorder(in: bounds)
        } else {
            WinFileTheme.drawRaisedBorder(in: bounds)
        }

        // Draw title centered
        let titleAttr: [NSAttributedString.Key: Any] = [
            .font: WinFileFonts.toolbar,
            .foregroundColor: NSColor.black
        ]
        let titleSize = (title as NSString).size(withAttributes: titleAttr)
        let titleRect = NSRect(
            x: (bounds.width - titleSize.width) / 2,
            y: (bounds.height - titleSize.height) / 2,
            width: titleSize.width,
            height: titleSize.height
        )
        (title as NSString).draw(in: titleRect, withAttributes: titleAttr)

        // Draw image if present
        if let img = image {
            let imgRect = NSRect(
                x: (bounds.width - img.size.width) / 2,
                y: (bounds.height - img.size.height) / 2,
                width: img.size.width,
                height: img.size.height
            )
            img.draw(in: imgRect, from: .zero, operation: .sourceOver, fraction: 1.0)
        }
    }

    override func mouseDown(with event: NSEvent) {
        isPressed = true
        needsDisplay = true
        super.mouseDown(with: event)
        isPressed = false
        needsDisplay = true
    }
}
