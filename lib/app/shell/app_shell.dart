import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../motion/ambient_background.dart';
import '../motion/enviro_motion.dart';
import '../motion/motion_widgets.dart';
import '../../core/preferences/app_preferences.dart';

/// UI shell for Overview, Room, Trends, Devices, and Settings.
/// Hardware pairing is intentionally deferred; the Devices-tab action is an
/// informational preview until the hardware integration phase.
class EnviroSenseShell extends ConsumerStatefulWidget {
  const EnviroSenseShell({
    required this.pages,
    required this.onAddDevice,
    this.roomAccent = EnviroPalette.teal,
    this.initialPage = 0,
    super.key,
  })  : assert(pages.length == 5, 'Provide exactly five top-level pages.'),
        assert(initialPage >= 0 && initialPage < 5);

  final List<Widget> pages;
  final VoidCallback onAddDevice;
  final Color roomAccent;
  final int initialPage;

  static const pageNames = <String>[
    'Overview',
    'Room View',
    'Trends',
    'Devices',
    'Settings',
  ];

  static const pageAccents = <Color>[
    EnviroPalette.brass,
    EnviroPalette.teal,
    EnviroPalette.teal,
    EnviroPalette.brass,
    EnviroPalette.textMuted,
  ];

  static List<Color> pageAccentsFor(Color roomAccent) => [
    EnviroPalette.brass,
    roomAccent,
    EnviroPalette.teal,
    EnviroPalette.brass,
    EnviroPalette.textMuted,
  ];

  @override
  ConsumerState<EnviroSenseShell> createState() => _EnviroSenseShellState();
}

