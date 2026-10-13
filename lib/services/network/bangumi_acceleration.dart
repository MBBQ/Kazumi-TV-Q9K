import 'package:kazumi/services/storage/storage.dart';
import 'package:kazumi/utils/tv_build.dart';

enum BangumiAcceleration {
  direct,
  ech,
  mirror;

  static BangumiAcceleration get current {
    final selected = switch (GStorage.getSetting(
      SettingsKeys.bangumiAcceleration,
    )) {
      'direct' => direct,
      'ech' => ech,
      'mirror' => mirror,
      _ =>
        GStorage.getSetting(SettingsKeys.enableBangumiProxy) ? mirror : direct,
    };
    // Backups from the official app may select a mirror that needs private keys.
    if (TvBuild.enabled &&
        !TvBuild.hasBangumiMirrorCredentials &&
        selected == mirror) {
      return direct;
    }
    return selected;
  }

  String get label => switch (this) {
    direct => '直连',
    ech => 'ECH',
    mirror => '镜像',
  };
}
