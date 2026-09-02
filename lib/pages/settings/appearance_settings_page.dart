import 'package:flutter/material.dart';
import '../../services/theme/app_theme_service.dart';
import '../../services/audiobook/audiobook_settings.dart';
import '../../services/theme/custom_background_service.dart';
import '../../services/theme/dock_settings.dart';
import '../../services/theme/glass_settings.dart';
import '../../services/iptv/iptv_settings.dart';
import '../../services/manga/manga_settings.dart';
import '../../services/music/music_settings.dart';
import 'appearance/audiobook_settings_page.dart';
import 'appearance/custom_background_settings_page.dart';
import 'appearance/dock_settings_page.dart';
import 'appearance/home_ui_settings_page.dart';
import 'appearance/liquid_glass_settings_page.dart';
import 'appearance/live_tv_settings_page.dart';
import 'appearance/manga_settings_page.dart';
import 'appearance/music_settings_page.dart';

class AppearanceSettingsPage extends StatefulWidget {
  const AppearanceSettingsPage({super.key});

  @override
  State<AppearanceSettingsPage> createState() => _AppearanceSettingsPageState();
}

class _AppearanceSettingsPageState extends State<AppearanceSettingsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080A0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1017),
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '外觀與介面',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 19),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            children: [
              // Header description
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Text(
                  '微調視覺氛圍、自訂桌布背景、色彩配置與介面版面。',
                  style: TextStyle(
                    fontSize: 13.5,
                    color: Colors.white.withValues(alpha: 0.5),
                    height: 1.4,
                  ),
                ),
              ),

              // Button 0: Custom Wallpaper & Atmosphere Background
              ValueListenableBuilder<CustomBackgroundData>(
                valueListenable: CustomBackgroundService.notifier,
                builder: (context, customBg, _) {
                  return ValueListenableBuilder<AppThemePalette>(
                    valueListenable: AppThemeService.currentPalette,
                    builder: (context, currentPalette, _) {
                      return _buildSectionButton(
                        icon: Icons.wallpaper_rounded,
                        iconColor: currentPalette.primaryColor,
                        title: '自訂背景與桌布',
                        subtitle: 'Upload custom photos, choose curated dark wallpapers, and blend theme ambient lighting',
                        badgeText: customBg.hasCustomBackground ? '自訂已啟用' : '預設主題',
                        badgeColor: customBg.hasCustomBackground ? currentPalette.primaryColor : Colors.white38,
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const CustomBackgroundSettingsPage(),
                            ),
                          );
                          setState(() {});
                        },
                      );
                    },
                  );
                },
              ),

              const SizedBox(height: 14),

              // Button 1: Liquid Glass Setup
              ValueListenableBuilder<bool>(
                valueListenable: GlassSettings.enabled,
                builder: (context, glassEnabled, _) {
                  return ValueListenableBuilder<GlassPreset>(
                    valueListenable: GlassSettings.preset,
                    builder: (context, preset, _) {
                      return _buildSectionButton(
                        icon: Icons.blur_on_rounded,
                        iconColor: const Color(0xFF7C5CFF),
                        title: 'Liquid Glass 設定',
                        subtitle: '調整懸停效果、彈簧晃動、鏡片折射與色差',
                        badgeText: glassEnabled ? preset.label : '已停用',
                        badgeColor: glassEnabled ? const Color(0xFF7C5CFF) : Colors.white38,
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LiquidGlassSettingsPage(),
                            ),
                          );
                          setState(() {});
                        },
                      );
                    },
                  );
                },
              ),

              const SizedBox(height: 14),

              // Button 2: Liquid Dock / Navbar Items
              ValueListenableBuilder<Map<String, bool>>(
                valueListenable: DockSettings.enabledNotifier,
                builder: (context, enabledMap, _) {
                  final activeCount = enabledMap.values.where((v) => v).length;
                  return _buildSectionButton(
                    icon: Icons.dock_rounded,
                    iconColor: const Color(0xFF7C5CFF),
                    title: 'Liquid Dock／底部導覽列',
                    subtitle: '選擇底部 Liquid Glass Dock 在所有畫面顯示的導覽捷徑',
                    badgeText: '$activeCount / ${DockItemKey.values.length} Items',
                    badgeColor: const Color(0xFF7C5CFF),
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const DockSettingsPage(),
                        ),
                      );
                      setState(() {});
                    },
                  );
                },
              ),

              const SizedBox(height: 14),

              // Button 3: Home Page UI & Themes
              ValueListenableBuilder<AppThemePalette>(
                valueListenable: AppThemeService.currentPalette,
                builder: (context, currentPalette, _) {
                  return _buildSectionButton(
                    icon: Icons.palette_rounded,
                    iconColor: currentPalette.primaryColor,
                    title: '首頁介面與主題',
                    subtitle: 'Color schemes, "因為你已加入清單" smart slider, hero spotlight, and card density',
                    badgeText: currentPalette.name,
                    badgeColor: currentPalette.primaryColor,
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const HomeUiSettingsPage(),
                        ),
                      );
                      setState(() {});
                    },
                  );
                },
              ),

              const SizedBox(height: 14),

              // Button 3: Live TV & Sports UI
              ValueListenableBuilder<bool>(
                valueListenable: IptvSettings.enableSpotlight,
                builder: (context, spotlightEnabled, _) {
                  return ValueListenableBuilder<AppThemePalette>(
                    valueListenable: AppThemeService.currentPalette,
                    builder: (context, currentPalette, _) {
                      return _buildSectionButton(
                        icon: Icons.live_tv_rounded,
                        iconColor: currentPalette.primaryColor,
                        title: 'Live TV 與體育介面',
                        subtitle: '直播首頁聚光燈、頻道卡片密度、分類排序與直播標籤樣式',
                        badgeText: spotlightEnabled ? '聚光燈已開啟' : '精簡',
                        badgeColor: currentPalette.primaryColor,
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LiveTvSettingsPage(),
                            ),
                          );
                          setState(() {});
                        },
                      );
                    },
                  );
                },
              ),

              const SizedBox(height: 14),

              // Button 4: Manga UI & Reader Atmosphere
              ValueListenableBuilder<MangaReadingMode>(
                valueListenable: MangaSettings.defaultReadingMode,
                builder: (context, readingMode, _) {
                  return ValueListenableBuilder<AppThemePalette>(
                    valueListenable: AppThemeService.currentPalette,
                    builder: (context, currentPalette, _) {
                      return _buildSectionButton(
                        icon: Icons.menu_book_rounded,
                        iconColor: currentPalette.primaryColor,
                        title: '漫畫介面與閱讀氛圍',
                        subtitle: '動態環境光、卡片密度、閱讀寬度、條漫／橫向模式與頁面縮圖預覽',
                        badgeText: readingMode == MangaReadingMode.webtoon ? '條漫' : '橫向',
                        badgeColor: currentPalette.primaryColor,
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const MangaSettingsPage(),
                            ),
                          );
                          setState(() {});
                        },
                      );
                    },
                  );
                },
              ),

              const SizedBox(height: 14),

              // Button 5: Audiobook UI & Player Studio
              ValueListenableBuilder<AudiobookPlayerPreset>(
                valueListenable: AudiobookSettings.selectedPlayerPreset,
                builder: (context, playerPreset, _) {
                  return ValueListenableBuilder<AppThemePalette>(
                    valueListenable: AppThemeService.currentPalette,
                    builder: (context, currentPalette, _) {
                      return _buildSectionButton(
                        icon: Icons.headphones_rounded,
                        iconColor: currentPalette.primaryColor,
                        title: '有聲書介面與播放器工作室',
                        subtitle: '首頁聚光燈、5 種播放器設計、拖放模組化工作室、波形進度條與自訂控制項',
                        badgeText: playerPreset.label.split(' ').first,
                        badgeColor: currentPalette.primaryColor,
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AudiobookSettingsPage(),
                            ),
                          );
                          setState(() {});
                        },
                      );
                    },
                  );
                },
              ),

              const SizedBox(height: 14),

              // Button 6: Music UI & Player Studio
              ValueListenableBuilder<MusicFullscreenPreset>(
                valueListenable: MusicSettings.selectedFullscreenPreset,
                builder: (context, fullPreset, _) {
                  return ValueListenableBuilder<AppThemePalette>(
                    valueListenable: AppThemeService.currentPalette,
                    builder: (context, currentPalette, _) {
                      return _buildSectionButton(
                        icon: Icons.music_note_rounded,
                        iconColor: currentPalette.primaryColor,
                        title: '音樂介面與播放器工作室',
                        subtitle: '首頁聚光燈、無損標籤，以及迷你 Dock 與全螢幕唱盤／等化器的雙引擎自訂器',
                        badgeText: fullPreset.label.split(' ').first,
                        badgeColor: currentPalette.primaryColor,
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const MusicSettingsPage(),
                            ),
                          );
                          setState(() {});
                        },
                      );
                    },
                  );
                },
              ),

              const SizedBox(height: 28),

              // Visual Overview Notes
              Text(
                '即時自訂範圍',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withValues(alpha: 0.35),
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 12),

              _buildScopeTile(
                icon: Icons.dock_rounded,
                title: '底部 Liquid Dock',
                description: 'Dock 項目會依自訂懸停放大、鄰近波紋與彈簧晃動效果動態反應。',
              ),
              const SizedBox(height: 10),
              _buildScopeTile(
                icon: Icons.play_circle_outline_rounded,
                title: '影片播放器與觀看畫面',
                description: '覆蓋層、玻璃面板與媒體控制項會套用自訂光學模糊、折射率與邊框閃爍。',
              ),
              const SizedBox(height: 10),
              _buildScopeTile(
                icon: Icons.home_rounded,
                title: '首頁與探索',
                description: '依照你選擇的主題強調色、BestSimilar 智慧推薦滑桿與海報密度調整。',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionButton({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String badgeText,
    required Color badgeColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFF12151E),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: badgeColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            badgeText,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: badgeColor,
                            ),
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.45),
                        height: 1.25,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: Colors.white.withValues(alpha: 0.3),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScopeTile({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF12151E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.05),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 2),
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.white70, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.4),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
