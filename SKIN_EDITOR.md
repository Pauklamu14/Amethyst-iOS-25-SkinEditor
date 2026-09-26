# Skin Editor integration

This repository contains the first working, self-contained SwiftUI Skin Editor module.

## Features

- Own `TabView` with Editor, Preview, and Tools tabs
- 64×64 canvas for Minecraft Java skins
- Pencil and eraser with adjustable brush size
- Color picker
- Import PNG and export PNG through the iOS document picker
- Undo/redo history
- Transparent pixels preserved

## Integration into Amethyst

The source project uses a legacy `Makefile`/`PBXLegacyTarget` build rather than a SwiftUI app target. Add the two files in `SkinEditor/` to the iOS application target in Xcode, then present `SkinEditorView()` from the launcher’s existing navigation controller or tab controller. The current commit intentionally keeps the editor independent so it can be integrated without changing launcher or Java runtime code.

The module has not been compiled in this API-only environment; build it in the upstream Xcode/Makefile environment after adding the files to the target.
