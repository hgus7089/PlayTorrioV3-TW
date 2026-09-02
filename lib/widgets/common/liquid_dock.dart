import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:liquid_glass_easy/liquid_glass_easy.dart';

import '../../services/theme/glass_settings.dart';
import 'performance_liquid_lens.dart';

class DockItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const DockItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });
}

/// A single retained liquid lens containing lightweight dock items.
///
/// One lens preserves the refraction effect without the previous cost of a
/// separate shader and jelly simulation for every item.
class LiquidDock extends StatefulWidget {
  final List<DockItem> items;
  final double baseItemSize;
  final double maxItemSize;
  final double maxWidth;

  const LiquidDock({
    super.key,
    required this.items,
    this.baseItemSize = 48,
    this.maxItemSize = 72,
    this.maxWidth = 600,
  });

  @override
  State<LiquidDock> createState() => _LiquidDockState();
}

class _LiquidDockState extends State<LiquidDock> {
  final ScrollController _scrollController = ScrollController();
  double? _mouseX;
  bool _dockHovered = false;
  bool _isWarmingUp = false;

  @override
  void initState() {
    super.initState();
    _prewarmDockAnimation();
  }

  /// Pre-warms GPU shaders, layer composition, jelly physics, and proximity layout
  /// by sweeping mouse state across all dock items under the intro overlay.
  void _prewarmDockAnimation() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || !GlassSettings.enabled.value) return;

      final itemExtent = widget.baseItemSize + 10;
      final totalWidth = widget.items.length * itemExtent + 32;

      // Start prewarm sweep after initial layout stabilizes during intro screen
      await Future.delayed(const Duration(milliseconds: 150));
      if (!mounted) return;

      setState(() {
        _dockHovered = true;
        _isWarmingUp = true;
      });

      // Sweep hover position across all dock items so every item's shader/jelly texture is warmed up
      const steps = 12;
      for (int i = 0; i <= steps; i++) {
        await Future.delayed(const Duration(milliseconds: 30));
        if (!mounted || !_isWarmingUp) break;
        final progress = i / steps;
        setState(() {
          _mouseX = progress * totalWidth;
        });
      }

      await Future.delayed(const Duration(milliseconds: 40));

      if (mounted && _isWarmingUp) {
        setState(() {
          _dockHovered = false;
          _mouseX = null;
          _isWarmingUp = false;
        });
      }
    });
  }

  void _scrollBy(double delta) {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    final target = (_scrollController.offset + delta).clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );
    _scrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isMobile = screenWidth < 600;
    final effectiveMaxWidth = math.min(
      widget.maxWidth,
      isMobile ? screenWidth * 0.94 : screenWidth * 0.88,
    );
    final itemExtent = widget.baseItemSize + 10;
    final contentWidth = widget.items.length * itemExtent + 32;
    final needsScrolling = contentWidth > effectiveMaxWidth;
    final scrollAreaWidth = needsScrolling
        ? math.max(60.0, effectiveMaxWidth - 68.0)
        : contentWidth;

    final dockContent = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (needsScrolling)
          SizedBox(
            width: 30,
            height: 44,
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.chevron_left_rounded, color: Colors.white70, size: 20),
              onPressed: () => _scrollBy(-180),
            ),
          ),
        ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: scrollAreaWidth,
          ),
          child: ScrollConfiguration(
            behavior: const MaterialScrollBehavior().copyWith(
              scrollbars: false,
              overscroll: false,
            ),
            child: SingleChildScrollView(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(widget.items.length, (index) {
                  double proximity = 0;
                  if (_dockHovered && _mouseX != null) {
                    final arrowOffset = needsScrolling ? 30.0 : 0.0;
                    final center =
                        arrowOffset +
                        8 +
                        index * itemExtent +
                        itemExtent / 2 -
                        (_scrollController.hasClients
                            ? _scrollController.offset
                            : 0);
                    final distance = (_mouseX! - center).abs();
                    final range = widget.baseItemSize * GlassSettings.hoverProximity.value;
                    if (distance < range) {
                      proximity = math
                          .pow(1 - distance / range, 1.45)
                          .toDouble();
                    }
                  }

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: _DockItemWidget(
                      item: widget.items[index],
                      size: isMobile ? math.min(widget.baseItemSize, 42.0) : widget.baseItemSize,
                      hoverSize: isMobile ? math.min(widget.maxItemSize, 56.0) : widget.maxItemSize,
                      proximity: proximity,
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
        if (needsScrolling)
          SizedBox(
            width: 30,
            height: 44,
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: const Icon(
                Icons.chevron_right_rounded,
                color: Colors.white70,
                size: 20,
              ),
              onPressed: () => _scrollBy(180),
            ),
          ),
      ],
    );

    return MouseRegion(
      onEnter: (_) {
        if (GlassSettings.enabled.value) {
          setState(() => _dockHovered = true);
        }
      },
      onHover: (event) {
        if (GlassSettings.enabled.value) {
          setState(() => _mouseX = event.localPosition.dx);
        }
      },
      onExit: (_) {
        if (_dockHovered || _mouseX != null) {
          setState(() {
            _dockHovered = false;
            _mouseX = null;
          });
        }
      },
      child: RepaintBoundary(
        child: DecoratedBox(
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(32)),
            boxShadow: [
              BoxShadow(
                color: Color(0x66000000),
                blurRadius: 18,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: PerformanceLiquidLens(
            style: PerformanceGlassStyles.dock,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: const Color(0x24FFFFFF)),
              ),
              child: dockContent,
            ),
          ),
        ),
      ),
    );
  }
}

