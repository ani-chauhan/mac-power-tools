// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import CoreGraphics
import Foundation

/// Pure logic for the pixel ruler: tolerance presets, unit conversion and the
/// edge-detection scan itself. No AppKit or ScreenCaptureKit, so the scan can
/// be driven by a synthetic sampler in the test harness instead of a live
/// screen buffer.
enum PixelRulerTolerance: String, CaseIterable {
    case zero, low, medium, high

    /// Minimum luminance step (0…255) that counts as an edge. Higher
    /// tolerance means LESS sensitive: only strong boundaries count.
    var threshold: Int {
        switch self {
        case .zero: return 1
        case .low: return 8
        case .medium: return 24
        case .high: return 64
        }
    }

    static func sanitized(_ raw: String?) -> PixelRulerTolerance {
        raw.flatMap(PixelRulerTolerance.init(rawValue:)) ?? .low
    }

    /// The next preset for the cycle key, wrapping back to the first.
    func cycled() -> PixelRulerTolerance {
        let all = Self.allCases
        let index = all.firstIndex(of: self) ?? 0
        return all[(index + 1) % all.count]
    }

    /// One step up or down the preset list for the +/- keys, clamped at
    /// the ends instead of wrapping — repeatedly pressing "more sensitive"
    /// should settle on Zero, not cycle past it.
    func stepped(by delta: Int) -> PixelRulerTolerance {
        let all = Self.allCases
        let index = all.firstIndex(of: self) ?? 0
        let clamped = min(max(index + delta, 0), all.count - 1)
        return all[clamped]
    }
}

enum PixelRulerUnit: String, CaseIterable {
    case pixel, point

    static func sanitized(_ raw: String?) -> PixelRulerUnit {
        raw.flatMap(PixelRulerUnit.init(rawValue:)) ?? .pixel
    }

    func toggled() -> PixelRulerUnit {
        self == .pixel ? .point : .pixel
    }

    /// `devicePixels` is the raw scan distance; `scale` is the source
    /// display's `backingScaleFactor`, applied per screen so a reading taken
    /// on a non-Retina second display isn't halved by a Retina main display.
    /// Just the number — the unit is a setting, not something worth
    /// repeating next to every measurement on screen.
    func label(devicePixels: Int, scale: CGFloat) -> String {
        switch self {
        case .pixel:
            return "\(devicePixels)"
        case .point:
            let points = scale > 0 ? Double(devicePixels) / Double(scale) : Double(devicePixels)
            return String(format: "%.0f", points)
        }
    }
}

enum PixelRulerScan {
    /// Distance in device pixels from the cursor to the nearest detected edge
    /// in each direction, clamped to the buffer bounds when no edge is found.
    struct Reading: Equatable {
        var up: Int
        var down: Int
        var left: Int
        var right: Int
    }

    /// Widest transition, in device pixels, the localizer will walk past
    /// detection before giving up on finding a stable far-side plateau and
    /// treating the transition as crisp. A genuine anti-aliasing ramp or
    /// shadow falloff is only a handful of pixels wide; this bounds the
    /// search on content that never truly stabilizes.
    private static let maxGradient = 64

    /// Flatness threshold (luminance units) for "the color has stopped
    /// changing": two consecutive samples within this of each other mark a
    /// stable plateau, or judge two plateaus "the same color". A property
    /// of the image — real edges plateau; dithering noise doesn't move this
    /// far — not a user preference, and deliberately independent of
    /// `tolerance` below, so localization never shifts when the user
    /// adjusts sensitivity.
    private static let plateauEpsilon = 8

