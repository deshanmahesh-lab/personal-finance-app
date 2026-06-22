import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'security_setup_screen.dart';
import '../../providers/language_provider.dart';
import '../../../utils/app_translations.dart';

class PermissionsScreen extends ConsumerStatefulWidget {
  const PermissionsScreen({super.key});

  @override
  ConsumerState<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends ConsumerState<PermissionsScreen> {
  // වර්ණ සැකසුම්
  final Color primaryBlue = const Color(0xFF182D92);
  final Color backgroundLight = const Color(0xFFFCFDFC);
  final Color successGreen = const Color(0xFF10B981);

  // අවසර ලබා දී ඇතිදැයි පරීක්ෂා කරන විචල්‍යයන්
  bool _smsPermissionGranted = false;
  bool _notificationPermissionGranted = false;

  @override
  void initState() {
    super.initState();
    _checkInitialPermissions(); // තිරය විවෘත වනවිටම අවසර පරීක්ෂා කිරීම
  }

  Future<void> _checkInitialPermissions() async {
    final smsStatus = await Permission.sms.isGranted;
    final notificationStatus = await Permission.notification.isGranted;

    if (mounted) {
      setState(() {
        _smsPermissionGranted = smsStatus;
        _notificationPermissionGranted = notificationStatus;
      });
    }
  }

  Future<void> _requestSmsPermission() async {
    final status = await Permission.sms.request();
    final currentLang = ref.read(languageProvider);

    if (status.isGranted) {
      setState(() => _smsPermissionGranted = true);
    } else if (status.isPermanentlyDenied) {
      _showSettingsDialog(currentLang == 'සිංහල' ? 'SMS අවසරය' : (currentLang == 'தமிழ்' ? 'SMS அனுமதி' : 'SMS Permission'));
    }
  }

  Future<void> _requestNotificationPermission() async {
    final status = await Permission.notification.request();
    final currentLang = ref.read(languageProvider);

    if (status.isGranted) {
      setState(() => _notificationPermissionGranted = true);
    } else if (status.isPermanentlyDenied) {
      _showSettingsDialog(currentLang == 'සිංහල' ? 'දැනුම්දීම් අවසරය' : (currentLang == 'தமிழ்' ? 'அறிவிப்பு அனுமதி' : 'Notification Permission'));
    }
  }

  // Settings වෙත යොමු කරන Dialog එක (භාෂාවට අනුව පරිවර්තනය වේ)
  void _showSettingsDialog(String permissionName) {
    final currentLang = ref.read(languageProvider);

    final title = currentLang == 'සිංහල' ? '$permissionName අවශ්‍යයි' : (currentLang == 'தமிழ்' ? '$permissionName தேவை' : '$permissionName Required');
    final content = currentLang == 'සිංහල'
        ? 'කරුණාකර App Settings වෙත ගොස් $permissionName ලබා දෙන්න.'
        : (currentLang == 'தமிழ்' ? 'தயவுசெய்து App Settings சென்று $permissionName வழங்கவும்.' : 'Please open App Settings and grant the $permissionName to continue.');
    final cancelBtn = currentLang == 'සිංහල' ? 'අවලංගු කරන්න' : (currentLang == 'தமிழ்' ? 'ரத்துசெய்' : 'Cancel');
    final openBtn = currentLang == 'සිංහල' ? 'Settings විවෘත කරන්න' : (currentLang == 'தமிழ்' ? 'அமைப்புகளைத் திற' : 'Open Settings');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(cancelBtn),
          ),
          TextButton(
            onPressed: () {
              openAppSettings();
              Navigator.pop(context);
            },
            child: Text(openBtn),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 1. තේරූ භාෂාවට අදාළව තිරයේ වචන (Translations) ලබා ගැනීම
    final currentLanguage = ref.watch(languageProvider);
    final mainTitle = AppTranslations.getText('permissions_title', currentLanguage);
    final subTitle = AppTranslations.getText('permissions_desc', currentLanguage);
    final smsTitle = AppTranslations.getText('sms_perm_title', currentLanguage);
    final smsDesc = AppTranslations.getText('sms_perm_desc', currentLanguage);
    final notiTitle = AppTranslations.getText('noti_perm_title', currentLanguage);
    final notiDesc = AppTranslations.getText('noti_perm_desc', currentLanguage);
    final btnText = AppTranslations.getText('continue_btn', currentLanguage);

    // 2. අලංකාර වර්ණ සැකසුම් (Light / Dark Mode සඳහා)
    final Brightness brightness = Theme.of(context).brightness;
    final bool isDark = brightness == Brightness.dark;
    final Color backgroundColor = isDark ? const Color(0xFF121212) : backgroundLight;
    final Color textPrimary = isDark ? Colors.white : const Color(0xFF111827);
    final Color textSecondary = isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        bottom: true,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  // ආපසු යාමේ බොත්තම
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                    color: textPrimary,
                    splashRadius: 24,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(height: 32),

                  // මාතෘකාව
                  Text(
                    mainTitle,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                      height: 1.15,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // උප මාතෘකාව
                  Text(
                    subTitle,
                    style: TextStyle(
                      fontSize: 16,
                      color: textSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // SMS අවසර කාඩ්පත
                  PermissionCard(
                    title: smsTitle,
                    description: smsDesc,
                    icon: Icons.sms_outlined,
                    grantedIcon: Icons.check_circle,
                    isGranted: _smsPermissionGranted,
                    successGreen: successGreen,
                    primaryBlue: primaryBlue,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    onTap: _smsPermissionGranted ? () {} : _requestSmsPermission,
                  ),
                  const SizedBox(height: 16),

                  // Notification අවසර කාඩ්පත
                  PermissionCard(
                    title: notiTitle,
                    description: notiDesc,
                    icon: Icons.notifications_outlined,
                    grantedIcon: Icons.check_circle,
                    isGranted: _notificationPermissionGranted,
                    successGreen: successGreen,
                    primaryBlue: primaryBlue,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    onTap: _notificationPermissionGranted ? () {} : _requestNotificationPermission,
                  ),
                  const Spacer(),

                  // Continue බොත්තම
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 280),
                    curve: Curves.easeOutCubic,
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      color: _smsPermissionGranted ? primaryBlue : const Color(0xFFE5E7EB),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: _smsPermissionGranted
                          ? [
                        BoxShadow(
                          color: primaryBlue.withOpacity(0.35),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ]
                          : [],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _smsPermissionGranted
                            ? () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const SecuritySetupScreen()),
                          );
                        }
                            : null,
                        borderRadius: BorderRadius.circular(16),
                        splashColor: Colors.white.withOpacity(0.15),
                        highlightColor: Colors.white.withOpacity(0.08),
                        child: Center(
                          child: Text(
                            btnText,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: _smsPermissionGranted ? Colors.white : const Color(0xFF9CA3AF),
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// අවසර කාඩ්පත් සඳහා වන අලංකාර සැකිල්ල
class PermissionCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final IconData grantedIcon;
  final bool isGranted;
  final Color successGreen;
  final Color primaryBlue;
  final Color textPrimary;
  final Color textSecondary;
  final VoidCallback onTap;

  const PermissionCard({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.grantedIcon,
    required this.isGranted,
    required this.successGreen,
    required this.primaryBlue,
    required this.textPrimary,
    required this.textSecondary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: isGranted ? successGreen.withOpacity(0.05) : Colors.transparent,
        border: Border.all(
          color: isGranted ? successGreen : const Color(0xFFE5E7EB),
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          splashColor: primaryBlue.withOpacity(0.08),
          highlightColor: primaryBlue.withOpacity(0.04),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: isGranted
                        ? successGreen.withOpacity(0.12)
                        : const Color(0xFFF3F4F6),
                    shape: BoxShape.circle,
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 240),
                    transitionBuilder: (child, animation) {
                      return ScaleTransition(scale: animation, child: child);
                    },
                    child: Icon(
                      isGranted ? grantedIcon : icon,
                      key: ValueKey<bool>(isGranted),
                      color: isGranted ? successGreen : const Color(0xFF6B7280),
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 14,
                          color: textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                AnimatedOpacity(
                  opacity: isGranted ? 0.0 : 1.0,
                  duration: const Duration(milliseconds: 200),
                  child: const Icon(
                    Icons.chevron_right,
                    color: Color(0xFFD1D5DB),
                    size: 24,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}