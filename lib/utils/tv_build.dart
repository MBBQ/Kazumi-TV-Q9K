/// Settings for the separately signed television build.
class TvBuild {
  TvBuild._();

  static const enabled = bool.fromEnvironment('KAZUMI_TV');
  static const hasDanDanCredentials =
      String.fromEnvironment('DANDANAPI_APPID') != '' &&
      String.fromEnvironment('DANDANAPI_KEY') != '';
  static const hasBangumiMirrorCredentials =
      String.fromEnvironment('KAZUMI_APPID') != '' &&
      String.fromEnvironment('KAZUMI_KEY') != '';
}