    /// Walks outward from `(x, y)` in all four directions and localizes the
    /// nearest edge to its sub-pixel midpoint, rounded to the nearest
    /// device pixel. `luminance` is injected so this stays testable with a
    /// synthetic image instead of a live `CVPixelBuffer`.
    ///
    /// Detection and localization are deliberately separate steps:
    ///
    /// - **Detection** finds `firstOver`, the first step whose luminance
    ///   differs from the cursor's by more than `tolerance` — this is the
    ///   only place `tolerance` is consulted.
    /// - **Localization** then walks on until the color stabilizes into a
    ///   new plateau, and reports the 50%-brightness crossing between the
    ///   two plateau colors — independent of `tolerance` entirely.
    ///
    /// Because the reported position comes from the two plateau colors, not
    /// from wherever `firstOver` happened to land, a soft edge (shadow,
    /// glow, anti-aliasing, a fractionally-scaled resample) localizes to
    /// the same point no matter which pixel first tripped the tolerance —
    /// including one that shifts a pixel between frames from dithering
    /// noise. On a crisp edge the transition is zero pixels wide and this
    /// collapses to exactly the boundary between the last inside pixel and
    /// the first outside one, so hard edges are unaffected.
    static func scan(x: Int,
                     y: Int,
                     width: Int,
                     height: Int,
                     tolerance: Int,
                     luminance: (_ x: Int, _ y: Int) -> Int) -> Reading {
        guard width > 0, height > 0, x >= 0, x < width, y >= 0, y < height else {
            return Reading(up: 0, down: 0, left: 0, right: 0)
        }

        // A raw single-pixel sample is vulnerable to the dithering macOS
        // deliberately adds to shadows and gradients to hide banding.
        // Averaging a short strip perpendicular to the walk direction
        // cancels that out, since dithering alternates pixel-to-pixel while
        // a genuine edge reads uniformly across the strip.
        func sample(_ px: Int, _ py: Int, alongHorizontalRay: Bool) -> Int? {
            guard px >= 0, px < width, py >= 0, py < height else { return nil }
            var total = 0
            var count = 0
            for offset in -1...1 {
                let sx = alongHorizontalRay ? px : px + offset
                let sy = alongHorizontalRay ? py + offset : py
                guard sx >= 0, sx < width, sy >= 0, sy < height else { continue }
                total += luminance(sx, sy)
                count += 1
            }
            return count > 0 ? total / count : luminance(px, py)
        }

        func walk(dx: Int, dy: Int, limit: Int) -> Int {
            guard limit > 0 else { return 0 }
            let alongHorizontalRay = dy == 0
            func at(_ step: Int) -> Int? {
                sample(x + dx * step, y + dy * step, alongHorizontalRay: alongHorizontalRay)
            }
            guard let anchor = at(0) else { return limit }

            // Phase 1 — detection: the first step whose color differs from
            // the cursor's by more than `tolerance`.
            var firstOver = 1
            var firstOverColor = anchor
            while true {
                guard firstOver <= limit, let here = at(firstOver) else { return limit }
                if abs(here - anchor) > tolerance {
                    firstOverColor = here
                    break
                }
                firstOver += 1
            }

            // Phase 2 — find the far-side plateau: two consecutive samples
            // within `plateauEpsilon` mark where the color has stopped
            // changing, capped at `maxGradient` past detection so content
            // that never truly plateaus doesn't run the search away.
            let lastInside = firstOver - 1
            let cap = min(limit, firstOver + Self.maxGradient)
            var previous = firstOverColor
            var step = firstOver + 1
            var firstOutside = firstOver
            while true {
                if step > cap { firstOutside = firstOver; break }
                guard let here = at(step) else { firstOutside = step - 1; break }
                if abs(here - previous) <= Self.plateauEpsilon { firstOutside = step - 1; break }
                previous = here
                step += 1
            }

            // Phase 3 — localize: the sub-pixel 50%-brightness crossing
            // between the two plateau colors, tolerance-independent.
            let outside = at(firstOutside) ?? firstOverColor
            let boundary = localize(anchor: anchor, outside: outside,
                                    lastInside: lastInside, firstOutside: firstOutside, sample: at)
            return max(0, min(limit, Int(boundary.rounded())))
        }

        return Reading(up: walk(dx: 0, dy: -1, limit: y),
                       down: walk(dx: 0, dy: 1, limit: height - 1 - y),
                       left: walk(dx: -1, dy: 0, limit: x),
                       right: walk(dx: 1, dy: 0, limit: width - 1 - x))
    }

