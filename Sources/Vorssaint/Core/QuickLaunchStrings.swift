// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import Foundation

struct QuickLaunchStrings {
    let sectionTitle: String
    let enableToggle: String
    let enableCaption: String
    let modifierLabel: String
    let modifierRightCommand: String
    let modifierLeftCommand: String
    let modifierRightOption: String
    let modifierLeftOption: String
    let modifierRightControl: String
    let modifierLeftControl: String
    let prioritiesTitle: String
    let prioritiesCaption: String
    let addButton: String
    let removeButton: String
    let addLetterButton: String
    let removeLetterButton: String
}

extension FeatureStrings {
    static func quickLaunch(_ language: AppLanguage) -> QuickLaunchStrings {
        switch language {
        case .enUS: return .enUS
        }
    }
}

extension QuickLaunchStrings {
    static let enUS = QuickLaunchStrings(
        sectionTitle: "Quick Launch",
        enableToggle: "Enable Quick Launch",
        enableCaption: "Hold the modifier below and tap a letter to bring the matching running app forward. Tap the same letter again while still holding to cycle to the next match. Nothing is ever launched — only apps already running. While held, this key stops acting as an ordinary modifier — other shortcuts on it, like copy or paste, are blocked so they never also fire in the app you're leaving.",
        modifierLabel: "Modifier",
        modifierRightCommand: "Right ⌘",
        modifierLeftCommand: "Left ⌘",
        modifierRightOption: "Right ⌥",
        modifierLeftOption: "Left ⌥",
        modifierRightControl: "Right ⌃",
        modifierLeftControl: "Left ⌃",
        prioritiesTitle: "Letter priorities",
        prioritiesCaption: "Choose which app a letter reaches first, and add apps that don't start with that letter. Apps left unranked follow by how recently they were used.",
        addButton: "Add an app…",
        removeButton: "Remove",
        addLetterButton: "Add letter…",
        removeLetterButton: "Remove letter"
    )

}
