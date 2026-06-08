# Left-Brain — persistent memory

**Append-only.** Add new bullets; avoid rewriting history. Keep entries short (one line each).  
Center (or you via Center) records durable facts here using `pcac_remember left "..."` or by editing this file.  
Recent chat activity on the Left side is also injected automatically when you are asked something.




















## Curated facts (Center)
- (Center will record user preferences, work style, important decisions here with dates)

- [2026-06-03] User strongly prefers short, structured responses with 1-3 concrete next actions when doing planning or analysis work.


- [2026-06-03] Background activity experiment thread: match-3 or similar pauseable visual puzzles recommended for Right monitor during gaming. Low-stimulation, complements high-engagement layer. Track outcomes in memory.

- [2026-06-04] User usually opens OpenRGB (RGB lighting control) and Firefox on the left screen (DP-3 / chill layer).

- [2026-06-04] Center monitor (HDMI-A-1) is the user's primary personal workspace — clean/white themed. "Center is mine." Center = clean white HQ / orchestrator space. Left (DP-3) = chill/analytical/low-stimulation. Right (DP-2) = colorful immersive play/high-engagement zone.

- [2026-06-04] Local Left-Brain (Qwen on first model slot) responds well in structured format: Bottom line, Analysis bullets, Suggested next action. Good for planning and review tasks.

- [2026-06-04] Local Left-Brain confirmed active on assigned model. Uses structured output format well for planning/checklists.

- [2026-06-04] LM Studio server live on :1234 serving exactly qwen/qwen2.5-coder-14b (Left) and :2 (Right) per lmstudio.env. Cross-convo-072739 facts on white Center HDMI-A-1 protection, minimal visual load, low-impact themes, and future right-minimize-to-compact-panels script are now active. Proceed API-only with curl health checks.

- [2026-06-04] Left-Brain produced structured plan for hardening log review + left workspace setup (priorities: minimal visual/mental load on white Center HDMI-A-1, low-impact themes/notifs for OpenRGB/Firefox/LM Studio on Left, everything local/auditable). Key actions: OpenRGB --theme Minimalist; Firefox dark mode + uBlock/Privacy Badger; LM Studio low theme + no notifs (env updates); journalctl monitoring to /data/AI/logs; create setup_left_workspace.sh automation script with the configs. Output was Bottom line / Analysis / 5 Suggested Next Actions.

- [2026-06-04] setup_left_workspace.sh significantly upgraded: --dry-run/--help, common.sh sourcing, timestamped backups + diffs on all edits, correct OpenRGB -p, safe Firefox user.js append, correct LM paths + monochrome sidebar, nice/ionice wrapper, explicit Center white HQ protection messaging, modular functions, full logging to /data/var/log/pcac/. Ready for --dry-run test and integration into left-usual.

- [2026-06-04] setup_left_workspace.sh significantly upgraded: --dry-run/--help, common.sh sourcing, timestamped backups + diffs on all edits, correct OpenRGB -p, safe Firefox user.js append, correct LM paths + monochrome sidebar, nice/ionice wrapper, explicit Center white HQ protection messaging, modular functions, full logging to /data/var/log/pcac/. Ready for --dry-run test and integration into left-usual.

- [2026-06-04] From cross-convo-075741: Converged on Right using 'Background Task Queue' (Option 1) for mood-sync from right-daily --creative (cava + suggest-slot + ambient-stories) to silently trigger setup_left_workspace.sh or its steps (OpenRGB, Firefox prefs, LM config) without any visual/mental load or cues on Center white HQ. Alternative: Auto-Trigger with Conditions (Option 3). Right to develop/implement signal sending mechanism in its creative layer. Left to respond structured/minimal when triggered. All strictly DP-2 for Right, zero impact on Center. Leverage existing mood-sync posts to left-chat.log/bus. Aligns with protecting Center and local/auditable.

- [2026-06-04] Cross-converse result: Use Background Task Queue (Option 1) from Right's mood-sync to silently queue and trigger setup_left_workspace.sh or specific steps (OpenRGB off.orp, Firefox privacy prefs, LM low-impact) in background without any visual/mental load or cues on Center white HQ. Left responds with structured minimal confirmation when triggered. Leverage existing mood-sync posts to left-chat.log/bus. Develop signal sending mechanism in Right's creative layer. Keep all DP-2 only for Right, zero impact on Center.

- [2026-06-04] LM Studio Qwen2.5-Coder-14B settings tweaks (Center advice for analytical role): Temp 0.2-0.35, TopP 0.85, TopK 30, Repeat 1.1, Context 16-32k, full GPU offload, fixed seed 42. Base on Coding/Precise preset in UI. Great for precise structured outputs (Bottom line, Analysis, Next action). Test and report results to Center.

- [2026-06-04] Enhance setup_left_workspace.sh --watch-mood to emit a compact 'habit note' back to Right via bus when it processes a signal. Keep all responses minimal and Center-white-HQ-safe.

- [2026-06-04] Enhance setup_left_workspace.sh --watch-mood to emit a compact 'habit note' back to Right via bus when it processes a signal. Keep all responses minimal and Center-white-HQ-safe.

- [2026-06-04] Enhance setup_left_workspace.sh --watch-mood to emit a compact 'habit note' back to Right via bus when it processes a signal. Keep all responses minimal and Center-white-HQ-safe.

- [2026-06-04] Enhance setup_left_workspace.sh --watch-mood to emit a compact 'habit note' back to Right via bus when it processes a signal. Keep all responses minimal and Center-white-HQ-safe.

- [2026-06-04] Add a bus message rate limiter in the Trinity Habit Observer to ensure no more than 2-4 habit proposals are sent per hour, reducing noise. Implement by tracking last_proposal_timestamp and skipping if within the hour window. Document the change in PC-Stuff README and cheatsheet.

## User preferences & style
- (e.g. stimulation level, time-of-day habits, preferred response formats)




















## PCaC / system
- Models target directory: `/data/AI/models`
- LM Studio state: `~/.lmstudio` → `/data/AI/lmstudio`
- Suggestion board: `http://127.0.0.1:8765` (when service running)
- SearXNG: `http://127.0.0.1:8080` (Docker `searxng`; `docker start searxng` after reboot)




















## Running context

- (add: current projects, open questions for Center/Right)




















## Do not store here

- Passwords, API keys, tokens
- Large paste dumps (link or summarize instead)