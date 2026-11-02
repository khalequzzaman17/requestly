import AppKit
import CoreGraphics
import Foundation

func createMasterIcon() -> NSImage {
    let size: CGFloat = 1024
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()
    
    guard let ctx = NSGraphicsContext.current?.cgContext else {
        exit(1)
    }
    
    // Draw macOS App Icon squircle (Apple standard curvature)
    let inset: CGFloat = 80
    let rect = CGRect(x: inset, y: inset, width: size - inset * 2, height: size - inset * 2)
    let squirclePath = CGPath(roundedRect: rect, cornerWidth: 195, cornerHeight: 195, transform: nil)
    
    // Drop shadow under the squircle for native macOS dock depth
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -18), blur: 30, color: NSColor(red: 0, green: 0, blue: 0, alpha: 0.55).cgColor)
    ctx.setFillColor(NSColor(red: 0.09, green: 0.10, blue: 0.14, alpha: 1.0).cgColor)
    ctx.addPath(squirclePath)
    ctx.fillPath()
    ctx.restoreGState()
    
    ctx.addPath(squirclePath)
    ctx.clip()
    
    // Background: Dark developer gradient (#171A21 -> #0D0F14)
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let bgColors = [
        NSColor(red: 0.13, green: 0.15, blue: 0.20, alpha: 1.0).cgColor,
        NSColor(red: 0.06, green: 0.07, blue: 0.10, alpha: 1.0).cgColor
    ] as CFArray
    let bgLocations: [CGFloat] = [0.0, 1.0]
    if let bgGradient = CGGradient(colorsSpace: colorSpace, colors: bgColors, locations: bgLocations) {
        ctx.drawLinearGradient(bgGradient, start: CGPoint(x: 512, y: 1024 - inset), end: CGPoint(x: 512, y: inset), options: [])
    }
    
    // Grid pattern / Subtle network texture in background
    ctx.setStrokeColor(NSColor(red: 0.34, green: 0.52, blue: 0.97, alpha: 0.08).cgColor)
    ctx.setLineWidth(1.5)
    for i in stride(from: 100, through: 900, by: 60) {
        ctx.move(to: CGPoint(x: CGFloat(i), y: inset))
        ctx.addLine(to: CGPoint(x: CGFloat(i), y: size - inset))
        ctx.move(to: CGPoint(x: inset, y: CGFloat(i)))
        ctx.addLine(to: CGPoint(x: size - inset, y: CGFloat(i)))
    }
    ctx.strokePath()
    
    // Subtle border / rim highlight
    ctx.addPath(squirclePath)
    ctx.setStrokeColor(NSColor(red: 0.34, green: 0.52, blue: 0.97, alpha: 0.35).cgColor)
    ctx.setLineWidth(6)
    ctx.strokePath()
    
    // Top highlight rim
    let topRimPath = CGMutablePath()
    topRimPath.addRoundedRect(in: rect.insetBy(dx: 2, dy: 2), cornerWidth: 193, cornerHeight: 193)
    ctx.addPath(topRimPath)
    ctx.setStrokeColor(NSColor(white: 1.0, alpha: 0.15).cgColor)
    ctx.setLineWidth(2)
    ctx.strokePath()
    
    // Glowing ambient background behind the bolt
    let glowCenter = CGPoint(x: 512, y: 520)
    let glowColors = [
        NSColor(red: 0.34, green: 0.52, blue: 0.97, alpha: 0.45).cgColor,
        NSColor(red: 0.34, green: 0.52, blue: 0.97, alpha: 0.0).cgColor
    ] as CFArray
    if let radialGlow = CGGradient(colorsSpace: colorSpace, colors: glowColors, locations: [0.0, 1.0]) {
        ctx.drawRadialGradient(radialGlow, startCenter: glowCenter, startRadius: 20, endCenter: glowCenter, endRadius: 360, options: [])
    }
    
    // Stylized lightning / transmission bolt
    let boltPath = CGMutablePath()
    boltPath.move(to: CGPoint(x: 535, y: 775))
    boltPath.addLine(to: CGPoint(x: 370, y: 520))
    boltPath.addLine(to: CGPoint(x: 505, y: 520))
    boltPath.addLine(to: CGPoint(x: 470, y: 265))
    boltPath.addLine(to: CGPoint(x: 675, y: 505))
    boltPath.addLine(to: CGPoint(x: 540, y: 505))
    boltPath.closeSubpath()
    
    // Shadow / Neon glow for the bolt
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -4), blur: 30, color: NSColor(red: 0.35, green: 0.75, blue: 1.0, alpha: 0.85).cgColor)
    ctx.setFillColor(NSColor(red: 0.35, green: 0.75, blue: 1.0, alpha: 1.0).cgColor)
    ctx.addPath(boltPath)
    ctx.fillPath()
    ctx.restoreGState()
    
    // Fill bolt with gradient (Electric Blue -> Cyan -> Emerald green pulse tip)
    ctx.saveGState()
    ctx.addPath(boltPath)
    ctx.clip()
    
    let boltColors = [
        NSColor(red: 0.45, green: 0.85, blue: 1.0, alpha: 1.0).cgColor,
        NSColor(red: 0.34, green: 0.52, blue: 0.97, alpha: 1.0).cgColor,
        NSColor(red: 0.21, green: 0.79, blue: 0.56, alpha: 1.0).cgColor
    ] as CFArray
    let boltLocations: [CGFloat] = [0.0, 0.6, 1.0]
    if let boltGrad = CGGradient(colorsSpace: colorSpace, colors: boltColors, locations: boltLocations) {
        ctx.drawLinearGradient(boltGrad, start: CGPoint(x: 512, y: 775), end: CGPoint(x: 512, y: 265), options: [])
    }
    ctx.restoreGState()
    
    // Core white energy strike line
    let innerCore = CGMutablePath()
    innerCore.move(to: CGPoint(x: 528, y: 745))
    innerCore.addLine(to: CGPoint(x: 400, y: 525))
    innerCore.addLine(to: CGPoint(x: 515, y: 525))
    innerCore.addLine(to: CGPoint(x: 485, y: 310))
    innerCore.addLine(to: CGPoint(x: 640, y: 500))
    innerCore.addLine(to: CGPoint(x: 535, y: 500))
    innerCore.closeSubpath()
    
    ctx.addPath(innerCore)
    ctx.setFillColor(NSColor(white: 1.0, alpha: 0.45).cgColor)
    ctx.fillPath()
    
    image.unlockFocus()
    return image
}

