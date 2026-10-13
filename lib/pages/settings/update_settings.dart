import 'package:flutter/material.dart';

import 'package:kazumi/bean/settings/settings_detail_scaffold.dart';
import 'package:kazumi/bean/settings/settings_list.dart';
import 'package:kazumi/services/storage/storage.dart';
import 'package:kazumi/utils/tv_build.dart';

class UpdateSettingsPage extends StatefulWidget {
  const UpdateSettingsPage({super.key});

  @override
  State<UpdateSettingsPage> createState() => _UpdateSettingsPageState();
}

class _UpdateSettingsPageState extends State<UpdateSettingsPage> {
  bool _autoUpdate = GStorage.getSetting(SettingsKeys.autoUpdate);
  bool _pluginUpdate = GStorage.getSetting(
    SettingsKeys.checkPluginUpdateOnStartup,
  );

  @override
  Widget build(BuildContext context) => SettingsDetailScaffold(
    title: const Text('更新设置'),
    body: SettingsList(
      sections: [
        SettingsSection(
          title: const Text('启动时检查更新'),
          tiles: [
            if (TvBuild.enabled)
              SettingsTile(
                leading: Icons.tv_rounded,
                title: const Text('电视适配版更新'),
                description: const Text('请通过新版 APK 更新'),
              ),
            if (!TvBuild.enabled)
              SettingsTile.switchTile(
                leading: Icons.update_rounded,
                title: const Text('应用更新'),
                initialValue: _autoUpdate,
                onToggle: (value) {
                  setState(() => _autoUpdate = value ?? !_autoUpdate);
                  GStorage.putSetting(SettingsKeys.autoUpdate, _autoUpdate);
                },
              ),
            SettingsTile.switchTile(
              leading: Icons.extension_rounded,
              title: const Text('规则更新'),
              initialValue: _pluginUpdate,
              onToggle: (value) {
                setState(() => _pluginUpdate = value ?? !_pluginUpdate);
                GStorage.putSetting(
                  SettingsKeys.checkPluginUpdateOnStartup,
                  _pluginUpdate,
                );
              },
            ),
          ],
        ),
      ],
    ),
  );
}
