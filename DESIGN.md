---
name: iCourier WhiteLabel
description: One Flutter code base wearing thirty-five courier identities, held together by a semantic token layer no screen is allowed to bypass.
colors:
  bg: "#f7f7f5"
  surface: "#ffffff"
  surface-alt: "#eeeeea"
  primary: "#22577a"
  on-primary: "#ffffff"
  secondary: "#4f772d"
  on-secondary: "#ffffff"
  text: "#1f2529"
  text-muted: "#687076"
  border: "#dfe2e3"
  success: "#2e7d4f"
  warning: "#b26a00"
  danger: "#b3261e"
typography:
  display:
    fontFamily: "Myriad"
    fontSize: "34px"
    fontWeight: 700
    lineHeight: 1.15
  headline:
    fontFamily: "Myriad"
    fontSize: "28px"
    fontWeight: 700
    lineHeight: 1.2
  title:
    fontFamily: "Myriad"
    fontSize: "20px"
    fontWeight: 700
    lineHeight: 1.3
  body:
    fontFamily: "Myriad"
    fontSize: "15px"
    fontWeight: 400
    lineHeight: 1.55
  label:
    fontFamily: "Myriad"
    fontSize: "13px"
    fontWeight: 700
    lineHeight: 1.3
  eyebrow:
    fontFamily: "Myriad"
    fontSize: "11px"
    fontWeight: 600
    letterSpacing: "0.88px"
rounded:
  sm: "8px"
  md: "16px"
  lg: "24px"
  pill: "999px"
  header-skirt: "34px"
  tab-dock: "26px"
  sheet: "24px"
  glyph-tile: "12px"
  checkbox: "6px"
  rail: "3px"
  qr: "12px"
spacing:
  xxs: "4px"
  xs: "8px"
  sm: "12px"
  md: "16px"
  lg: "20px"
  xl: "24px"
  xxl: "32px"
components:
  button-primary:
    backgroundColor: "{colors.primary}"
    textColor: "{colors.on-primary}"
    rounded: "{rounded.sm}"
    padding: "13px 16px"
    height: "44px"
  button-outline:
    backgroundColor: "{colors.surface}"
    textColor: "{colors.text}"
    rounded: "{rounded.sm}"
    padding: "11px 12px"
    height: "44px"
  button-outline-selected:
    backgroundColor: "{colors.surface-alt}"
    textColor: "{colors.primary}"
    rounded: "{rounded.sm}"
  card:
    backgroundColor: "{colors.surface}"
    textColor: "{colors.text}"
    rounded: "{rounded.md}"
    padding: "14px 15px"
  pill:
    rounded: "{rounded.pill}"
    padding: "3px 9px"
    typography: "{typography.label}"
  glyph-tile:
    rounded: "{rounded.glyph-tile}"
    size: "38px"
  field:
    backgroundColor: "{colors.surface}"
    textColor: "{colors.text}"
    rounded: "{rounded.sm}"
    padding: "13px 13px"
  field-focus:
    backgroundColor: "{colors.surface}"
    rounded: "{rounded.sm}"
  screen-header:
    backgroundColor: "{colors.primary}"
    textColor: "{colors.on-primary}"
    typography: "{typography.title}"
    height: "44px"
  tab-dock:
    backgroundColor: "{colors.surface}"
    rounded: "{rounded.tab-dock}"
    height: "108px"
---

# Design System: iCourier WhiteLabel

## Overview

**Creative North Star: "The Scanned Manifest"**

This is a courier's counter turned into a phone screen. The mood is operational
rather than decorative: solid brand bands, flat surfaces with a hairline border,
one clear thing per row, and nothing on screen that a customer at a pickup
counter would not need. Every screen answers a small, urgent question — has it
arrived, what will it cost, when do you open — so density is generous rather than
tight, and the single moment of theatre in the whole system is the scanner beam
that wipes new content in, as if the app just read a barcode.

