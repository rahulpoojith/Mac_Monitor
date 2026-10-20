import AppKit
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

guard CommandLine.arguments.count == 2 else {
    fatalError("Usage: generate-icon.swift output.png")
}

let size = 1024
let outputURL = URL(fileURLWithPath: CommandLine.arguments[1])
let colorSpace = CGColorSpaceCreateDeviceRGB()
guard let context = CGContext(
    data: nil,
    width: size,
    height: size,
    bitsPerComponent: 8,
    bytesPerRow: 0,
    space: colorSpace,
    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
) else {
    fatalError("Unable to create icon drawing context")
}

let background = CGPath(
    roundedRect: CGRect(x: 36, y: 36, width: 952, height: 952),
    cornerWidth: 218,
    cornerHeight: 218,
    transform: nil
)
context.addPath(background)
context.clip()

let backgroundColors = [
    CGColor(red: 0.055, green: 0.17, blue: 0.20, alpha: 1),
    CGColor(red: 0.075, green: 0.27, blue: 0.30, alpha: 1),
    CGColor(red: 0.12, green: 0.20, blue: 0.28, alpha: 1)
] as CFArray
guard let gradient = CGGradient(colorsSpace: colorSpace, colors: backgroundColors, locations: [0, 0.52, 1]) else {
    fatalError("Unable to create icon gradient")
}
context.drawLinearGradient(gradient, start: CGPoint(x: 80, y: 960), end: CGPoint(x: 950, y: 80), options: [])

context.setFillColor(CGColor(red: 0.91, green: 0.96, blue: 0.92, alpha: 1))
context.addPath(CGPath(roundedRect: CGRect(x: 224, y: 326, width: 176, height: 438), cornerWidth: 88, cornerHeight: 88, transform: nil))
context.fillPath()
context.fillEllipse(in: CGRect(x: 197, y: 190, width: 230, height: 230))

context.setFillColor(CGColor(red: 1, green: 0.40, blue: 0.29, alpha: 1))
context.addPath(CGPath(roundedRect: CGRect(x: 282, y: 360, width: 60, height: 334), cornerWidth: 30, cornerHeight: 30, transform: nil))
context.fillPath()
context.fillEllipse(in: CGRect(x: 254, y: 226, width: 116, height: 116))

let tracePoints = [
    CGPoint(x: 478, y: 322),
    CGPoint(x: 590, y: 446),
    CGPoint(x: 698, y: 410),
    CGPoint(x: 854, y: 648)
]
let trace = CGMutablePath()
trace.move(to: tracePoints[0])
for point in tracePoints.dropFirst() {
    trace.addLine(to: point)
}
context.addPath(trace)
context.setStrokeColor(CGColor(red: 0.36, green: 0.88, blue: 0.77, alpha: 1))
context.setLineWidth(34)
context.setLineCap(.round)
context.setLineJoin(.round)
context.strokePath()

for point in tracePoints {
    context.setFillColor(CGColor(red: 0.36, green: 0.88, blue: 0.77, alpha: 1))
    context.fillEllipse(in: CGRect(x: point.x - 21, y: point.y - 21, width: 42, height: 42))
}

guard let image = context.makeImage(),
      let destination = CGImageDestinationCreateWithURL(outputURL as CFURL, UTType.png.identifier as CFString, 1, nil) else {
    fatalError("Unable to create icon image")
}
CGImageDestinationAddImage(destination, image, nil)
guard CGImageDestinationFinalize(destination) else {
    fatalError("Unable to write icon image")
}