import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../services/theme/app_theme_service.dart';
import '../../../services/theme/custom_background_service.dart';
import '../../../services/home/home_page_settings.dart';
import '../../../services/my_list/my_list_service.dart';
import '../../../services/simkl/simkl_service.dart';
import '../../../services/trakt/trakt_service.dart';
import '../../../widgets/common/animated_ambient_background.dart';
import 'custom_background_settings_page.dart';

class HomeUiSettingsPage extends StatefulWidget {
  const HomeUiSettingsPage({super.key});

  @override
  State<HomeUiSettingsPage> createState() => _HomeUiSettingsPageState();
}

class _HomeUiSettingsPageState extends State<HomeUiSettingsPage> {
  @override
  Widget build(BuildContext context) {
    final myListCount = MyListService.items.value.length;

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
          '首頁介面與主題',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 19),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            children: [
              // ── 1. Color Schemes & Themes ──
              Text(
                '色彩主題與強調色',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withValues(alpha: 0.35),
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 12),
              _buildThemesGrid(),

              const SizedBox(height: 28),

              // ── 2. Ambient Background Lighting & Moving Glows ──
              Text(
                '環境背景燈光與流動光暈',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withValues(alpha: 0.35),
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 12),
              _buildAmbientLightsCard(),

              const SizedBox(height: 28),

              // ── 2b. Custom Wallpaper & Background Photo ──
              Text(
                '自訂背景與桌布',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withValues(alpha: 0.35),
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 12),
              ValueListenableBuilder<CustomBackgroundData>(
                valueListenable: CustomBackgroundService.notifier,
                builder: (context, customBg, _) {
                  final hasWallpaper = customBg.hasCustomBackground;
                  final palette = AppThemeService.currentPalette.value;

                  return InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CustomBackgroundSettingsPage(),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF12151E),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: hasWallpaper
                              ? palette.primaryColor.withValues(alpha: 0.40)
                              : Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: palette.primaryColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.wallpaper_rounded,
                              color: palette.primaryColor,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '自訂桌布與燈光融合',
                                  style: TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  hasWallpaper
                                      ? 'Custom background active with ambient light blending'
                                      : 'Upload photos or choose curated dark wallpapers',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white.withValues(alpha: 0.5),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white38, size: 16),
                        ],
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 28),

              // ── 3. "Because you have on your list" Section ──
              Text(
                '智慧推薦（「因為你加入了清單」）',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withValues(alpha: 0.35),
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 12),
              _buildSimilarRecommendationsCard(myListCount),

              const SizedBox(height: 28),

              // ── 4. Hero Carousel & Spotlight ──
              Text(
                '主視覺橫幅與焦點',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withValues(alpha: 0.35),
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 12),
              _buildHeroControlsCard(),

              const SizedBox(height: 28),

              // ── 5. Card Layout & Poster Density ──
              Text(
                '海報卡片與密度',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withValues(alpha: 0.35),
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 12),
              _buildCardDensityCard(),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThemesGrid() {
    return ValueListenableBuilder<AppThemePalette>(
      valueListenable: AppThemeService.currentPalette,
      builder: (context, current, _) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final int crossAxisCount = w < 400 ? 1 : (w < 700 ? 2 : 3);
            final double childAspectRatio = w < 400 ? 4.2 : 2.6;

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                childAspectRatio: childAspectRatio,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: AppThemeService.palettes.length,
              itemBuilder: (context, index) {
                final palette = AppThemeService.palettes[index];
                final isSelected = palette.id == current.id;

                return InkWell(
                  onTap: () async {
                    await AppThemeService.setPalette(palette);
                    setState(() {});
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF12151E),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected
                            ? palette.primaryColor
                            : Colors.white.withValues(alpha: 0.08),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        // Swatch circles
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [palette.primaryColor, palette.accentColor],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              if (isSelected)
                                BoxShadow(
                                  color: palette.primaryColor.withValues(alpha: 0.4),
                                  blurRadius: 10,
                                  spreadRadius: 1,
                                ),
                            ],
                          ),
                          child: isSelected
                              ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
                              : null,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                palette.name,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                  color: isSelected ? Colors.white : Colors.white70,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                isSelected ? 'Active Theme' : 'Tap to apply',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  color: isSelected
                                      ? palette.primaryColor
                                      : Colors.white.withValues(alpha: 0.35),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildAmbientLightsCard() {
    final palette = AppThemeService.currentPalette.value;

    return ValueListenableBuilder<bool>(
      valueListenable: HomePageSettings.enableAmbientLights,
      builder: (context, enabled, _) {
        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFF12151E),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: enabled
                  ? palette.primaryColor.withValues(alpha: 0.35)
                  : Colors.white.withValues(alpha: 0.08),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Live Interactive Mini Preview
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  height: 90,
                  width: double.infinity,
                  child: Stack(
                    children: [
                      const Positioned.fill(
                        child: AnimatedAmbientBackground(),
                      ),
                      Positioned(
                        left: 14,
                        bottom: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.55),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.white.withOpacity(0.12)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.auto_awesome_motion_rounded, size: 14, color: palette.primaryColor),
                              const SizedBox(width: 6),
                              Text(
                                '即時燈光引擎預覽',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white.withOpacity(0.85),
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Master Switch
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: palette.primaryColor.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.blur_linear_rounded,
                      color: palette.primaryColor,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '流動環境光與光暈',
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          '背景中的漂浮淡光波與彩色光球',
                          style: TextStyle(fontSize: 11.5, color: Colors.white54),
                        ),
                      ],
                    ),
                  ),
                  Switch.adaptive(
                    value: enabled,
                    activeColor: palette.primaryColor,
                    onChanged: (val) {
                      HomePageSettings.setEnableAmbientLights(val);
                      setState(() {});
                    },
                  ),
                ],
              ),

              if (enabled) ...[
                const SizedBox(height: 16),
                Divider(color: Colors.white.withValues(alpha: 0.06)),
                const SizedBox(height: 12),

                // Lighting Pattern / Position
                Text(
                  '燈光樣式與位置',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 8),
                ValueListenableBuilder<AmbientLightPattern>(
                  valueListenable: HomePageSettings.ambientLightPattern,
                  builder: (context, currentPattern, _) {
                    return Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: AmbientLightPattern.values.map((pat) {
                        final isSelected = pat == currentPattern;
                        return ChoiceChip(
                          label: Text(pat.label),
                          selected: isSelected,
                          selectedColor: palette.primaryColor.withValues(alpha: 0.25),
                          backgroundColor: const Color(0xFF0D1017),
                          labelStyle: TextStyle(
                            color: isSelected ? palette.primaryColor : Colors.white70,
                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                            fontSize: 12,
                          ),
                          side: BorderSide(
                            color: isSelected
                                ? palette.primaryColor.withValues(alpha: 0.6)
                                : Colors.white.withValues(alpha: 0.08),
                          ),
                          onSelected: (selected) {
                            if (selected) {
                              HomePageSettings.setAmbientLightPattern(pat);
                              setState(() {});
                            }
                          },
                        );
                      }).toList(),
                    );
                  },
                ),

                const SizedBox(height: 16),
                Divider(color: Colors.white.withValues(alpha: 0.06)),
                const SizedBox(height: 12),

                // Strength / Intensity Slider
                ValueListenableBuilder<double>(
                  valueListenable: HomePageSettings.ambientLightIntensity,
                  builder: (context, intensity, _) {
                    final percent = (intensity * 200).round();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '光暈強度',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                            ),
                            Text(
                              '$percent%',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w800,
                                color: palette.primaryColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: palette.primaryColor,
                            inactiveTrackColor: Colors.white.withValues(alpha: 0.08),
                            thumbColor: palette.primaryColor,
                            trackHeight: 3,
                          ),
                          child: Slider(
                            value: intensity,
                            min: 0.05,
                            max: 0.50,
                            divisions: 18,
                            onChanged: (val) => HomePageSettings.setAmbientLightIntensity(val),
                          ),
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 12),

                // Motion Speed Slider
                ValueListenableBuilder<double>(
                  valueListenable: HomePageSettings.ambientLightSpeed,
                  builder: (context, speed, _) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '流動速度',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                            ),
                            Text(
                              '${speed.toStringAsFixed(1)}x',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w800,
                                color: palette.primaryColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: palette.primaryColor,
                            inactiveTrackColor: Colors.white.withValues(alpha: 0.08),
                            thumbColor: palette.primaryColor,
                            trackHeight: 3,
                          ),
                          child: Slider(
                            value: speed,
                            min: 0.4,
                            max: 2.5,
                            divisions: 21,
                            onChanged: (val) => HomePageSettings.setAmbientLightSpeed(val),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildSimilarRecommendationsCard(int myListCount) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF12151E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF7C5CFF).withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFF7C5CFF).withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: Color(0xFF7C5CFF),
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '智慧推薦',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      '設定個人化與演算法推薦列',
                      style: TextStyle(fontSize: 12, color: Colors.white54),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          Divider(color: Colors.white.withValues(alpha: 0.06)),
          const SizedBox(height: 8),

          // 1. Because You Have... (My List)
          _buildRecommendationToggleRow(
            title: '"Because You Have..." (My List)',
            subtitle: 'BestSimilar recommendations based on titles saved in My List',
            listenable: HomePageSettings.enableSimilar,
            onChanged: (val) {
              HomePageSettings.setEnableSimilar(val);
              setState(() {});
            },
          ),

          // 2. Because You're Watching... (Continue Watching)
          _buildRecommendationToggleRow(
            title: '"Because You\'re Watching..."',
            subtitle: 'BestSimilar recommendations based on active Continue Watching titles',
            listenable: HomePageSettings.enableWatchingSimilar,
            onChanged: (val) {
              HomePageSettings.setEnableWatchingSimilar(val);
              setState(() {});
            },
          ),

          // 3. Trakt Recommendations
          FutureBuilder<bool>(
            future: TraktService.instance.isAuthenticated(),
            builder: (context, snapshot) {
              final isAuthed = snapshot.data ?? false;
              return _buildRecommendationToggleRow(
                title: 'Trakt Recommendations',
                subtitle: isAuthed
                    ? 'Personalized recommendations computed by Trakt'
                    : 'Requires Trakt login in Settings -> Trakt',
                listenable: HomePageSettings.enableTraktRecommendations,
                trailingExtra: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: (isAuthed ? const Color(0xFFED1C24) : Colors.white12).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: (isAuthed ? const Color(0xFFED1C24) : Colors.white24).withValues(alpha: 0.4),
                      width: 0.8,
                    ),
                  ),
                  child: Text(
                    isAuthed ? '已連線' : '未連線',
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      color: isAuthed ? const Color(0xFFFF5252) : Colors.white38,
                    ),
                  ),
                ),
                onChanged: (val) {
                  HomePageSettings.setEnableTraktRecommendations(val);
                  setState(() {});
                },
              );
            },
          ),

          // 4. Simkl Recommendations
          FutureBuilder<bool>(
            future: SimklService.instance.isAuthenticated(),
            builder: (context, snapshot) {
              final isAuthed = snapshot.data ?? false;
              return _buildRecommendationToggleRow(
                title: 'Simkl Recommendations',
                subtitle: isAuthed
                    ? 'Top-rated & personalized suggestions from Simkl'
                    : 'Requires Simkl login in Settings -> Simkl',
                listenable: HomePageSettings.enableSimklRecommendations,
                trailingExtra: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: (isAuthed ? const Color(0xFF00B2FF) : Colors.white12).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: (isAuthed ? const Color(0xFF00B2FF) : Colors.white24).withValues(alpha: 0.4),
                      width: 0.8,
                    ),
                  ),
                  child: Text(
                    isAuthed ? '已連線' : '未連線',
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      color: isAuthed ? const Color(0xFF40C4FF) : Colors.white38,
                    ),
                  ),
                ),
                onChanged: (val) {
                  HomePageSettings.setEnableSimklRecommendations(val);
                  setState(() {});
                },
              );
            },
          ),

          const SizedBox(height: 12),
          Divider(color: Colors.white.withValues(alpha: 0.06)),
          const SizedBox(height: 12),

          // Position Dropdown
          Text(
            '推薦列在首頁的位置',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 6),
          ValueListenableBuilder<SimilarSectionPosition>(
            valueListenable: HomePageSettings.similarPosition,
            builder: (context, pos, _) {
              return DropdownButtonFormField<SimilarSectionPosition>(
                value: pos,
                dropdownColor: const Color(0xFF151822),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFF0D1017),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
                  ),
                ),
                style: const TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w600),
                items: SimilarSectionPosition.values.map((p) {
                  return DropdownMenuItem(
                    value: p,
                    child: Text(p.label),
                  );
                }).toList(),
                onChanged: (newPos) {
                  if (newPos != null) {
                    HomePageSettings.setSimilarPosition(newPos);
                    setState(() {});
                  }
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationToggleRow({
    required String title,
    required String subtitle,
    required ValueListenable<bool> listenable,
    required ValueChanged<bool> onChanged,
    Widget? trailingExtra,
  }) {
    return ValueListenableBuilder<bool>(
      valueListenable: listenable,
      builder: (context, enabled, _) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        if (trailingExtra != null) ...[
                          const SizedBox(width: 8),
                          trailingExtra,
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 11.5, color: Colors.white54),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Switch.adaptive(
                value: enabled,
                activeColor: const Color(0xFF7C5CFF),
                onChanged: onChanged,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeroControlsCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF12151E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Master Spotlight Switch
          ValueListenableBuilder<bool>(
            valueListenable: HomePageSettings.enableSpotlight,
            builder: (context, enabled, _) {
              return Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF7C5CFF).withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.movie_filter_rounded,
                      color: Color(0xFF7C5CFF),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '顯示主視覺焦點橫幅',
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          '在首頁頂部顯示精選輪播橫幅',
                          style: TextStyle(fontSize: 11.5, color: Colors.white54),
                        ),
                      ],
                    ),
                  ),
                  Switch.adaptive(
                    value: enabled,
                    activeColor: const Color(0xFF7C5CFF),
                    onChanged: (val) {
                      HomePageSettings.setEnableSpotlight(val);
                      setState(() {});
                    },
                  ),
                ],
              );
            },
          ),

          ValueListenableBuilder<bool>(
            valueListenable: HomePageSettings.enableSpotlight,
            builder: (context, enabled, _) {
              if (!enabled) {
                return const SizedBox.shrink();
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  Divider(color: Colors.white.withValues(alpha: 0.06)),
                  const SizedBox(height: 12),

                  // Hero Style Selector
                  Text(
                    '焦點樣式',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ValueListenableBuilder<HeroStyle>(
                    valueListenable: HomePageSettings.heroStyle,
                    builder: (context, currentStyle, _) {
                      return Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: HeroStyle.values.map((style) {
                          final isSelected = style == currentStyle;
                          return ChoiceChip(
                            label: Text(style.label),
                            selected: isSelected,
                            selectedColor: const Color(0xFF7C5CFF).withValues(alpha: 0.25),
                            backgroundColor: const Color(0xFF0D1017),
                            labelStyle: TextStyle(
                              color: isSelected ? const Color(0xFF7C5CFF) : Colors.white70,
                              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                              fontSize: 12,
                            ),
                            side: BorderSide(
                              color: isSelected
                                  ? const Color(0xFF7C5CFF).withValues(alpha: 0.6)
                                  : Colors.white.withValues(alpha: 0.08),
                            ),
                            onSelected: (selected) {
                              if (selected) {
                                HomePageSettings.setHeroStyle(style);
                                setState(() {});
                              }
                            },
                          );
                        }).toList(),
                      );
                    },
                  ),

          // Auto-Rotate Switch & Interval
          ValueListenableBuilder<bool>(
            valueListenable: HomePageSettings.heroAutoRotate,
            builder: (context, autoRotate, _) {
              return Column(
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '自動輪播焦點內容',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              '自動輪播精選內容',
                              style: TextStyle(fontSize: 11.5, color: Colors.white54),
                            ),
                          ],
                        ),
                      ),
                      Switch.adaptive(
                        value: autoRotate,
                        activeColor: const Color(0xFF7C5CFF),
                        onChanged: (val) {
                          HomePageSettings.setHeroAutoRotate(val);
                          setState(() {});
                        },
                      ),
                    ],
                  ),
                  if (autoRotate) ...[
                    const SizedBox(height: 10),
                    ValueListenableBuilder<int>(
                      valueListenable: HomePageSettings.heroRotateSeconds,
                      builder: (context, seconds, _) {
                        return Row(
                          children: [
                            Text(
                              'Interval: ${seconds}s',
                              style: const TextStyle(fontSize: 12, color: Colors.white70),
                            ),
                            Expanded(
                              child: SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  activeTrackColor: const Color(0xFF7C5CFF),
                                  inactiveTrackColor: Colors.white.withValues(alpha: 0.08),
                                  thumbColor: const Color(0xFF7C5CFF),
                                  trackHeight: 3,
                                ),
                                child: Slider(
                                  value: seconds.toDouble(),
                                  min: 3,
                                  max: 15,
                                  divisions: 12,
                                  onChanged: (val) =>
                                      HomePageSettings.setHeroRotateSeconds(val.round()),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ],
              );
            },
          ),

          const SizedBox(height: 12),
          Divider(color: Colors.white.withValues(alpha: 0.06)),
          const SizedBox(height: 12),

          // Ambient Glow Switch
          ValueListenableBuilder<bool>(
            valueListenable: HomePageSettings.ambientGlow,
            builder: (context, glow, _) {
              return Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '環境背景燈光',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          '在目前主視覺海報後方呈現柔和擴散的色彩光暈',
                          style: TextStyle(fontSize: 11.5, color: Colors.white54),
                        ),
                      ],
                    ),
                  ),
                  Switch.adaptive(
                    value: glow,
                    activeColor: const Color(0xFF7C5CFF),
                    onChanged: (val) {
                      HomePageSettings.setAmbientGlow(val);
                      setState(() {});
                    },
                  ),
                ],
              );
            },
          ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCardDensityCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF12151E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '海報大小與網格密度',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 8),
          ValueListenableBuilder<CardDensity>(
            valueListenable: HomePageSettings.cardDensity,
            builder: (context, currentDensity, _) {
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: CardDensity.values.map((density) {
                  final isSelected = density == currentDensity;
                  return ChoiceChip(
                    label: Text(density.label),
                    selected: isSelected,
                    selectedColor: const Color(0xFF7C5CFF).withValues(alpha: 0.25),
                    backgroundColor: const Color(0xFF0D1017),
                    labelStyle: TextStyle(
                      color: isSelected ? const Color(0xFF7C5CFF) : Colors.white70,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                      fontSize: 12,
                    ),
                    side: BorderSide(
                      color: isSelected
                          ? const Color(0xFF7C5CFF).withValues(alpha: 0.6)
                          : Colors.white.withValues(alpha: 0.08),
                    ),
                    onSelected: (selected) {
                      if (selected) {
                        HomePageSettings.setCardDensity(density);
                        setState(() {});
                      }
                    },
                  );
                }).toList(),
              );
            },
          ),

          const SizedBox(height: 16),
          Divider(color: Colors.white.withValues(alpha: 0.06)),
          const SizedBox(height: 12),

          // Rating Badges Switch
          ValueListenableBuilder<bool>(
            valueListenable: HomePageSettings.showRating,
            builder: (context, showRating, _) {
              return Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '顯示 IMDb 評分標籤',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          '在海報角落顯示星級評分',
                          style: TextStyle(fontSize: 11.5, color: Colors.white54),
                        ),
                      ],
                    ),
                  ),
                  Switch.adaptive(
                    value: showRating,
                    activeColor: const Color(0xFF7C5CFF),
                    onChanged: (val) {
                      HomePageSettings.setShowRating(val);
                      setState(() {});
                    },
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 12),
          Divider(color: Colors.white.withValues(alpha: 0.06)),
          const SizedBox(height: 12),

          // Card Hover Zoom Strength
          ValueListenableBuilder<double>(
            valueListenable: HomePageSettings.cardHoverZoom,
            builder: (context, zoom, _) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          '海報懸停縮放比例',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      Text(
                        '${zoom.toStringAsFixed(2)}x',
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF7C5CFF),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: const Color(0xFF7C5CFF),
                      inactiveTrackColor: Colors.white.withValues(alpha: 0.08),
                      thumbColor: const Color(0xFF7C5CFF),
                      trackHeight: 3,
                    ),
                    child: Slider(
                      value: zoom,
                      min: 1.00,
                      max: 1.15,
                      divisions: 15,
                      onChanged: (val) => HomePageSettings.setCardHoverZoom(val),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
