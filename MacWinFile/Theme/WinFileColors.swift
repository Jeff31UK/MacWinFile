import Cocoa

enum WinFileColors {
    // Main background - softened classic silver-gray
    static let windowBackground = NSColor(calibratedRed: 0.784, green: 0.784, blue: 0.784, alpha: 1.0) // #C8C8C8

    // 3D button/border effects
    static let buttonHighlight = NSColor.white
    static let buttonShadow = NSColor(calibratedWhite: 0.5, alpha: 1.0)       // #808080
    static let buttonDarkShadow = NSColor(calibratedWhite: 0.25, alpha: 1.0)   // #404040
    static let buttonFace = NSColor(calibratedWhite: 0.75, alpha: 1.0)         // #C0C0C0

    // Title bars
    static let activeTitleBar = NSColor(calibratedRed: 0.29, green: 0.435, blue: 0.647, alpha: 1.0) // #4A6FA5
    static let inactiveTitleBar = NSColor(calibratedWhite: 0.62, alpha: 1.0)  // #9E9E9E
    static let titleBarText = NSColor.white
    static let inactiveTitleBarText = NSColor(calibratedWhite: 0.85, alpha: 1.0)

    // Selection
    static let selectedBackground = NSColor(calibratedRed: 0.29, green: 0.435, blue: 0.647, alpha: 1.0)
    static let selectedText = NSColor.white

    // Content areas
    static let contentBackground = NSColor.white
    static let contentText = NSColor.black

    // Status bar
    static let statusBarBackground = NSColor(calibratedWhite: 0.78, alpha: 1.0)
    static let statusBarText = NSColor.black

    // Sunken border (inset panels)
    static let sunkenBorderDark = NSColor(calibratedWhite: 0.5, alpha: 1.0)
    static let sunkenBorderLight = NSColor.white

    // Toolbar
    static let toolbarBackground = NSColor(calibratedWhite: 0.78, alpha: 1.0)
    static let toolbarSeparator = NSColor(calibratedWhite: 0.6, alpha: 1.0)
}
