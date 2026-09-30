# Feature Matrix — PrivateAgent (Regression Checklist)

Legend: **E** = Existing (must keep working), **W** = Wired to UI/loop, **D** = Implemented but unwired (dead), status verified by code analysis on branch `ui-redesign-60-30-10`.

| Feature | Status | Entry point | Relevant files | Dependencies | Regression risks |
|---|---|---|---|---|---|
| Onboarding / first-run gate | E, W | `app.dart` home gate → `OnboardingScreen(onFinished)`; `_finish` sets `onboarding_complete` | `app.dart`, `onboarding_screen.dart`, `settings_service.dart` | `permission_handler`, `flutter_overlay_window`, a11y settings intents | Page indices 0–3 hardcoded; tests assert `Meet PrivateAgent` + `Continue`; provider chips write-through immediately |
| LLM configuration (OpenAI-compatible) | E, W | Onboarding p.3 + Settings → AI Provider card (Base URL/key/model, explicit Save, system-prompt toggle, temp, max-tokens) | `settings_service.dart` (`ai_*`), `ai_service.dart`, `settings_screen.dart`, `onboarding_screen.dart` | `http` only; browser-spoofed UA; OpenRouter headers | `setProvider` overwrites URL+model; `_lastSyncedProvider` guard (regression-tested); local/ollama host skips key check; cleartext allowed for Ollama |
| OpenAI-compatible providers (DeepSeek/OpenRouter/NVIDIA/Gemini/OpenAI/custom) | E, W | provider `ChoiceChip` row in Settings/Onboarding | `settings_service.providers`, `ai_service.dart` | — | preset table must stay in sync with chip labels (`Ollama (local)` string pinned by test) |
| Ollama (fully local) | E, W | provider = `ollama` | same | `usesCleartextTraffic=true` | default model `llama3.2` (test-pinned) |
| Accessibility service | E, W | `ScreenAutomationService.isServiceEnabled()` gates tasks; onboarding p.2; home warning banner | `screen_automation_service.dart`, `MainActivity.kt`, `AgentAccessibilityService.kt`, manifest, `accessibility_service_config.xml` | `BIND_ACCESSIBILITY_SERVICE` channel `com.privateagent/accessibility` | channel name hardcoded both sides; `dumpScreen` throws `SERVICE_OFF`; own-package window exclusion |
| Screen automation (dump/tap/type/swipe/scroll/back/home/screenshot) | E, W | via `TaskExecutor._performAction`, `clickText`; Telegram `/screenshot` | `screen_automation_service.dart`, `AgentAccessibilityService.kt` | GestureDescription (80 ms tap, 50–5000 ms swipe), `ACTION_SET_TEXT`, global actions, API 30+ screenshot | native scroll→gesture fallback; set-not-append text semantics; LLM dump caps (60/150 nodes) |
| Task execution loop (step caps, repeat detection, pause/resume/cancel) | E, W | Home submit (Genie), task bar controls, overlay commands, Telegram `/cancel` | `task_executor.dart` (618 L) | `SettingsService.maxSteps` (3–40, dflt 15), `stepDelayMs`, 60 s LLM timeout, 3 JSON failures abort | pause = 300 ms busy-wait; cancel unblocks paused; chat mode shares executor; `_finalize` writes history + TTS + notification + Telegram |
| Skill memory (macro replay) | E, W | auto in `executeTask` when `agent_skills_enabled` (Settings → Agent card) | `skill_memory_service.dart`, `models/skill.dart` | SharedPreferences `skill_memory_v1`, `uuid` | Jaccard ≥ 0.75 / exact match; failed replay deletes skill; ≤100 skills |
| Recovery engine | E, W | inside `_aiLoop` after each action | `recovery_engine.dart` | — | triggers on 3 identical actions OR 3 identical dumps; rotates scroll→wait→back |
| Telegram remote control | E, W | `main._wireTelegram`; Settings toggle/token/chats | `telegram_service.dart`, `main.dart` | `http` long-poll 25 s | commands `/status` `/screenshot` `/cancel`/`/stop` + goal dispatch; owner pairing (first sender); allowlist; `telegram_offset` persisted |
| Voice (STT/TTS) | E, W | Home mic (`_toggleListening`); overlay mic (own STT instance); TTS on task finish when `voice_feedback` | `voice_service.dart`, `home_screen.dart`, `overlay_app.dart`, `task_executor.dart` | `speech_to_text`, `flutter_tts`, RECORD_AUDIO | SnackBar `'Speech recognition unavailable…'` (home only); overlay silent; separate isolate → separate STT |
| Overlay floating window | E, W | Home AppBar bubble toggle; onboarding permission tile | `overlay_app.dart`, `main.dart` (`overlayMain`), `task_executor._broadcastOverlay`, manifest `OverlayService` | `flutter_overlay_window`, SYSTEM_ALERT_WINDOW, FGS specialUse | `vm:entry-point` top-level fn; JSON `state`/`command` protocol field names; sizes 120×120 show vs 110×110 bubble vs 340×520 panel; visual restyle must not touch protocol |
| System controls | **D** (notify only) | only `SystemControlService.notify()` from `_finalize` | `system_control_service.dart` | `volume_controller`, `screen_brightness`, `android_intent_plus`, `shizuku_api`, manifest perms | volume/brightness/alarm/dial/contacts/Shizuku have **zero callers** and no LLM actions — do not build UI on them; keep code (no functionality removal) |
| App launching | E, W (agent action `open_app`) | `TaskExecutor` action | `app_launcher_service.dart` | `installed_apps`, QUERY_ALL_PACKAGES | fuzzy matcher; process cache |
| Contacts | **D** (perm only) | onboarding permission tile requests OS perm | `system_control_service.dart` | `flutter_contacts` | search/dial never called |
| Task history | E, W | AppBar History; drawer sessions; share log | `task_history_screen.dart`, `session_detail_screen.dart`, `task_executor` (`task_history_v1`, ≤50) | `share_plus`, `intl` | **session replay regex** `[role #step] text` — do not change `_log()` format; dismiss-delete + clear-all dialog flows |
| Settings persistence | E, W | SettingsScreen + Onboarding; read by all services | `settings_service.dart` | SharedPreferences only | every setter `notifyListeners`; Save is explicit (`_aiDirty`) |
| Genie / Chat mode switch | E, W | Home `SegmentedButton` (only entry point) | `home_screen.dart`, `AppMode` | — | disabled while busy; persisted `ui_app_mode`; mock_llm keys off `'Describe a task'` hint |
| Skill persistence & history persistence | E | automatic | `skill_memory_v1`, `task_history_v1` JSON | — | JSON schema (`TaskStep`/`Skill`/`TaskHistoryEntry` fromJson) |
| Notifications (task finished) | E, W | `_finalize` → `notify()` | `flutter_local_notifications` channel `agent_status` | POST_NOTIFICATIONS | high importance channel |
| Voice feedback (TTS on completion) | E, W | Settings → Agent card | `voice_feedback` flag | — | default off |
| Theme mode (system/light/dark) | E, W | Settings → Appearance `SegmentedButton` | `ui_theme_mode` | — | test persists `ThemeMode.dark` |
| Shizuku privileged shell | **D** | none | `runShizukuCommand` | `shizuku_api`, manifest provider | unwired |

