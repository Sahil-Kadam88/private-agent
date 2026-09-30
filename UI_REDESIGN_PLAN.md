# UI Redesign Plan — 60-30-10 Color Rule

Project: PrivateAgent
Branch: `ui-redesign-60-30-10`

## Reference hierarchy

| Share | Role | Values |
|---|---|---|
| 60% | PRIMARY — backgrounds | `#FFFFFF` white / very light surfaces |
| 30% | SECONDARY — surfaces & typography | `#000000` black, `#111111`, `#1A1A1A` |
| 10% | ACCENT — CTAs, active states, indicators | `#E21B23` red, `#B51218` pressed, `#FDE7E8` light |

## Current UI → Target UI

| Aspect | Current | Target |
|---|---|---|
| Theme seed | Indigo `#6366F1`, Slate palette | Centralized `AppColors` palette (white/black/red) |
| Light scaffold | Slate50 `#F8FAFC` | Pure white `#FFFFFF` |
| Dark scaffold | Slate950 `#020617` | `#111111` near-black |
| App bar | Transparent, inherits bg | Solid black `#000000` nav surface, white title/icons |
| Primary CTA | Indigo FilledButtons | Red `#E21B23` FilledButtons (pressed `#B51218`) |
| Selected segment | Indigo | Red `#E21B23` |
| Switches / sliders | Indigo active | Red active (active states = accent) |
| User chat bubble | Indigo (`colorScheme.primary`) | Black `#111111` with white text |
| Agent chat bubble | Slate container | Light gray `#F5F5F5` with black text |
| Error bubble | Red danger | Error `#D71920` tint (unchanged semantics) |
| Active task bar | Indigo 8% tint | Black `#111111` surface, white text, red progress/cancel |
| Overlay bubble | Indigo gradient + glow | Solid black circle, white icon, red busy spinner |
| Overlay panel | Indigo glassmorphism | Black glass `#111111` @ ~85%, white text, red send/cancel |
| Text button | Indigo label | Black label (accent reserved for CTAs) |
| Borders | Slate outlines | `#D9D9D9` |
| Muted text | Slate500/600 | `#6B6B6B` |

## Files requiring modification

| File | Change scope |
|---|---|
| `lib/theme/app_colors.dart` | **NEW** — centralized palette |
| `lib/theme/app_spacing.dart` | **NEW** — spacing/radius constants |
| `lib/theme/app_theme.dart` | **REWRITE** — light/dark themes + component themes |
| `lib/widgets/app_logo.dart` | **NEW** — black-circle logo widget (white tile on dark surfaces) |
| `lib/widgets/chat_bubble.dart` | User bubble → secondary (black); semantic colors from `AppColors` |
| `lib/widgets/status_chip.dart` | Palette refs → `AppColors` |
| `lib/screens/home/home_screen.dart` | Black task bar, logo widget, `Colors.green` → `AppColors.success`, input/CTA review |
| `lib/screens/onboarding/onboarding_screen.dart` | Palette refs → `AppColors` (logic untouched) |
| `lib/screens/history/task_history_screen.dart` | `Colors.red` → `AppColors.error` |
| `lib/screens/settings/settings_screen.dart` | Theme-driven; verify Save/active states read as accent |
| `lib/screens/sessions/session_detail_screen.dart` | Theme-driven only |
| `lib/overlay/overlay_app.dart` | Visual restyle only (19 raw `Colors.*` + 11 palette refs); **command protocol untouched** |
| `pubspec.yaml` | Asset path for logo (unchanged name) |

## Reusable widgets to introduce

- `AppLogo` — black circle; renders on white tile when the surrounding surface is dark (app bar).
- `SectionHeader` — uppercase 12px w800 letter-spaced header (settings + drawer "RECENT SESSIONS").
- `EmptyState` — icon + title + subtitle block (home, history, session detail, overlay).

## Theme changes (component-level)

- `AppBarTheme`: black bg, white foreground/title — the 30% "black navigation" element.
- `FilledButtonTheme`: red background, white label, `#B51218` pressed, radius 14.
- `TextButtonTheme`: black label (light) / white label (dark) — accent not spent on passive actions.
- `OutlinedButtonTheme`: black 1.2px border + black label (high contrast, minimal).
- `SegmentedButton`: selected = red bg / white label; unselected = white bg / black label / `#D9D9D9` border.
- `CardTheme`: white, `#D9D9D9` 1px border, radius 16, elevation 0.
- `InputDecorationTheme`: white fill, `#D9D9D9` border, red focused border 1.6.
- `SwitchTheme` / `SliderTheme`: red active track/thumb.
- `SnackBarTheme`: black `#111111` surface, white text.
- `DividerTheme`: `#D9D9D9`.
- Typography: default Roboto (no custom fonts); headings w700–w800, letter-spacing −0.3 on titles.

## Accessibility considerations

- Red `#E21B23` on white: used as *background* of white-labeled buttons (contrast ≈ 4.6:1 for white on `#E21B23`, AA for large/bold UI text) — button labels are 14px w600+.
- Black `#000000` text on white: maximum contrast.
- Muted `#6B6B6B` on white ≈ 5.3:1 (AA normal text).
- Never red-on-red or black-on-black: status colors keep semantic trio (`success #1B8A3A`, `warning #D98C00`, `error #D71920`) with tinted backgrounds.
- 60-30-10 is applied per screen and overall — accent remains selective (CTAs, active toggles, progress, error).

## Constraints (from regression analysis)

- Preserve exact test-visible strings: `Meet PrivateAgent`, `Continue`, `Get Started`, `Ollama (local)`, `Model`, `Save changes`, `Send system prompt`, `Settings`, `Task History`.
- Preserve all callbacks: submit/voice/overlay toggles, provider write-through, onboarding gate, executor listeners, overlay JSON protocol (`command` / `state`).
- Overlay runs in its own isolate but imports `theme/app_theme.dart` — palette changes propagate automatically.
