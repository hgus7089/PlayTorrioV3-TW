import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../services/addon/addon_manager.dart';
import '../../services/theme/app_theme_service.dart';
import '../../services/debrid/debrid_service.dart';
import '../../services/theme/glass_settings.dart';
import '../../services/trakt/trakt_service.dart';
import '../../services/simkl/simkl_service.dart';

import 'appearance_settings_page.dart';
import 'video_settings_page.dart';
import 'debrid_settings_page.dart';
import 'addons_settings_page.dart';
import 'trakt_settings_page.dart';
import 'simkl_settings_page.dart';
import 'updates_settings_page.dart';
import 'about_settings_page.dart';
import '../../services/player/player_settings.dart';
import '../../services/p2p/p2p_settings_service.dart';
import '../../widgets/p2p/p2p_warning_dialog.dart';
import '../../services/discord/discord_rpc_service.dart';
import '../../services/backup/backup_restore_service.dart';

import '../../widgets/common/animated_ambient_background.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _debrid = DebridService();
  bool _useDebrid = false;
  String _debridProvider = 'None';
  String? _appVersion;
  bool _traktConnected = false;
  bool _simklConnected = false;

  void _showBackupRestoreDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: const Color(0xFF12151E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.backup_rounded, color: Color(0xFF10B981), size: 22),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '備份與還原',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              '跨裝置 JSON 設定',
                              style: TextStyle(fontSize: 12, color: Colors.white54),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.white54),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    '將設定（已安裝外掛、IPTV 入口、Debrid 金鑰與主題）匯出成 JSON，或從其他裝置匯入。',
                    style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.7), height: 1.4),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.file_upload_outlined, size: 18),
                          label: const Text('匯出 JSON', style: TextStyle(fontWeight: FontWeight.bold)),
                          onPressed: () async {
                            final jsonStr = await BackupRestoreService.exportSettingsJson();
                            await Clipboard.setData(ClipboardData(text: jsonStr));
                            if (!ctx.mounted) return;
                            Navigator.pop(ctx);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('設定 JSON 已複製到剪貼簿！你可以儲存後在其他裝置貼上。'),
                                  backgroundColor: Color(0xFF10B981),
                                  duration: Duration(seconds: 4),
                                ),
                              );
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.file_download_outlined, size: 18),
                          label: const Text('匯入 JSON', style: TextStyle(fontWeight: FontWeight.bold)),
                          onPressed: () {
                            Navigator.pop(ctx);
                            _showImportJsonInputDialog();
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showImportJsonInputDialog() {
    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: const Color(0xFF12151E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.file_download_outlined, color: Color(0xFF00E5FF), size: 22),
                      const SizedBox(width: 10),
                      const Text(
                        '貼上設定 JSON',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.white54),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: textController,
                    maxLines: 8,
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontFamily: 'monospace'),
                    decoration: InputDecoration(
                      hintText: '請在此貼上備份 JSON…',
                      hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                      filled: true,
                      fillColor: const Color(0xFF0A0C12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      TextButton.icon(
                        icon: const Icon(Icons.paste_rounded, size: 16, color: Color(0xFF00E5FF)),
                        label: const Text('從剪貼簿貼上', style: TextStyle(color: Color(0xFF00E5FF))),
                        onPressed: () async {
                          final data = await Clipboard.getData(Clipboard.kTextPlain);
                          if (data?.text != null) {
                            textController.text = data!.text!;
                          }
                        },
                      ),
                      const Spacer(),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00E5FF),
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('立即還原', style: TextStyle(fontWeight: FontWeight.bold)),
                        onPressed: () async {
                          final txt = textController.text.trim();
                          if (txt.isEmpty) return;
                          try {
                            final msg = await BackupRestoreService.importSettingsJson(txt);
                            if (!ctx.mounted) return;
                            Navigator.pop(ctx);
                            if (mounted) {
                              _loadOverviewState();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(msg),
                                  backgroundColor: const Color(0xFF10B981),
                                  duration: const Duration(seconds: 3),
                                ),
                              );
                            }
                          } catch (e) {
                            if (!ctx.mounted) return;
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              SnackBar(
                                content: Text('匯入失敗：$e'),
                                backgroundColor: Colors.redAccent,
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _loadOverviewState();
  }

  Future<void> _loadOverviewState() async {
    final useDebrid = await _debrid.getUseDebridForStreams();
    final provider = await _debrid.getSelectedService();
    final traktAuth = await TraktService.instance.isAuthenticated();
    final simklAuth = await SimklService.instance.isAuthenticated();
    final pkg = await PackageInfo.fromPlatform().catchError((_) => PackageInfo(
          appName: 'PlayTorrio',
          packageName: 'com.playtorrio',
          version: '1.0.9',
          buildNumber: '10',
        ));

    if (mounted) {
      setState(() {
        _useDebrid = useDebrid;
        _debridProvider = provider;
        _appVersion = pkg.version;
        _traktConnected = traktAuth;
        _simklConnected = simklAuth;
      });
    }
  }

  Future<void> _navigateTo(Widget page) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => page),
    );
    // Refresh badges when returning
    _loadOverviewState();
  }

  @override
  Widget build(BuildContext context) {
    final addonCount = AddonManager.instance.addons.length;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1017).withValues(alpha: 0.85),
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '設定',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
        ),
      ),
      body: AnimatedAmbientBackground(
        child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: ListView(
            padding: EdgeInsets.fromLTRB(16, 20, 16, 32 + bottomInset),
            children: [
              // Header Intro Card
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF7C5CFF).withValues(alpha: 0.12),
                      const Color(0xFF00E5FF).withValues(alpha: 0.04),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: const Color(0xFF7C5CFF).withValues(alpha: 20 / 100),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFF7C5CFF).withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.tune_rounded,
                        color: Color(0xFF7C5CFF),
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '偏好設定與配置',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '管理串流服務、外掛、介面效果與帳號同步。',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: Colors.white.withValues(alpha: 0.5),
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Section Label
              Text(
                '分類',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withValues(alpha: 0.35),
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 12),

              // 1. Appearance & Interface
              ValueListenableBuilder<bool>(
                valueListenable: GlassSettings.enabled,
                builder: (context, glassEnabled, _) {
                  return ValueListenableBuilder<AppThemePalette>(
                    valueListenable: AppThemeService.currentPalette,
                    builder: (context, currentPalette, _) {
                      return _SettingsCategoryTile(
                        icon: Icons.palette_rounded,
                        iconColor: currentPalette.primaryColor,
                        title: '外觀與介面',
                        subtitle: 'Liquid Glass、色彩主題與首頁介面設定',
                        badgeText: glassEnabled ? '${currentPalette.name} · Glass ON' : currentPalette.name,
                        badgeColor: currentPalette.primaryColor,
                        onTap: () => _navigateTo(const AppearanceSettingsPage()),
                      );
                    },
                  );
                },
              ),

              const SizedBox(height: 12),

              // 2. Video & Anime4K Upscaling
              ValueListenableBuilder<Anime4KPreset>(
                valueListenable: PlayerSettings.anime4kPreset,
                builder: (context, anime4kPreset, _) {
                  return _SettingsCategoryTile(
                    icon: Icons.auto_awesome_rounded,
                    iconColor: const Color(0xFF7C5CFF),
                    title: '影片與升頻',
                    subtitle: 'Anime4K 神經 GLSL 著色器預設與 GPU 管線',
                    badgeText: anime4kPreset == Anime4KPreset.off
                        ? '關閉'
                        : anime4kPreset.label.split('(').first.trim(),
                    badgeColor: anime4kPreset == Anime4KPreset.off
                        ? Colors.white38
                        : const Color(0xFF7C5CFF),
                    onTap: () => _navigateTo(const VideoSettingsPage()),
                  );
                },
              ),

              const SizedBox(height: 12),

              // 3. Debrid & Cloud Streaming
              _SettingsCategoryTile(
                icon: Icons.cloud_download_rounded,
                iconColor: const Color(0xFF00E5FF),
                title: 'Debrid 與雲端串流',
                subtitle: 'Real-Debrid, TorBox, AllDebrid, Premiumize & Debrid-Link',
                badgeText: _useDebrid
                    ? (_debridProvider != 'None' ? _debridProvider : 'Active')
                    : 'Disabled',
                badgeColor: _useDebrid ? const Color(0xFF00E5FF) : Colors.white38,
                onTap: () => _navigateTo(const DebridSettingsPage()),
              ),

              const SizedBox(height: 12),

              // 3. Metadata & Catalogs (Addons)
              _SettingsCategoryTile(
                icon: Icons.extension_rounded,
                iconColor: const Color(0xFF10B981),
                title: '外掛程式',
                subtitle: 'Stremio 目錄與內容來源',
                badgeText: '$addonCount Installed',
                badgeColor: const Color(0xFF10B981),
                onTap: () => _navigateTo(const AddonsSettingsPage()),
              ),

              const SizedBox(height: 12),

              // 4. Built-in P2P Torrent Source Toggle (PlayTorrio)
              ValueListenableBuilder<bool>(
                valueListenable: P2pSettingsService.isP2pEnabled,
                builder: (context, isP2p, _) {
                  return _SettingsSwitchTile(
                    icon: Icons.hub_rounded,
                    iconColor: isP2p ? const Color(0xFFF59E0B) : Colors.white54,
                    title: '內建 P2P Torrent 來源',
                    subtitle: isP2p
                        ? 'PlayTorrio Torrent 群集（Knaben、TorrentGalaxy）已啟用'
                        : 'P2P 已停用，僅使用直接 HTTP 串流（PlayTorrioHTTP）',
                    badgeText: isP2p ? 'P2P 已啟用' : '僅 HTTP',
                    badgeColor: isP2p ? const Color(0xFFF59E0B) : const Color(0xFF10B981),
                    value: isP2p,
                    onChanged: (val) async {
                      await P2pSettingsService.setP2pEnabled(val);
                    },
                    onInfoTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => const P2pWarningDialog(),
                      );
                    },
                  );
                },
              ),

              const SizedBox(height: 12),

              // 5. Discord Rich Presence (Desktop Only)
              if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) ...[
                ValueListenableBuilder<bool>(
                  valueListenable: DiscordRpcService.instance.isEnabled,
                  builder: (context, isDiscordEnabled, _) {
                    return _SettingsSwitchTile(
                      icon: Icons.sports_esports_rounded,
                      iconColor: isDiscordEnabled ? const Color(0xFF5865F2) : Colors.white54,
                      title: 'Discord Rich Presence',
                      subtitle: isDiscordEnabled
                          ? '將電影、影集、音樂與即時活動同步至 Discord'
                          : '已停用，活動不會顯示在 Discord',
                      badgeText: isDiscordEnabled ? 'Active' : 'Disabled',
                      badgeColor: isDiscordEnabled ? const Color(0xFF5865F2) : Colors.white38,
                      value: isDiscordEnabled,
                      onChanged: (val) async {
                        await DiscordRpcService.instance.setEnabled(val);
                      },
                    );
                  },
                ),
                const SizedBox(height: 12),
              ],

              // 6. Trakt Sync
              _SettingsCategoryTile(
                icon: Icons.movie_filter_rounded,
                iconColor: const Color(0xFFED1C24),
                title: 'Trakt.tv 同步',
                subtitle: '跨裝置同步待看清單、觀看紀錄與播放進度',
                badgeText: _traktConnected ? '已連線' : '離線',
                badgeColor: _traktConnected ? const Color(0xFFED1C24) : Colors.white38,
                onTap: () => _navigateTo(const TraktSettingsPage()),
              ),

              const SizedBox(height: 12),

              // 6. Simkl Sync
              _SettingsCategoryTile(
                icon: Icons.tv_rounded,
                iconColor: const Color(0xFF00ADFF),
                title: 'Simkl 同步',
                subtitle: '跨裝置同步電影、電視與動漫',
                badgeText: _simklConnected ? '已連線' : '離線',
                badgeColor: _simklConnected ? const Color(0xFF00ADFF) : Colors.white38,
                onTap: () => _navigateTo(const SimklSettingsPage()),
              ),

              const SizedBox(height: 12),

              // 7. Backup & Restore (JSON)
              _SettingsCategoryTile(
                icon: Icons.backup_rounded,
                iconColor: const Color(0xFF10B981),
                title: '備份與還原',
                subtitle: '匯出或匯入設定、外掛與 IPTV 入口（JSON）',
                badgeText: 'JSON',
                badgeColor: const Color(0xFF10B981),
                onTap: _showBackupRestoreDialog,
              ),

              const SizedBox(height: 12),

              // 8. App Updates & System
              _SettingsCategoryTile(
                icon: Icons.system_update_rounded,
                iconColor: const Color(0xFFF59E0B),
                title: '應用程式更新',
                subtitle: '檢查最新版本與修補程式',
                badgeText: _appVersion != null ? 'v$_appVersion' : '檢查',
                badgeColor: const Color(0xFFF59E0B),
                onTap: () => _navigateTo(const UpdatesSettingsPage()),
              ),

              const SizedBox(height: 12),

              // 9. About PlayTorrio
              _SettingsCategoryTile(
                icon: Icons.info_outline_rounded,
                iconColor: Colors.white70,
                title: '關於 PlayTorrio',
                subtitle: '架構、影片引擎與製作資訊',
                onTap: () => _navigateTo(const AboutSettingsPage()),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Settings Category Tile
// ─────────────────────────────────────────────────────────────────────────────

class _SettingsCategoryTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String? badgeText;
  final Color? badgeColor;
  final VoidCallback onTap;

  const _SettingsCategoryTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.badgeText,
    this.badgeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
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
              // Icon Container with subtle tinted background
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),

              // Title and Subtitle
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
                        if (badgeText != null) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: (badgeColor ?? iconColor).withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              badgeText!,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: badgeColor ?? iconColor,
                              ),
                              maxLines: 1,
                            ),
                          ),
                        ],
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

              // Chevron right
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: Colors.white.withValues(alpha: 0.25),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Settings Switch Tile
// ─────────────────────────────────────────────────────────────────────────────

