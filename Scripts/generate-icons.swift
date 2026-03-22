#!/usr/bin/swift

import AppKit
import Foundation

let fileManager = FileManager.default
let rootURL = URL(fileURLWithPath: fileManager.currentDirectoryPath)
let iconsetURL = rootURL.appendingPathComponent("Resources/AppBundle/AppIcon.iconset", isDirectory: true)
let icnsURL = rootURL.appendingPathComponent("Resources/AppBundle/AppIcon.icns")
let previewURL = rootURL.appendingPathComponent("Resources/AppBundle/AppIconPreview.png")

try? fileManager.removeItem(at: iconsetURL)
try? fileManager.removeItem(at: icnsURL)
try fileManager.createDirectory(at: iconsetURL, withIntermediateDirectories: true)

let baseSize: CGFloat = 1024
let cornerRadius: CGFloat = 220

func roundedPath(_ rect: CGRect, radius: CGFloat) -> NSBezierPath {
    NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)
}

func drawIconBackground(in rect: CGRect) {
    let radius = min(rect.width, rect.height) * (cornerRadius / baseSize)
    let background = roundedPath(rect, radius: radius)
    background.addClip()

    let gradient = NSGradient(colors: [
        NSColor(calibratedWhite: 0.21, alpha: 1.0),
        NSColor(calibratedWhite: 0.17, alpha: 1.0),
        NSColor(calibratedWhite: 0.14, alpha: 1.0)
    ])!
    gradient.draw(in: rect, angle: -28)

    NSColor.white.withAlphaComponent(0.04).setStroke()
    let inset = max(rect.width * 0.0025, 0.8)
    let outerStroke = roundedPath(rect.insetBy(dx: inset, dy: inset), radius: max(radius - inset, 0))
    outerStroke.lineWidth = 5
    outerStroke.stroke()
}

func drawTrack(in rect: CGRect) {
    let path = roundedPath(rect, radius: rect.width / 2)
    let gradient = NSGradient(colors: [
        NSColor(calibratedWhite: 0.52, alpha: 1.0),
        NSColor(calibratedWhite: 0.30, alpha: 1.0)
    ])!
    gradient.draw(in: path, angle: 0)

    NSColor.black.withAlphaComponent(0.36).setStroke()
    path.lineWidth = 1.8
    path.stroke()
}

func drawKnob(in rect: CGRect) {
    let shadow = NSShadow()
    shadow.shadowBlurRadius = 30
    shadow.shadowOffset = NSSize(width: 0, height: -10)
    shadow.shadowColor = NSColor.black.withAlphaComponent(0.52)
    shadow.set()

    let knob = NSBezierPath(ovalIn: rect)
    let gradient = NSGradient(colors: [
        NSColor(calibratedWhite: 1.0, alpha: 1.0),
        NSColor(calibratedWhite: 0.95, alpha: 1.0),
        NSColor(calibratedWhite: 0.89, alpha: 1.0)
    ])!
    gradient.draw(in: knob, angle: -90)

    NSColor.black.withAlphaComponent(0.18).setStroke()
    knob.lineWidth = 1
    knob.stroke()

    NSGraphicsContext.current?.saveGraphicsState()
    let innerShadow = NSShadow()
    innerShadow.shadowBlurRadius = 6
    innerShadow.shadowOffset = NSSize(width: 0, height: -2)
    innerShadow.shadowColor = NSColor.white.withAlphaComponent(0.55)
    innerShadow.set()
    NSColor.white.withAlphaComponent(0.78).setFill()
    NSBezierPath(ovalIn: CGRect(x: rect.minX + rect.width * 0.18, y: rect.minY + rect.height * 0.58, width: rect.width * 0.34, height: rect.height * 0.18)).fill()
    NSGraphicsContext.current?.restoreGraphicsState()
}

func drawSliderSet(in rect: CGRect) {
    let trackWidth = rect.width * 0.060
    let knobSize = rect.width * 0.162
    let trackHeight = rect.height * 0.82
    let topOffset = rect.height * 0.10
    let positions: [CGFloat] = [0.61, 0.42, 0.76]
    let centers: [CGFloat] = [0.12, 0.50, 0.88]

    for index in 0..<3 {
        let centerX = rect.minX + rect.width * centers[index]
        let trackRect = CGRect(
            x: centerX - trackWidth / 2,
            y: rect.minY + topOffset,
            width: trackWidth,
            height: trackHeight
        )
        drawTrack(in: trackRect)

        let knobCenterY = trackRect.minY + trackRect.height * positions[index]
        let knobRect = CGRect(
            x: centerX - knobSize / 2,
            y: knobCenterY - knobSize / 2,
            width: knobSize,
            height: knobSize
        )
        drawKnob(in: knobRect)
    }
}

func makeImage(size: CGFloat) -> NSImage {
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()

    let rect = CGRect(origin: .zero, size: CGSize(width: size, height: size))
    let scale = size / baseSize

    drawIconBackground(in: rect)
    drawSliderSet(
        in: CGRect(
            x: 258 * scale,
            y: 196 * scale,
            width: 508 * scale,
            height: 632 * scale
        )
    )

    image.unlockFocus()
    return image
}

func savePNG(_ image: NSImage, to url: URL) throws {
    guard
        let tiffData = image.tiffRepresentation,
        let bitmap = NSBitmapImageRep(data: tiffData),
        let pngData = bitmap.representation(using: .png, properties: [:])
    else {
        throw NSError(domain: "IconGeneration", code: 1)
    }

    try pngData.write(to: url)
}

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
    let image = makeImage(size: size)
    try savePNG(image, to: iconsetURL.appendingPathComponent(name))
}

try savePNG(makeImage(size: 1024), to: previewURL)

let task = Process()
task.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
task.arguments = ["-c", "icns", iconsetURL.path, "-o", icnsURL.path]
try task.run()
task.waitUntilExit()

guard task.terminationStatus == 0 else {
    throw NSError(domain: "IconGeneration", code: Int(task.terminationStatus))
}

print("Generated \(icnsURL.path)")
