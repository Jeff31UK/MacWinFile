import Cocoa

enum WinFileTheme {
    static let splitViewDividerWidth: CGFloat = 6
    static let statusBarHeight: CGFloat = 22
    static let toolbarHeight: CGFloat = 32
    static let driveBarHeight: CGFloat = 28
    static let sunkenBorderWidth: CGFloat = 1
    static let buttonBorderWidth: CGFloat = 1
    static let treeIndentation: CGFloat = 18
    static let rowHeight: CGFloat = 20
    static let iconSize: CGFloat = 16

    /// Draw a Win3.1-style raised (outset) 3D border
    static func drawRaisedBorder(in rect: NSRect) {
        let path = NSBezierPath()

        // Light top-left edges
        WinFileColors.buttonHighlight.setStroke()
        path.move(to: NSPoint(x: rect.minX, y: rect.minY))
        path.line(to: NSPoint(x: rect.minX, y: rect.maxY - 1))
        path.line(to: NSPoint(x: rect.maxX - 1, y: rect.maxY - 1))
        path.lineWidth = buttonBorderWidth
        path.stroke()

        // Dark bottom-right edges
        let shadowPath = NSBezierPath()
        WinFileColors.buttonShadow.setStroke()
        shadowPath.move(to: NSPoint(x: rect.maxX - 1, y: rect.maxY - 1))
        shadowPath.line(to: NSPoint(x: rect.maxX - 1, y: rect.minY))
        shadowPath.line(to: NSPoint(x: rect.minX, y: rect.minY))
        shadowPath.lineWidth = buttonBorderWidth
        shadowPath.stroke()
    }

    /// Draw a Win3.1-style sunken (inset) 3D border
    static func drawSunkenBorder(in rect: NSRect) {
        let path = NSBezierPath()

        // Dark top-left edges
        WinFileColors.buttonShadow.setStroke()
        path.move(to: NSPoint(x: rect.minX, y: rect.minY))
        path.line(to: NSPoint(x: rect.minX, y: rect.maxY - 1))
        path.line(to: NSPoint(x: rect.maxX - 1, y: rect.maxY - 1))
        path.lineWidth = buttonBorderWidth
        path.stroke()

        // Light bottom-right edges
        let lightPath = NSBezierPath()
        WinFileColors.buttonHighlight.setStroke()
        lightPath.move(to: NSPoint(x: rect.maxX - 1, y: rect.maxY - 1))
        lightPath.line(to: NSPoint(x: rect.maxX - 1, y: rect.minY))
        lightPath.line(to: NSPoint(x: rect.minX, y: rect.minY))
        lightPath.lineWidth = buttonBorderWidth
        lightPath.stroke()
    }
}
