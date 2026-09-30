<div align="center">

# 🧞 PrivateAgent

**A fully private, on-device autonomous agent for Android**

PrivateAgent turns any OpenAI-compatible LLM into an autonomous Android UI
automation agent. It observes the screen through Android's Accessibility
Service, reasons about what it sees with an LLM of your choice, and acts —
tapping, typing, and swiping — until your goal is accomplished.

*Your keys. Your data. Your device. Nothing leaves your phone except LLM calls
you configure yourself.*

</div>

---

## ✨ Features

| Capability | Description |
|---|---|
| 🤖 **Autonomous task execution** | Observe → reason → act → verify → recover feedback loop: dumps the visible UI, asks the LLM for one JSON action, executes it, and repeats until the goal is done (step caps and repeat-action detection included). |
| 🧠 **Skill memory (macro replay)** | Successful action sequences are stored locally per goal. Repeated tasks replay as macros — zero LLM tokens spent. Match = exact normalized goal, else Jaccard ≥ 0.75 token overlap; failed replays are forgotten. |
| 🔌 **Any OpenAI-compatible LLM** | Works with DeepSeek, OpenRouter, NVIDIA NIM, Gemini, OpenAI, Ollama (fully local/offline), or any custom base URL. |
| ♿ **Screen automation** | Native Android accessibility service for screen dumps, taps, text input, swipes, scroll, back/home/recents and API 30+ screenshots. |
| 📱 **Telegram remote control** | Drive your phone from anywhere via a Telegram bot — send goals, get status updates and screenshots back. First sender becomes the owner; optional chat allowlist. |
| 🎙️ **Voice interface** | Speech-to-text input on the home bar and overlay, text-to-speech replies on task completion. |
| 🪟 **Overlay assistant** | Floating black bubble over any app; expand into a glass panel to launch/pause/cancel tasks without leaving what you're doing. |
| 🔁 **Recovery engine** | Detects stuck states (3 identical actions or 3 identical screen dumps) and autonomously recovers: scroll → wait → back. |
| ⚙️ **System integration** | App launching (fuzzy package/name matching), local notifications on completion, sharing task logs, contacts/microphone/notification permissions during onboarding. |
| 🔐 **Private by design** | All state (settings, skills, history) stays on-device via `SharedPreferences`. No telemetry, no analytics, no crash reporting — ever. |
| 🎨 **60-30-10 design system** | Minimal white/black/red visual hierarchy: 60% white surfaces, 30% black navigation & typography, 10% red accent for CTAs and active states. Light **and** dark themes. |

---

## 🎨 Design system (60-30-10)

The UI follows a strict color rule, centralized in `lib/theme/app_colors.dart`
and applied through `lib/theme/app_theme.dart` — no hardcoded colors in screens:

| Share | Role | Values | Where |
|---|---|---|---|
| **60%** | Primary backgrounds | `#FFFFFF`, `#F4F4F4`, `#EDEDED` | Scaffold, cards, inputs, dialogs, drawer |
| **30%** | Secondary surfaces & type | `#000000`, `#111111`, `#1A1A1A` | App bar, typography, user chat bubbles, active-task bar, overlay bubble/panel |
| **10%** | Accent | `#E21B23` (pressed `#B51218`, tint `#FDE7E8`) | CTAs, send button, selected chips/segments, switches, sliders, progress, step chips, active mic |

Semantic statuses: success `#1B8A3A` · warning `#D98C00` · error `#D71920`.
Borders `#D9D9D9` · muted text `#6B6B6B`. Dark theme maps the primary
background to `#111111` and keeps the same red accent.

The launcher icon is a **simple solid black circle** (adaptive vector icon on
white, plus density fallbacks) — regenerate everything with
`tool/generate_black_circle_icons.ps1`.

---

## 🧠 How it works

```
        ┌─────────────────────────────────────────────┐
        │              TaskExecutor                   │
        │                                             │
        │  1. Verify accessibility service            │
        │  2. Try skill-memory replay (no LLM)        │
        │  3. Loop:                                   │
        │     dump screen ──► LLM decides one JSON    │
        │     action ──► execute ──► repeat           │
        │     (+ step caps, repeat detection,         │
        │      RecoveryEngine for stuck states)       │
        │  4. Finalize: history + skills + TTS +      │
        │     notification + Telegram result          │
        └─────────────────────────────────────────────┘
```