class _DockItemWidget extends StatefulWidget {
  final DockItem item;
  final double size;
  final double hoverSize;
  final double proximity;

  const _DockItemWidget({
    required this.item,
    required this.size,
    required this.hoverSize,
    required this.proximity,
  });

  @override
  State<_DockItemWidget> createState() => _DockItemWidgetState();
}

class _DockItemWidgetState extends State<_DockItemWidget> {
  bool _pressed = false;
  bool _hovered = false;

  Widget _icon(double size) => Tooltip(
    message: widget.item.label,
    child: Icon(
      widget.item.icon,
      size: size * 0.45,
      color: const Color(0xF2FFFFFF),
    ),
  );

  void _setHover(bool value) {
    setState(() {
      _hovered = value;
    });
  }

  void _setPressed(bool value) {
    setState(() {
      _pressed = value;
    });
  }

  Widget _buildFullLiquid() {
    final hoverAmount = _hovered ? 1.0 : widget.proximity;
    final scaleMultiplier = GlassSettings.hoverScale.value;
    final maxHoverSize = widget.size * scaleMultiplier;
    final targetSize =
        widget.size + (maxHoverSize - widget.size) * hoverAmount;
    final wobble = GlassSettings.wobbleIntensity.value;
    final dynamicStyle = GlassSettings.createButtonGlassStyle();

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => _setHover(true),
      onExit: (_) => _setHover(false),
      child: AnimatedContainer(
        duration: Duration(milliseconds: (190 / wobble.clamp(0.5, 2.0)).round()),
        curve: Curves.easeOutBack,
        width: targetSize,
        height: targetSize,
        child: SizedBox.square(
          dimension: targetSize,
          child: LiquidGlassButton(
            padding: EdgeInsets.zero,
            touch: LiquidGlassTouch(
              flex: wobble > 1.4 ? const LiquidGlassFlex.pronounced() : const LiquidGlassFlex(),
            ),
            style: dynamicStyle,
            onPressed: widget.item.onTap,
            child: AnimatedScale(
              scale: _hovered ? scaleMultiplier : 1.0,
              duration: const Duration(milliseconds: 160),
              curve: Curves.easeOutBack,
              child: _icon(targetSize),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOptimized() {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => _setHover(true),
      onExit: (_) => _setHover(false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _setPressed(true),
        onTapUp: (_) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        onTap: widget.item.onTap,
        child: AnimatedScale(
          scale: _pressed ? 0.92 : (_hovered ? 1.08 : 1),
          duration: const Duration(milliseconds: 110),
          curve: Curves.easeOut,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: _hovered
                    ? const [Color(0x38FFFFFF), Color(0x1FFFFFFF)]
                    : const [Color(0x24FFFFFF), Color(0x12FFFFFF)],
              ),
              border: Border.all(color: const Color(0x26FFFFFF)),
            ),
            child: _icon(widget.size),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: ValueListenableBuilder<bool>(
        valueListenable: GlassSettings.enabled,
        builder: (context, enabled, _) =>
            enabled ? _buildFullLiquid() : _buildOptimized(),
      ),
    );
  }
}
