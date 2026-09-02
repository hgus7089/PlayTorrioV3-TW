import 'package:flutter/material.dart';
import '../../services/theme/app_theme_service.dart';
import '../../services/player/player_settings.dart';

class VideoSettingsPage extends StatefulWidget {
  const VideoSettingsPage({super.key});

  @override
  State<VideoSettingsPage> createState() => _VideoSettingsPageState();
}

class _VideoSettingsPageState extends State<VideoSettingsPage> {
  @override
  Widget build(BuildContext context) {
    final palette = AppThemeService.currentPalette.value;

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
          '影片與升頻',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 19),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            children: [
              // ── Top Intro Banner ──
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      palette.primaryColor.withValues(alpha: 0.12),
                      const Color(0xFF00E5FF).withValues(alpha: 0.04),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: palette.primaryColor.withValues(alpha: 0.20),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: palette.primaryColor.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        Icons.auto_awesome_rounded,
                        color: palette.primaryColor,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '動漫4K 神經升頻',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Real-time GLSL anime upscaling and line reconstruction running directly on libmpv GPU shaders.',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: Colors.white.withValues(alpha: 0.6),
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

              // ── Section: Presets ──
              Text(
                'UPSCALING PRESETS',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withValues(alpha: 0.35),
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 12),

              ValueListenableBuilder<Anime4KPreset>(
                valueListenable: PlayerSettings.anime4kPreset,
                builder: (context, currentPreset, _) {
                  return Column(
                    children: [
                      _buildPresetCard(
                        preset: Anime4KPreset.off,
                        title: '已停用（關閉）',
                        subtitle: '不使用 GLSL 神經濾鏡的標準影片播放，GPU 負擔最低。',
                        tag: 'Standard',
                        tagColor: Colors.white38,
                        icon: Icons.block_rounded,
                        isSelected: currentPreset == Anime4KPreset.off,
                        palette: palette,
                        onTap: () => PlayerSettings.setAnime4kPreset(Anime4KPreset.off),
                      ),
                      const SizedBox(height: 10),
                      _buildPresetCard(
                        preset: Anime4KPreset.modeAFast,
                        title: 'Mode A — Fast / Balanced',
                        subtitle: 'Sharp line restoration & 2x CNN upscale. Best for 1080p anime and balanced GPU power.',
                        tag: '推薦',
                        tagColor: const Color(0xFF10B981),
                        icon: Icons.speed_rounded,
                        isSelected: currentPreset == Anime4KPreset.modeAFast,
                        palette: palette,
                        onTap: () => PlayerSettings.setAnime4kPreset(Anime4KPreset.modeAFast),
                      ),
                      const SizedBox(height: 10),
                      _buildPresetCard(
                        preset: Anime4KPreset.modeAHQ,
                        title: 'Mode A — High 畫質 (Ultra)',
                        subtitle: 'Maximum perceptual fidelity using Very Large CNNs. 推薦 for discrete GPUs (RTX/Radeon).',
                        tag: 'Ultra 畫質',
                        tagColor: const Color(0xFF7C5CFF),
                        icon: Icons.diamond_rounded,
                        isSelected: currentPreset == Anime4KPreset.modeAHQ,
                        palette: palette,
                        onTap: () => PlayerSettings.setAnime4kPreset(Anime4KPreset.modeAHQ),
                      ),
                      const SizedBox(height: 10),
                      _buildPresetCard(
                        preset: Anime4KPreset.modeB,
                        title: 'Mode B — Soft / Denoise',
                        subtitle: '平滑線條重建並降低壓縮瑕疵。適合模糊、壓縮或較舊的動畫。',
                        tag: 'Denoise',
                        tagColor: const Color(0xFF00E5FF),
                        icon: Icons.blur_linear_rounded,
                        isSelected: currentPreset == Anime4KPreset.modeB,
                        palette: palette,
                        onTap: () => PlayerSettings.setAnime4kPreset(Anime4KPreset.modeB),
                      ),
                      const SizedBox(height: 10),
                      _buildPresetCard(
                        preset: Anime4KPreset.modeC,
                        title: 'Mode C — Deblur & Scale',
                        subtitle: '強力去模糊與升頻。適合 480p、720p 等低解析度動畫。',
                        tag: 'Deblur',
                        tagColor: const Color(0xFFF59E0B),
                        icon: Icons.high_quality_rounded,
                        isSelected: currentPreset == Anime4KPreset.modeC,
                        palette: palette,
                        onTap: () => PlayerSettings.setAnime4kPreset(Anime4KPreset.modeC),
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 28),

              // ── Section: Details & Performance Note ──
              Text(
                '管線與相容性',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withValues(alpha: 0.35),
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF0E121B),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: Column(
                  children: [
                    _buildInfoRow(
                      icon: Icons.info_outline_rounded,
                      title: '播放back Start Application',
                      description: '著色器會在播放前設定。變更預設值後，會套用到下一個開啟的串流或影片。',
                    ),
                    const Divider(color: Colors.white10, height: 24),
                    _buildInfoRow(
                      icon: Icons.memory_rounded,
                      title: '硬體解碼加速',
                      description: 'media_kit uses native auto-safe hardware decoding to feed GPU texture memory directly into the GLSL shader pass.',
                    ),
                    const Divider(color: Colors.white10, height: 24),
                    _buildInfoRow(
                      icon: Icons.devices_rounded,
                      title: 'Platform Recommendation',
                      description: 'For desktop (Windows/macOS/Linux), Mode A HQ provides crystal-clear lines. For mobile devices, Mode A Fast offers smooth 60fps playback.',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPresetCard({
    required Anime4KPreset preset,
    required String title,
    required String subtitle,
    required String tag,
    required Color tagColor,
    required IconData icon,
    required bool isSelected,
    required AppThemePalette palette,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? palette.primaryColor.withValues(alpha: 0.08)
              : const Color(0xFF0E121B),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? palette.primaryColor
                : Colors.white.withValues(alpha: 0.08),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected
                    ? palette.primaryColor.withValues(alpha: 0.20)
                    : Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isSelected ? palette.primaryColor : Colors.white70,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: tagColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: tagColor.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          tag,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: tagColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: Colors.white.withValues(alpha: 0.55),
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(
                isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_unchecked_rounded,
                color: isSelected ? palette.primaryColor : Colors.white24,
                size: 22,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: const Color(0xFF00E5FF), size: 20),
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
              const SizedBox(height: 3),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.55),
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