    /// Sub-pixel 50%-brightness crossing between `anchor` (the inside
    /// plateau) and `outside` (the far-side plateau), walking the
    /// transition and linearly interpolating between the first consecutive
    /// pair of steps that straddle the midpoint. Falls back to the
    /// transition's geometric center when the two plateaus are
    /// indistinguishable (a thin feature the walk passed through and back
    /// out of, with no meaningful midpoint) or the ramp never cleanly
    /// crosses (non-monotone content).
    private static func localize(anchor: Int,
                                 outside: Int,
                                 lastInside: Int,
                                 firstOutside: Int,
                                 sample: (Int) -> Int?) -> Double {
        let geometricCenter = Double(lastInside + firstOutside) / 2
        let axis = outside - anchor
        guard abs(axis) > plateauEpsilon else { return geometricCenter }

        func projection(_ value: Int) -> Double { Double(value - anchor) / Double(axis) }

        var previousStep = 0
        var previousProjection = 0.0 // step 0 is the anchor itself
        var step = 1
        while step <= firstOutside {
            guard let value = sample(step) else { break }
            let projected = projection(value)
            if previousProjection <= 0.5, projected > 0.5 {
                let crossing = (0.5 - previousProjection) / (projected - previousProjection)
                return Double(previousStep) + crossing
            }
            previousStep = step
            previousProjection = projected
            step += 1
        }
        return geometricCenter
    }

    /// Standard BT.601-ish integer luminance from BGRA bytes, no floating
    /// point in what is otherwise a per-pixel inner loop.
    static func luminance(b: UInt8, g: UInt8, r: UInt8) -> Int {
        (54 * Int(r) + 183 * Int(g) + 19 * Int(b)) >> 8
    }
}

/// Pure geometry for the area (drag-to-measure) tool.
enum PixelRulerArea {
    /// A reduced "W:H" ratio, e.g. 1920x1080 -> "16:9". Empty for a
    /// degenerate rectangle so the caller can skip drawing it.
    static func aspectRatioLabel(width: Int, height: Int) -> String {
        guard width > 0, height > 0 else { return "" }
        let divisor = greatestCommonDivisor(width, height)
        return "\(width / divisor):\(height / divisor)"
    }

    private static func greatestCommonDivisor(_ a: Int, _ b: Int) -> Int {
        var a = a, b = b
        while b != 0 {
            (a, b) = (b, a % b)
        }
        return max(a, 1)
    }

    /// The drag rectangle for the area tool. `origin` is always where the
    /// drag started. `squareConstrained` forces equal width/height (Shift);
    /// `centeredOnOrigin` treats `origin` as the center instead of a corner,
    /// growing symmetrically in every direction (Option) — the same
    /// corner-vs-center and free-vs-square modifiers most design apps share,
    /// and they compose independently.
    static func dragRect(from origin: CGPoint,
                         to current: CGPoint,
                         squareConstrained: Bool,
                         centeredOnOrigin: Bool) -> CGRect {
        let dx = current.x - origin.x
        let dy = current.y - origin.y

        if centeredOnOrigin {
            let halfWidth = squareConstrained ? max(abs(dx), abs(dy)) : abs(dx)
            let halfHeight = squareConstrained ? max(abs(dx), abs(dy)) : abs(dy)
            return CGRect(x: origin.x - halfWidth, y: origin.y - halfHeight,
                         width: halfWidth * 2, height: halfHeight * 2)
        }

        let corner: CGPoint
        if squareConstrained {
            let side = max(abs(dx), abs(dy))
            let signX: CGFloat = dx >= 0 ? 1 : -1
            let signY: CGFloat = dy >= 0 ? 1 : -1
            corner = CGPoint(x: origin.x + signX * side, y: origin.y + signY * side)
        } else {
            corner = current
        }
        return CGRect(x: min(origin.x, corner.x), y: min(origin.y, corner.y),
                     width: abs(corner.x - origin.x), height: abs(corner.y - origin.y))
    }
}