**Observe** — the Kotlin `AgentAccessibilityService` flattens the visible UI
hierarchy (only interactive or labelled nodes) into a compact,
token-friendly format:

```
#<index> "<label>" [<widget class>] @(<centerX>,<centerY>) <flags>
```

The dump excludes PrivateAgent's own window so the agent never sees itself
(it detects its own UI only when deliberately told to).

**Reason** — `AiService` posts the dump + a system prompt + recent steps to
`/chat/completions` (60 s timeout) and parses **one** JSON action:

```json
{ "action": "click_text", "params": { "text": "Search" }, "reasoning": "...", "is_complete": false }
```

Actions: `click_text`, `click_at`, `type_text`, `press_enter`, `scroll`,
`swipe`, `press_back`, `press_home`, `open_app`, `done`. Tolerant parsing
accepts JSON embedded in markdown fences with surrounding prose; 3 parse
failures in a row abort the run.

**Act** — the action is executed through the `com.privateagent/accessibility`
MethodChannel (gesture dispatch, `ACTION_SET_TEXT`, global actions). Steps are
capped (`maxSteps`, default 15), and a 300 ms delay between steps keeps the
loop observable.

**Verify / Recover** — before each step the `RecoveryEngine` checks for
repetition: the same action 3× in a row, or an identical screen dump 3× in a
row → it rotates through *scroll down → wait 2 s → press back*. Pause / resume
/ cancel are supported everywhere (home task bar, Telegram `/cancel`,
overlay).

**Remember** — on `done`, the executed step sequence is stored as a skill.
Next time a goal matches (exact normalized match or Jaccard ≥ 0.75), the macro
replays directly — dump → resolve → tap — with **no LLM calls**. Failed
replays delete the skill.

**Telegram** — long-polls `getUpdates` (25 s) and maps commands:

| Command | Action |
|---|---|
| `/status` | Current task state + accessibility service status |
| `/screenshot` | Capture and send the current screen |
| `/cancel`, `/stop` | Cancel the running task |
| *(any text)* | Executed as an agent task (busy-guarded) |

**Overlay** — a separate Flutter engine (`overlayMain()`, `vm:entry-point`)
talks to the main app over `shareData` JSON:
`{type:'state', goal, state, step, maxSteps, messages}` downstream, and
`{type:'command', command: start|pause|resume|cancel}` upstream.

---

## 🧰 Tech stack

### Application layer

| Technology | Version / choice | Used for |
|---|---|---|
| **Flutter** | 3.47.5 (stable) | UI framework, Material 3 widgets |
| **Dart** | 3.13.4 (`sdk ^3.12.2`) | App logic, agent loop, services |
| **State management** | `ChangeNotifier` + listeners | Singletons (`TaskExecutor`, `SettingsService`, `TelegramService`) observed by screens — no external state package |
| `http` | ^1.4.0 | OpenAI-compatible chat completions + Telegram Bot API |
| `flutter_markdown_plus` | ^1.0.12 | Selectable markdown agent messages |
| `shared_preferences` | ^2.5.5 | Settings, task history, skill memory (JSON blobs) |
| `speech_to_text` / `flutter_tts` | ^7.4 / ^4.2 | Voice input and spoken results |
| `flutter_overlay_window` | ^0.5.0 | Floating bubble + panel (separate engine) |
| `flutter_local_notifications` | ^22.3 | Task-completion notifications |
| `permission_handler` | ^12.0.1 | Mic / notifications / contacts permission flow |
| `installed_apps` | ^2.1.1 | Installed-app index for `open_app` |
| `android_intent_plus` / `url_launcher` | ^6.1 / ^6.3 | Dialer, settings, app-info intents |
| `share_plus` | ^13.3 | Sharing task logs |
| `volume_controller` / `screen_brightness` / `shizuku_api` | — | System-control surface (present, partially unwired) |
| `flutter_contacts` / `intl` / `uuid` | — | Contacts permission, date formats, entity IDs |

### Native Android layer

