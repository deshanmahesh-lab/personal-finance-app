import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/local_auth_service.dart';

// [වෙනස] Provider භාවිතා කිරීම සඳහා ConsumerStatefulWidget බවට පත් කර ඇත
class LockScreen extends ConsumerStatefulWidget {
  final Widget child;

  const LockScreen({super.key, required this.child});

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen> with WidgetsBindingObserver {
  bool _isAuthenticated = false;
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) {
        _checkAndAuthenticate();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      setState(() => _isAuthenticated = false);
    } else if (state == AppLifecycleState.resumed && !_isAuthenticated) {
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (mounted) {
          _checkAndAuthenticate();
        }
      });
    }
  }

  Future<void> _checkAndAuthenticate() async {
    if (_isChecking) return;
    setState(() => _isChecking = true);

    // [නව තර්කය] App Lock එක Settings වලින් Off කර ඇත්දැයි බැලීම
    final prefs = await SharedPreferences.getInstance();
    final isLockEnabled = prefs.getBool('isAppLockEnabled') ?? true;

    if (!isLockEnabled) {
      if (mounted) {
        setState(() {
          _isAuthenticated = true; // Lock කර නැත්නම් කෙලින්ම ඇතුළට යවයි
          _isChecking = false;
        });
      }
      return;
    }

    // Lock කර ඇත්නම් පමණක් Fingerprint ඉල්ලයි
    final authenticated = await LocalAuthService.authenticate();

    if (mounted) {
      setState(() {
        _isAuthenticated = authenticated;
        _isChecking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isAuthenticated) {
      return widget.child;
    }

    return Scaffold(
      backgroundColor: Colors.blue.shade900,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.1)),
              child: const Icon(Icons.lock_outline_rounded, size: 80, color: Colors.white),
            ),
            const SizedBox(height: 32),
            const Text('App Locked', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 16),
            Text('Your financial data is secure.', style: TextStyle(fontSize: 16, color: Colors.blue.shade100)),
            const SizedBox(height: 48),
            _isChecking
                ? const CircularProgressIndicator(color: Colors.white)
                : ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.blue.shade900, padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)), elevation: 0),
              icon: const Icon(Icons.fingerprint_rounded, size: 24),
              label: const Text('Tap to Unlock', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              onPressed: _checkAndAuthenticate,
            ),
          ],
        ),
      ),
    );
  }
}