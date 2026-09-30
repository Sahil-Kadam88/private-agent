# Architecture Report — PrivateAgent

Repository: https://github.com/AbuZar-Ansarii/PrivateAgent.git
Analysis date: 2026-09-30 · Branch: `ui-redesign-60-30-10`

## Toolchain

| Item | Value |
|---|---|
| Flutter | 3.47.5 (stable) |
| Dart | 3.13.4 (SDK constraint `^3.12.2`) |
| AGP | 9.0.1 · Kotlin 2.3.20 · Gradle (wrapper) |
| compileSdk / targetSdk | `flutter.compileSdkVersion` / `flutter.targetSdkVersion` (SDK 36 toolchain) |
| minSdk | 26 |
| NDK | 28.2.13676358 (Flutter default) |
| Application ID | `com.privateagent.private_agent` |
| Release signing | debug keystore (project TODO in `build.gradle.kts`) |

## Project structure

```
lib/
├── main.dart                     # entry, Telegram + overlay command wiring, overlayMain() isolate entry
├── app.dart                      # MaterialApp, theme mode, onboarding gate
├── models/                       # chat_message, screen_node, skill, task_history_entry, task_step
├── overlay/overlay_app.dart      # floating bubble + panel (separate engine)
├── screens/
│   ├── home/home_screen.dart             # transcript, input, mode switcher, sessions drawer
│   ├── onboarding/onboarding_screen.dart # 4-page first-run setup
│   ├── settings/settings_screen.dart     # AI provider / agent / telegram / appearance
│   ├── history/task_history_screen.dart  # expandable task log list
│   └── sessions/session_detail_screen.dart
├── services/                     # 10 singletons (see below)
├── theme/app_theme.dart          # ThemeData factory (Slate + indigo palette)
└── widgets/                      # chat_bubble, status_chip
android/
├── app/build.gradle.kts, AndroidManifest.xml
└── app/src/main/kotlin/com/privateagent/private_agent/
    ├── MainActivity.kt                   # MethodChannel handler
    └── AgentAccessibilityService.kt      # screen dump + gestures + screenshot
assets/icon/genie_logo.png        # only registered asset (in-app logo)
tool/mock_llm.py                  # offline OpenAI-compatible E2E mock server
tool/generate_icons.py            # Pillow launcher-icon generator (hardcoded macOS path)
test/widget_test.dart              # 10 tests (parsing, skills, settings, 2 widget tests)
```

## Main entry points

- `main()` — init `SettingsService` + `TaskExecutor`, wire Telegram (`_wireTelegram`) and overlay commands (`_wireOverlayCommands`), `runApp(PrivateAgentApp)`.
- `overlayMain()` — `@pragma('vm:entry-point')` top-level function for the overlay's separate Flutter engine. **Must stay top-level and unreferenced (tree-shaking).**

## UI architecture

- Plain `MaterialApp` (no named routes); navigation via `MaterialPageRoute`.
- First-run gate: `settings.onboardingComplete` selects `OnboardingScreen` vs `HomeScreen`.
- Screens: Home (root), Onboarding, Settings, History, SessionDetail, Overlay.
- Widgets: `ChatBubble` (markdown agent bubbles), `StatusChip`/`ServiceStatusDot`.

## State management

Singleton `ChangeNotifier` + manual `addListener`/`setState`:
- `SettingsService.instance` — observed by `PrivateAgentApp` (theme/onboarding) and `SettingsScreen`.
- `TaskExecutor.instance` — observed by Home, History, SessionDetail.
- `TelegramService.instance` — `isRunning` observed by Settings.
- Other services (`ScreenAutomationService`, `AiService`, `VoiceService`, …) are plain singletons polled on lifecycle events.

## Services

| Service | Role |
|---|---|
| `TaskExecutor` (618 L) | observe→reason→act→verify→recover loop, chat mode, pause/resume/cancel, history, overlay broadcast, notifications, TTS |
| `AiService` | OpenAI-compatible `/chat/completions` over `http` (DeepSeek/OpenAI/Gemini/OpenRouter/NVIDIA/Ollama/custom), system prompt builder |
| `ScreenAutomationService` | Dart façade over the accessibility MethodChannel: dump/tap/swipe/scroll/type/keys/screenshot |
| `SettingsService` | all persistence via SharedPreferences (AI config, agent params, telegram, UI mode, theme, onboarding) |
| `SkillMemoryService` | macro replay of successful action sequences (`skill_memory_v1`, Jaccard ≥ 0.75 match) |
| `RecoveryEngine` | stuck detection (3 identical actions or 3 identical dumps) → rotate scroll/wait/back |
| `TelegramService` | long-poll bot: `/status` `/screenshot` `/cancel` `/stop`, goal dispatch, owner pairing |
| `VoiceService` | STT (`speech_to_text`) + TTS (`flutter_tts`) |
| `SystemControlService` | volume/brightness/intents/contacts/Shizuku **+ only `notify()` is wired** (see risks) |
| `AppLauncherService` | fuzzy installed-app resolution for `open_app` action |

## Native Android bridge

Single custom MethodChannel: **`com.privateagent/accessibility`**
(Dart: `screen_automation_service.dart` · Kotlin: `MainActivity.kt` → `AgentAccessibilityService.instance`)

Methods: `isServiceEnabled`, `openAccessibilitySettings`, `openAppInfoSettings`, `getScreenSize` (unused), `dumpScreen`, `takeScreenshot` (API 30+), `clickAt`, `swipe`, `scroll`, `typeText`, `pressKey` (back/home/recents/notifications/quick_settings/power_dialog/lock/enter).