## UI strings load-bearing for tests / E2E

| String | Contract |
|---|---|
| `Meet PrivateAgent`, `Continue` | `test/widget_test.dart` onboarding boot |
| `Ollama (local)`, `llama3.2`, `Model`, `Send system prompt`, `Save changes` | `test/widget_test.dart` settings regression |
| `Describe a task…` hint, `Pause` / `Cancel task` tooltips, `privateagent` label | `tool/mock_llm.py` offline E2E screen-dump heuristics |
| Log line format `[role #step] text` | `SessionDetailScreen` replay regex |

## Manual runtime verification checklist (post-redesign)

- [ ] App launches, splash OK, first-run → onboarding, onboarding finishes → home
- [ ] Accessibility banner/dot reflects service state; opens settings
- [ ] Goal submit runs agent loop (with service ON): dump → LLM → act; step bar, pause/resume/cancel
- [ ] Chat mode sends message and gets reply
- [ ] Voice mic fills input (or shows permission SnackBar)
- [ ] Overlay permission → bubble appears → expand → start/pause/resume/cancel commands work
- [ ] Skill memory replay on repeated goal (no LLM call)
- [ ] Telegram: enable bot → `/status` `/screenshot` goal → result pushed
- [ ] History: entries appear, expand, share, swipe-delete, clear-all dialog
- [ ] Session detail replay renders bubbles
- [ ] Settings: provider switch + Save persists across restart; theme mode switches
- [ ] Notifications fire on task completion (permission granted)
- [ ] Release APK installs and performs smoke run
