import AppKit
import Foundation

let canvasSize = NSSize(width: 1600, height: 900)
let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
let outputDirectory = root.appendingPathComponent("assets/medium", isDirectory: true)
try FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)

func color(_ red: CGFloat, _ green: CGFloat, _ blue: CGFloat, _ alpha: CGFloat = 1) -> NSColor {
    NSColor(srgbRed: red, green: green, blue: blue, alpha: alpha)
}

func rect(_ x: CGFloat, _ top: CGFloat, _ width: CGFloat, _ height: CGFloat) -> NSRect {
    NSRect(x: x, y: canvasSize.height - top - height, width: width, height: height)
}

func drawText(_ value: String, x: CGFloat, top: CGFloat, width: CGFloat, height: CGFloat, size: CGFloat, weight: NSFont.Weight = .regular, color: NSColor) {
    let attributes: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: size, weight: weight),
        .foregroundColor: color
    ]
    (value as NSString).draw(in: rect(x, top, width, height), withAttributes: attributes)
}

func roundedRect(_ x: CGFloat, _ top: CGFloat, _ width: CGFloat, _ height: CGFloat, _ radius: CGFloat, fill: NSColor, stroke: NSColor? = nil, lineWidth: CGFloat = 1) {
    let path = NSBezierPath(roundedRect: rect(x, top, width, height), xRadius: radius, yRadius: radius)
    fill.setFill()
    path.fill()
    if let stroke {
        stroke.setStroke()
        path.lineWidth = lineWidth
        path.stroke()
    }
}

func line(_ points: [(CGFloat, CGFloat)], color: NSColor, width: CGFloat) {
    guard let first = points.first else { return }
    let path = NSBezierPath()
    path.lineCapStyle = .round
    path.lineJoinStyle = .round
    path.lineWidth = width
    path.move(to: NSPoint(x: first.0, y: canvasSize.height - first.1))
    for point in points.dropFirst() {
        path.line(to: NSPoint(x: point.0, y: canvasSize.height - point.1))
    }
    color.setStroke()
    path.stroke()
}

func circle(_ x: CGFloat, _ top: CGFloat, _ diameter: CGFloat, fill: NSColor) {
    fill.setFill()
    NSBezierPath(ovalIn: rect(x, top, diameter, diameter)).fill()
}

func makeImage(_ name: String, drawing: () -> Void) throws {
    let representation = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: Int(canvasSize.width),
        pixelsHigh: Int(canvasSize.height),
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    )!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: representation)
    NSGraphicsContext.current?.imageInterpolation = .high
    drawing()
    NSGraphicsContext.restoreGraphicsState()
    let data = representation.representation(using: .png, properties: [:])!
    try data.write(to: outputDirectory.appendingPathComponent(name))
}

func metricCard(x: CGFloat, top: CGFloat, title: String, value: String, detail: String, accent: NSColor, progress: CGFloat? = nil) {
    roundedRect(x, top, 330, 166, 18, fill: color(0.10, 0.20, 0.22), stroke: color(0.23, 0.35, 0.36))
    circle(x + 22, top + 22, 12, fill: accent)
    drawText(title.uppercased(), x: x + 44, top: top + 19, width: 256, height: 24, size: 15, weight: .medium, color: color(0.69, 0.79, 0.77))
    drawText(value, x: x + 22, top: top + 58, width: 285, height: 42, size: 29, weight: .semibold, color: color(0.94, 0.97, 0.92))
    drawText(detail, x: x + 22, top: top + 108, width: 285, height: 24, size: 14, color: color(0.62, 0.73, 0.71))
    if let progress {
        roundedRect(x + 22, top + 142, 286, 5, 3, fill: color(0.21, 0.32, 0.32))
        roundedRect(x + 22, top + 142, 286 * progress, 5, 3, fill: accent)
    }
}

