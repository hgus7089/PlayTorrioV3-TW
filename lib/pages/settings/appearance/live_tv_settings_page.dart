import 'package:flutter/material.dart';
import '../../../services/theme/app_theme_service.dart';
import '../../../services/home/home_page_settings.dart';
import '../../../services/iptv/iptv_settings.dart';

class LiveTvSettingsPage extends StatefulWidget {
  const LiveTvSettingsPage({super.key});

  @override
  State<LiveTvSettingsPage> createState() => _LiveTvSettingsPageState();
}

class _LiveTvSettingsPageState extends State<LiveTvSettingsPage> {
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
          '直播電視與體育介面',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 19),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            children: [
              // ── 1. Hero Spotlight Carousel ──
              Text(
                '直播焦點與主視覺橫幅',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withValues(alpha: 0.35),
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 12),
              _buildHeroSpotlightCard(palette),

              const SizedBox(height: 28),

              // ── 2. Card Layout & Poster Density ──
              Text(
                '頻道卡片與海報密度',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withValues(alpha: 0.35),
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 12),
              _buildCardDensityCard(palette),

              const SizedBox(height: 28),

              // ── 3. Category Visibility & Ordering ──
              Text(
                '區塊與分類管理',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withValues(alpha: 0.35),
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 12),
              _buildCategoryManagerCard(palette),

              const SizedBox(height: 28),

              // ── 4. Portals Modal Customization ──
              Text(
                '入口與播放清單視窗',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withValues(alpha: 0.35),
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 12),
              _buildPortalsModalCustomizerCard(palette),

              const SizedBox(height: 28),

              // ── 5. Portal Browser Customization ──
              Text(
                '入口瀏覽器與頻道指南',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withValues(alpha: 0.35),
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 12),
              _buildPortalBrowserCustomizerCard(palette),

              const SizedBox(height: 36),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroSpotlightCard(AppThemePalette palette) {
    return ValueListenableBuilder<bool>(
      valueListenable: IptvSettings.enableSpotlight,
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
              // Master Toggle
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
                      Icons.tv_rounded,
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
                          '顯示直播焦點橫幅',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          '在頂部顯示精選冠軍賽事與熱門頻道',
                          style: TextStyle(fontSize: 12, color: Colors.white54),
                        ),
                      ],
                    ),
                  ),
                  Switch.adaptive(
                    value: enabled,
                    activeColor: palette.primaryColor,
                    onChanged: (val) {
                      IptvSettings.setEnableSpotlight(val);
                      setState(() {});
                    },
                  ),
                ],
              ),

              if (enabled) ...[
                const SizedBox(height: 16),
                Divider(color: Colors.white.withValues(alpha: 0.06)),
                const SizedBox(height: 12),

                // Style Selection
                Text(
                  '主視覺橫幅樣式',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 8),
                ValueListenableBuilder<HeroStyle>(
                  valueListenable: IptvSettings.heroStyle,
                  builder: (context, currentStyle, _) {
                    return Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: HeroStyle.values.map((style) {
                        final isSelected = style == currentStyle;
                        return ChoiceChip(
                          label: Text(style.label),
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
                              IptvSettings.setHeroStyle(style);
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

                // Auto Rotate
                ValueListenableBuilder<bool>(
                  valueListenable: IptvSettings.heroAutoRotate,
                  builder: (context, autoRotate, _) {
                    return Row(
                      children: [
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '自動輪播頻道',
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                '自動輪播精選直播活動',
                                style: TextStyle(fontSize: 11.5, color: Colors.white54),
                              ),
                            ],
                          ),
                        ),
                        Switch.adaptive(
                          value: autoRotate,
                          activeColor: palette.primaryColor,
                          onChanged: (val) => IptvSettings.setHeroAutoRotate(val),
                        ),
                      ],
                    );
                  },
                ),

                // Rotate Timer Slider
                ValueListenableBuilder<bool>(
                  valueListenable: IptvSettings.heroAutoRotate,
                  builder: (context, autoRotate, _) {
                    if (!autoRotate) return const SizedBox.shrink();
                    return ValueListenableBuilder<int>(
                      valueListenable: IptvSettings.heroRotateSeconds,
                      builder: (context, seconds, _) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '輪播間隔',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    color: Colors.white.withValues(alpha: 0.7),
                                  ),
                                ),
                                Text(
                                  '$seconds seconds',
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
                                value: seconds.toDouble(),
                                min: 3,
                                max: 15,
                                divisions: 12,
                                onChanged: (val) => IptvSettings.setHeroRotateSeconds(val.round()),
                              ),
                            ),
                          ],
                        );
                      },
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

  Widget _buildCardDensityCard(AppThemePalette palette) {
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
          // Density Choice
          Text(
            '頻道卡片大小',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 8),
          ValueListenableBuilder<CardDensity>(
            valueListenable: IptvSettings.cardDensity,
            builder: (context, currentDensity, _) {
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: CardDensity.values.map((density) {
                  final isSelected = density == currentDensity;
                  return ChoiceChip(
                    label: Text(density.label),
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
                        IptvSettings.setCardDensity(density);
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

          // Hover Zoom Slider
          ValueListenableBuilder<double>(
            valueListenable: IptvSettings.cardHoverZoom,
            builder: (context, zoom, _) {
              final percent = ((zoom - 1.0) * 100).round();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '卡片懸停縮放',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                      Text(
                        '+$percent%',
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
                      value: zoom,
                      min: 1.00,
                      max: 1.15,
                      divisions: 15,
                      onChanged: (val) => IptvSettings.setCardHoverZoom(val),
                    ),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 12),
          Divider(color: Colors.white.withValues(alpha: 0.06)),
          const SizedBox(height: 12),

          // HD Badge Toggle
          ValueListenableBuilder<bool>(
            valueListenable: IptvSettings.showHdBadge,
            builder: (context, showHd, _) {
              return Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '顯示 LIVE / HD 串流標籤',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          '在頻道角落顯示醒目的直播標籤',
                          style: TextStyle(fontSize: 11.5, color: Colors.white54),
                        ),
                      ],
                    ),
                  ),
                  Switch.adaptive(
                    value: showHd,
                    activeColor: palette.primaryColor,
                    onChanged: (val) => IptvSettings.setShowHdBadge(val),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 12),
          Divider(color: Colors.white.withValues(alpha: 0.06)),
          const SizedBox(height: 12),

          // Category Tag Toggle
          ValueListenableBuilder<bool>(
            valueListenable: IptvSettings.showCategoryTag,
            builder: (context, showTag, _) {
              return Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '顯示頻道分類標籤',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          '在頻道名稱下方顯示分類',
                          style: TextStyle(fontSize: 11.5, color: Colors.white54),
                        ),
                      ],
                    ),
                  ),
                  Switch.adaptive(
                    value: showTag,
                    activeColor: palette.primaryColor,
                    onChanged: (val) => IptvSettings.setShowCategoryTag(val),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryManagerCard(AppThemePalette palette) {
    return ValueListenableBuilder<List<String>>(
      valueListenable: IptvSettings.visibleCategories,
      builder: (context, visibleList, _) {
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '頻道分類與區塊',
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        '切換直播電視列的顯示',
                        style: TextStyle(fontSize: 11.5, color: Colors.white54),
                      ),
                    ],
                  ),
                  TextButton.icon(
                    onPressed: () => IptvSettings.resetCategories(),
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: const Text('全部重設', style: TextStyle(fontSize: 12)),
                    style: TextButton.styleFrom(
                      foregroundColor: palette.primaryColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Divider(color: Colors.white.withValues(alpha: 0.06)),
              const SizedBox(height: 6),

              ...IptvSettings.defaultCategories.map((cat) {
                final isVisible = visibleList.contains(cat);
                return CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    cat,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: isVisible ? FontWeight.w700 : FontWeight.w500,
                      color: isVisible ? Colors.white : Colors.white38,
                    ),
                  ),
                  value: isVisible,
                  activeColor: palette.primaryColor,
                  checkColor: Colors.white,
                  onChanged: (val) {
                    IptvSettings.toggleCategoryVisibility(cat);
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPortalsModalCustomizerCard(AppThemePalette palette) {
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
            '入口卡片顯示樣式',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 8),
          ValueListenableBuilder<PortalCardStyle>(
            valueListenable: IptvSettings.portalCardStyle,
            builder: (context, style, _) {
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: PortalCardStyle.values.map((s) {
                  final isSelected = s == style;
                  return ChoiceChip(
                    label: Text(s.label),
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
                        IptvSettings.setPortalCardStyle(s);
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

          ValueListenableBuilder<bool>(
            valueListenable: IptvSettings.showPortalExpiry,
            builder: (context, showExpiry, _) {
              return Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '顯示入口到期日',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          '在入口卡片顯示訂閱到期標籤',
                          style: TextStyle(fontSize: 11.5, color: Colors.white54),
                        ),
                      ],
                    ),
                  ),
                  Switch.adaptive(
                    value: showExpiry,
                    activeColor: palette.primaryColor,
                    onChanged: (val) => IptvSettings.setShowPortalExpiry(val),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 12),
          Divider(color: Colors.white.withValues(alpha: 0.06)),
          const SizedBox(height: 12),

          ValueListenableBuilder<bool>(
            valueListenable: IptvSettings.showPortalConnections,
            builder: (context, showConn, _) {
              return Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '顯示最大連線數標籤',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          '顯示目前與最大同時串流連線數',
                          style: TextStyle(fontSize: 11.5, color: Colors.white54),
                        ),
                      ],
                    ),
                  ),
                  Switch.adaptive(
                    value: showConn,
                    activeColor: palette.primaryColor,
                    onChanged: (val) => IptvSettings.setShowPortalConnections(val),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 12),
          Divider(color: Colors.white.withValues(alpha: 0.06)),
          const SizedBox(height: 12),

          Text(
            '預設起始分頁',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 8),
          ValueListenableBuilder<int>(
            valueListenable: IptvSettings.defaultPortalTab,
            builder: (context, tabIdx, _) {
              return Row(
                children: [
                  ChoiceChip(
                    label: const Text('Xtream 面板'),
                    selected: tabIdx == 0,
                    selectedColor: palette.primaryColor.withValues(alpha: 0.25),
                    backgroundColor: const Color(0xFF0D1017),
                    labelStyle: TextStyle(
                      color: tabIdx == 0 ? palette.primaryColor : Colors.white70,
                      fontWeight: tabIdx == 0 ? FontWeight.w800 : FontWeight.w500,
                      fontSize: 12,
                    ),
                    side: BorderSide(
                      color: tabIdx == 0
                          ? palette.primaryColor.withValues(alpha: 0.6)
                          : Colors.white.withValues(alpha: 0.08),
                    ),
                    onSelected: (selected) {
                      if (selected) IptvSettings.setDefaultPortalTab(0);
                    },
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('M3U 播放清單'),
                    selected: tabIdx == 1,
                    selectedColor: palette.primaryColor.withValues(alpha: 0.25),
                    backgroundColor: const Color(0xFF0D1017),
                    labelStyle: TextStyle(
                      color: tabIdx == 1 ? palette.primaryColor : Colors.white70,
                      fontWeight: tabIdx == 1 ? FontWeight.w800 : FontWeight.w500,
                      fontSize: 12,
                    ),
                    side: BorderSide(
                      color: tabIdx == 1
                          ? palette.primaryColor.withValues(alpha: 0.6)
                          : Colors.white.withValues(alpha: 0.08),
                    ),
                    onSelected: (selected) {
                      if (selected) IptvSettings.setDefaultPortalTab(1);
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

  Widget _buildPortalBrowserCustomizerCard(AppThemePalette palette) {
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
            '頻道串流版面模式',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 8),
          ValueListenableBuilder<PortalBrowserLayout>(
            valueListenable: IptvSettings.browserLayout,
            builder: (context, layout, _) {
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: PortalBrowserLayout.values.map((l) {
                  final isSelected = l == layout;
                  return ChoiceChip(
                    label: Text(l.label),
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
                        IptvSettings.setBrowserLayout(l);
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

          ValueListenableBuilder<PortalBrowserLayout>(
            valueListenable: IptvSettings.browserLayout,
            builder: (context, layout, _) {
              if (layout != PortalBrowserLayout.grid) return const SizedBox.shrink();
              return ValueListenableBuilder<int>(
                valueListenable: IptvSettings.browserGridColumns,
                builder: (context, cols, _) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '網格串流欄數',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                          Text(
                            '$cols Columns',
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
                          value: cols.toDouble(),
                          min: 2,
                          max: 6,
                          divisions: 4,
                          onChanged: (val) => IptvSettings.setBrowserGridColumns(val.round()),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Divider(color: Colors.white.withValues(alpha: 0.06)),
                      const SizedBox(height: 12),
                    ],
                  );
                },
              );
            },
          ),

          ValueListenableBuilder<double>(
            valueListenable: IptvSettings.sidebarWidth,
            builder: (context, width, _) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '分類側邊欄寬度',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                      Text(
                        '${width.round()} px',
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
                      value: width,
                      min: 200.0,
                      max: 340.0,
                      divisions: 14,
                      onChanged: (val) => IptvSettings.setSidebarWidth(val),
                    ),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 12),
          Divider(color: Colors.white.withValues(alpha: 0.06)),
          const SizedBox(height: 12),

          ValueListenableBuilder<bool>(
            valueListenable: IptvSettings.showStreamLogos,
            builder: (context, showLogos, _) {
              return Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '顯示頻道串流 Logo',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Display channel poster and logos in stream rows',
                          style: TextStyle(fontSize: 11.5, color: Colors.white54),
                        ),
                      ],
                    ),
                  ),
                  Switch.adaptive(
                    value: showLogos,
                    activeColor: palette.primaryColor,
                    onChanged: (val) => IptvSettings.setShowStreamLogos(val),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 12),
          Divider(color: Colors.white.withValues(alpha: 0.06)),
          const SizedBox(height: 12),

          ValueListenableBuilder<bool>(
            valueListenable: IptvSettings.showEpgSnippet,
            builder: (context, showEpg, _) {
              return Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '顯示 EPG「目前播放」資訊',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Display current television guide title below channel',
                          style: TextStyle(fontSize: 11.5, color: Colors.white54),
                        ),
                      ],
                    ),
                  ),
                  Switch.adaptive(
                    value: showEpg,
                    activeColor: palette.primaryColor,
                    onChanged: (val) => IptvSettings.setShowEpgSnippet(val),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 12),
          Divider(color: Colors.white.withValues(alpha: 0.06)),
          const SizedBox(height: 12),

          ValueListenableBuilder<bool>(
            valueListenable: IptvSettings.showCategoryCount,
            builder: (context, showCount, _) {
              return Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '顯示分類串流數量',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Show number of available streams next to category names',
                          style: TextStyle(fontSize: 11.5, color: Colors.white54),
                        ),
                      ],
                    ),
                  ),
                  Switch.adaptive(
                    value: showCount,
                    activeColor: palette.primaryColor,
                    onChanged: (val) => IptvSettings.setShowCategoryCount(val),
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
