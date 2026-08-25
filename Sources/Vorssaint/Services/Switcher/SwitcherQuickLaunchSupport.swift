// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import Foundation

/// The rules behind quick launch: hold a modifier, tap a letter, the matching
/// running app comes forward. Kept free of AppKit/CoreGraphics event types so
/// the tap thread can hand it raw integers and it stays testable on its own —
/// getting the modifier or cycling logic wrong is invisible in a build.
enum SwitcherQuickLaunchSupport {
    /// One app a letter can resolve to.
    struct Target: Equatable {
        let pid: pid_t
        let name: String
    }

    /// A running app as the roster builder sees it. `mruRank` mirrors
    /// `WindowUseTracker.rank(of:)` — `Int.max` for an app never focused.
    struct RunningApp: Equatable {
        let pid: pid_t
        let bundleID: String?
        let name: String
        let mruRank: Int
    }

    /// The live state of one held-modifier session. `candidates` is frozen the
    /// moment a letter is first pressed, so repeated taps cycle a stable list
    /// even if an app launches or quits mid-hold; a fresh roster only ever
    /// applies to the *next* letter pressed.
    struct Hold: Equatable {
        static let idle = Hold(letter: nil, candidates: [], index: 0)
        var letter: Character?
        var candidates: [Target]
        var index: Int
    }

    enum Decision: Equatable {
        /// No known match for this letter: pass the key through untouched, so
        /// an app's own shortcut on that key keeps working.
        case ignore
        /// A match exists but this is a key-repeat of an already-handled
        /// press: swallow it without acting again.
        case swallow
        case activate(pid: pid_t, name: String)
    }

    // MARK: - Held modifier

    /// The physical modifier key that arms quick launch. Side-specific: a
    /// plain `GlobalShortcutModifiers` mask cannot tell left from right, and
    /// telling them apart is the entire point (the app's own left-⌘ shortcuts
    /// must keep working).
    enum Modifier: String, CaseIterable, Identifiable {
        case rightCommand, leftCommand, rightOption, leftOption, rightControl, leftControl

        var id: String { rawValue }

        /// Device-dependent bit (IOKit `IOLLEvent.h`, `NX_DEVICE*KEYMASK`) that
        /// distinguishes this physical key from its opposite-side twin.
        var deviceMask: UInt64 {
            switch self {
            case .leftControl: return 0x0000_0001
            case .leftCommand: return 0x0000_0008
            case .rightCommand: return 0x0000_0010
            case .leftOption: return 0x0000_0020
            case .rightOption: return 0x0000_0040
            case .rightControl: return 0x0000_2000
            }
        }

        /// The ordinary, side-agnostic `CGEventFlags` bit every app already
        /// checks (`kCGEventFlagMaskCommand` and friends).
        var groupMask: UInt64 {
            switch self {
            case .leftCommand, .rightCommand: return 0x0010_0000
            case .leftOption, .rightOption: return 0x0008_0000
            case .leftControl, .rightControl: return 0x0004_0000
            }
        }
    }

    private static let allPrimaryGroupMasks: UInt64 =
        0x0010_0000 | 0x0008_0000 | 0x0004_0000 | 0x0002_0000 // command | option | control | shift

    /// Whether exactly the configured side of the configured modifier is held,
    /// with no other primary modifier also down. Requiring both the group flag
    /// and the device bit keeps synthetic events (which often set only the
    /// group flag) from arming quick launch by accident; requiring exclusivity
    /// means ⇧⌘F or ⌥⌘F still reach the frontmost app's own shortcut.
    static func isHeld(_ modifier: Modifier, flags: UInt64) -> Bool {
        guard flags & modifier.groupMask != 0, flags & modifier.deviceMask != 0 else { return false }
        return flags & allPrimaryGroupMasks & ~modifier.groupMask == 0
    }

    static let defaultModifier: Modifier = .rightCommand
    static var defaultModifierStorageValue: String { defaultModifier.rawValue }

    static func modifier(from storedValue: String?) -> Modifier {
        storedValue.flatMap(Modifier.init(rawValue:)) ?? defaultModifier
    }

    static func storageValue(for modifier: Modifier) -> String { modifier.rawValue }

    // MARK: - Letter from a keystroke

    /// US ANSI virtual keycode for each letter, the fallback for layouts that
    /// type no Latin letter at all (Cyrillic, Greek) — the same fallback
    /// policy `SwitcherSupport.letterAction` already uses for its W/Q/S keys,
    /// generalized here to the full alphabet.
    private static let usANSIKeyCodeToLetter: [Int64: Character] = [
        0: "a", 11: "b", 8: "c", 2: "d", 14: "e", 3: "f", 5: "g", 4: "h",
        34: "i", 38: "j", 40: "k", 37: "l", 46: "m", 45: "n", 31: "o", 35: "p",
        12: "q", 15: "r", 1: "s", 17: "t", 32: "u", 9: "v", 13: "w", 7: "x",
        16: "y", 6: "z",
    ]

    /// The plain lowercase letter a keystroke means, whether typed directly or
    /// resolved from key position on a non-Latin layout.
    static func letter(typedCharacter: String?, keyCode: Int64) -> Character? {
        latinLetter(in: typedCharacter) ?? usANSIKeyCodeToLetter[keyCode]
    }

