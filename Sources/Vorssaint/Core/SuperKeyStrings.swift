// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import Foundation

struct SuperKeyStrings {
    let pageTitle: String
    let hubDescription: String
    let enableToggle: String
    let enableCaption: String
    let capsLockKey: String
    let holdHint: String
    let soloSection: String
    let soloCaption: String
    let soloNothing: String
    let soloCapsLock: String
    let soloEscape: String
    let activeNow: String
    let panelCaptionFormat: String
    let manageButton: String
    let soloInputSource: String
    let mappingForeignMapping: String
    let mappingSystemRefused: String

    /// What to show when the key mapping was refused. Every refusal names one
    /// thing to change; none of them is visible in the key itself.
    func mappingFailure(_ failure: SuperKeyMappingFailure) -> String {
        switch failure {
        case .foreignMapping: return mappingForeignMapping
        case .systemRefused: return mappingSystemRefused
        }
    }
}

extension FeatureStrings {
    static func superKey(_ language: AppLanguage) -> SuperKeyStrings {
        switch language {
        case .enUS: return .enUS
        }
    }
}

extension SuperKeyStrings {
    static let enUS = SuperKeyStrings(
        pageTitle: "Super key",
        hubDescription: "Turns Caps Lock into the modifier combination you choose.",
        enableToggle: "Use Caps Lock as the super key",
        enableCaption: "Hold it and press any key. Choose one or more modifiers below.",
        capsLockKey: "Caps Lock",
        holdHint: "Hold",
        soloSection: "A tap on its own",
        soloCaption: "What a quick tap does when no other key is pressed.",
        soloNothing: "Nothing",
        soloCapsLock: "Turn capitals on and off",
        soloEscape: "Press Escape",
        activeNow: "Working now",
        panelCaptionFormat: "Caps Lock holds %@.",
        manageButton: "Set up…",
        soloInputSource: "Switch input source; hold for Caps Lock",
        mappingForeignMapping: "Another app's key mapping holds Caps Lock. Remove it in that app: quitting it is not enough.",
        mappingSystemRefused: "macOS refused the key mapping. Reconnect the keyboard or restart the Mac, then switch this on again."
    )

}