class _EnviroSenseShellState extends ConsumerState<EnviroSenseShell> {
  late final PageController _pageController;
  late final ValueNotifier<double> _pageProgress;
  int _currentPage = 0;
  bool _reduceMotion = false;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialPage;
    _pageController = PageController(initialPage: widget.initialPage);
    _pageProgress = ValueNotifier<double>(widget.initialPage.toDouble());
    _pageController.addListener(_syncPageProgress);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.of(context).disableAnimations;
  }

  void _playFeedback() {
    final preferences = ref.read(appPreferencesProvider);
    if (preferences.hapticFeedback) HapticFeedback.selectionClick();
    if (preferences.soundFeedback) SystemSound.play(SystemSoundType.click);
  }

  void _syncPageProgress() {
    if (!_pageController.hasClients) return;
    final page = _pageController.page;
    if (page != null && page.isFinite) _pageProgress.value = page;
  }

  void _selectPage(int index) {
    _playFeedback();
    if (_reduceMotion) {
      _pageController.jumpToPage(index);
      return;
    }
    _pageController.animateToPage(
      index,
      duration: EnviroMotion.pageDuration,
      curve: Curves.easeOutCubic,
    );
  }

  Widget _ambientLayer() {
    return Positioned.fill(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final height = constraints.maxHeight;
          return ClipRect(
            child: ValueListenableBuilder<double>(
              valueListenable: _pageProgress,
              builder: (context, page, _) => OverflowBox(
                alignment: Alignment.centerLeft,
                minWidth: width * 3,
                maxWidth: width * 3,
                minHeight: height,
                maxHeight: height,
                child: Transform.translate(
                  offset: Offset(-page * width * 0.4, 0),
                  child: SizedBox(
                    width: width * 3,
                    height: height,
                    child: AmbientBackground(
                      pageProgress: _pageProgress,
                      accents: EnviroSenseShell.pageAccentsFor(widget.roomAccent),
                      reduceMotion: _reduceMotion,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _pageController.removeListener(_syncPageProgress);
    _pageController.dispose();
    _pageProgress.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final preferences = ref.watch(appPreferencesProvider);
    _reduceMotion = MediaQuery.of(context).disableAnimations ||
        preferences.reducedMotion;
    final safeBottom = MediaQuery.of(context).padding.bottom;
    return Scaffold(
      backgroundColor: EnviroPalette.bg,
      body: Stack(
        fit: StackFit.expand,
        children: [
          _ambientLayer(),
          Theme(
            data: Theme.of(context).copyWith(
              scaffoldBackgroundColor: Colors.transparent,
            ),
            child: PageView.builder(
              controller: _pageController,
              itemCount: widget.pages.length,
              onPageChanged: (index) => setState(() => _currentPage = index),
              physics: _reduceMotion
                  ? const ClampingScrollPhysics(parent: PageScrollPhysics())
                  : const BouncingScrollPhysics(parent: PageScrollPhysics()),
              itemBuilder: (context, index) => AnimatedBuilder(
                animation: _pageController,
                child: RepaintBoundary(child: widget.pages[index]),
                builder: (context, child) {
                  final page = _pageController.hasClients
                      ? (_pageController.page ?? index.toDouble())
                      : index.toDouble();
                  final offset = (page - index).clamp(-1.0, 1.0).toDouble();
                  final distance = offset.abs();
                  final scale = _reduceMotion ? 1.0 : 1 - 0.045 * distance;
                  final tilt = _reduceMotion ? 0.0 : -offset * 0.008;
                  return Opacity(
                    opacity: 1 - 0.22 * distance,
                    child: Transform.translate(
                      offset: Offset(_reduceMotion ? 0 : -offset * 24, 0),
                      child: Transform.rotate(
                        angle: tilt,
                        child: Transform.scale(scale: scale, child: child),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              minimum: const EdgeInsets.only(bottom: 24),
              child: _PageIndicator(
                currentIndex: _currentPage,
                accents: EnviroSenseShell.pageAccentsFor(widget.roomAccent),
                onSelect: _selectPage,
                reduceMotion: _reduceMotion,
              ),
            ),
          ),
          if (_currentPage == 3)
            Positioned(
              right: 20,
              bottom: 78 + safeBottom,
              child: SpringPressable(
                onPressed: () {
                  _playFeedback();
                  widget.onAddDevice();
                },
                reduceMotion: _reduceMotion,
                semanticsLabel: 'Hardware pairing will be added later',
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: EnviroPalette.brass,
                    borderRadius: BorderRadius.circular(100),
                    boxShadow: _reduceMotion
                        ? const []
                        : [
                      BoxShadow(
                        color: EnviroPalette.brass.withValues(alpha: 0.25),
                        blurRadius: 20,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.info_outline_rounded, color: EnviroPalette.bg, size: 18),
                        SizedBox(width: 7),
                        Text(
                          'Hardware later',
                          style: TextStyle(
                            color: EnviroPalette.bg,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PageIndicator extends StatefulWidget {
  const _PageIndicator({
    required this.currentIndex,
    required this.accents,
    required this.onSelect,
    required this.reduceMotion,
  });

  final int currentIndex;
  final List<Color> accents;
  final ValueChanged<int> onSelect;
  final bool reduceMotion;

  @override
  State<_PageIndicator> createState() => _PageIndicatorState();
}

class _PageIndicatorState extends State<_PageIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _position;

  @override
  void initState() {
    super.initState();
    _position = AnimationController.unbounded(
      vsync: this,
      value: widget.currentIndex.toDouble(),
    );
  }

  @override
  void didUpdateWidget(covariant _PageIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentIndex != oldWidget.currentIndex) {
      if (widget.reduceMotion) {
        _position.value = widget.currentIndex.toDouble();
      } else {
        _position.animateWith(
          SpringSimulation(
            EnviroMotion.elementSpring,
            _position.value,
            widget.currentIndex.toDouble(),
            0,
          ),
        );
      }
    } else if (widget.reduceMotion && !oldWidget.reduceMotion) {
      _position.stop();
      _position.value = widget.currentIndex.toDouble();
    }
  }

  @override
  void dispose() {
    _position.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AnimatedBuilder(
        animation: _position,
        builder: (context, _) {
          final position = _position.value;
          return DecoratedBox(
            decoration: BoxDecoration(
              color: EnviroPalette.surfaceGlass,
              borderRadius: BorderRadius.circular(100),
              border: Border.all(color: EnviroPalette.hairline),
              boxShadow: widget.reduceMotion
                  ? const []
                  : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.24),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 5, 9, 5),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 72,
                    child: AnimatedSwitcher(
                      duration: widget.reduceMotion
                          ? Duration.zero
                          : const Duration(milliseconds: 240),
                      transitionBuilder: (child, animation) => FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0.12, 0),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        ),
                      ),
                      child: Align(
                        key: ValueKey<int>(widget.currentIndex),
                        alignment: Alignment.centerLeft,
                        child: Text(
                          EnviroSenseShell.pageNames[widget.currentIndex],
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: EnviroPalette.textPrimary,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 5),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List<Widget>.generate(5, (index) {
                      final influence = (1 - (position - index).abs())
                          .clamp(0.0, 1.0)
                          .toDouble();
                      final color = Color.lerp(
                        Colors.white.withValues(alpha: 0.20),
                        widget.accents[index],
                        influence,
                      )!;
                      return Semantics(
                        button: true,
                        selected: index == widget.currentIndex,
                        label: EnviroSenseShell.pageNames[index],
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => widget.onSelect(index),
                          child: SizedBox(
                            width: 25,
                            height: 34,
                            child: Center(
                              child: AnimatedContainer(
                                duration: widget.reduceMotion
                                    ? Duration.zero
                                    : const Duration(milliseconds: 180),
                                curve: Curves.easeOutCubic,
                                width: 6 + 17 * influence,
                                height: 5,
                                decoration: BoxDecoration(
                                  color: color,
                                  borderRadius: BorderRadius.circular(100),
                                  boxShadow:
                                  influence > 0.05 && !widget.reduceMotion
                                      ? [
                                    BoxShadow(
                                      color: color.withValues(
                                        alpha: 0.30 * influence,
                                      ),
                                      blurRadius: 10 * influence,
                                      spreadRadius: influence,
                                    ),
                                  ]
                                      : const [],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
