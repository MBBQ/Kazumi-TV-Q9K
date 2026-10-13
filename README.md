# Kazumi TV Q9K

基于 [Predidit/Kazumi](https://github.com/Predidit/Kazumi) 的非官方 Android TV 适配版，用遥控器方向键移动焦点、确定键执行操作。主要在 TCL Q9K（Android 11、ARM32）上验证，也保留 ARM64 构建支持。

本项目与 TCL、Kazumi 原作者及其社区没有官方从属关系。TV 分支的问题请提交到[本仓库 Issues](https://github.com/MBBQ/Kazumi-TV-Q9K/issues)。

## 下载与安装

当前版本：**2.3.8-q9k.7**。

- [下载 q9k.7 安装包](https://github.com/MBBQ/Kazumi-TV-Q9K/releases/tag/v2.3.8-q9k.7)
- [所有发布版本](https://github.com/MBBQ/Kazumi-TV-Q9K/releases)
- [遥控器操作、构建说明和已知限制](README_Q9K.md)
- [版本记录](CHANGELOG_Q9K.md)

要求 Android 10 / API 29 及以上。APK 同时包含 ARM32（armeabi-v7a）和 ARM64（arm64-v8a）；TCL Q9K 的 32 位系统需要 ARM32。

将 APK 复制到 U 盘后，通过电视的正常安装入口安装。应用名为 `Kazumi TV Q9K`，包名为 `com.local.kazumi.q9k`，可与原版 Kazumi 并存。本仓库签名发布的 q9k.7 可覆盖 q9k.2 至 q9k.6 并保留数据。

q9k.7 为预发布版本：已完成静态检查和双架构构建，新增下载目录与更新源选择尚未完成 TCL Q9K 实体遥控验收。

## TV 适配

- 方向键移动金色焦点框，确定键执行操作，列表随焦点滚动。
- 设置、弹窗、播放菜单、选集和规则卡片支持方向导航及返回后的焦点恢复。
- 播放背景下，确定暂停/继续，左右快退/快进，上键或菜单键打开控件，下键打开选集。
- 规则名称处长按确定进入多选，返回退出多选；更多菜单提供规则排序等操作。
- 输入框按确定呼出电视输入法，关闭输入法后可用方向键离开。
- 保留鼠标点击支持，移除原生虚拟光标。

新安装默认使用条目和图片 ECH、`mediacodec_embed` 硬件渲染及低内存模式，超分关闭。默认关闭原版应用更新检查，保留规则更新。

## 验证范围与限制

q9k.3 的主要播放操作和短时音画、q9k.4 的长按与多选返回、q9k.6 的连续规则导航已在 TCL Q9K 上通过实体遥控确认。q9k.7 同步官方主分支至 [`4960f9c`](https://github.com/Predidit/Kazumi/commit/4960f9c04246eb52e1f36728f0f5c60ae6fa54dc)，保留上述适配，并合入自定义下载目录和更新下载源选择。

Anime4K 超分在目标电视上仍可能导致卡顿或卡死，本版没有修复该问题；`mediacodec_embed` 不支持超分。视频来源网络也可能造成缓冲。其他机型、全部页面和长期播放尚未完成全面验收。

仓库不包含上游私有服务密钥，因此默认关闭弹弹 Play 弹幕来源，也不提供需要该密钥的条目镜像。规则及第三方服务的可用性由对应服务决定。

## 开发与构建

环境：Flutter 3.47.7、JDK 17、Android SDK Platform 36、NDK 28.2.13676358。使用 `pubspec.lock` 锁定的依赖。

```sh
flutter pub get
flutter analyze --no-pub --no-fatal-infos --fatal-warnings
flutter build apk --release --target-platform android-arm,android-arm64 --dart-define=KAZUMI_TV=true
```

`KAZUMI_TV=true` 是启用电视适配的必要构建参数。生成文件为 `build/app/outputs/flutter-apk/app-release.apk`。

未设置签名变量时使用 Android debug key，仅用于开发验证；它不能覆盖本仓库的签名发布包。发布者通过 `KAZUMI_SIGNING_STORE` 和 `KAZUMI_SIGNING_PASSWORD` 提供自己的密钥。只有与已安装版本签名一致的 APK 才能覆盖安装。完整说明见 [README_Q9K.md](README_Q9K.md)。

GitHub Actions 自动执行静态检查和双架构构建，其构建产物使用开发签名。电视安装请使用 Releases 中的发布包。

## 贡献与反馈

欢迎提交 [Issue](https://github.com/MBBQ/Kazumi-TV-Q9K/issues) 或 Pull Request。请说明应用版本、电视型号、Android 版本、实体遥控的操作步骤和验证结果，并在分享日志或截图前移除个人信息。

- [贡献指南](CONTRIBUTING.md)
- [安全问题报告](SECURITY.md)
- 上游[规则仓库](https://github.com/Predidit/KazumiRules)和[规则开发文档](https://kazumi.app/docs/rules/develop-rules)

## 许可与致谢

主体代码沿用 **GPL-3.0**，见 [LICENSE](LICENSE)。上游代码与本分支修改保留其版权和许可证；第三方资源不能仅因仓库主体许可证而被视为可任意使用，见 [NOTICE.md](NOTICE.md) 和 [licenses](licenses/)。

感谢 [Kazumi 原作者和贡献者](https://github.com/Predidit/Kazumi/graphs/contributors)，以及 [media-kit](https://github.com/media-kit/media-kit)、[XpathSelector](https://github.com/simonkimi/xpath_selector)、[Bangumi](https://bangumi.tv/)、[弹弹play](https://www.dandanplay.com/)、[Anime4K](https://github.com/bloc97/Anime4K)、[Syncplay](https://github.com/Syncplay/syncplay)、[trace.moe](https://trace.moe)、[avbuild](https://github.com/wang-bin/avbuild) 和 [Hive](https://github.com/isar/hive)。

上游图标来自 [Yuquanaaa](https://www.pixiv.net/users/66219277) 的 [Pixiv 作品](https://www.pixiv.net/artworks/116666979)。上游声明其已取得作者授权，同时明确该图标并非自由使用资源；本分支不主张额外授权。内嵌 Mi Sans 字体由 [Xiaomi](https://hyperos.mi.com/font/zh/details/sc/) 开发并拥有版权。Android TV 图标及横幅使用本分支的矢量资源。
