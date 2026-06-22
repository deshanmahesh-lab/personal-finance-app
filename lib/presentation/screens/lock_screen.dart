import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/local_auth_service.dart';

class LockScreen extends ConsumerStatefulWidget {
  final Widget child;

  const LockScreen({super.key, required this.child});

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen> with WidgetsBindingObserver, TickerProviderStateMixin {
  bool _isAuthenticated = false;
  bool _isChecking = false;
  bool _isBackground = false;

  late final AnimationController _breathController;
  late final Animation<double> _breath;

  static const Color _accent = Color(0xFF182D92);
  static const Color _accentSoft = Color(0xFF3A52C9);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _breathController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat(reverse: true);
    _breath = CurvedAnimation(parent: _breathController, curve: Curves.easeInOut);

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _checkAndAuthenticate();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _breathController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      setState(() {
        _isAuthenticated = false;
        _isBackground = true;
      });
    } else if (state == AppLifecycleState.resumed) {
      setState(() => _isBackground = false);
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted && !_isAuthenticated) _checkAndAuthenticate();
      });
    }
  }

  Future<void> _checkAndAuthenticate() async {
    if (_isChecking) return;
    setState(() => _isChecking = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final isLockEnabled = prefs.getBool('app_lock_enabled') ?? false;

      if (!isLockEnabled) {
        if (mounted) {
          setState(() {
            _isAuthenticated = true;
            _isChecking = false;
          });
        }
        return;
      }

      final authenticated = await LocalAuthService.authenticate();

      if (mounted) {
        setState(() {
          _isAuthenticated = authenticated;
          _isChecking = false;
        });
      }
    } catch (e) {
      debugPrint("Authentication Error: $e");
      if (mounted) {
        setState(() {
          _isAuthenticated = false;
          _isChecking = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isAuthenticated && !_isBackground) return widget.child;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF121212) : const Color(0xFFFCFDFC);
    final titleColor = isDark ? Colors.white : const Color(0xFF0A0F2C);
    final subtitleColor = isDark ? Colors.white.withOpacity(0.55) : const Color(0xFF5A6175);

    if (_isBackground) {
      return Scaffold(backgroundColor: bgColor, body: Center(child: Icon(Icons.lock_rounded, size: 64, color: _accent.withOpacity(0.4))));
    }

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          Positioned(top: -120, left: -80, child: _AmbientOrb(size: 360, color: _accent.withOpacity(isDark ? 0.35 : 0.18))),
          Positioned(bottom: -140, right: -100, child: _AmbientOrb(size: 420, color: _accentSoft.withOpacity(isDark ? 0.28 : 0.14))),
          Positioned(top: 280, right: -60, child: _AmbientOrb(size: 200, color: _accent.withOpacity(isDark ? 0.22 : 0.10))),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                children: [
                  const Spacer(flex: 2),

                  AnimatedBuilder(
                    animation: _breath,
                    builder: (context, child) {
                      final scale = 0.96 + (_breath.value * 0.08);
                      final glow = 0.35 + (_breath.value * 0.35);
                      return Transform.scale(
                        scale: scale,
                        child: Container(
                          width: 180, height: 180,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(colors: [_accent.withOpacity(isDark ? 0.30 : 0.18), _accent.withOpacity(0.0)]),
                            boxShadow: [BoxShadow(color: _accent.withOpacity(glow * 0.55), blurRadius: 60, spreadRadius: 8)],
                          ),
                          child: Center(
                            child: Container(
                              width: 130, height: 130,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                                  colors: isDark ? [Colors.white.withOpacity(0.10), Colors.white.withOpacity(0.02)] : [Colors.white.withOpacity(0.85), Colors.white.withOpacity(0.45)],
                                ),
                                border: Border.all(color: Colors.white.withOpacity(isDark ? 0.18 : 0.6), width: 1.2),
                                boxShadow: [BoxShadow(color: _accent.withOpacity(0.25), blurRadius: 30, offset: const Offset(0, 12))],
                              ),
                              child: ShaderMask(
                                shaderCallback: (rect) => const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [_accentSoft, _accent]).createShader(rect),
                                child: const Icon(Icons.fingerprint_rounded, size: 72, color: Colors.white),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  const Spacer(flex: 1),

                  Text('Luxe Finance', style: TextStyle(fontSize: 38, fontWeight: FontWeight.w800, letterSpacing: -1.0, color: titleColor)),
                  const SizedBox(height: 12),
                  Text('App Locked. Authenticate to continue.', textAlign: TextAlign.center, style: TextStyle(fontSize: 15, height: 1.4, letterSpacing: 0.2, color: subtitleColor, fontWeight: FontWeight.w400)),

                  const Spacer(flex: 3),

                  _UnlockButton(
                    isLoading: _isChecking,
                    onPressed: _checkAndAuthenticate,
                    accent: _accent,
                    accentSoft: _accentSoft,
                  ),
                  const SizedBox(height: 20),
                  Text('Secured by Biometric Authentication', style: TextStyle(fontSize: 12, color: subtitleColor, letterSpacing: 0.4)),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AmbientOrb extends StatelessWidget {
  final double size; final Color color;
  const _AmbientOrb({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(width: size, height: size, decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [color, color.withOpacity(0)]))),
    );
  }
}

class _UnlockButton extends StatelessWidget {
  final bool isLoading; final VoidCallback onPressed; final Color accent; final Color accentSoft;

  const _UnlockButton({required this.isLoading, required this.onPressed, required this.accent, required this.accentSoft});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250), curve: Curves.easeOut,
        height: 64, width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(40),
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [accentSoft, accent]),
          boxShadow: [
            BoxShadow(color: accent.withOpacity(0.45), blurRadius: 30, offset: const Offset(0, 14)),
            BoxShadow(color: accent.withOpacity(0.20), blurRadius: 8, offset: const Offset(0, 4)),
          ],
        ),
        child: Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: isLoading
                ? const SizedBox(key: ValueKey('loading'), width: 26, height: 26, child: CircularProgressIndicator(strokeWidth: 2.6, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                : const Row(
              key: ValueKey('idle'),
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.fingerprint_rounded, color: Colors.white, size: 24),
                SizedBox(width: 12),
                Text('Unlock App', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w600, letterSpacing: 0.4)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}