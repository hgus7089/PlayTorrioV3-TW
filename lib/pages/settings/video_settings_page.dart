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
          'Video & Upscaling',
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
                            'Anime4K Neural Upscaling',
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
                        title: 'Disabled (Off)',
                        subtitle: 'Standard video playback without GLSL neural filters. Lowest GPU overhead.',
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
                        tag: 'Recommended',
                        tagColor: const Color(0xFF10B981),
                        icon: Icons.speed_rounded,
                        isSelected: currentPreset == Anime4KPreset.modeAFast,
                        palette: palette,
                        onTap: () => PlayerSettings.setAnime4kPreset(Anime4KPreset.modeAFast),
                      ),
                      const SizedBox(height: 10),
                      _buildPresetCard(
                        preset: Anime4KPreset.modeAHQ,
                        title: 'Mode A — High Quality (Ultra)',
                        subtitle: 'Maximum perceptual fidelity using Very Large CNNs. Recommended for discrete GPUs (RTX/Radeon).',
                        tag: 'Ultra Quality',
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
                        subtitle: 'Smooth line reconstruction and artifact reduction. Best for blurry, compressed, or older anime.',
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
                        subtitle: 'Aggressive deblurring and scaling. Best for 480p and 720p low-resolution anime episodes.',
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
                'PIPELINE & COMPATIBILITY',
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
                      title: 'Playback Start Application',
                      description: 'Shaders are configured before playback begins. Changing a preset applies to the next opened stream or video.',
                    ),
                    const Divider(color: Colors.white10, height: 24),
                    _buildInfoRow(
                      icon: Icons.memory_rounded,
                      title: 'Hardware Decoder Acceleration',
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
