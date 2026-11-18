# Changes / 变更记录

## 2026-11-18 — Initial public snapshot

- Source copied from `Tidepost-2.0.0-source.zip` (SHA-256 `bf548ac266a9e1bbde2a2d6f7c7540d38fb2f7645d0e323ee74918f45503952c`).
- Added publication files only: `README.md`, `ORIGINAL-README.md` (byte-for-byte copy of the original README), `PACKAGING.md`, `CHANGES.md`, `.gitignore`.
- Game source under `game/` and `tools/` was not modified for this commit.
- macOS Release zip: UTF-8 language bit only, see `PACKAGING.md`. No game behavior change.
- Desktop Linux / Windows zips and the 60-second video were not added to git history; they are Release assets.
- Web export, if any, will be recorded in a later entry. The original snapshot has no Web preset.

- 源码复制自上述 source zip。
- 本提交只增加公开说明文件；未改 `game/` 与 `tools/`。
- macOS Release zip 仅处理 UTF-8 语言位，见 `PACKAGING.md`。
- 桌面包与视频不进入 git 历史。
- 原快照没有 Web 导出预设；如有 Web 版，将另开记录。

## 2026-11-18 — Web export package (not a source change)

- Exported a browser build in a throwaway working copy with official Godot **4.7.2.stable** templates, `variant/thread_support=false`, and `ensureCrossOriginIsolationHeaders=false`, so the site would not need new COOP/COEP headers.
- The committed `game/export_presets.cfg` and other game source were **not** modified. The temporary Web preset was not merged.
- Release asset: `Tidepost-2.0.0-web.zip` (SHA-256 `a83893d4990b58d3e1350ef01a15f2fc9cac69f81ffb3b70d02d359c1c62b715`). File list and hashes: `WEB-SHA256SUMS.txt`.
- Public path `https://page.thweki.com:8443/tidepost/` is the intended isolated location, but coordinated isolated deployment is still pending. Interactive play has not been browser-verified.

- 在一次性工作副本中用官方 Godot 4.7.2 无线程模板导出了 Web 包；已提交的源码与 `export_presets.cfg` 未改。
- 公开路径待协调隔离部署后再上线。交互游玩尚未经浏览器实测。

## 2026-11-18 — Short Web smoke test (docs only)

- Added [TESTING.md](TESTING.md) and later verification screenshots in `docs/browser-smoke-2026-11-18/`. No game source was changed.
- Smoke test was on the publishing agent’s computer at `http://127.0.0.1:8870/tidepost/`, not the user’s Mac, and not a verification of the public site URL.
- Observed: title and delivery scene OK; slight movement after ↑; after Space, 信袋 00/07 → 01/07, 连投 ×1; screenshot HUD shows 000100 分 (the written note said “分数10”); refresh returned to the title with no「继续」, still 已靠港 00/72 · 章节 00/12 (observation only — port not finished, not reported as a save bug). Console: no errors. Audio and full play/QA were not tested. This is not a pass.

- 仅增加测试文档与事后截图，未改游戏源码。短烟测不是通过结论。
