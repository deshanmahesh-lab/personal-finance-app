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
  bool _smsPermissionGranted = false;
  bool _notificationPermissionGranted = false;

  @override
  void initState() {
    super.initState();
    _checkInitialPermissions();
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
    final canProceed = _smsPermissionGranted;
    final currentLanguage = ref.watch(languageProvider);

    final mainTitle = AppTranslations.getText('permissions_title', currentLanguage);
    final subTitle = AppTranslations.getText('permissions_desc', currentLanguage);
    final smsTitle = AppTranslations.getText('sms_perm_title', currentLanguage);
    final smsDesc = AppTranslations.getText('sms_perm_desc', currentLanguage);
    final notiTitle = AppTranslations.getText('noti_perm_title', currentLanguage);
    final notiDesc = AppTranslations.getText('noti_perm_desc', currentLanguage);
    final btnText = AppTranslations.getText('continue_btn', currentLanguage);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios, size: 24),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ),
              const SizedBox(height: 24),

              Text(mainTitle, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, height: 1.3)),
              const SizedBox(height: 12),
              Text(subTitle, style: TextStyle(fontSize: 16, color: Colors.grey.shade600)),
              const SizedBox(height: 40),

              _PermissionCard(
                icon: Icons.sms_outlined,
                title: smsTitle,
                description: smsDesc,
                isGranted: _smsPermissionGranted,
                onTap: _smsPermissionGranted ? null : _requestSmsPermission,
              ),
              const SizedBox(height: 16),
              _PermissionCard(
                icon: Icons.notifications_active_outlined,
                title: notiTitle,
                description: notiDesc,
                isGranted: _notificationPermissionGranted,
                onTap: _notificationPermissionGranted ? null : _requestNotificationPermission,
              ),

              const Spacer(),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: canProceed ? () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SecuritySetupScreen()),
                    );
                  } : null,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade300,
                  ),
                  child: Text(btnText, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PermissionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final bool isGranted;
  final VoidCallback? onTap;

  const _PermissionCard({required this.icon, required this.title, required this.description, required this.isGranted, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isGranted ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.05),
          border: Border.all(color: isGranted ? Colors.green : Colors.grey.shade300, width: 2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(isGranted ? Icons.check_circle : icon, color: isGranted ? Colors.green : Colors.grey.shade600, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isGranted ? Colors.green.shade700 : null)),
                  const SizedBox(height: 4),
                  Text(description, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}