The system's hardest constraint is that it has no fixed appearance. Thirty-five
courier brands ship this same binary; each supplies its own `whitelabel/<slug>.json`
with a primary, an optional secondary, two font families, and three corner radii.
Everything else — background, surfaces, text, muted text, borders, in light and in
dark — is derived from that primary's hue, so a brand that declares almost nothing
still gets a coherent, recognisably warm or cool world instead of the same grey as
everyone else. The consequence is that no screen may know what colour it is. The
token layer is a Flutter `ThemeExtension` named `BrandTokens`, reached only through
`context.brand`, and a repo gate (`dart run tool/audit_presentation.dart`) fails the
build if a presentation file names a colour, a font family, a literal radius, or a
brand slug. That gate is why this system holds; it is as much a part of the design
as the palette.

Because the palette is unknown at authoring time, contrast cannot be eyeballed —
it has to be computed. The system therefore ships derivation helpers rather than
hard-coded pairings: a foreground for an arbitrary accent, a soft wash plus a
foreground that survives it, a muted text colour that walks toward the body colour
only as far as the 4.5:1 floor demands. Reaching for a raw token where a derivation
exists is the most common way to break this system, and it does not show up on the
default brand.

All values below are Flutter logical pixels, which map 1:1 to CSS px.

**Key Characteristics:**
- Semantic tokens only; no screen names a colour, font or radius.
- Palette derived from one brand primary, per brightness, per brand.
- Flat surfaces on a tinted background; depth from four allowed shadows only.
- Contrast computed at runtime, never assumed.
- Exactly one authored motion, and it respects Reduce Motion.
- Five navigation tabs, home always centre.

## Colors

A brand supplies as little as one colour; the rest of the world is derived from
its hue, so the palette below is the shipped neutral default (`BrandPalette.lightDefaults`)
and a description of roles, not a description of how any shipped brand looks.

### Primary
- **Manifest Blue** — the brand's own voice. It fills the `ScreenHeader` band and
  the home header gradient, tints selected tab glyphs, fills the primary button,
  marks the focused field border, colours list bullets and links inside a generated
  answer, and is the accent of the scanner beam. It is the only colour allowed to
  cover a large area.
- **On-Primary** — the foreground for anything sitting on that band. Never chosen
  by hand: a brand's declared `onPrimary` is kept only if it clears 4.5:1 over the
  primary, otherwise it is replaced at config-parse time.

### Secondary
- **Manifest Green** — a second brand colour used sparingly: the trailing half of
  the scanner beam gradient and brand-specific accents. It is never a second
  primary and never fills a second full-width button on the same screen.

### Tertiary
This system has no tertiary accent. Status colour comes from the semantic trio
below, not from an extra decorative hue.

- **Success** — a delivered package, a completed stage.
- **Warning** — a package the customer must act on (missing invoice, retained
  goods); it is the border and glyph colour of `BrandNotice`.
- **Danger** — failed loads, destructive actions, the offline error state.

### Neutral
- **Background** — the app canvas behind everything; `Scaffold.backgroundColor`.
  It is a tinted near-white, not pure grey: the cast carries the brand hue.
- **Surface** — cards, sheets, the tab dock, fields, dialogs. A step above the
  background rather than a step in front of it.
- **Surface-Alt** — the third step: skeleton placeholder blocks, selected outline
  buttons, snackbars, the `BrandNotice` fill.
- **Text** — primary body and heading colour.
- **Text-Muted** — secondary strings; see the Readable Muted Rule below, which
  governs how it is actually reached.
- **Border** — the hairline that does the work a shadow would do elsewhere.

### Named Rules

**The Token-Only Rule.** No presentation file names a colour, a font family, a
literal corner radius, or a brand slug. Everything reaches the palette through
`context.brand`. This is enforced by `tool/audit_presentation.dart`, which fails
the build on `Color(`, `Colors.`, `fontFamily: '...'`, `BorderRadius.circular(<number>)`,
or any brand conditional, across every presentation directory.

**The Untrusted Accent Rule.** A brand's accent cannot be assumed to carry text or
icons. Any foreground drawn on an accent goes through a derivation:
`onAccent(background)` picks whichever of `text` or `surface` reads better;
`accessibleForeground(background, preferred:, minimumContrast:)` keeps the accent
when it clears the floor and falls back when it does not; `softAccentPair(accent)`
returns a wash *and* a foreground that survives it. Painting `primary` straight
onto `surface` as a text colour is the violation this rule exists to stop.