- `AgentAccessibilityService`: poll-driven (no event handling); window selection excludes the app's own package; `GestureDescription` dispatch; native scroll first, gesture fallback; PNG q85 screenshots.
- Manifest: accessibility service + `accessibility_service_config.xml`, `flutter_overlay_window` special-use foreground service, `ShizukuProvider`, 18 permissions, `<queries>` for PROCESS_TEXT/TTS/DIAL, `usesCleartextTraffic=true` (local Ollama).
- Plugin channels (GeneratedPluginRegistrant): speech_to_text, flutter_tts, shared_preferences, installed_apps, url_launcher, android_intent_plus, flutter_contacts, permission_handler, flutter_local_notifications, volume_controller, screen_brightness, shizuku_api, share_plus, flutter_overlay_window, path_provider.

## Dependencies (`pubspec.yaml`)

Networking `http` · Voice `speech_to_text` `flutter_tts` · App mgmt `installed_apps` `url_launcher` `android_intent_plus` · Contacts `flutter_contacts` · Permissions `permission_handler` ^12 · Storage `shared_preferences` `path_provider` · Notifications `flutter_local_notifications` · System `volume_controller` `screen_brightness` `shizuku_api` · Share `share_plus` · Format `intl` · Overlay `flutter_overlay_window` · Markdown `flutter_markdown_plus` · `uuid` · `cupertino_icons` · dev: `flutter_lints` ^6.

## Persistence (SharedPreferences)

AI config `ai_*` (provider/base_url/api_key/model/max_tokens/temperature/use_system_prompt) · agent `agent_max_steps` `agent_step_delay_ms` `agent_skills_enabled` · telegram `telegram_*` (incl. `telegram_offset`) · UI `ui_app_mode` `ui_theme_mode` `onboarding_complete` `voice_feedback` · data blobs `task_history_v1` (≤50 entries, JSON) `skill_memory_v1` (≤100 skills, JSON).

## Existing UI theme system

`lib/theme/app_theme.dart`: `AppTheme.light()/dark()` built from `ColorScheme.fromSeed(seedColor: indigo)` with Slate surface palette + static constants (`slate50…950`, `indigo`, `indigoLight`, `success`, `danger`, `warning`). Component themes: app bar (transparent), card (radius 16, outline border), inputs (radius 14), FilledButton (radius 14), chips, snackbars, dividers. Overlay imports the same file and forces `AppTheme.dark()`.

## Existing asset system

- One registered asset: `assets/icon/genie_logo.png` (512px, indigo/amber "magic lamp"), used in Home app bar + drawer only.
- Launcher: adaptive icon (`mipmap-anydpi-v26/ic_launcher.xml`) + per-density `ic_launcher.png`, `ic_launcher_foreground.png` (indigo gradient lamp art), `ic_launcher_background.png`.
- Splash: plain white `launch_background.xml`, no logo.
- Web scaffold: `favicon.png`, `Icon-192/512`, `Icon-maskable-192/512`.
- `tool/generate_icons.py` regenerates all of the above (Pillow; hardcoded base path, macOS-only as-is).

## Existing risks

1. **Test/tool string contracts**: widget tests assert `Meet PrivateAgent`, `Continue`, `Ollama (local)`, `llama3.2`, `Send system prompt`, `Save changes`, field `Model`. `tool/mock_llm.py` keys off home-screen strings (`Describe a task…`, `Pause`, `Cancel task`, `privateagent`).
2. **Session replay regex**: `SessionDetailScreen` parses persisted log lines `[role #step] text` — format changes corrupt history.
3. **Settings unsaved-edit guard** (`_lastSyncedProvider`) — regression-tested; naive rebuilds re-break it.
4. **Overlay isolate**: `overlayMain()` pruning risk; untyped JSON protocol (`state`/`command`) hardcoded on both sides; size constants duplicated (120×120 show vs 110×110 bubble).
5. **Dead / unwired code**: `SystemControlService` volume/brightness/alarm/dial/contacts/Shizuku have zero callers and no LLM actions; `path_provider` never imported; `getScreenSize()`/`clickNode()` unused; `ChatMessage.toJson` unused; README overstates "System control".
6. **Secrets at rest**: `ai_api_key`, `telegram_token` in plaintext SharedPreferences; history share includes transcripts (no secrets).
7. **Release signed with debug keys.**
8. **Web scaffold cannot build** (`dart:io` in system_control_service); analyzer excludes `web/**`.
9. `usesCleartextTraffic=true` required for local Ollama HTTP.
10. Home-screen `SegmentedButton` is the **only** entry point to Chat mode.

## Existing APK size contributors (hypotheses to verify with `--analyze-size`)

- ARM64 + ARMv7 native `.so` per plugin (flutter engine, plugin libs) — universal APK doubles ABI payloads.
- Debug info / unstripped native libs; no R8 `minifyEnabled`/`shrinkResources` today.
- `flutter_local_notifications`, `shizuku_api`, `flutter_contacts` native bits.
- Icon PNGs (small), Material Icons font (needed), `cupertino_icons` font (check if used).
- Unused `path_provider` plugin (verify before removal).

## Potential optimization opportunities

1. `--split-per-abi` (arm64-v8a primary) — largest safe win.
2. Enable `minifyEnabled` + `shrinkResources` (R8) with targeted keep rules if needed.
3. Verify & remove genuinely unused deps (`path_provider`, `cupertino_icons` if unused).
4. Compress/replace launcher PNGs (vector adaptive icon + tiny fallbacks).
5. `flutter build apk --release --analyze-size` for data-driven follow-ups.
6. Strip dev-only files from the repo (not packaged anyway — `tool/`, `Prompt.txt` don't ship in APK).
