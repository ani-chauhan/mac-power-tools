// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import SwiftUI

/// Settings > Pixel Ruler: the shortcut, edge-detection tolerance and the
/// unit the live readings are shown in.
struct PixelRulerSettings: View {
    @ObservedObject private var l10n = L10n.shared
    @ObservedObject private var permissions = Permissions.shared
    @ObservedObject private var service = PixelRulerService.shared
    @AppStorage(DefaultsKey.pixelRulerShortcutEnabled) private var shortcutEnabled = false
    @AppStorage(DefaultsKey.pixelRulerTolerance) private var toleranceRaw = PixelRulerTolerance.low.rawValue
    @AppStorage(DefaultsKey.pixelRulerUnit) private var unitRaw = PixelRulerUnit.pixel.rawValue

    private var strings: PixelRulerFeatureStrings { FeatureStrings.pixelRuler(l10n.language) }

    var body: some View {
        Form {
            Section {
                Toggle(strings.enableShortcutToggle, isOn: $shortcutEnabled)
                    .onChange(of: shortcutEnabled) { _, _ in
                        PixelRulerService.shared.syncWithPreferences()
                    }
                Text(strings.hubDescription)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                ShortcutPreferenceRow(role: .pixelRuler, isEnabled: shortcutEnabled) {
                    PixelRulerService.shared.syncWithPreferences()
                }
                if shortcutEnabled, service.shortcutRegistrationFailed {
                    Text(l10n.s.shortcutUnavailable)
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
                if !permissions.screenRecording {
                    PermissionRow(kind: .screenRecording)
                }

                Picker(strings.toleranceTitle, selection: $toleranceRaw) {
                    Text(strings.toleranceZero).tag(PixelRulerTolerance.zero.rawValue)
                    Text(strings.toleranceLow).tag(PixelRulerTolerance.low.rawValue)
                    Text(strings.toleranceMedium).tag(PixelRulerTolerance.medium.rawValue)
                    Text(strings.toleranceHigh).tag(PixelRulerTolerance.high.rawValue)
                }
                Text(strings.toleranceCaption)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Picker(strings.unitTitle, selection: $unitRaw) {
                    Text(strings.unitPixels).tag(PixelRulerUnit.pixel.rawValue)
                    Text(strings.unitPoints).tag(PixelRulerUnit.point.rawValue)
                }

                Text(strings.keysCaption)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } header: {
                Text(strings.pageTitle)
            }
        }
        .formStyle(.grouped)
    }
}