func resize(image: NSImage, targetSize: NSSize) -> NSImage {
    let newImage = NSImage(size: targetSize)
    newImage.lockFocus()
    image.draw(
        in: NSRect(origin: .zero, size: targetSize),
        from: NSRect(origin: .zero, size: image.size),
        operation: .sourceOver,
        fraction: 1.0
    )
    newImage.unlockFocus()
    return newImage
}

func savePNG(image: NSImage, path: String) {
    if let tiff = image.tiffRepresentation,
       let bitmap = NSBitmapImageRep(data: tiff),
       let pngData = bitmap.representation(using: .png, properties: [:]) {
        try? pngData.write(to: URL(fileURLWithPath: path))
    }
}

// Generate all standard iconset sizes
let fileManager = FileManager.default
let iconsetDir = "Resources/AppIcon.iconset"
try? fileManager.createDirectory(atPath: iconsetDir, withIntermediateDirectories: true)

let masterImage = createMasterIcon()

// Save high-resolution preview and app asset
savePNG(image: masterImage, path: "Resources/AppIcon-1024.png")

let iconSizes: [(String, CGFloat)] = [
    ("icon_16x16.png", 16),
    ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32),
    ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128),
    ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256),
    ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512),
    ("icon_512x512@2x.png", 1024)
]

for (name, size) in iconSizes {
    let resized = resize(image: masterImage, targetSize: NSSize(width: size, height: size))
    savePNG(image: resized, path: "\(iconsetDir)/\(name)")
}

print("Iconset images generated successfully.")

