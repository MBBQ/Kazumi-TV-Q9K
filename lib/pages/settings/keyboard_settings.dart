import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:kazumi/bean/dialog/dialog_helper.dart';
import 'package:kazumi/bean/settings/settings_detail_scaffold.dart';
import 'package:kazumi/bean/widget/content_section.dart';
import 'package:kazumi/services/storage/storage.dart';
import 'package:kazumi/utils/constants.dart';
import 'package:kazumi/utils/tv_build.dart';

class _ShortcutGroup {
  const _ShortcutGroup(this.title, this.functions);

  final String title;
  final List<String> functions;
}

const List<_ShortcutGroup> _shortcutGroups = [
  _ShortcutGroup(
      '播放控制', ['playorpause', 'forward', 'rewind', 'skip', 'next', 'prev']),
  _ShortcutGroup('音量', ['volumeup', 'volumedown', 'togglemute']),
  _ShortcutGroup(
      '画面与弹幕', ['fullscreen', 'exitfullscreen', 'screenshot', 'toggledanmaku']),
  _ShortcutGroup('倍速', ['speed1', 'speed2', 'speed3', 'speedup', 'speeddown']),
];

class KeyboardSettingsPage extends StatefulWidget {
  const KeyboardSettingsPage({super.key});

  @override
  State<KeyboardSettingsPage> createState() => _KeyboardSettingsPageState();
}

class _KeyboardSettingsPageState extends State<KeyboardSettingsPage> {
  String? listeningFunction;
  int? listeningIndex;

  // An empty original value marks a new, uncommitted binding.
  String originalValue = '';

  late Map<String, List<String>> shortcuts;

  final FocusNode focusNode = FocusNode();

  bool get isListening => listeningFunction != null && listeningIndex != null;

  @override
  void initState() {
    super.initState();
    // Repair persisted placeholders and keep at least one binding per action.
    shortcuts = {};
    for (final key in defaultShortcuts.keys) {
      final stored = GStorage.getStringListSettingByName(
        'shortcut_$key',
        defaultValue: defaultShortcuts[key]!.toList(),
      );
      final keys =
          stored.where((value) => value.isNotEmpty && value != '...').toList();
      var changed = keys.length != stored.length;
      if (keys.isEmpty) {
        keys.addAll(defaultShortcuts[key]!);
        changed = true;
      }
      if (changed) {
        GStorage.putStringListSettingByName('shortcut_$key', keys);
      }
      shortcuts[key] = keys;
    }
  }

  @override
  void dispose() {
    cancelListening();
    focusNode.dispose();
    super.dispose();
  }

  // Also called during dispose; do not setState here.
  void cancelListening() {
    if (!isListening) return;
    final func = listeningFunction!;
    final keys = shortcuts[func]!;
    final index = listeningIndex!;
    if (index < keys.length) {
      if (originalValue.isEmpty) {
        keys.removeAt(index);
      } else {
        keys[index] = originalValue;
      }
    }
    GStorage.putStringListSettingByName('shortcut_$func', keys);
    listeningFunction = null;
    listeningIndex = null;
    originalValue = '';
  }

  void beginListening(String func, int index) {
    originalValue = shortcuts[func]![index];
    shortcuts[func]![index] = '...';
    listeningFunction = func;
    listeningIndex = index;

    Future.delayed(const Duration(milliseconds: 50), () {
      if (!mounted) return;
      focusNode.requestFocus();
    });
  }

  bool handleShortcutInput(String rawKey) {
    if (!isListening || rawKey.isEmpty) return false;

    final func = listeningFunction!;
    final index = listeningIndex!;

    for (final entry in shortcuts.entries) {
      final otherFunc = entry.key;
      final otherKeys = entry.value;

      for (int i = 0; i < otherKeys.length; i++) {
        if (otherFunc == func && i == index) continue;
        if (otherKeys[i] == rawKey) {
          final name = shortcutsChineseName[otherFunc] ?? otherFunc;
          KazumiDialog.showToast(message: "按键已被【$name】占用，请重新输入");
          return true;
        }
      }
    }
    setState(() {
      shortcuts[func]![index] = rawKey;
      listeningFunction = null;
      listeningIndex = null;
      originalValue = '';
    });
    GStorage.putStringListSettingByName('shortcut_$func', shortcuts[func]!);

    return true;
  }

  // Persist a new binding only after recording or cancellation.
  void onAddKey(String func) {
    setState(() {
      cancelListening();
      final keys = shortcuts[func]!;
      keys.add('');
      beginListening(func, keys.length - 1);
    });
  }

  void onKeyCapTap(String func, int index) {
    if (listeningFunction == func && listeningIndex == index) {
      setState(cancelListening);
      return;
    }
    final keyValue = shortcuts[func]![index];
    setState(() {
      cancelListening();
      // Cancellation can shift indices; locate the binding again by value.
      final idx = shortcuts[func]!.indexOf(keyValue);
      if (idx >= 0) {
        beginListening(func, idx);
      }
    });
  }

  void onRemoveKey(String func, int index) {
    final keyValue = shortcuts[func]![index];
    setState(() {
      cancelListening();
      final keys = shortcuts[func]!;
      keys.remove(keyValue);
      GStorage.putStringListSettingByName('shortcut_$func', keys);
    });
  }

  void restoreDefaults() {
    setState(() {
      listeningFunction = null;
      listeningIndex = null;
      originalValue = '';
      for (final func in shortcuts.keys) {
        shortcuts[func] = defaultShortcuts[func]?.toList() ?? [];
        GStorage.putStringListSettingByName('shortcut_$func', shortcuts[func]!);
      }
    });
    KazumiDialog.showToast(message: '已恢复默认快捷键');
  }

