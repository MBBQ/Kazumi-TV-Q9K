# Kazumi TV Q9K — 方向键焦点版

版本：`2.3.8-q9k.7+2030807`。状态截至 2026-10-13。基于 Predidit/Kazumi `main`，同步至提交 `4960f9c04246eb52e1f36728f0f5c60ae6fa54dc`；该主分支从 `2.3.8` 标签继续包含下载路径、Android 自定义下载目录、Flutter 3.47.7 和更新下载源选择等改动。

q9k.7 在 q9k.6 的基础上保留 TV 规则卡片焦点修复、设置菜单返回处理和 q9k.2 起的签名，可通过 U 盘覆盖安装；同时同步官方主分支的下载目录与更新源改动。指针点击空白区域仍保留。

新增的自定义下载目录和更新下载源选择只完成了本地构建验证，尚未在 TCL Q9K 上完成实体遥控验收；本次版本不能据此宣称所有新增页面都已适配电视。

q9k.3 已在电视上通过 ADB 方向键验证首页菜单返回、侧栏跨越、输入法关闭后离开输入框、设置开关/滑块/单选、来源、选集、播放跳转及独立播放/暂停键，用户确认主要遥控播放操作正常、画面流畅且声音同步。q9k.4 已由用户确认规则长按与多选返回；q9k.5 已实机通过更多菜单打开/移动/返回、规则排序并恢复、设置内返回与最终退出。q9k.6 已完成规则卡片焦点恢复的自动检查和实体遥控确认：编辑页返回、更多菜单返回、多选返回后仍可继续方向键移动。

## 安装要求

- Android 10 / API 29 或更新版本，包含 ARM32（armeabi-v7a）和 ARM64（arm64-v8a）。TCL Q9K 的 Android 系统需要 ARM32。
- 应用名 `Kazumi TV Q9K`，包名 `com.local.kazumi.q9k`，可与原版并存。
- q9k.7 与 q9k.2 至 q9k.6 使用同一项目签名，可覆盖这些版本并保留规则和观看记录。公开构建不包含项目私钥；使用自己的签名只能覆盖同一签名链的安装包。

## 遥控器操作

| 场景 | 按键与行为 |
| --- | --- |
| 页面、列表、设置、弹窗 | 方向键移动金色焦点框；确定键执行选中控件；列表随焦点滚动 |
| 返回 | 先关闭当前菜单、选集面板或弹窗，再返回上一页 |
| 输入框 | 确定呼出电视输入法；输入法关闭后，方向键可离开输入框 |
| 设置滑块 | 左右调整数值，上下离开滑块；搜索范围分别调整上下限 |
| 播放背景 | 确定暂停/继续；左右按设置的步长快退/快进；长按连续跳转 |
| 播放背景上键 / 菜单键 | 显示播放菜单并选中暂停按钮，再用方向键选择倍速、弹幕、画面比例等 |
| 播放背景下键 | 打开选集面板 |
| 播放菜单进度条 | 左右调整播放位置，确定暂停/继续 |
| 跳过按钮 | 短按确定跳过，长按确定约 0.65 秒修改跳过秒数 |
| 规则卡片 | 左右在名称与操作间移动；名称处长按确定约 0.65 秒或按菜单键进入多选；更多菜单提供上移、下移等操作 |
| 图片预览 | 可选择翻页、缩放、还原及移动图片按钮 |
| 独立媒体键 | 应用收到事件时支持播放、暂停、停止（暂停）、上一集、下一集、快进、快退 |
| 音量、静音、电源、主页 | 由电视系统处理；语音及厂商专用键取决于系统是否传递给应用 |

已移除原生虚拟光标处理和对应旧代码。USB 鼠标仍能使用原页面的点击操作。

## 默认配置与限制

新安装默认使用条目 ECH、图片 ECH、`mediacodec_embed`、硬件解码和低内存模式；默认超分关闭。这些设置基于本机此前的实测结果。

`mediacodec_embed` 不支持超分；切换其他渲染器并启用质量/效率超分，仍可能触发此前的卡顿或卡死，本版没有修复超分问题。来源网络中断仍可能导致缓冲，不能将焦点导航改造视为播放稳定性保证。

本版不含上游私有服务密钥，默认关闭弹弹 Play 弹幕来源，也不提供需要该密钥的条目镜像。规则仓库与其他来源受各自网络可用性影响。原版应用更新检查关闭，规则更新保留。

## 主要代码

- `lib/bean/tv/tv_navigation.dart`：统一焦点框、方向导航、滚动、初始焦点和输入框处理。
- `lib/bean/tv/tv_controls.dart`：长按确定、播放进度条、范围滑块。
- `lib/bean/widget/kazumi_menu.dart`：菜单初始焦点、返回关闭及原焦点恢复。
- `lib/pages/player/player_item.dart`、`player_item_panel.dart`：播放器按键与控件焦点。
- `lib/pages/video/video_side_panel.dart`：选集面板焦点范围和返回行为。
- `android/app/src/main/kotlin/com/example/kazumi/MainActivity.kt`：按键直接交给 Flutter / Android。

## 重新构建

工具：Flutter 3.47.7 及其内置 Dart SDK、JDK 17、Android SDK Platform 36、NDK 28.2.13676358。保留 `pubspec.lock` 中锁定的依赖。

不设置签名变量也可以构建本地验证 APK，Gradle 会使用标准 debug key。自行发布时，请准备 PKCS12 密钥库，别名 `kazumi-q9k`，并为当前构建进程设置以下变量。要覆盖已安装版本，必须使用与该版本相同的密钥；新建密钥不能覆盖本仓库的签名发布包。

```text
KAZUMI_SIGNING_STORE=密钥库绝对路径
KAZUMI_SIGNING_PASSWORD=密钥库密码
```

```sh
flutter pub get
flutter analyze --no-pub --no-fatal-infos --fatal-warnings
flutter build apk --release --target-platform android-arm,android-arm64 --dart-define=KAZUMI_TV=true
```

只构建 Android 时，可在构建进程设置 `FLUTTER_WINDOWS=false`、`FLUTTER_LINUX=false`、`FLUTTER_MACOS=false`。SDK 父路径中不要出现名为 `toolchains` 的目录，避免锁定版本 `ech_http` 错误推断 NDK 路径。保留 build 命令默认的 pub 步骤，避免残留开发依赖注册。

APK 输出为 `build/app/outputs/flutter-apk/app-release.apk`。源码仓库不包含私钥、缓存、本机路径或电视现场日志。静态检查和构建不能替代实体遥控器验收；当前已验证的范围和已知限制见本文件的默认配置说明。

## 上游与许可

上游：https://github.com/Predidit/Kazumi

沿用 GPL-3.0 许可，见 `LICENSE`，并保留第三方许可与资源声明。电视图标和横幅为 Android 矢量资源。本版是个人适配，未经 TCL 或 Kazumi 原作者认证。项目图标、字体、规则和第三方资源仍须遵守各自的版权与许可条件。
