# 贡献指南

这是一个面向 Android TV 的个人适配分支。提交改动前，请先确认改动不会把上游 Kazumi 的通用行为误改成只适用于单台电视的行为；涉及电视焦点时，请同时说明实体遥控器的验证路径。

## 开发环境

- Flutter 3.47.7 及其内置 Dart SDK
- JDK 17
- Android SDK Platform 36
- Android NDK 28.2.13676358

首次准备依赖：

```sh
flutter pub get
```

提交前至少执行：

```sh
flutter analyze --no-pub --no-fatal-infos --fatal-warnings
```

涉及行为改动时，应补充或更新相应测试，并在实际 Android TV 遥控器上验证方向键、确定、返回和菜单键行为。当前项目的人工验证范围与已知限制见 `README_Q9K.md`。

## 构建和签名

没有签名变量时可以构建本地验证 APK，Gradle 使用 debug key。发布包需要由发布者在本地或受保护的 CI 环境中设置：

```text
KAZUMI_SIGNING_STORE=/absolute/path/to/release.p12
KAZUMI_SIGNING_PASSWORD=********
```

不要提交 PKCS12/JKS 文件、密码、`android/local.properties`、`.env`、构建缓存或电视日志。签名密钥一旦泄露，应立即停止使用并更换发布签名策略。

## Pull Request

请在描述中说明问题、改动范围、验证方式和已知限制。不要把与本分支无关的上游重构、生成文件或个人设备资料混入提交。