try makeImage("01-mac-monitor-cover.png") {
    color(0.035, 0.12, 0.14).setFill()
    NSBezierPath(rect: NSRect(origin: .zero, size: canvasSize)).fill()
    for index in 0..<9 {
        let x = CGFloat(index) * 200
        line([(x, 0), (x, 900)], color: color(0.13, 0.25, 0.25, 0.28), width: 1)
    }
    drawText("MAC MONITOR  /  A NATIVE MACOS DASHBOARD", x: 96, top: 116, width: 570, height: 28, size: 15, weight: .semibold, color: color(0.41, 0.86, 0.75))
    drawText("Know what your\nMac is doing.", x: 96, top: 192, width: 600, height: 180, size: 62, weight: .bold, color: color(0.95, 0.97, 0.92))
    drawText("A quiet, live view of system health, storage,\nthermal state, and process-name indicators.", x: 100, top: 408, width: 520, height: 70, size: 23, color: color(0.70, 0.80, 0.77))
    roundedRect(100, 540, 535, 62, 18, fill: color(0.08, 0.21, 0.22), stroke: color(0.20, 0.40, 0.37))
    drawText("CPU     MEMORY     STORAGE     NETWORK     BATTERY", x: 120, top: 561, width: 500, height: 24, size: 13, weight: .semibold, color: color(0.57, 0.84, 0.76))
    drawText("Illustrative dashboard data", x: 100, top: 810, width: 360, height: 24, size: 14, color: color(0.49, 0.63, 0.61))

    roundedRect(720, 78, 790, 744, 28, fill: color(0.075, 0.16, 0.18), stroke: color(0.23, 0.37, 0.37), lineWidth: 2)
    circle(755, 110, 12, fill: color(1.0, 0.40, 0.29))
    drawText("LIVE SYSTEM OVERVIEW", x: 780, top: 104, width: 430, height: 28, size: 15, weight: .semibold, color: color(0.78, 0.86, 0.82))
    drawText("refreshes every few seconds", x: 1210, top: 104, width: 255, height: 25, size: 13, color: color(0.54, 0.69, 0.67))
    metricCard(x: 755, top: 158, title: "CPU", value: "18%", detail: "Current total load", accent: color(0.36, 0.68, 0.96), progress: 0.18)
    metricCard(x: 1125, top: 158, title: "Memory", value: "8.4 / 16 GB", detail: "Active, wired, compressed", accent: color(1.0, 0.67, 0.32), progress: 0.53)
    metricCard(x: 755, top: 346, title: "Storage", value: "158 GB available", detail: "Home volume", accent: color(0.40, 0.79, 0.59), progress: 0.64)
    metricCard(x: 1125, top: 346, title: "Temperature", value: "32°C", detail: "Battery sensor", accent: color(1.0, 0.43, 0.33), progress: 0.40)
    metricCard(x: 755, top: 534, title: "Network", value: "↓ 1.2  ↑ 0.4 MB/s", detail: "Live throughput", accent: color(0.35, 0.83, 0.75))
    metricCard(x: 1125, top: 534, title: "Thermal pressure", value: "Normal", detail: "macOS system state", accent: color(0.55, 0.77, 0.60))
    drawText("Mac Monitor  ·  illustrative values", x: 755, top: 743, width: 420, height: 24, size: 13, color: color(0.52, 0.66, 0.63))
}

try makeImage("02-temperature-sources.png") {
    color(0.94, 0.96, 0.93).setFill()
    NSBezierPath(rect: NSRect(origin: .zero, size: canvasSize)).fill()
    drawText("TEMPERATURE HAS A SOURCE", x: 100, top: 82, width: 700, height: 26, size: 15, weight: .semibold, color: color(0.08, 0.47, 0.42))
    drawText("One Mac. Different\nthermal signals.", x: 100, top: 132, width: 780, height: 142, size: 54, weight: .bold, color: color(0.08, 0.17, 0.19))
    drawText("A reading is useful only when you know what it measures.", x: 104, top: 295, width: 810, height: 36, size: 21, color: color(0.31, 0.42, 0.42))

    let cardTop: CGFloat = 400
    let cardWidth: CGFloat = 430
    let gap: CGFloat = 28
    let starts: [CGFloat] = [100, 100 + cardWidth + gap, 100 + 2 * (cardWidth + gap)]
    let backgrounds = [color(0.89, 0.93, 0.90), color(0.86, 0.93, 0.89), color(0.88, 0.91, 0.94)]
    let accents = [color(0.89, 0.34, 0.26), color(0.06, 0.52, 0.44), color(0.28, 0.48, 0.69)]
    let labels = ["CPU SENSOR", "BATTERY SENSOR", "THERMAL PRESSURE"]
    let values = ["Unavailable", "32°C", "Normal"]
    let details = ["Helper returned 0.0°C", "A battery reading, not CPU", "macOS reports system state"]

    for index in 0..<3 {
        let x = starts[index]
        roundedRect(x, cardTop, cardWidth, 300, 22, fill: backgrounds[index])
        circle(x + 30, cardTop + 32, 18, fill: accents[index])
        drawText(labels[index], x: x + 60, top: cardTop + 29, width: 330, height: 26, size: 15, weight: .semibold, color: color(0.27, 0.38, 0.37))
        drawText(values[index], x: x + 30, top: cardTop + 104, width: 365, height: 58, size: 34, weight: .bold, color: color(0.08, 0.17, 0.19))
        drawText(details[index], x: x + 32, top: cardTop + 175, width: 360, height: 48, size: 18, color: color(0.34, 0.44, 0.43))
        if index == 0 {
            line([(x + 30, cardTop + 253), (x + 400, cardTop + 253)], color: color(0.76, 0.81, 0.77), width: 2)
            drawText("No false zero", x: x + 32, top: cardTop + 264, width: 240, height: 24, size: 14, weight: .semibold, color: accents[index])
        } else if index == 1 {
            line([(x + 30, cardTop + 253), (x + 400, cardTop + 253)], color: color(0.76, 0.81, 0.77), width: 2)
            drawText("Source is labeled", x: x + 32, top: cardTop + 264, width: 240, height: 24, size: 14, weight: .semibold, color: accents[index])
        } else {
            line([(x + 30, cardTop + 253), (x + 400, cardTop + 253)], color: color(0.76, 0.81, 0.77), width: 2)
            drawText("A separate system signal", x: x + 32, top: cardTop + 264, width: 350, height: 24, size: 14, weight: .semibold, color: accents[index])
        }
    }
    drawText("Illustrative values; sensor availability varies by Mac model.", x: 102, top: 770, width: 790, height: 28, size: 15, color: color(0.43, 0.51, 0.49))
}