    /// Accents fold away, so an accented letter of a Latin alphabet still
    /// resolves to its plain form.
    private static func latinLetter(in text: String?) -> Character? {
        guard let folded = text?.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current),
              folded.count == 1, let letter = folded.first, letter.isASCII, letter.isLetter
        else { return nil }
        return Character(letter.lowercased())
    }

    /// The letter an app's own name starts with, by the same folding rule, so
    /// an accented or uppercase app name still lands on the right letter.
    static func firstLetter(of name: String) -> Character? {
        latinLetter(in: name.trimmingCharacters(in: .whitespacesAndNewlines).first.map(String.init))
    }

    // MARK: - Priority assignments (stored preference)

    /// Round-trips the per-letter ordered bundle-ID list, mirroring
    /// `SwitcherAppRule.rules(storedValue:)` but keyed by letter and
    /// order-preserving rather than a single enum value per key.
    static func assignments(storedValue: [String: Any]?) -> [Character: [String]] {
        guard let storedValue else { return [:] }
        var result: [Character: [String]] = [:]
        for (rawLetter, rawList) in storedValue {
            guard rawLetter.count == 1,
                  let letter = latinLetter(in: rawLetter),
                  let bundleIDs = rawList as? [String]
            else { continue }
            let cleaned = bundleIDs
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
            guard !cleaned.isEmpty else { continue }
            result[letter] = cleaned
        }
        return result
    }

    /// Moves `bundleID` to the front of `letter`'s list, creating the letter's
    /// entry if it had none, and leaving every other letter untouched. Called
    /// after a successful activation, so quick launch is self-reinforcing: the
    /// app you actually switch to becomes that letter's top match from then
    /// on, ranked or not, ahead of whatever the list said before.
    static func promoting(_ bundleID: String, to letter: Character,
                          in assignments: [Character: [String]]) -> [Character: [String]] {
        var updated = assignments
        var current = updated[letter] ?? []
        current.removeAll { $0 == bundleID }
        current.insert(bundleID, at: 0)
        updated[letter] = current
        return updated
    }

    static func storedValue(_ assignments: [Character: [String]]) -> [String: [String]] {
        var stored: [String: [String]] = [:]
        for (letter, bundleIDs) in assignments {
            let cleaned = bundleIDs
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
            guard !cleaned.isEmpty else { continue }
            stored[String(letter).uppercased()] = cleaned
        }
        return stored
    }

    // MARK: - Roster

    /// Every letter that currently resolves to at least one running app,
    /// ranked apps first (in configured order), then unranked name-prefix
    /// matches by app MRU, then name, then pid for a fully deterministic
    /// order. An app already placed by an assignment is never duplicated into
    /// its own name-matched position.
    static func roster(apps: [RunningApp], assignments: [Character: [String]]) -> [Character: [Target]] {
        var byBundleID: [String: RunningApp] = [:]
        for app in apps {
            guard let bundleID = app.bundleID else { continue }
            byBundleID[bundleID] = app
        }

        var letters = Set(assignments.keys)
        for app in apps {
            if let letter = firstLetter(of: app.name) { letters.insert(letter) }
        }

        var result: [Character: [Target]] = [:]
        for letter in letters {
            var seenPIDs = Set<pid_t>()
            var ordered: [Target] = []

            for bundleID in assignments[letter] ?? [] {
                guard let app = byBundleID[bundleID], seenPIDs.insert(app.pid).inserted else { continue }
                ordered.append(Target(pid: app.pid, name: app.name))
            }

            let prefixMatches = apps
                .filter { !seenPIDs.contains($0.pid) && firstLetter(of: $0.name) == letter }
                .sorted { lhs, rhs in
                    if lhs.mruRank != rhs.mruRank { return lhs.mruRank < rhs.mruRank }
                    let nameOrder = lhs.name.localizedCaseInsensitiveCompare(rhs.name)
                    if nameOrder != .orderedSame { return nameOrder == .orderedAscending }
                    return lhs.pid < rhs.pid
                }
            for app in prefixMatches where seenPIDs.insert(app.pid).inserted {
                ordered.append(Target(pid: app.pid, name: app.name))
            }

            guard !ordered.isEmpty else { continue }
            result[letter] = ordered
        }
        return result
    }

    // MARK: - Cycling

    /// The whole interaction in one pure step: given the letter just pressed,
    /// decide what happens to it and how the hold evolves.
    ///
    /// A key-repeat of the letter that started the current hold is swallowed
    /// with no further action, so holding a letter down never stampedes
    /// through every match. A repeat of anything else, or a fresh press with
    /// no roster entry, is passed straight through.
    static func decide(letter: Character, isRepeat: Bool,
                       roster: [Character: [Target]],
                       hold: inout Hold) -> Decision {
        if isRepeat {
            return hold.letter == letter && !hold.candidates.isEmpty ? .swallow : .ignore
        }
        if hold.letter == letter, !hold.candidates.isEmpty {
            hold.index = (hold.index + 1) % hold.candidates.count
        } else {
            guard let candidates = roster[letter], !candidates.isEmpty else {
                hold = .idle
                return .ignore
            }
            hold = Hold(letter: letter, candidates: candidates, index: 0)
        }
        let target = hold.candidates[hold.index]
        return .activate(pid: target.pid, name: target.name)
    }
}