**The Readable Muted Rule.** Every secondary or muted string resolves through
`readableMuted(background)`, never through raw `textMuted`. `textMuted` is authored
against `surface`; on `bg` several derived palettes land it near 4.1:1, under the
4.5:1 floor. `readableMuted` returns it untouched where it already clears the floor
and otherwise walks it toward `text` in tenths until it does, so the muted step in
the hierarchy survives everywhere it legitimately can.

**The Derived Neutral Rule.** Neutrals are generated from the brand primary's hue
at fixed saturation and lightness targets, one set per brightness, and both
brightnesses take the hue of the *light* primary so a brand whose dark accent moves
across the wheel keeps the cast that identifies it. A value declared explicitly in
`whitelabel/<slug>.json` always wins over the derived one. A primary with under 8%
saturation falls back to the shipped neutral defaults rather than producing a
muddy family.

**The Fixed Foreground Rule.** Three colours are deliberately not brand-derived,
because the material underneath them is not brand-controlled: the scrim gradient
over banner artwork (5% to 55% black) and its white foreground, and `logoBackdrop`,
which stays white in both themes because brand marks are authored for a light
background and would be swallowed by a dark `surface`.

## Typography

**Display Font:** brand `fonts.head` (default Myriad; bundled families are used
directly, anything else is resolved through Google Fonts, e.g. Rubik for BM Cargo)
**Body Font:** brand `fonts.body` (default Myriad)

**Character:** two families at most, both brand-supplied, so the type carries the
identity while the ramp stays identical everywhere. The heading face is used
tightly and at weight 700; the body face carries everything else across four sizes.
The pairing is functional rather than expressive — the personality budget in this
system is spent on the palette, not on the type.

### Hierarchy
- **Display** (700, 34px / 28px, 1.15–1.2): the largest numbers and figures; account
  balances, point totals, calculator results.
- **Title** (700, 20px / 24px, 1.3): screen titles in the `ScreenHeader` band —
  20px on a pushed screen, 24px on a tab root.
- **Heading** (700, 16–18px, 1.3–1.35): card titles, the question a generated answer
  is answering, headings inside long-form prose.
- **Body** (400/500, 15px, 1.55): reading text, including generated answers. 13px is
  the compact variant for supporting copy inside a card; 12px is the floor, used only
  for provenance lines, field labels and metadata.
- **Label** (700, 12–13px, tight): buttons, pills, table figures.

### Named Rules

**The Two-Family Rule.** Every text style in the app is produced by `head()`,
`body()` or `eyebrow()` on `BrandTokens`. A widget states a size, a weight and a
token colour; it never states a family. This is what lets one screen render in
Myriad for one brand and Rubik for another with no conditional anywhere.

**The Fifteen-Point Rule.** Long-form reading text is 15px at 1.55 line-height and
runs the full content width between the standard 20px gutters. Generated prose gets
the same ramp as authored prose — an assistant answer is typeset as a document, with
a 16px heading, a 15px paragraph, and list items whose bullet is a 5px primary dot
optically centred on the first line at any system text scale.

## Layout

The spatial model is a single column of full-width cards on a tinted canvas. The
standard screen gutter is 20px (`BrandSpace.lg`); cards are separated by 10–12px,
sections by 24px. The spacing scale is `xxs 4 / xs 8 / sm 12 / md 16 / lg 20 /
xl 24 / xxl 32`, and everything structural comes from it.

Screen chrome is fixed. A pushed screen wears a `ScreenHeader`: a solid `primary`
band under the status bar whose action row is pinned to exactly 44px — the minimum
touch target — rather than letting a Material icon button stretch it to 48, because
the extra four pixels read as slack under a vertically centred title. Where a screen
offers filtering, the search field takes over the title in place instead of claiming
a row of its own.

The bottom of every screen belongs to the floating tab dock. It carries exactly five
destinations with `home` always at index 2 — `BrandNavigationConfig` throws a
`FormatException` at parse time on any other shape — and the centre slot is the
brand mark on its own light backdrop rather than a glyph.

Responsive behaviour is phone-first and one-handed. There is no multi-column
breakpoint; width is absorbed by the cards, and text scaling is respected rather
than clamped (bullet alignment is computed from `MediaQuery.textScalerOf`).

### Named Rules

**The Dock Inset Rule.** Every scrolling screen reserves `BrandTabBar.height`
(108px) of bottom padding so its last row clears the floating dock and the home
indicator. A screen that forgets it hides its own final item.

