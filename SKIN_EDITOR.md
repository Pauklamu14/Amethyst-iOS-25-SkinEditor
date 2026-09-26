# Direkte Launcher-Integration

Der Skin Editor ist jetzt über `SkinEditorLauncherEntry.makeViewController()` als UIKit-ViewController aufrufbar:

```swift
let editor = await MainActor.run {
    SkinEditorLauncherEntry.makeViewController()
}
present(editor, animated: true)
```

Für einen echten Tab in der vorhandenen Launcher-Navigation muss diese View in den bestehenden iOS-ViewController bzw. die vorhandene Tab-Bar des upstream Projekts aufgenommen werden. Das Repository `catsruledogs/Amethyst-iOS-25` verwendet derzeit ein Legacy-Makefile/PBXLegacyTarget und enthält keinen SwiftUI-App-Target. Deshalb kann die API-Integration hier vollständig vorbereitet, aber nicht automatisch in eine nicht vorhandene native Tab-Bar-Datei geschrieben werden.

Die Swift-Dateien müssen in Xcode dem App-Target hinzugefügt werden. Danach kann der Entry-Point aus dem vorhandenen Launcher-Controller präsentiert werden.
