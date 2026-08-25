// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import SwiftUI
import UniformTypeIdentifiers

/// Per-letter cycling order for quick launch. Each letter's list doubles as an
/// assignment: an app placed under a letter is reachable through it even when
/// its name does not start with that letter.
struct QuickLaunchPrioritiesList: View {
    @ObservedObject private var l10n = L10n.shared
    @State private var assignments: [Character: [String]]
    @State private var isExpanded: Bool
    @State private var addingAppTarget: LetterTarget?
    @State private var draggingBundleID: String?

    private var text: QuickLaunchStrings { FeatureStrings.quickLaunch(l10n.language) }

    /// Wraps a letter so it can drive `.sheet(item:)`, the presentation API
    /// that ties a sheet's lifetime to a value rather than a hand-derived
    /// boolean — the latter has a documented history of flakiness in SwiftUI
    /// when the same view can be asked to present twice in quick succession.
    private struct LetterTarget: Identifiable {
        let letter: Character
        var id: Character { letter }
    }

    init() {
        let saved = Self.savedAssignments
        _assignments = State(initialValue: saved)
        _isExpanded = State(initialValue: !saved.isEmpty)
    }

    private static var savedAssignments: [Character: [String]] {
        SwitcherQuickLaunchSupport.assignments(
            storedValue: UserDefaults.standard.dictionary(forKey: DefaultsKey.switcherQuickLaunchPriorities))
    }

    private var sortedLetters: [Character] {
        assignments.keys.sorted()
    }

    private var availableLetters: [Character] {
        let used = Set(assignments.keys)
        return (Character("a").asciiValue!...Character("z").asciiValue!)
            .map { Character(UnicodeScalar($0)) }
            .filter { !used.contains($0) }
    }

    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            VStack(alignment: .leading, spacing: 10) {
                ForEach(sortedLetters, id: \.self) { letter in
                    letterRow(letter)
                    if letter != sortedLetters.last { Divider() }
                }
                addLetterMenu
                    .controlSize(.small)
                Text(text.prioritiesCaption)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.top, 4)
        } label: {
            HStack {
                Text(text.prioritiesTitle)
                Spacer()
                if !assignments.isEmpty {
                    Text("\(assignments.count)")
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
            }
        }
        .sheet(item: $addingAppTarget) { target in
            appPickerSheet(for: target.letter)
        }
    }

    private func letterRow(_ letter: Character) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(String(letter).uppercased())
                    .font(.system(.body, design: .rounded).bold())
                    .frame(width: 20, alignment: .leading)
                Spacer()
                Button {
                    addingAppTarget = LetterTarget(letter: letter)
                } label: {
                    Image(systemName: "plus.circle")
                }
                .buttonStyle(.borderless)
                .accessibilityLabel(text.addButton)
                Button(role: .destructive) {
                    removeLetter(letter)
                } label: {
                    Image(systemName: "trash")
                }
                .buttonStyle(.borderless)
                .accessibilityLabel(text.removeLetterButton)
            }
            ForEach(assignments[letter] ?? [], id: \.self) { bundleID in
                appRow(letter: letter, bundleID: bundleID)
            }
        }
    }

    private func appRow(letter: Character, bundleID: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "line.3.horizontal")
                .font(.system(size: 11))
                .foregroundStyle(.tertiary)
            Image(nsImage: InstalledApps.icon(for: bundleID))
                .resizable()
                .frame(width: 16, height: 16)
            Text(InstalledApps.name(for: bundleID))
                .lineLimit(1)
            Spacer(minLength: 8)
            Button {
                remove(bundleID: bundleID, from: letter)
            } label: {
                Image(systemName: "minus.circle.fill")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.borderless)
            .accessibilityLabel(text.removeButton)
        }
        .frame(height: 24)
        .contentShape(Rectangle())
        .opacity(draggingBundleID == bundleID ? 0.45 : 1)
        .onDrag {
            draggingBundleID = bundleID
            return NSItemProvider(object: bundleID as NSString)
        }
        .onDrop(of: [UTType.text],
                delegate: QuickLaunchPriorityDropDelegate(target: bundleID,
                                                          order: binding(for: letter),
                                                          dragging: $draggingBundleID))
    }

    private var addLetterMenu: some View {
        Menu {
            ForEach(availableLetters, id: \.self) { letter in
                Button(String(letter).uppercased()) {
                    addingAppTarget = LetterTarget(letter: letter)
                }
            }
        } label: {
            Label(text.addLetterButton, systemImage: "plus")
        }
        .disabled(availableLetters.isEmpty)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func appPickerSheet(for letter: Character) -> some View {
        let listed = Set(assignments[letter] ?? [])
        return AppPickerView(canBrowseApplications: true) {
            addingAppTarget = nil
        } onSelect: { url in
            addingAppTarget = nil
            guard let bundleID = Bundle(url: url)?.bundleIdentifier else { return }
            add(bundleID: bundleID, to: letter)
        } loadApps: {
            InstalledApps.installedBundleApplications(excluding: listed, includeRunningApplications: true)
        }
    }

    /// Every mutation re-reads the persisted dictionary first rather than
    /// trusting this view's in-memory copy, so a Settings edit can never lose
    /// a previous addition to stale local state — it always merges into
    /// whatever is actually on disk right now.
    private func mutateAssignments(_ transform: (inout [Character: [String]]) -> Void) {
        var current = Self.savedAssignments
        transform(&current)
        assignments = current
        UserDefaults.standard.set(SwitcherQuickLaunchSupport.storedValue(current),
                                  forKey: DefaultsKey.switcherQuickLaunchPriorities)
        AppSwitcher.shared.syncWithPreferences()
    }

    private func binding(for letter: Character) -> Binding<[String]> {
        Binding(
            get: { assignments[letter] ?? [] },
            set: { newValue in
                mutateAssignments { current in
                    if newValue.isEmpty {
                        current.removeValue(forKey: letter)
                    } else {
                        current[letter] = newValue
                    }
                }
            }
        )
    }

    private func add(bundleID: String, to letter: Character) {
        mutateAssignments { current in
            var list = current[letter] ?? []
            guard !list.contains(bundleID) else { return }
            list.append(bundleID)
            current[letter] = list
        }
    }

    private func remove(bundleID: String, from letter: Character) {
        mutateAssignments { current in
            guard var list = current[letter] else { return }
            list.removeAll { $0 == bundleID }
            if list.isEmpty {
                current.removeValue(forKey: letter)
            } else {
                current[letter] = list
            }
        }
    }

    private func removeLetter(_ letter: Character) {
        mutateAssignments { current in
            current.removeValue(forKey: letter)
        }
    }
}

private struct QuickLaunchPriorityDropDelegate: DropDelegate {
    let target: String
    @Binding var order: [String]
    @Binding var dragging: String?

    func dropEntered(info: DropInfo) {
        guard let dragging, dragging != target,
              let from = order.firstIndex(of: dragging),
              let to = order.firstIndex(of: target) else { return }
        withAnimation(.easeInOut(duration: 0.12)) {
            order.move(fromOffsets: IndexSet(integer: from), toOffset: to > from ? to + 1 : to)
        }
    }

    func dropUpdated(info: DropInfo) -> DropProposal? { DropProposal(operation: .move) }

    func performDrop(info: DropInfo) -> Bool {
        dragging = nil
        return true
    }
}
