import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum DockItemKey {
  home(
    key: 'home',
    label: '首頁',
    icon: Icons.home_rounded,
    isRemovable: false,
    description: '探索熱門內容、繼續觀看與目錄推薦。',
  ),
  manga(
    key: 'manga',
    label: '漫畫',
    icon: Icons.auto_stories_rounded,
    isRemovable: true,
    description: '瀏覽、搜尋與閱讀漫畫及條漫。',
  ),
  books(
    key: 'books',
    label: '書籍',
    icon: Icons.menu_book_rounded,
    isRemovable: true,
    description: '使用自訂主題閱讀 EPUB 與 PDF 電子書。',
  ),
  audiobooks(
    key: 'audiobooks',
    label: '有聲書',
    icon: Icons.headphones_rounded,
    isRemovable: true,
    description: '收聽有聲書，並支援章節書籤。',
  ),
  music(
    key: 'music',
    label: '音樂',
    icon: Icons.music_note_rounded,
    isRemovable: true,
    description: '高解析度無損串流、視覺化效果與工作室播放。',
  ),
  anime(
    key: 'anime',
    label: '動漫',
    icon: Icons.animation_rounded,
    isRemovable: true,
    description: '探索熱門季度動畫、阿拉伯／英文字幕與各集內容。',
  ),
  liveTv(
    key: 'livetv',
    label: 'Live TV',
    icon: Icons.live_tv_rounded,
    isRemovable: true,
    description: '觀看全球直播電視頻道與體育串流。',
  ),
  addons(
    key: 'addons',
    label: '附加元件',
    icon: Icons.extension_rounded,
    isRemovable: true,
    description: '管理已安裝的 Stremio 附加元件、目錄與搜尋器。',
  ),
  downloads(
    key: 'downloads',
    label: '下載',
    icon: Icons.download_rounded,
    isRemovable: true,
    description: '查看目前的 Torrent 與直接媒體下載工作。',
  ),
  myList(
    key: 'mylist',
    label: '我的清單',
    icon: Icons.favorite_rounded,
    isRemovable: true,
    description: '查看已儲存的書籤、待看清單與最愛。',
  ),
  settings(
    key: 'settings',
    label: '設定',
    icon: Icons.settings_rounded,
    isRemovable: false,
    description: 'App 偏好設定、帳號、外觀與播放器選項。',
  ),
  search(
    key: 'search',
    label: '搜尋',
    icon: Icons.search_rounded,
    isRemovable: true,
    description: '搜尋所有目錄 metadata 與附加元件。',
  );

  final String key;
  final String label;
  final IconData icon;
  final bool isRemovable;
  final String description;

  const DockItemKey({
    required this.key,
    required this.label,
    required this.icon,
    required this.isRemovable,
    required this.description,
  });
}

abstract final class DockSettings {
  static const String _prefPrefix = 'dock_item_enabled_';

  /// Reactive notifier containing the map of enabled dock item keys.
  static final ValueNotifier<Map<String, bool>> enabledNotifier =
      ValueNotifier<Map<String, bool>>({
    for (final item in DockItemKey.values) item.key: true,
  });

  /// Initialize and load saved state from SharedPreferences.
  static Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final map = <String, bool>{};

    for (final item in DockItemKey.values) {
      if (!item.isRemovable) {
        // Home and Settings are strictly non-removable
        map[item.key] = true;
      } else {
        map[item.key] = prefs.getBool('$_prefPrefix${item.key}') ?? true;
      }
    }

    enabledNotifier.value = map;
  }

  /// Check whether a specific item key is currently enabled.
  static bool isEnabled(String key) {
    if (key == 'home' || key == 'settings') return true;
    return enabledNotifier.value[key] ?? true;
  }

  /// Toggle or update the enabled status of an item.
  static Future<void> setItemEnabled(String key, bool enabled) async {
    // Prevent disabling non-removable essential items
    if (key == 'home' || key == 'settings') return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_prefPrefix$key', enabled);

    final updated = Map<String, bool>.from(enabledNotifier.value);
    updated[key] = enabled;
    enabledNotifier.value = updated;
  }

  /// Reset all dock item toggles to enabled default.
  static Future<void> resetToDefaults() async {
    final prefs = await SharedPreferences.getInstance();
    for (final item in DockItemKey.values) {
      if (item.isRemovable) {
        await prefs.remove('$_prefPrefix${item.key}');
      }
    }

    enabledNotifier.value = {
      for (final item in DockItemKey.values) item.key: true,
    };
  }
}
