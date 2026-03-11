# MQ Navigation — Agent Notes

Raouf: 2026-03-11 (AEDT) — Sync root docs with mq_navigation state
- Scope: Update all root-level documentation to match the current Flutter app after auth/calendar/feed removal and project rename.
- Summary: Rewrote root README.md to reference `mq_navigation` directory, current features (Home, Map, Notifications, Settings), 83 tests, 3-tab nav, and completed roadmap phases. Updated CONTRIBUTING.md with correct directory path and relevant examples. Rewrote SECURITY.md to remove biometric/PKCE/MFA sections and add Edge Function proxying. Updated CHANGELOG.md with full sync entry.
- Files changed: `README.md`, `CONTRIBUTING.md`, `SECURITY.md`, `AGENT.md`, `CHANGELOG.md`.

Raouf: 2026-03-11 (AEDT) — Repository cleanup
- Scope: Repository cleanup after the temporary upstream history merge introduced the unrelated `MQ_Navigation` app tree.
- Summary: Removed `MQ_Navigation` from the root repository, preserved `mq_navigation` as the primary Flutter codebase, and updated the root README.
- Files changed: `README.md`, root git index (removed `MQ_Navigation/**`).

Raouf: 2026-03-10 (AEDT) — Persian translation
- Task: Create a complete Persian translation file for `MQ_OpenDay_NavApp_Roadmap_v2.docx`.
- Output: Added `MQ_OpenDay_NavApp_Roadmap_v2_fa.md` in the repository root.
