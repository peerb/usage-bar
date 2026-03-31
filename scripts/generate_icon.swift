#!/usr/bin/env swift
import CoreGraphics
import Foundation
import ImageIO

// MARK: - Icon Design
// Two vertical bars on a dark background, mirroring the menu bar widget.
// Left bar ~40% filled, right bar ~75% filled.

func renderIcon(size: Int) -> CGImage {
    let s = CGFloat(size)
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let ctx = CGContext(
        data: nil,
        width: size,
        height: size,
        bitsPerComponent: 8,
        bytesPerRow: 0,
        space: colorSpace,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    )!

    // Background — dark charcoal
    ctx.setFillColor(CGColor(red: 0.11, green: 0.11, blue: 0.12, alpha: 1.0))
    ctx.fill(CGRect(x: 0, y: 0, width: s, height: s))

    let barW   = (s * 0.10).rounded()
    let gap    = (s * 0.07).rounded()
    let totalW = barW * 2 + gap
    let startX = ((s - totalW) / 2).rounded()
    let bottomY = (s * 0.14).rounded()
    let maxH    = (s * 0.68).rounded()
    let radius  = (barW * 0.28).rounded()

    let leftPct:  CGFloat = 0.40
    let rightPct: CGFloat = 0.75

    let leftX  = startX
    let rightX = startX + barW + gap

    func roundedRect(_ rect: CGRect) -> CGPath {
        CGPath(roundedRect: rect, cornerWidth: radius, cornerHeight: radius, transform: nil)
    }

    func drawBar(x: CGFloat, pct: CGFloat) {
        let track = CGRect(x: x, y: bottomY, width: barW, height: maxH)
        let fill  = CGRect(x: x, y: bottomY, width: barW, height: (maxH * pct).rounded())

        // Track
        ctx.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.12))
        ctx.addPath(roundedRect(track))
        ctx.fillPath()

        // Fill clipped to track shape
        ctx.saveGState()
        ctx.addPath(roundedRect(track))
        ctx.clip()
        ctx.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.88))
        ctx.fill(fill)
        ctx.restoreGState()
    }

    drawBar(x: leftX,  pct: leftPct)
    drawBar(x: rightX, pct: rightPct)

    return ctx.makeImage()!
}

func writePNG(_ image: CGImage, to url: URL) {
    let dest = CGImageDestinationCreateWithURL(url as CFURL, "public.png" as CFString, 1, nil)!
    CGImageDestinationAddImage(dest, image, nil)
    CGImageDestinationFinalize(dest)
}

// MARK: - Generate iconset

let fm = FileManager.default
let projectDir = URL(fileURLWithPath: #file).deletingLastPathComponent().deletingLastPathComponent()
let iconsetURL = projectDir.appendingPathComponent("AppIcon.iconset")
let outputURL  = projectDir.appendingPathComponent("Resources/AppIcon.icns")

try? fm.removeItem(at: iconsetURL)
try! fm.createDirectory(at: iconsetURL, withIntermediateDirectories: true)
try! fm.createDirectory(at: outputURL.deletingLastPathComponent(), withIntermediateDirectories: true)

let sizes: [(name: String, px: Int)] = [
    ("icon_16x16",       16),
    ("icon_16x16@2x",    32),
    ("icon_32x32",       32),
    ("icon_32x32@2x",    64),
    ("icon_128x128",    128),
    ("icon_128x128@2x", 256),
    ("icon_256x256",    256),
    ("icon_256x256@2x", 512),
    ("icon_512x512",    512),
    ("icon_512x512@2x",1024),
]

for (name, px) in sizes {
    let url = iconsetURL.appendingPathComponent("\(name).png")
    writePNG(renderIcon(size: px), to: url)
    print("  \(name).png (\(px)px)")
}

// MARK: - Convert to .icns

let proc = Process()
proc.launchPath = "/usr/bin/iconutil"
proc.arguments  = ["-c", "icns", iconsetURL.path, "-o", outputURL.path]
try! proc.run()
proc.waitUntilExit()

try? fm.removeItem(at: iconsetURL)

if proc.terminationStatus == 0 {
    print("\nWrote \(outputURL.path)")
} else {
    print("iconutil failed"); exit(1)
}