**The 44-Point Rule.** 44px is the floor for anything tappable: header actions,
both button variants (`minimumSize: Size(44, 44)`), row hit areas.

## Elevation & Depth

This system is mostly flat. Separation comes from a three-step tonal stack —
`bg` → `surface` → `surfaceAlt` — plus a 1px `border` hairline on every card.
Shadows are reserved for surfaces that genuinely float above the content, and the
vocabulary is closed: four presets and nothing else.

### Shadow Vocabulary
- **Card** (`0 1px 2px rgba(0,0,0,.03)`): resting list and content cards. Opt-in;
  most cards ship with the border alone.
- **Hero** (`0 12px 30px rgba(0,0,0,.13), 0 2px 6px rgba(0,0,0,.05)`): the single
  home card that overlaps the brand header skirt.
- **Dock** (`0 8px 24px rgba(0,0,0,.10)`): the floating tab bar.
- **Home Button** (`0 10px 24px` of the brand primary at 45%): the only tinted
  shadow in the system, under the centre navigation button.

### Named Rules

**The Four Shadows Rule.** `BrandElevation.card`, `.hero`, `.dock` and
`.homeButton(primary)` are the complete set. Three of them are neutral black by
design so they stay identical across all thirty-five identities; the fourth is the
one deliberate exception. A new shadow value in a screen is a system violation, not
a style choice.

**The Border-Before-Shadow Rule.** When a surface needs to separate from what is
behind it, raise it one tonal step and give it a hairline border. Reach for a shadow
only when it actually floats over scrolling content.

## Shapes

Corners come from two places and never from a literal. Three radii are
brand-controlled — `radiusSm` (default 8px) on buttons, fields and small controls,
`radiusMd` (16px) on cards, snackbars and skeleton blocks, `radiusLg` (24px) on
dialogs and date pickers — so a brand can be rounder or squarer across the whole app
by editing three numbers.

The rest are fixed geometry, identical for every identity, because their shape is
part of the design language rather than part of the brand: the pill (999px) for
chips and circular controls, the 34px skirt on the bottom of the home header, the
26px tab dock, the 24px top of a modal sheet, the 12px rounded square behind a glyph,
the 6px selection checkbox, the 3px segment of the four-part package rail, and the
12px membership QR card.

Icons are single-tone SVG silhouettes tinted from a token, so the same asset reads
correctly on any brand and in either theme. Multi-tone artwork is excluded on
purpose: a glyph that draws its detail as a white knockout collapses into a blob
when tinted.

### Named Rules

**The Two-Source Corner Rule.** A corner is either a brand radius token or a named
`BrandShape` constant. There is no third option, and the audit gate enforces it.

## Components

### Buttons
- **Shape:** the small brand corner (8px), or a full pill where a button floats
  inside an empty state or a summary bar.
- **Primary:** brand primary fill, foreground derived via `onAccent(fill)`, label at
  weight 700, 13px vertical padding, full width by default, 44px minimum.
- **Outline:** `surface` fill, `border` stroke at 1.5px, `text` label. Selected state
  swaps to `surfaceAlt` with a 2px `primary` stroke and a `primary` label.
- **Hierarchy:** one primary button per view. A second destination is an outline
  button, never a second fill.

### Chips
- **Style:** `BrandPill` — a pill capsule with a caller-supplied background and
  foreground pair, 700 weight, 12px, `3px 9px` padding. The pair always comes from
  `softAccentPair` or a semantic token, never from a raw accent.
- **State:** used for counts and status words; uppercase variant adds 5% tracking.

### Cards / Containers
- **Corner Style:** brand `radiusMd` (16px).
- **Background:** `surface`, or `surfaceAlt` when the card is a notice.
- **Shadow Strategy:** none by default; `BrandElevation.card` is opt-in.
- **Border:** 1px `border` hairline, always.
- **Internal Padding:** `14px 15px`. A tappable card gets an `InkWell` clipped to the
  same radius and, if it drills down, a `BrandChevron` in muted colour at the end of
  the row.

### Inputs / Fields
- **Style:** `surface` fill, 1px `border` stroke, small brand corner, `13px` padding,
  a 12px muted label above.
- **Focus:** the stroke becomes 2px `primary`. No glow, no shift.
- **Search:** inside a header, the field is borderless and typed in `onPrimary` over
  the primary band, with the hint at 60% opacity.

