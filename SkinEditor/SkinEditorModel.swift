import SwiftUI
import UIKit
import UniformTypeIdentifiers

public struct PixelColor: Equatable, Codable {
    public var r: UInt8; public var g: UInt8; public var b: UInt8; public var a: UInt8
    public init(_ color: Color) {
        let ui = UIColor(color)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        ui.getRed(&r, green: &g, blue: &b, alpha: &a)
        self.init(r: UInt8(r * 255), g: UInt8(g * 255), b: UInt8(b * 255), a: UInt8(a * 255))
    }
    public init(r: UInt8, g: UInt8, b: UInt8, a: UInt8 = 255) { self.r = r; self.g = g; self.b = b; self.a = a }
    var swiftUIColor: Color { Color(.sRGB, red: Double(r)/255, green: Double(g)/255, blue: Double(b)/255, opacity: Double(a)/255) }
}

@MainActor public final class SkinEditorModel: ObservableObject {
    @Published public private(set) var pixels: [PixelColor] = Array(repeating: PixelColor(r: 255, g: 255, b: 255), count: 4096)
    @Published public var color = PixelColor(r: 220, g: 80, b: 80)
    @Published public var tool: SkinTool = .pencil
    @Published public var brushSize: Double = 1
    private var undoStack: [[PixelColor]] = []
    private var redoStack: [[PixelColor]] = []
    private var lastPoint: Int?

    public init() {}
    public var canUndo: Bool { !undoStack.isEmpty }; public var canRedo: Bool { !redoStack.isEmpty }
    public var undoCount: Int { undoStack.count }; public var redoCount: Int { redoStack.count }
    public var image: UIImage? { makeImage() }
    public var pngData: Data? { makeImage()?.pngData() }

    func apply(at x: Int, y: Int) {
        guard (0..<64).contains(x), (0..<64).contains(y) else { return }
        let index = y * 64 + x
        if lastPoint != index { undoStack.append(pixels); redoStack.removeAll(); lastPoint = index }
        let radius = max(0, Int(brushSize.rounded()) - 1)
        for yy in max(0, y-radius)...min(63, y+radius) {
            for xx in max(0, x-radius)...min(63, x+radius) { pixels[yy * 64 + xx] = tool == .eraser ? PixelColor(r: 255, g: 255, b: 255, a: 0) : color }
        }
        objectWillChange.send()
    }
    func undo() { guard let old = undoStack.popLast() else { return }; redoStack.append(pixels); pixels = old; lastPoint = nil }
    func redo() { guard let next = redoStack.popLast() else { return }; undoStack.append(pixels); pixels = next; lastPoint = nil }
    func clear() { undoStack.append(pixels); redoStack.removeAll(); pixels = Array(repeating: PixelColor(r: 255, g: 255, b: 255, a: 0), count: 4096); lastPoint = nil }
    func importPNG(from url: URL) { guard let image = UIImage(contentsOfFile: url.path), let cg = image.cgImage else { return }; guard let data = rgbaData(cg) else { return }; undoStack.append(pixels); pixels = data; redoStack.removeAll() }

    private func makeImage() -> UIImage? {
        var raw = pixels.flatMap { [$0.r, $0.g, $0.b, $0.a] }
        guard let provider = CGDataProvider(data: Data(raw) as CFData), let cg = CGImage(width: 64, height: 64, bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: 256, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.last.rawValue), provider: provider, decode: nil, shouldInterpolate: false, intent: .defaultIntent) else { return nil }
        return UIImage(cgImage: cg)
    }
    private func rgbaData(_ cg: CGImage) -> [PixelColor]? {
        guard let ctx = CGContext(data: nil, width: 64, height: 64, bitsPerComponent: 8, bytesPerRow: 256, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return nil }
        ctx.interpolationQuality = .none; ctx.draw(cg, in: CGRect(x: 0, y: 0, width: 64, height: 64)); guard let base = ctx.data else { return nil }
        let bytes = base.assumingMemoryBound(to: UInt8.self); return (0..<4096).map { let i = $0 * 4; return PixelColor(r: bytes[i], g: bytes[i+1], b: bytes[i+2], a: bytes[i+3]) }
    }
}