try makeImage("03-process-monitor-limits.png") {
    color(0.055, 0.12, 0.17).setFill()
    NSBezierPath(rect: NSRect(origin: .zero, size: canvasSize)).fill()
    drawText("PROCESS-NAME MONITORING", x: 100, top: 86, width: 650, height: 26, size: 15, weight: .semibold, color: color(0.40, 0.82, 0.72))
    drawText("A match is a prompt\nto investigate.", x: 100, top: 135, width: 820, height: 145, size: 54, weight: .bold, color: color(0.94, 0.96, 0.93))
    drawText("Mac Monitor checks running process names against a small indicator list.", x: 105, top: 300, width: 1200, height: 36, size: 21, color: color(0.69, 0.76, 0.77))

    roundedRect(100, 398, 570, 245, 22, fill: color(0.10, 0.20, 0.25), stroke: color(0.22, 0.34, 0.38))
    drawText("RUNNING PROCESSES", x: 132, top: 426, width: 360, height: 24, size: 14, weight: .semibold, color: color(0.61, 0.72, 0.74))
    drawText("Safari", x: 136, top: 475, width: 300, height: 26, size: 19, color: color(0.92, 0.94, 0.91))
    drawText("WindowServer", x: 136, top: 522, width: 300, height: 26, size: 19, color: color(0.92, 0.94, 0.91))
    drawText("xmrig  ·  example name", x: 136, top: 569, width: 390, height: 26, size: 19, weight: .semibold, color: color(1.0, 0.55, 0.42))
    line([(720, 520), (850, 520)], color: color(0.40, 0.82, 0.72), width: 5)
    line([(823, 494), (850, 520), (823, 546)], color: color(0.40, 0.82, 0.72), width: 5)

    roundedRect(900, 398, 600, 245, 22, fill: color(0.10, 0.20, 0.25), stroke: color(0.22, 0.34, 0.38))
    circle(934, 430, 22, fill: color(1.0, 0.61, 0.34))
    drawText("REVIEW THE MATCH", x: 970, top: 430, width: 420, height: 28, size: 15, weight: .semibold, color: color(0.75, 0.83, 0.82))
    drawText("Name + PID", x: 936, top: 493, width: 300, height: 32, size: 23, weight: .semibold, color: color(0.94, 0.96, 0.93))
    drawText("No automatic termination", x: 936, top: 548, width: 440, height: 28, size: 17, color: color(0.69, 0.76, 0.77))

    roundedRect(100, 700, 1400, 104, 18, fill: color(0.16, 0.18, 0.18))
    drawText("A name match is not proof of malware. No match does not prove a Mac is clean.", x: 132, top: 737, width: 1310, height: 34, size: 20, weight: .medium, color: color(0.95, 0.84, 0.67))
    drawText("Illustrative process names", x: 102, top: 828, width: 440, height: 24, size: 14, color: color(0.53, 0.63, 0.66))
}

print("Created Medium images in \(outputDirectory.path)")