| Technology | Version | Used for |
|---|---|---|
| **Kotlin** | 2.3.20 | `MainActivity` (channel handler), `AgentAccessibilityService` |
| **Android Gradle Plugin** | 9.0.1 (Gradle 9.1.0, Kotlin DSL) | Build |
| **Java / JVM target** | 17 | Source/target for app and plugins (aligned repo-wide) |
| **compileSdk / targetSdk** | 36 | Android 16 |
| **minSdk** | 26 | Android 8.0+ (foreground-service types, gesture APIs) |
| **AccessibilityService** | `typeAllMask`, interactive-window flags | Screen hierarchy dumps, `GestureDescription` taps/swipes, `ACTION_SET_TEXT`, global actions, `takeScreenshot` (API 30+) |
| **R8** | `minifyEnabled` + `shrinkResources` | Release code/resource shrinking |
| **Adaptive icons** | Vector drawable + color background | Black-circle launcher icon |

### MethodChannel bridge

`com.privateagent/accessibility` — Dart (`screen_automation_service.dart`) ⇄
Kotlin (`MainActivity.kt` → `AgentAccessibilityService.instance`):

| Method | Purpose |
|---|---|
| `isServiceEnabled` | Is the accessibility service connected |
| `dumpScreen` | Serialized visible UI tree (throws `SERVICE_OFF` when unbound) |
| `clickAt` / `swipe` / `scroll` | Gesture dispatch (native scroll action first, gesture fallback) |
| `typeText` / `pressKey` | `ACTION_SET_TEXT`, global actions (back/home/recents/lock/…) |
| `takeScreenshot` | PNG → base64 (API 30+) |
| `openAccessibilitySettings` / `openAppInfoSettings` | Settings intents (Android 13 restricted-settings workaround) |

### AI providers

| Provider | Preset base URL |
|---|---|
| DeepSeek (default) | `https://api.deepseek.com/v1` |
| OpenAI | `https://api.openai.com/v1` |
| OpenRouter | `https://openrouter.ai/api/v1` |
| NVIDIA NIM | `https://integrate.api.nvidia.com/v1` |
| Gemini (OpenAI-compat) | `https://generativelanguage.googleapis.com/v1beta/openai` |
| **Ollama (offline)** | `http://localhost:11434/v1` (cleartext allowed) |
| Custom | any OpenAI-compatible `/chat/completions` endpoint |

Settings: API key, model, temperature, max tokens, system-prompt toggle —
saved explicitly via **Save changes** in Settings (unsaved-edit guard is
regression-tested).

---

## 🏗️ Architecture

```
lib/
├── main.dart                    # Entry point, Telegram & overlay wiring, overlayMain()
├── app.dart                     # MaterialApp, theme mode, onboarding gate
├── models/                      # ChatMessage, Skill, ScreenNode, TaskStep, TaskHistoryEntry
├── screens/
│   ├── home/                    # Live transcript, input + voice, mode switcher, sessions drawer
│   ├── onboarding/              # 4-page first-run setup (welcome, a11y, AI key, permissions)
│   ├── sessions/                # Session detail (log → chat bubble replay)
│   ├── history/                 # Task history (expand, share, swipe-delete, clear)
│   └── settings/                # AI provider, agent loop, Telegram, appearance
├── services/
│   ├── task_executor.dart       # The observe → think → act loop (+ chat mode)
│   ├── ai_service.dart          # OpenAI-compatible client + system prompt
│   ├── screen_automation_service.dart  # Accessibility MethodChannel bridge
│   ├── skill_memory_service.dart      # Macro replay memory
│   ├── recovery_engine.dart     # Stuck-state recovery
│   ├── telegram_service.dart    # Bot long-poll remote control
│   ├── voice_service.dart       # STT / TTS
│   ├── system_control_service.dart    # Volume, brightness, intents, notifications
│   ├── app_launcher_service.dart      # Installed apps & launching
│   └── settings_service.dart    # Persisted settings (single source)
├── overlay/overlay_app.dart     # Floating bubble + panel (own engine/isolate)
├── theme/                       # app_colors, app_theme, app_spacing (60-30-10)
└── widgets/                     # ChatBubble, StatusChip, AppLogo

android/app/src/main/kotlin/com/privateagent/private_agent/
├── MainActivity.kt              # MethodChannel handler
└── AgentAccessibilityService.kt # Dump, gestures, screenshots
```

