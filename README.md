# 潮邮局 · Tidepost

**这是 GPT-6.2 Astra 的模型能力测试产物，不是经过长期打磨的成熟正式产品。**  
**This is a GPT-6.2 Astra model-capability test artifact, not a finished or commercially polished product.**

本次公开的源码与桌面运行包来自一次模型测试交付（Drive 目录「潮邮局 Tidepost 2.0.0｜游戏与试玩」）。原包未提供测试提示词、推理参数、耗时或评测分数；本仓库也不编造这些信息。

The source and desktop builds published here come from a model-capability test delivery (Google Drive folder “潮邮局 Tidepost 2.0.0｜游戏与试玩”). The original package did not include the test prompt, sampling parameters, runtime, or scores; this repository does not invent them.

---

## 这是什么 / What this is

版本 **2.0.0**，一款可离线游玩的中文像素驾驶冒险，使用 **Godot 4.7.2**（OpenGL Compatibility）。标题画面的「启航」进入新主线（实时邮航），「海图解谜」进入独立的回合制玩法。完整玩法、操作与复现命令见原说明：[ORIGINAL-README.md](ORIGINAL-README.md)。第三方许可见 [`notices/`](notices/)。

Version **2.0.0** is an offline Chinese pixel sailing adventure built with **Godot 4.7.2** (OpenGL Compatibility). “启航” starts the real-time mail-run campaign; “海图解谜” is a separate turn-based chart-puzzle mode. Full rules, controls, and reproduction commands are preserved in [ORIGINAL-README.md](ORIGINAL-README.md). Third-party licenses are in [`notices/`](notices/).

## 运行包 / Runnable packages

桌面运行包在 [GitHub Releases](https://github.com/Thweki/tidepost/releases)（预发布 / pre-release）。不需要安装 Godot，也不需要联网或账号。

Desktop builds are on [GitHub Releases](https://github.com/Thweki/tidepost/releases) (marked as pre-release). Godot, a network connection, and an account are not required.

| 文件 / File | 平台 / Platform | 说明 / Notes |
| --- | --- | --- |
| `Tidepost-2.0.0-macOS-universal.zip` | macOS (Apple silicon 与 Intel) | 打开 `Tidepost.app`。本地签名，未做 Apple 公证。为正确解压中文可执行文件名，Release 中的 zip 仅重写了 UTF-8 语言位，**未改游戏内容**。 |
| `Tidepost-2.0.0-Windows-x86_64.zip` | Windows 64-bit | 解压后运行 `Tidepost.exe`。未使用商业代码签名证书。 |
| `Tidepost-2.0.0-Linux-x86_64.zip` | Linux x86-64 | 在桌面图形环境运行 `./Tidepost.x86_64`。若没有执行权限：`chmod +x Tidepost.x86_64`。 |
| `Tidepost-2.0.0-source.zip` | 源码快照 | 与本仓库首提内容对应的原始源码包。 |
| `Tidepost-60s.mp4` | 试玩视频 | 60 秒、960×672、30 fps。仓库 git 历史中不含该视频。 |

操作摘要：实时驾驶用 ↑↓ / W S 或鼠标掌舵，空格或左键抛索，Shift 或右键消耗潮能冲浪，Esc / P 暂停。海图解谜用方向键或 WASD，Z 撤回，R 重置，H 提示。详细说明见原 README。

macOS / Windows / Linux 包均为原测试交付中的桌面导出。macOS zip 的处理记录见 [PACKAGING.md](PACKAGING.md)。校验和见 Release 中的 `SHA256SUMS.txt`。

## Web 版 / Web build

计划中的独立路径是 <https://page.thweki.com:8443/tidepost/>（站点只在端口 **8443** 提供服务，不是 443）。**公开站点的隔离部署仍待协调，请先用 Release 里的 `Tidepost-2.0.0-web.zip` 或本地 HTTP 服务试玩。交互游玩尚未经浏览器实测，不能视为已经通过。**

The planned isolated path is <https://page.thweki.com:8443/tidepost/> (port **8443**, not 443). **Coordinated isolated publication is still pending. Use `Tidepost-2.0.0-web.zip` from the Release, or a local HTTP server, for now. Interactive play has not been browser-verified and must not be treated as passing.**

原包没有 Web 导出预设。Web 版本如已提供，是后来用与项目匹配的官方 Godot 4.7.2 导出模板另外打包的，不会改动上方桌面包的游戏内容。已提交源码快照保持原样；后续变更记在 [CHANGES.md](CHANGES.md)。

The original package has no Web export preset. Any Web build is a later packaging step using official Godot 4.7.2 export templates that match this project. It does not change the desktop game content above. The committed source snapshot stays as delivered; later changes are listed in [CHANGES.md](CHANGES.md).

## 从源码打开 / Opening the source

源码根目录含 `game/project.godot`，用 Godot 4.7.2 项目管理器导入。运行或重新导出桌面版无需 Python。开发工具在 `tools/`，说明见原 README。

```sh
godot --headless --path game --editor --import
godot --headless --path game -- --verify-pilot
godot --headless --path game -- --verify-voyage
godot --path game --audio-driver Dummy -- --verify-input
```

本仓库发布过程**没有**重跑上述校验，因此不把这些命令的结果当作本页的验证结论。

These verification commands were **not** re-run as part of this publication, so their results are not claimed here.

## 许可 / Licensing

- 引擎：Godot，MIT（`notices/Godot-LICENSE.txt`，版权说明见 `notices/Godot-COPYRIGHT.txt`）。
- 字体：Noto Sans SC 子集，SIL Open Font License 1.1（`notices/Noto-SIL-OFL.txt`；`game/media/font-license.txt` 为同一 OFL 族的 Adobe Source Han 版权声明）。
- **本项目的原创源码与资源没有附带项目级许可证。公开此仓库并不授予使用、修改或再分发这些原创内容的许可。** 第三方文件仍按其原许可条款。
- 船与建筑图集在原说明中写明使用了生成式辅助的透明部件；港镇远景与滩岸材质由程序生成。详见 [ORIGINAL-README.md](ORIGINAL-README.md)。

There is **no project-level license** for the original source and assets. Publishing this repository does not grant permission to use, modify, or redistribute that original content. Third-party files remain under their own licenses.

## 本仓库包含什么 / What is in this repo

- `game/`、`tools/`、`notices/`：原始源码快照
- `ORIGINAL-README.md`：原包 README 的逐字节副本
- `PACKAGING.md`、`CHANGES.md`：公开时的打包与后续变更记录
- 大视频与桌面 zip **不**进入 git 历史，只放在 Release
