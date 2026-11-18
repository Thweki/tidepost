# Testing / 测试记录

This is a record of what was actually tried after publication. It is **not** a pass, a full QA report, or a claim that the game is complete.

这是公开发布之后实际做过的测试记录，**不是**测试通过结论，也不是完整 QA。

## 2026-11-18 short Web smoke test / 短烟测

- **When:** 2026-11-18, about 09:11–09:14 America/New_York.
- **Where:** Desktop browser on the publishing agent’s computer, `http://127.0.0.1:8870/tidepost/`. **Not** the user’s Mac, and **not** a test of the public `page.thweki.com` URL.
- **Build:** The official Godot 4.7.2 no-threads Web export published as `Tidepost-2.0.0-web.zip`.
- **Screenshots:** [docs/browser-smoke-2026-11-18/](docs/browser-smoke-2026-11-18/) (later verification shots; not original delivery art).

### Observed / 已观察到

- Title screen rendered normally (潮邮局 / TIDEPOST, 航路手册,「启航」).
- Starting「启航」reached the delivery scene: PORT 01 晨班栈桥, 信袋 00/07, 连投 ×0, 000000 分.
- After ↑, the boat moved slightly (screenshot: 001% 靠港).
- After Space, 信袋 went from 00/07 to 01/07, 连投 ×1. The written smoke-test note said “分数10”; the corresponding screenshot HUD shows **000100 分**. This page records both, and does not treat either figure as a verified scoring rule or as a defect report.
- After a browser refresh, the title screen returned. There was no「继续」control. The title still showed 已靠港 00/72 · 章节 00/12. The port was **not** completed in this test, so this is observation only and is **not** a save-system bug report.
- The tester reported **no errors** in the browser console.

### Not tested / 未测

- Audio / 音频
- A full port, the remaining 71 ports, or chapters 1–12 / 完整靠港、其余航段与章节
- Chart-puzzle mode「海图解谜」
- Desktop macOS / Windows / Linux packages
- The public site URL
- Long play, saves after actually docking, settings, accessibility, mobile, or other browsers
- The in-repo `verify-pilot` / `verify-voyage` / `verify-input` commands were still not re-run for this publication

**Not a pass. Not a complete QA.**
