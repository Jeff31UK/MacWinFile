#!/usr/bin/env swift
import Cocoa

func generateIcon(size: Int) -> NSImage {
    let s = CGFloat(size)
    let image = NSImage(size: NSSize(width: s, height: s))
    image.lockFocus()

    let ctx = NSGraphicsContext.current!.cgContext

    // Background - rounded rect
    let bgRect = NSRect(x: s*0.05, y: s*0.02, width: s*0.9, height: s*0.93)
    let bgPath = NSBezierPath(roundedRect: bgRect, xRadius: s*0.08, yRadius: s*0.08)

    // Gradient background - retro beige/tan to warm gray
    let gradient = NSGradient(colors: [
        NSColor(calibratedRed: 0.82, green: 0.78, blue: 0.72, alpha: 1.0),
        NSColor(calibratedRed: 0.72, green: 0.68, blue: 0.62, alpha: 1.0),
    ])!
    gradient.draw(in: bgPath, angle: 90)

    // Shadow/border
    NSColor(calibratedWhite: 0.35, alpha: 0.6).setStroke()
    bgPath.lineWidth = s * 0.015
    bgPath.stroke()

    // 3D raised effect - top highlight
    NSColor(calibratedWhite: 1.0, alpha: 0.4).setStroke()
    let highlightPath = NSBezierPath()
    highlightPath.move(to: NSPoint(x: s*0.12, y: s*0.92))
    highlightPath.line(to: NSPoint(x: s*0.88, y: s*0.92))
    highlightPath.lineWidth = s * 0.015
    highlightPath.stroke()

    // Title bar area
    let titleRect = NSRect(x: s*0.1, y: s*0.78, width: s*0.8, height: s*0.1)
    let titleGrad = NSGradient(colors: [
        NSColor(calibratedRed: 0.0, green: 0.0, blue: 0.55, alpha: 1.0),
        NSColor(calibratedRed: 0.15, green: 0.25, blue: 0.7, alpha: 1.0),
    ])!
    let titlePath = NSBezierPath(roundedRect: titleRect, xRadius: s*0.02, yRadius: s*0.02)
    titleGrad.draw(in: titlePath, angle: 0)

    // Title text
    let titleFont = NSFont.boldSystemFont(ofSize: s * 0.055)
    let titleAttrs: [NSAttributedString.Key: Any] = [
        .font: titleFont,
        .foregroundColor: NSColor.white
    ]
    let titleStr = "MacWinFile" as NSString
    let titleSize = titleStr.size(withAttributes: titleAttrs)
    let titlePt = NSPoint(
        x: titleRect.midX - titleSize.width / 2,
        y: titleRect.midY - titleSize.height / 2
    )
    titleStr.draw(at: titlePt, withAttributes: titleAttrs)

    // Content area - white/light
    let contentRect = NSRect(x: s*0.1, y: s*0.08, width: s*0.8, height: s*0.68)
    NSColor(calibratedWhite: 0.95, alpha: 1.0).setFill()
    let contentPath = NSBezierPath(rect: contentRect)
    contentPath.fill()

    // Sunken border on content
    NSColor(calibratedWhite: 0.5, alpha: 0.5).setStroke()
    contentPath.lineWidth = s * 0.01
    contentPath.stroke()

    // Split divider
    let dividerX = s * 0.38
    NSColor(calibratedWhite: 0.65, alpha: 1.0).setStroke()
    let divLine = NSBezierPath()
    divLine.move(to: NSPoint(x: dividerX, y: s*0.08))
    divLine.line(to: NSPoint(x: dividerX, y: s*0.76))
    divLine.lineWidth = s * 0.01
    divLine.stroke()

    // Tree items (left pane) - folder icons with lines
    let folderColor = NSColor(calibratedRed: 0.95, green: 0.85, blue: 0.35, alpha: 1.0)
    let textColor = NSColor(calibratedWhite: 0.15, alpha: 1.0)
    let itemFont = NSFont.systemFont(ofSize: s * 0.04)

    let treeItems = [
        (x: s*0.13, y: s*0.66, indent: 0, name: "Desktop"),
        (x: s*0.13, y: s*0.58, indent: 0, name: "Documents"),
        (x: s*0.17, y: s*0.50, indent: 1, name: "Work"),
        (x: s*0.17, y: s*0.42, indent: 1, name: "Personal"),
        (x: s*0.13, y: s*0.34, indent: 0, name: "Downloads"),
        (x: s*0.13, y: s*0.26, indent: 0, name: "Music"),
        (x: s*0.13, y: s*0.18, indent: 0, name: "Pictures"),
    ]

    for item in treeItems {
        let fx = item.x + CGFloat(item.indent) * s * 0.04
        // Folder icon
        let folderRect = NSRect(x: fx, y: item.y, width: s*0.05, height: s*0.04)
        folderColor.setFill()
        NSBezierPath(roundedRect: folderRect, xRadius: s*0.005, yRadius: s*0.005).fill()
        // Folder tab
        let tabRect = NSRect(x: fx, y: item.y + s*0.035, width: s*0.025, height: s*0.012)
        folderColor.setFill()
        NSBezierPath(roundedRect: tabRect, xRadius: s*0.003, yRadius: s*0.003).fill()

        // Name
        let nameAttrs: [NSAttributedString.Key: Any] = [.font: itemFont, .foregroundColor: textColor]
        (item.name as NSString).draw(at: NSPoint(x: fx + s*0.06, y: item.y), withAttributes: nameAttrs)
    }

    // Expand indicators
    let indicatorFont = NSFont.systemFont(ofSize: s * 0.035)
    let indicatorAttrs: [NSAttributedString.Key: Any] = [.font: indicatorFont, .foregroundColor: textColor]
    ("v" as NSString).draw(at: NSPoint(x: s*0.115, y: s*0.585), withAttributes: indicatorAttrs)
    (">" as NSString).draw(at: NSPoint(x: s*0.115, y: s*0.345), withAttributes: indicatorAttrs)

    // File list (right pane) - column header
    let headerRect = NSRect(x: dividerX + s*0.01, y: s*0.7, width: s*0.5, height: s*0.055)
    NSColor(calibratedWhite: 0.85, alpha: 1.0).setFill()
    NSBezierPath(rect: headerRect).fill()

    let headerFont = NSFont.boldSystemFont(ofSize: s * 0.032)
    let headerAttrs: [NSAttributedString.Key: Any] = [.font: headerFont, .foregroundColor: textColor]
    ("Name" as NSString).draw(at: NSPoint(x: dividerX + s*0.03, y: headerRect.origin.y + s*0.012), withAttributes: headerAttrs)
    ("Size" as NSString).draw(at: NSPoint(x: s*0.7, y: headerRect.origin.y + s*0.012), withAttributes: headerAttrs)
    ("Date" as NSString).draw(at: NSPoint(x: s*0.82, y: headerRect.origin.y + s*0.012), withAttributes: headerAttrs)

    // File rows
    let fileFont = NSFont.systemFont(ofSize: s * 0.032)
    let fileRows = [
        "report.doc", "budget.xls", "photo.jpg",
        "notes.txt", "backup.zip", "readme.md",
        "config.ini", "data.csv"
    ]
    let docColor = NSColor(calibratedRed: 0.4, green: 0.6, blue: 0.9, alpha: 1.0)

    for (i, name) in fileRows.enumerated() {
        let fy = s * 0.63 - CGFloat(i) * s * 0.065
        if fy < s * 0.09 { break }

        // Alternating row bg
        if i % 2 == 0 {
            NSColor(calibratedWhite: 0.92, alpha: 1.0).setFill()
            NSBezierPath(rect: NSRect(x: dividerX + s*0.01, y: fy, width: s*0.5, height: s*0.06)).fill()
        }

        // Doc icon
        let docRect = NSRect(x: dividerX + s*0.03, y: fy + s*0.01, width: s*0.035, height: s*0.04)
        docColor.setFill()
        NSBezierPath(roundedRect: docRect, xRadius: s*0.003, yRadius: s*0.003).fill()

        // File name
        let fileAttrs: [NSAttributedString.Key: Any] = [.font: fileFont, .foregroundColor: textColor]
        (name as NSString).draw(at: NSPoint(x: dividerX + s*0.075, y: fy + s*0.01), withAttributes: fileAttrs)
    }

    // Highlight one selected row
    let selY = s * 0.63 - s * 0.065
    NSColor(calibratedRed: 0.2, green: 0.4, blue: 0.8, alpha: 0.3).setFill()
    NSBezierPath(rect: NSRect(x: dividerX + s*0.01, y: selY, width: s*0.5, height: s*0.06)).fill()

    image.unlockFocus()
    return image
}

// Generate all required sizes
let sizes = [16, 32, 64, 128, 256, 512, 1024]
let outputDir = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "."

for size in sizes {
    let image = generateIcon(size: size)
    guard let tiffData = image.tiffRepresentation,
          let bitmap = NSBitmapImageRep(data: tiffData),
          let pngData = bitmap.representation(using: .png, properties: [:]) else {
        print("Failed to generate \(size)x\(size)")
        continue
    }
    let filename = "\(outputDir)/icon_\(size)x\(size).png"
    try! pngData.write(to: URL(fileURLWithPath: filename))
    print("Generated \(filename)")
}