  List<_ShortcutGroup> get displayGroups {
    final groups = <_ShortcutGroup>[];
    final covered = <String>{};
    for (final group in _shortcutGroups) {
      final funcs = group.functions.where(shortcuts.containsKey).toList();
      covered.addAll(funcs);
      if (funcs.isNotEmpty) {
        groups.add(_ShortcutGroup(group.title, funcs));
      }
    }
    final leftovers =
        shortcuts.keys.where((func) => !covered.contains(func)).toList();
    if (leftovers.isNotEmpty) {
      groups.add(_ShortcutGroup('其他', leftovers));
    }
    return groups;
  }

  @override
  Widget build(BuildContext context) {
    if (TvBuild.enabled) {
      return SettingsDetailScaffold(
        title: const Text('遥控器操作'),
        body: ListView(
          padding: const EdgeInsets.all(24),
          children: const [
            ListTile(title: Text('方向键'), subtitle: Text('移动金色选中框，列表自动滚动')),
            ListTile(title: Text('确定'), subtitle: Text('执行选中项；观看视频时暂停或继续')),
            ListTile(title: Text('返回'), subtitle: Text('先关闭菜单或选集面板，再返回上一页')),
            ListTile(title: Text('观看时左右键'), subtitle: Text('快退或快进，长按连续跳转；步长在播放设置中调整')),
            ListTile(title: Text('观看时上键 / 菜单键'), subtitle: Text('打开播放控制，方向键选择倍速、弹幕和其他选项')),
            ListTile(title: Text('观看时下键'), subtitle: Text('打开选集和播放线路面板')),
            ListTile(title: Text('长按确定'), subtitle: Text('规则卡片进入多选；跳过按钮可修改跳过秒数')),
            ListTile(title: Text('搜索输入'), subtitle: Text('确定进入输入法；返回关闭输入法后可用方向键离开输入框')),
            ListTile(title: Text('音量与系统按键'), subtitle: Text('音量、主页、电源和语音保持电视系统的原有操作')),
            ListTile(title: Text('专用播放按键'), subtitle: Text('支持播放、暂停、上一集和下一集；以遥控器实际提供的按键为准')),
          ],
        ),
      );
    }
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return SettingsDetailScaffold(
      title: const Text('操作设置'),
      actions: [
        IconButton(
          icon: const Icon(Icons.settings_backup_restore_rounded),
          tooltip: '恢复默认',
          onPressed: restoreDefaults,
        ),
      ],
      body: FocusScope(
        autofocus: true,
        child: Focus(
          focusNode: focusNode,
          autofocus: true,
          canRequestFocus: true,
          skipTraversal: true,
          descendantsAreFocusable: true,
          onKeyEvent: (node, event) {
            if (event is! KeyDownEvent) return KeyEventResult.ignored;
            if (!isListening) return KeyEventResult.ignored;

            final rawKey = event.logicalKey.keyLabel.isNotEmpty
                ? event.logicalKey.keyLabel
                : event.logicalKey.debugName ?? '';

            final handled = handleShortcutInput(rawKey);
            return handled ? KeyEventResult.handled : KeyEventResult.ignored;
          },
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1000),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      '点按按键标签，再按下新按键完成修改',
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ),
              for (final group in displayGroups)
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1000),
                    child: _buildGroupCard(group),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGroupCard(_ShortcutGroup group) => Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: ContentSection(
          title: group.title,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final func in group.functions) _buildShortcutRow(func),
            ],
          ),
        ),
      );

  Widget _buildShortcutRow(String func) {
    final textTheme = Theme.of(context).textTheme;
    final keys = shortcuts[func]!;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(shortcutsChineseName[func] ?? func, style: textTheme.bodyMedium),
          const SizedBox(width: 12),
          Expanded(
            child: Wrap(
              alignment: WrapAlignment.end,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 6,
              runSpacing: 6,
              children: [
                for (int i = 0; i < keys.length; i++)
                  _buildKeyCap(func, keys, i),
                _AddKeyButton(onTap: () => onAddKey(func)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeyCap(String func, List<String> keys, int i) {
    final listening = listeningFunction == func && listeningIndex == i;
    // Pending placeholders must not count toward the last-binding safeguard.
    final realCount = keys.where((value) => value != '...').length;
    return _KeyCap(
      label: listening ? '按任意键' : keyAliases[keys[i]] ?? keys[i],
      listening: listening,
      onTap: () => onKeyCapTap(func, i),
      onDelete:
          realCount >= 2 && !listening ? () => onRemoveKey(func, i) : null,
    );
  }
}

class _KeyCap extends StatelessWidget {
  const _KeyCap({
    required this.label,
    required this.listening,
    required this.onTap,
    this.onDelete,
  });

  final String label;
  final bool listening;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: listening
          ? colorScheme.primaryContainer
          : colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: textTheme.labelMedium?.copyWith(
                  color: listening
                      ? colorScheme.onPrimaryContainer
                      : colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (onDelete != null) ...[
                const SizedBox(width: 4),
                InkWell(
                  onTap: onDelete,
                  child: Icon(
                    Icons.close_rounded,
                    size: 14,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _AddKeyButton extends StatelessWidget {
  const _AddKeyButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
      side: BorderSide(color: colorScheme.outlineVariant),
    );

    return Tooltip(
      message: '添加按键',
      child: Material(
        color: Colors.transparent,
        shape: shape,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          customBorder: shape,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Icon(
              Icons.add_rounded,
              size: 16,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}
