# Packaging notes / 打包说明

This file records publication packaging only. It does not change the game's source or runtime behavior.

本文件只记录公开时的打包处理，不改变游戏源码或运行时行为。

## macOS zip UTF-8 language flag

The Drive file `Tidepost-2.0.0-macOS-universal.zip` stored the executable and `.pck` names as UTF-8 bytes (`潮邮局 · Tidepost`) but did not set the ZIP language encoding bit (general-purpose bit 11). Some unzip tools therefore show mojibake and may fail to launch the app, because `Info.plist` still expects the UTF-8 name.

Drive 中的 `Tidepost-2.0.0-macOS-universal.zip` 已用 UTF-8 字节保存可执行文件和 `.pck` 名称（`潮邮局 · Tidepost`），但未设置 ZIP 语言编码位（通用标志位 11）。部分解压工具会显示乱码，并可能无法启动，因为 `Info.plist` 仍要求该 UTF-8 名称。

The Release asset of the same name was rewritten with that UTF-8 flag set. Every zip member's **decompressed** SHA-256 is unchanged. The archive-level SHA-256 and file size changed because the container was rewritten.

Release 中的同名文件只补上了该 UTF-8 标志。各成员解压后的 SHA-256 **未变**。由于重写了 zip 容器，整包 SHA-256 和文件大小会不同。

- Original Drive zip SHA-256: `54f9c1d19246d38d566234bacd6421c6876ef194078c7ed81e14a7eb5dceb4d9` (68,888,615 bytes)
- Release zip SHA-256: `2debd86601811f2bba976bdfb360eb3827b8a09da40f028ad519ab3651f63123` (68,714,402 bytes)
- Unchanged member examples: `Tidepost.app/Contents/MacOS/潮邮局 · Tidepost` SHA-256 starts with `f202ae8420a0`; `…/潮邮局 · Tidepost.pck` starts with `8a573a194d69`; `Info.plist` starts with `d3bb761ad397`.

Linux and Windows zips were uploaded unchanged from the Drive originals. The source zip is the original snapshot; this git repository adds publication docs (README, PACKAGING, CHANGES, .gitignore) on top of that snapshot.

Linux 与 Windows 的 zip 按 Drive 原件上传。源码 zip 是原始快照；本 git 仓库只在快照之上增加了公开说明（README、PACKAGING、CHANGES、.gitignore）。