class _SettingsSwitchTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String? badgeText;
  final Color? badgeColor;
  final bool value;
  final ValueChanged<bool> onChanged;
  final VoidCallback? onInfoTap;

  const _SettingsSwitchTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.badgeText,
    this.badgeColor,
    required this.value,
    required this.onChanged,
    this.onInfoTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF12151E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: value
              ? iconColor.withValues(alpha: 0.20)
              : Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        children: [
          // Icon Container
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),

          // Title and Subtitle
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
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (onInfoTap != null) ...[
                      const SizedBox(width: 4),
                      IconButton(
                        icon: const Icon(Icons.info_outline_rounded, size: 16, color: Colors.white54),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        tooltip: 'P2P Advisory Details',
                        onPressed: onInfoTap,
                      ),
                    ],
                    if (badgeText != null) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: (badgeColor ?? iconColor).withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          badgeText!,
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            color: badgeColor ?? iconColor,
                          ),
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11.5,
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

          // Switch
          Transform.scale(
            scale: 0.9,
            child: Switch.adaptive(
              value: value,
              activeColor: const Color(0xFFF59E0B),
              activeTrackColor: const Color(0xFFF59E0B).withValues(alpha: 0.35),
              inactiveThumbColor: Colors.white60,
              inactiveTrackColor: Colors.white10,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}
