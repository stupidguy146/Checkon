import 'dart:ui' show FragmentProgram, FragmentShader, ImageFilter;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/customer_profile.dart';
import '../services/customer_service.dart';
import '../theme/app_tokens.dart';
import '../i18n/locale_scope.dart';
import '../widgets/app_widgets.dart';
import '../widgets/auth_scope.dart';
import 'change_password_screen.dart';
import 'change_pin_screen.dart';
import 'edit_profile_screen.dart';
import 'home_screen.dart';
import 'items_screen.dart';
import 'budget_screen.dart';
import 'to_buy_screen.dart';
import 'settings_screen.dart';
import 'product_master_screen.dart';

/// Main app shell with Checkon's five-tab bottom navigation.
class MainShell extends StatefulWidget {
  final bool showStartupArtwork;

  const MainShell({
    super.key,
    this.showStartupArtwork = true,
  });

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;
  bool _homeReady = false;

  void _goItems() => setState(() => _index = 1);

  void _onHomeReady() {
    if (_homeReady || !mounted) return;
    setState(() => _homeReady = true);
  }

  void _selectTab(int index) {
    if (index == _index) return;
    HapticFeedback.selectionClick();
    setState(() => _index = index);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.strings;
    final pages = [
      HomeScreen(
        onSeeAllItems: _goItems,
        onInitialLoadComplete: _onHomeReady,
        showStartupArtwork: widget.showStartupArtwork,
      ),
      const ItemsScreen(),
      const ToBuyScreen(),
      const BudgetScreen(),
      const _MenuScreen(),
    ];
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          IndexedStack(index: _index, children: pages),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            child: _homeReady || !widget.showStartupArtwork
                ? const SizedBox.shrink(key: ValueKey('home-ready'))
                : const StartupLoadingView(
                    key: ValueKey('home-startup-artwork'),
                  ),
          ),
        ],
      ),
      bottomNavigationBar: _homeReady || !widget.showStartupArtwork
          ? _GlassNavigationBar(
              selectedIndex: _index,
              onDestinationSelected: _selectTab,
              destinations: [
                _GlassNavItem(
                  icon: Icons.home_outlined,
                  selectedIcon: Icons.home_rounded,
                  label: s.navHome,
                ),
                _GlassNavItem(
                  icon: Icons.inventory_2_outlined,
                  selectedIcon: Icons.inventory_2_rounded,
                  label: s.navItems,
                ),
                _GlassNavItem(
                  icon: Icons.shopping_cart_outlined,
                  selectedIcon: Icons.shopping_cart_rounded,
                  label: s.navToBuy,
                ),
                _GlassNavItem(
                  icon: Icons.account_balance_wallet_outlined,
                  selectedIcon: Icons.account_balance_wallet_rounded,
                  label: s.navBudget,
                ),
                _GlassNavItem(
                  icon: Icons.menu_rounded,
                  selectedIcon: Icons.menu_open_rounded,
                  label: s.navMenu,
                ),
              ],
            )
          : null,
    );
  }
}

class _GlassNavItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;

  const _GlassNavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });
}

class _GlassNavigationBar extends StatefulWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<_GlassNavItem> destinations;

  const _GlassNavigationBar({
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinations,
  });

  @override
  State<_GlassNavigationBar> createState() => _GlassNavigationBarState();
}

class _GlassNavigationBarState extends State<_GlassNavigationBar> {
  late double _indicatorPosition = widget.selectedIndex.toDouble();
  late final Future<FragmentProgram> _glassProgram =
      FragmentProgram.fromAsset('shaders/glass_lens.frag');
  bool _isDragging = false;
  bool _shaderErrorReported = false;