**Persistence keys** (all `SharedPreferences`): `ai_*` (provider, base URL,
key, model, sampling), `agent_*` (max steps, delay, skills on/off),
`telegram_*` (enable, token, chats, owner, offset), `ui_app_mode`,
`ui_theme_mode`, `onboarding_complete`, `voice_feedback`,
`task_history_v1` (≤ 50 JSON entries), `skill_memory_v1` (≤ 100 skills).

---

## 🚀 Getting started

### Prerequisites

- Flutter SDK (Dart `>= 3.12.2`) — built with Flutter 3.47.5
- Android SDK (compileSdk 36, minSdk 26 / Android 8.0+)
- NDK 28.2.13676358 (`sdkmanager "ndk;28.2.13676358"`)
- An API key for an OpenAI-compatible provider — **or** a local
  [Ollama](https://ollama.com) server for a 100% offline setup

### Install & run

```bash
git clone <this-repo>
cd PrivateAgent
flutter pub get
flutter run        # on a connected device / emulator
```

### Setup

1. Launch the app and complete onboarding.
2. In **Settings**, pick a provider (DeepSeek, OpenRouter, NVIDIA NIM, Ollama,
   or custom) and enter your API key — then **Save changes**.
3. Enable the **PrivateAgent Accessibility Service** in Android settings when
   prompted — required for screen automation.
4. (Optional) Configure the **Telegram bot** token for remote control.
5. Give it a goal — e.g. *"Open WhatsApp and send 'hi' to Mom"* — and watch it
   work.

---

## 📦 Building the APK

```bash
# Universal release APK (all ABIs) — R8 minified + resource-shrunk
flutter build apk --release
# → build/app/outputs/flutter-apk/app-release.apk

# Per-ABI APKs (recommended for distribution)
flutter build apk --release --split-per-abi
# → app-arm64-v8a-release.apk     (modern devices — ship this)
# → app-armeabi-v7a-release.apk   (older 32-bit devices)
# → app-x86_64-release.apk        (emulators)
```

Measured sizes on this project:

| APK | Size | vs universal |
|---|---|---|
| `app-release.apk` (universal) | **55,231,153 B (52.7 MB)** | — |
| `app-arm64-v8a-release.apk` | **19,405,903 B (18.5 MB)** | **−65.0 %** |
| `app-armeabi-v7a-release.apk` | **16,962,075 B (16.2 MB)** | −69.4 % |
| `app-x86_64-release.apk` | **20,955,211 B (20.0 MB)** | −62.2 % |

> ⚠️ Release builds are currently **signed with the debug keystore** (project
> default). Add your own signing config in `android/app/build.gradle.kts`
> before store distribution.

Prebuilt APKs for every release are attached to the repository's
**Releases** page.

---

## 🛠️ Development

```bash
flutter analyze    # Static analysis (0 errors; 8 documented pre-existing
                   # warnings in task_executor.dart)
flutter test       # Unit + widget tests (TaskStep parsing, skill matching,
                   # settings persistence, onboarding gate, Ollama regression)
flutter build apk --release
```

A mock LLM server for offline end-to-end development (scripts the
"open YouTube / search lofi" scenario by reading PrivateAgent's own screen
dumps):

```bash
python tool/mock_llm.py        # serves http://127.0.0.1:8787
```

Point the provider's Base URL at `http://127.0.0.1:8787/v1` in Settings.

Icon regeneration (PowerShell, no dependencies beyond .NET):

```powershell
powershell -ExecutionPolicy Bypass -File tool\generate_black_circle_icons.ps1
```

---

## 🔒 Privacy

- LLM requests go **only** to the base URL you configure.
- Skills, task history, and settings are stored locally (`SharedPreferences`).
- Telegram traffic goes only to `api.telegram.org` when you enable the bot.
- No analytics, no crash reporting, no tracking of any kind.
- API keys and bot tokens are stored unencrypted on-device (SharedPreferences)
  — treat the device as the trust boundary.

---

## ⚠️ Disclaimer

PrivateAgent controls your device's UI. Autonomy comes with risk — review what
it's doing, start with simple goals, and never give it credentials you can't
afford to expose. Intended for personal, lawful use on your own devices.

---

## 📄 License

All rights reserved. (Add a LICENSE file if you'd like to open-source this
project.)
