// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import Foundation

/// Localized strings for the pixel ruler: hover-to-measure edge distances,
/// styled after PixelSnap.
struct PixelRulerFeatureStrings {
    let pageTitle: String
    let hubDescription: String
    let panelCaption: String
    let enableShortcutToggle: String
    let toleranceTitle: String
    let toleranceZero: String
    let toleranceLow: String
    let toleranceMedium: String
    let toleranceHigh: String
    let toleranceCaption: String
    let unitTitle: String
    let unitPixels: String
    let unitPoints: String
    let keysCaption: String
    let streamFailedHUD: String
}

extension FeatureStrings {
    static func pixelRuler(_ language: AppLanguage) -> PixelRulerFeatureStrings {
        switch language {
        case .enUS: return .enUS
        }
    }
}

extension PixelRulerFeatureStrings {
    static let enUS = PixelRulerFeatureStrings(
        pageTitle: "Pixel Ruler",
        hubDescription: "Hover to measure live pixel distances to nearby edges",
        panelCaption: "Measure distances between edges on screen",
        enableShortcutToggle: "Enable shortcut",
        toleranceTitle: "Edge sensitivity",
        toleranceZero: "Zero",
        toleranceLow: "Low",
        toleranceMedium: "Medium",
        toleranceHigh: "High",
        toleranceCaption: "How much contrast counts as an edge. Lower catches more edges; higher ignores subtle shadows and gradients.",
        unitTitle: "Units",
        unitPixels: "Pixels",
        unitPoints: "Points",
        keysCaption: "While measuring: Esc to stop, +/- to adjust sensitivity, Tab to cycle presets, U to switch units.",
        streamFailedHUD: "Pixel Ruler couldn't start")

}