  @override
  void didUpdateWidget(covariant _GlassNavigationBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isDragging && oldWidget.selectedIndex != widget.selectedIndex) {
      _indicatorPosition = widget.selectedIndex.toDouble();
    }
  }

  void _updateDragPosition(double dx, double width) {
    final count = widget.destinations.length;
    if (width <= 0 || count == 0) return;

    final cellWidth = width / count;
    final position = (dx / cellWidth - 0.5).clamp(0.0, count - 1.0);
    final nextIndex = position.round().clamp(0, count - 1);
    if (position != _indicatorPosition) {
      setState(() => _indicatorPosition = position);
    }
    if (nextIndex != widget.selectedIndex) {
      widget.onDestinationSelected(nextIndex);
    }
  }

  void _finishDrag() {
    if (!_isDragging) return;
    setState(() {
      _isDragging = false;
      _indicatorPosition = widget.selectedIndex.toDouble();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final selectedColor = isDark ? AppColors.brand300 : AppColors.brand500;
    final unselectedColor =
        isDark ? AppColors.darkTextMuted : AppColors.neutral600;
    final radius = BorderRadius.circular(28);

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        child: ClipRRect(
          borderRadius: radius,
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: AppGlass.blurSigma,
              sigmaY: AppGlass.blurSigma,
            ),
            child: Container(
              height: 72,
              decoration: BoxDecoration(
                color: isDark
                    ? AppSurfaces.darkGlass.withValues(alpha: 0.82)
                    : AppColors.iceBlue.withValues(alpha: 0.58),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [
                          AppColors.skyBlue.withValues(alpha: 0.16),
                          AppColors.aqua.withValues(alpha: 0.045),
                        ]
                      : [
                          Colors.white.withValues(alpha: 0.84),
                          AppColors.skyBlue.withValues(alpha: 0.23),
                        ],
                ),
                borderRadius: radius,
                border: Border.all(
                  color: isDark
                      ? AppColors.skyBlue.withValues(alpha: 0.34)
                      : AppColors.skyBlue.withValues(alpha: 0.5),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? Colors.black.withValues(alpha: 0.22)
                        : AppColors.oceanBlue.withValues(alpha: 0.12),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                  BoxShadow(
                    color: AppColors.skyBlue.withValues(
                      alpha: isDark ? 0.08 : 0.16,
                    ),
                    blurRadius: 1,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onHorizontalDragStart: (details) {
                      setState(() => _isDragging = true);
                      _updateDragPosition(
                        details.localPosition.dx,
                        constraints.maxWidth,
                      );
                    },
                    onHorizontalDragUpdate: (details) => _updateDragPosition(
                      details.localPosition.dx,
                      constraints.maxWidth,
                    ),
                    onHorizontalDragEnd: (_) => _finishDrag(),
                    onHorizontalDragCancel: _finishDrag,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        AnimatedAlign(
                          alignment: Alignment(
                            widget.destinations.length == 1
                                ? 0
                                : -1 +
                                    (2 * _indicatorPosition) /
                                        (widget.destinations.length - 1),
                            0,
                          ),
                          duration: _isDragging
                              ? Duration.zero
                              : AppMotion.duration(
                                  context,
                                  const Duration(milliseconds: 520),
                                ),
                          curve:
                              _isDragging ? Curves.linear : Curves.easeOutBack,
                          child: FractionallySizedBox(
                            widthFactor: 1 / widget.destinations.length,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 3,
                                vertical: 6,
                              ),
                              child: _GlassSelectionPill(isDark: isDark),
                            ),
                          ),
                        ),
                        FutureBuilder<FragmentProgram>(
                          future: _glassProgram,
                          builder: (context, snapshot) {
                            if (snapshot.hasError && !_shaderErrorReported) {
                              _shaderErrorReported = true;
                              FlutterError.reportError(
                                FlutterErrorDetails(
                                  exception: snapshot.error!,
                                  stack: snapshot.stackTrace,
                                  library: 'Checkon glass navigation',
                                  context: ErrorDescription(
                                    'while loading the glass refraction shader',
                                  ),
                                ),
                              );
                            }
                            return _GlassNavContent(
                              program: snapshot.data,
                              lensCenter: (_indicatorPosition + 0.5) /
                                  widget.destinations.length,
                              lensWidth: constraints.maxWidth /
                                      widget.destinations.length -
                                  6,
                              lensHeight: constraints.maxHeight - 12,
                              isDragging: _isDragging,
                              child: Row(
                                children: [
                                  for (var i = 0;
                                      i < widget.destinations.length;
                                      i++)
                                    Expanded(
                                      child: _GlassNavigationDestination(
                                        item: widget.destinations[i],
                                        selected: widget.selectedIndex == i,
                                        selectedColor: selectedColor,
                                        unselectedColor: unselectedColor,
                                        onTap: () =>
                                            widget.onDestinationSelected(i),
                                      ),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassSelectionPill extends StatelessWidget {
  final bool isDark;

  const _GlassSelectionPill({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(22);
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.skyBlue.withValues(alpha: 0.13)
            : Colors.white.withValues(alpha: 0.32),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  Colors.white.withValues(alpha: 0.17),
                  AppColors.skyBlue.withValues(alpha: 0.045),
                ]
              : [
                  Colors.white.withValues(alpha: 0.68),
                  AppColors.skyBlue.withValues(alpha: 0.17),
                ],
        ),
        borderRadius: radius,
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.35)
              : Colors.white.withValues(alpha: 0.86),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.skyBlue.withValues(
              alpha: isDark ? 0.12 : 0.2,
            ),
            blurRadius: 16,
            offset: const Offset(0, 3),
          ),
        ],
      ),
    );
  }
}

class _GlassNavContent extends StatefulWidget {
  final FragmentProgram? program;
  final double lensCenter;
  final double lensWidth;
  final double lensHeight;
  final bool isDragging;
  final Widget child;

  const _GlassNavContent({
    required this.program,
    required this.lensCenter,
    required this.lensWidth,
    required this.lensHeight,
    required this.isDragging,
    required this.child,
  });

  @override
  State<_GlassNavContent> createState() => _GlassNavContentState();
}

class _GlassNavContentState extends State<_GlassNavContent> {
  FragmentShader? _shader;

  @override
  void initState() {
    super.initState();
    _shader = widget.program?.fragmentShader();
  }

  @override
  void didUpdateWidget(covariant _GlassNavContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.program != widget.program) {
      _shader?.dispose();
      _shader = widget.program?.fragmentShader();
    }
  }

  @override
  void dispose() {
    _shader?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shader = _shader;
    if (shader == null || !ImageFilter.isShaderFilterSupported) {
      return widget.child;
    }

    final pixelRatio = MediaQuery.devicePixelRatioOf(context);
    shader
      ..setFloat(2, widget.lensCenter)
      ..setFloat(3, 0.5)
      ..setFloat(4, widget.lensWidth * pixelRatio / 2)
      ..setFloat(5, widget.lensHeight * pixelRatio / 2)
      ..setFloat(6, 22 * pixelRatio)
      ..setFloat(7, (widget.isDragging ? 3.5 : 2.5) * pixelRatio);
    return ImageFiltered(
      imageFilter: ImageFilter.shader(shader),
      child: widget.child,
    );
  }
}

class _GlassNavigationDestination extends StatelessWidget {
  final _GlassNavItem item;
  final bool selected;
  final Color selectedColor;
  final Color unselectedColor;
  final VoidCallback onTap;

  const _GlassNavigationDestination({
    required this.item,
    required this.selected,
    required this.selectedColor,
    required this.unselectedColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final foreground = selected ? selectedColor : unselectedColor;
    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      child: Tooltip(
        message: item.label,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            splashFactory: NoSplash.splashFactory,
            overlayColor: const WidgetStatePropertyAll(Colors.transparent),
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            focusColor: Colors.transparent,
            hoverColor: Colors.transparent,
            customBorder: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 2,
                vertical: 5,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedSwitcher(
                    duration: AppMotion.duration(
                      context,
                      AppDurations.interactiveTransition,
                    ),
                    switchInCurve: Curves.easeOutBack,
                    switchOutCurve: Curves.easeIn,
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: ScaleTransition(
                        scale: animation.drive(
                          Tween<double>(begin: 0.72, end: 1),
                        ),
                        child: child,
                      ),
                    ),
                    child: Icon(
                      selected ? item.selectedIcon : item.icon,
                      key: ValueKey(selected ? item.selectedIcon : item.icon),
                      color: foreground,
                      size: 22,
                    ),
                  ),
                  const SizedBox(height: 3),
                  AnimatedDefaultTextStyle(
                    duration: AppMotion.duration(
                      context,
                      AppDurations.interactiveTransition,
                    ),
                    curve: Curves.easeOutCubic,
                    style: AppType.caption.copyWith(
                      color: foreground,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                    child: Text(
                      item.label,
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MenuScreen extends StatefulWidget {
  const _MenuScreen();

  @override
  State<_MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<_MenuScreen> {
  CustomerService? _customer;
  Future<CustomerProfile>? _profile;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_customer == null) {
      _customer = CustomerService(auth: AuthScope.of(context));
      _profile = _customer!.getMyProfile();
    }
  }

  Future<void> _editProfile() async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const EditProfileScreen()),
    );
    if (changed == true && mounted) {
      setState(() {
        _profile = _customer!.getMyProfile();
      });
    }
  }

  Future<void> _confirmLogout() async {
    final s = context.strings;
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: Theme.of(dialogContext).cardTheme.color,
        insetPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.rXl),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: AppColors.coralTint,
                    borderRadius: AppRadius.rLg,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.danger.withValues(alpha: 0.22),
                        blurRadius: 22,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.logout_rounded,
                    color: AppColors.danger,
                    size: 28,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  s.logoutConfirmTitle,
                  style: Theme.of(dialogContext).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  s.logoutConfirmMessage,
                  style: Theme.of(dialogContext).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xl),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(dialogContext, false),
                        child: Text(s.cancel),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.danger,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm),
                        ),
                        onPressed: () => Navigator.pop(dialogContext, true),
                        icon: const Icon(Icons.logout_rounded, size: 18),
                        label: Flexible(
                          child: Text(
                            s.logout,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            softWrap: false,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (shouldLogout == true && mounted) {
      // read scopes before the first await to avoid using a stale context
      final auth = AuthScope.read(context);
      await auth.logout(); // keeps the device PIN and clears the login session
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.strings;
    return Scaffold(
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          GradientHeader(
            title: s.navMenu,
            titleIcon: Icons.menu_rounded,
            centerTitle: false,
            logoBackground: false,
            logoAsset:
                'assets/images/logos/953b0995-0966-4844-9cac-afe275ac9282.png',
            logoHeight: 64,
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.lg,
              AppSpacing.xl,
              AppSpacing.lg,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
                FutureBuilder<CustomerProfile>(
                  future: _profile,
                  builder: (context, snapshot) {
                    final profile = snapshot.data;
                    final bytes = _decodeAvatar(profile?.avatarBase64);
                    final name = profile?.fullName.isNotEmpty == true
                        ? profile!.fullName
                        : profile?.username ?? s.myProfile;
                    return AppCard(
                      onTap: _editProfile,
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: AppColors.brand100,
                            backgroundImage:
                                bytes == null ? null : MemoryImage(bytes),
                            child: bytes == null
                                ? const Icon(Icons.person_rounded,
                                    color: AppColors.brand500, size: 32)
                                : null,
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(name,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium),
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  profile?.username.isNotEmpty == true
                                      ? '@${profile!.username} · ${s.editProfile}'
                                      : s.editProfile,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                _MenuOption(
                  icon: Icons.inventory_2_outlined,
                  label: s.productsMenu,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const ProductMasterScreen()),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                _MenuOption(
                  icon: Icons.lock_reset_rounded,
                  label: s.changePassword,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const ChangePasswordScreen()),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                _MenuOption(
                  icon: Icons.pin_rounded,
                  label: s.changePinMenu,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ChangePinScreen()),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                _MenuOption(
                  icon: Icons.settings_outlined,
                  label: s.settings,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                _MenuOption(
                  icon: Icons.logout_rounded,
                  label: s.logout,
                  color: AppColors.danger,
                  onTap: _confirmLogout,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Uint8List? _decodeAvatar(String? avatar) {
    if (avatar == null || avatar.isEmpty) return null;
    try {
      return base64Decode(
          avatar.contains(',') ? avatar.split(',').last : avatar);
    } catch (_) {
      return null;
    }
  }
}

class _MenuOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  const _MenuOption({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = AppColors.brand500,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.titleMedium),
          ),
          const Icon(Icons.chevron_right_rounded),
        ],
      ),
    );
  }
}
