import SwiftUI
import UIKit

/// UIKit entry point that can be presented from the launcher's existing controller.
/// The upstream project currently exposes a legacy Makefile/PBXLegacyTarget rather
/// than a SwiftUI application target, so this bridge keeps integration isolated.
public enum SkinEditorLauncherEntry {
    @MainActor
    public static func makeViewController() -> UIViewController {
        UIHostingController(rootView: NavigationStack { SkinEditorView() })
    }
}
