import SwiftUI

public struct SkinEditorView: View {
    @StateObject private var model = SkinEditorModel()
    @State private var tab: EditorTab = .draw

    public init() {}

    public var body: some View {
        TabView(selection: $tab) {
            SkinCanvasView(model: model)
                .tabItem { Label("Editor", systemImage: "pencil.and.outline") }
                .tag(EditorTab.draw)
            SkinPreviewView(model: model)
                .tabItem { Label("Preview", systemImage: "person.crop.square") }
                .tag(EditorTab.preview)
            SkinToolsView(model: model)
                .tabItem { Label("Tools", systemImage: "square.and.arrow.up") }
                .tag(EditorTab.tools)
        }
        .navigationTitle("Skin Editor")
    }
}

private enum EditorTab { case draw, preview, tools }

private struct SkinCanvasView: View {
    @ObservedObject var model: SkinEditorModel
    @State private var showColorPicker = false

    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Picker("Tool", selection: $model.tool) {
                    ForEach(SkinTool.allCases, id: \.self) { Text($0.title).tag($0) }
                }
                .pickerStyle(.segmented)
                Button { showColorPicker = true } label: {
                    Circle().fill(model.color.swiftUIColor).frame(width: 28, height: 28)
                }
                .accessibilityLabel("Choose color")
            }
            .padding(.horizontal)

            HStack {
                Button { model.undo() } label: { Image(systemName: "arrow.uturn.backward") }
                    .disabled(!model.canUndo)
                Slider(value: $model.brushSize, in: 1...8, step: 1)
                Text("\(Int(model.brushSize)) px").monospacedDigit()
                Button { model.redo() } label: { Image(systemName: "arrow.uturn.forward") }
                    .disabled(!model.canRedo)
            }
            .padding(.horizontal)

            SkinGrid(model: model)
                .padding()
                .background(Color.secondary.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal)

            Text("64 × 64 PNG • Minecraft Java skin format")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .sheet(isPresented: $showColorPicker) {
            NavigationStack {
                ColorPicker("Color", selection: Binding(get: { model.color.swiftUIColor }, set: { model.color = PixelColor($0) }))
                    .padding()
                    .navigationTitle("Color")
                    .navigationBarTitleDisplayMode(.inline)
            }
            .presentationDetents([.medium])
        }
    }
}

private struct SkinGrid: View {
    @ObservedObject var model: SkinEditorModel
    private let side: CGFloat = 320

    var body: some View {
        Canvas { context, size in
            let cell = min(size.width, size.height) / 64
            for y in 0..<64 {
                for x in 0..<64 {
                    let rect = CGRect(x: CGFloat(x) * cell, y: CGFloat(y) * cell, width: cell + 0.5, height: cell + 0.5)
                    context.fill(Path(rect), with: .color(model.pixels[y * 64 + x].swiftUIColor))
                    if cell >= 5 { context.stroke(Path(rect), with: .color(.black.opacity(0.18)), lineWidth: 0.35) }
                }
            }
        }
        .frame(width: side, height: side)
        .contentShape(Rectangle())
        .gesture(DragGesture(minimumDistance: 0).onChanged { value in
            let cell = side / 64
            model.apply(at: Int(value.location.x / cell), y: Int(value.location.y / cell))
        })
        .accessibilityLabel("64 by 64 skin canvas")
    }
}

private struct SkinPreviewView: View {
    @ObservedObject var model: SkinEditorModel
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text("Texture Preview").font(.headline)
                if let image = model.image {
                    Image(uiImage: image).interpolation(.none).resizable().scaledToFit().padding()
                }
                Text("The texture can be exported directly as a 64×64 PNG skin.")
                    .font(.footnote).foregroundStyle(.secondary)
            }.padding()
        }
    }
}

private struct SkinToolsView: View {
    @ObservedObject var model: SkinEditorModel
    @State private var importing = false
    @State private var exporting = false

    var body: some View {
        List {
            Section("File") {
                Button { importing = true } label: { Label("Import 64×64 PNG", systemImage: "arrow.down.doc") }
                Button { exporting = true } label: { Label("Export skin PNG", systemImage: "square.and.arrow.up") }
                Button(role: .destructive) { model.clear() } label: { Label("Clear canvas", systemImage: "trash") }
            }
            Section("History") {
                LabeledContent("Undo steps", value: "\(model.undoCount)")
                LabeledContent("Redo steps", value: "\(model.redoCount)")
            }
        }
        .fileImporter(isPresented: $importing, allowedContentTypes: [.png, .image]) { result in
            if case .success(let url) = result { model.importPNG(from: url) }
        }
        .fileExporter(isPresented: $exporting, document: PNGDocument(data: model.pngData ?? Data()), contentType: .png, defaultFilename: "minecraft-skin.png") { _ in }
    }
}

private enum SkinTool: CaseIterable { case pencil, eraser
    var title: String { self == .pencil ? "Pencil" : "Eraser" }
}

private struct PNGDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.png] }
    var data: Data
    init(data: Data) { self.data = data }
    init(configuration: ReadConfiguration) throws { data = configuration.file.regularFileContents ?? Data() }
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper { FileWrapper(regularFileWithContents: data) }
}