### Navigation
- **Style:** a floating dock — `surface`, hairline border, 26px corners, dock shadow,
  inset 12px from the screen edges and 10px above the safe area.
- **States:** unselected glyphs are `textMuted`; the selected glyph resolves through
  `accessibleForeground(surface, preferred: primary, minimumContrast: 3)` so a pale
  brand accent still reads. Selection on the centre button is carried by a 2px
  primary ring, not by recolouring the mark.
- **Shape of the set:** five slots, home at index 2, enforced at config-parse time.

### State Devices
Four devices cover every non-happy path, and screens compose them rather than
inventing their own.
- **Skeleton:** alternating 92px and 64px `surfaceAlt` blocks at the card radius,
  labelled for screen readers.
- **Empty:** a 74px circular glyph tile, a centred 13px muted line capped at 230px,
  and optionally the pill outline button that fills the emptiness.
- **Error:** a `danger` cloud-off mark, a 13px muted line, and one retry action.
- **Notice:** a `surfaceAlt` card with a `warning` border and glyph, a 13px bold
  title, a 12px muted explanation, and a compact `warning`-filled action.

### Named Rules

**The No-Spinner Rule.** A loading screen shows placeholder blocks in the shape of
the content that is coming. A full-screen spinner is never the answer.

**The Answer-Action-Provenance Rule.** Generated content reads in one order: the
answer, then the action it points at, then the disclosure of where it came from.
The disclosure never sits between the answer and its button, and it stays quiet —
a 12px muted line under an info mark — because it rides under every correct answer
too, and a warning band would cry wolf on all of them.

### Signature: the parcel-scanner reveal

`BrandManifestReveal` is the app's one authored motion and its most recognisable
gesture. Content is wiped in behind a diagonal mask raked 14px off vertical, with
a 2px beam at the mask's leading edge that runs from `primary` to `secondary` over
a 12px primary glow, fading in and out on a sine so it never lands hard. It runs
620ms on `easeOutExpo`, once per widget identity, and stops painting entirely once
it arrives. Sequences stagger with `brandManifestDelay(index)` at 55ms per item,
capped at six items so a long backend list cannot turn motion into latency.

### Named Rules

**The One Motion Rule.** `BrandManifestReveal` is the only authored entrance in the
system. New surfaces reuse it; they do not add a second signature.

**The Honest Motion Rule.** The reveal resolves instantly to its finished state when
the OS reports `disableAnimations` or `accessibleNavigation`. Motion is never the
only carrier of meaning, and it never repeats on rebuild.

## Do's and Don'ts

### Do:
- **Do** reach every colour, font and radius through `context.brand`; run
  `dart run tool/audit_presentation.dart` before calling a screen done.
- **Do** resolve muted text with `readableMuted(background)` against the background
  it actually sits on — `bg` and `surface` are different backgrounds.
- **Do** derive any accent foreground through `onAccent`, `accessibleForeground` or
  `softAccentPair`.
- **Do** reserve `BrandTabBar.height` (108px) at the bottom of every scrolling screen.
- **Do** compose the four state devices — skeleton, empty, error, notice — instead of
  writing a new one.
- **Do** keep to one primary button per view; a second destination is an outline.
- **Do** verify a new screen in light *and* dark on at least two brands with very
  different primaries; `flutter test` includes per-brand golden tests for both.

### Don't:
- **Don't** write a hex, a font family name, a numeric `BorderRadius.circular`, or a
  brand conditional (`if (slug == 'x')`) in presentation code. The build fails.
- **Don't** use raw `textMuted` for a string on `bg`.
- **Don't** paint text or an icon in `primary` or `secondary` without a contrast
  derivation; a brand accent may be far too pale to carry it.
- **Don't** invent a shadow. The vocabulary is `card`, `hero`, `dock`,
  `homeButton(primary)`.
- **Don't** show a full-screen spinner, and don't leave a failure without a retry.
- **Don't** add a second entrance animation, and don't make an animation the only
  way a change is perceivable.
- **Don't** assume the tab set: five slots, `home` at index 2, and every module is
  gated by `BrandCapabilities` resolved against what the backend reports.
- **Don't** tint multi-tone artwork; icons in this system are single-tone silhouettes.
