import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/theme_provider.dart';
import '../providers/database_provider.dart';
import '../providers/app_lock_provider.dart';
import '../providers/language_provider.dart';
import '../../utils/app_translations.dart';
import '../../services/sms_parser_service.dart';
import '../../services/google_drive_backup_service.dart';
import 'onboarding/splash_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  static const Color kPrimary = Color(0xFF182D92);
  static const Color kLightBg = Color(0xFFF9FAFB);
  static const Color kDarkBg = Color(0xFF121212);

  // --- Backend Logic Functions ---

  Future<bool> _hasInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }

  void _showLoadingDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return PopScope(
          canPop: false,
          child: AlertDialog(
            content: Row(
              children: [
                const CircularProgressIndicator(),
                const SizedBox(width: 24),
                Expanded(child: Text(message, style: const TextStyle(fontWeight: FontWeight.bold))),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleBackup() async {
    if (!await _hasInternetConnection()) {
      if (mounted) _snack('No internet connection! Please connect to Wi-Fi or Mobile Data.', isError: true);
      return;
    }
    _showLoadingDialog(context, 'Backing up to Google Drive...');
    try {
      final service = ref.read(backupServiceProvider);
      final success = await service.backupDatabase();
      if (mounted) {
        Navigator.pop(context);
        _snack(success ? 'Backup Successful!' : 'Backup Cancelled.', isError: !success);
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        _snack('Error: $e', isError: true);
      }
    }
  }

  Future<void> _handleRestore() async {
    if (!await _hasInternetConnection()) {
      if (mounted) _snack('No internet connection!', isError: true);
      return;
    }
    _showLoadingDialog(context, 'Restoring from Google Drive...');
    try {
      final service = ref.read(backupServiceProvider);
      final success = await service.restoreDatabase();
      if (mounted) {
        Navigator.pop(context);
        if (success) {
          _snack('Restore Successful! Restarting app...');
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const SplashScreen()),
                (Route<dynamic> route) => false,
          );
        } else {
          _snack('Restore Cancelled.', isError: true);
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        _snack('Error: $e', isError: true);
      }
    }
  }

  Future<void> _handleChangeAccount() async {
    try {
      final service = ref.read(backupServiceProvider);
      await service.signOut();
      if (mounted) _snack('Google Account Disconnected!');
    } catch (e) {
      if (mounted) _snack('Error: $e', isError: true);
    }
  }

  Future<void> _syncSms() async {
    _snack('Syncing background SMS...');
    final prefs = await SharedPreferences.getInstance();
    final selectedBanks = prefs.getStringList('selectedBanks') ?? [];
    await SmsParserService(ref.read(appDatabaseProvider)).syncRecentBankSms(selectedBanks);
    if (mounted) _snack('SMS Sync Completed!');
  }

  // --- UI Build ---

  @override
  Widget build(BuildContext context) {
    // සජීවීව State ලබා ගැනීම
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentLang = ref.watch(languageProvider);
    final currentTheme = ref.watch(themeProvider);
    final isAppLockEnabled = ref.watch(appLockProvider);

    final bg = isDark ? kDarkBg : kLightBg;
    final cardColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final primaryText = isDark ? Colors.white : const Color(0xFF0B1020);
    final secondaryText = isDark ? Colors.white60 : const Color(0xFF6B7280);
    final dividerColor = isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFEFF1F4);

    // පරිවර්තනය වූ වචන
    final String themeName = currentTheme == ThemeMode.system
        ? AppTranslations.getText('system_default', currentLang)
        : (currentTheme == ThemeMode.dark
        ? AppTranslations.getText('dark_mode', currentLang)
        : AppTranslations.getText('light_mode', currentLang));

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: _buildHeader(context, primaryText, cardColor, isDark, AppTranslations.getText('settings', currentLang)),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([

                      // 1. PREFERENCES SECTION
                      _sectionLabel(AppTranslations.getText('preferences', currentLang).toUpperCase(), secondaryText),
                      _buildGroup(cardColor, dividerColor, [
                        _SettingItem(
                          iconBg: kPrimary.withOpacity(0.12),
                          iconColor: kPrimary,
                          icon: Icons.language_rounded,
                          title: AppTranslations.getText('language', currentLang),
                          trailing: _trailingValue(currentLang, secondaryText),
                          onTap: () => _showLanguageSheet(context, isDark, cardColor, primaryText),
                        ),
                        _SettingItem(
                          iconBg: const Color(0xFF8B5CF6).withOpacity(0.14),
                          iconColor: const Color(0xFF8B5CF6),
                          icon: Icons.dark_mode_rounded,
                          title: AppTranslations.getText('choose_theme', currentLang) == 'choose_theme' ? 'Appearance' : AppTranslations.getText('choose_theme', currentLang),
                          trailing: _trailingValue(themeName, secondaryText),
                          onTap: () => _showThemeSheet(context, isDark, cardColor, primaryText, currentTheme, currentLang),
                        ),
                      ], primaryText),

                      const SizedBox(height: 28),

                      // 2. CLOUD BACKUP SECTION
                      _sectionLabel('CLOUD BACKUP', secondaryText),
                      _buildGroup(cardColor, dividerColor, [
                        _SettingItem(
                          iconBg: const Color(0xFF10B981).withOpacity(0.14),
                          iconColor: const Color(0xFF10B981),
                          icon: Icons.cloud_upload_rounded,
                          title: 'Backup to Cloud',
                          subtitle: 'Save data securely to Google Drive',
                          trailing: Icon(Icons.chevron_right_rounded, color: secondaryText.withOpacity(0.6)),
                          onTap: _handleBackup,
                        ),
                        _SettingItem(
                          iconBg: const Color(0xFF06B6D4).withOpacity(0.14),
                          iconColor: const Color(0xFF06B6D4),
                          icon: Icons.restore_rounded,
                          title: 'Restore Data',
                          subtitle: 'Recover previous database',
                          trailing: Icon(Icons.chevron_right_rounded, color: secondaryText.withOpacity(0.6)),
                          onTap: _handleRestore,
                        ),
                        _SettingItem(
                          iconBg: const Color(0xFFF59E0B).withOpacity(0.14),
                          iconColor: const Color(0xFFF59E0B),
                          icon: Icons.manage_accounts_rounded,
                          title: 'Change Google Account',
                          trailing: Icon(Icons.chevron_right_rounded, color: secondaryText.withOpacity(0.6)),
                          onTap: _handleChangeAccount,
                        ),
                      ], primaryText),

                      const SizedBox(height: 28),

                      // 3. SECURITY & DATA SECTION
                      _sectionLabel(AppTranslations.getText('security_data', currentLang).toUpperCase(), secondaryText),
                      _buildGroup(cardColor, dividerColor, [
                        _SettingItem(
                          iconBg: kPrimary.withOpacity(0.12),
                          iconColor: kPrimary,
                          icon: Icons.lock_rounded,
                          title: AppTranslations.getText('enable_app_lock', currentLang),
                          trailing: _buildSwitch(isAppLockEnabled, (v) => ref.read(appLockProvider.notifier).setLock(v)),
                          onTap: () => ref.read(appLockProvider.notifier).setLock(!isAppLockEnabled),
                        ),
                        _SettingItem(
                          iconBg: const Color(0xFF14B8A6).withOpacity(0.14),
                          iconColor: const Color(0xFF14B8A6),
                          icon: Icons.sms_rounded,
                          title: AppTranslations.getText('sync_sms', currentLang),
                          subtitle: AppTranslations.getText('sync_sms_desc', currentLang),
                          trailing: Icon(Icons.chevron_right_rounded, color: secondaryText.withOpacity(0.6)),
                          onTap: _syncSms,
                        ),
                        _SettingItem(
                          iconBg: const Color(0xFFEF4444).withOpacity(0.14),
                          iconColor: const Color(0xFFEF4444),
                          icon: Icons.delete_forever_rounded,
                          title: AppTranslations.getText('factory_reset', currentLang),
                          titleColor: const Color(0xFFEF4444),
                          trailing: Icon(Icons.chevron_right_rounded, color: secondaryText.withOpacity(0.6)),
                          onTap: () => _confirmReset(context, currentLang),
                        ),
                      ], primaryText),

                      const SizedBox(height: 32),
                      Center(
                        child: Text(
                          'Version 1.0.0',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: secondaryText.withOpacity(0.7),
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- Sub UI Components ---

  Widget _buildHeader(BuildContext context, Color textColor, Color buttonBg, bool isDark, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      child: Row(
        children: [
          Material(
            color: buttonBg,
            shape: const CircleBorder(),
            elevation: 0,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => Navigator.of(context).maybePop(),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFE5E7EB),
                  ),
                ),
                child: Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: textColor),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: textColor,
                letterSpacing: -0.8,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 12, 6, 10),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildGroup(Color cardColor, Color dividerColor, List<_SettingItem> items, Color textColor) {
    final children = <Widget>[];
    for (var i = 0; i < items.length; i++) {
      children.add(items[i].build(context, textColor));
      if (i != items.length - 1) {
        children.add(Padding(
          padding: const EdgeInsets.only(left: 68),
          child: Divider(height: 1, thickness: 0.6, color: dividerColor),
        ));
      }
    }
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(children: children),
      ),
    );
  }

  Widget _trailingValue(String value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value, style: TextStyle(fontSize: 14.5, color: color, fontWeight: FontWeight.w500)),
        const SizedBox(width: 4),
        Icon(Icons.chevron_right_rounded, color: color.withOpacity(0.6)),
      ],
    );
  }

  Widget _buildSwitch(bool value, ValueChanged<bool> onChanged) {
    return Switch.adaptive(
      value: value,
      onChanged: onChanged,
      activeColor: Colors.white,
      activeTrackColor: kPrimary,
    );
  }

  void _snack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red.shade700 : kPrimary,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(milliseconds: 1800),
      ),
    );
  }

  // --- Bottom Sheets & Dialogs ---

  void _showLanguageSheet(BuildContext context, bool isDark, Color cardColor, Color textColor) {
    final langs = ['English', 'සිංහල', 'தமிழ்'];
    final currentLang = ref.read(languageProvider);
    _showSheet(
      context, cardColor, textColor,
      'Language / භාෂාව',
      langs.map((l) => _sheetTile(l, currentLang == l, () {
        ref.read(languageProvider.notifier).setLanguage(l);
        Navigator.pop(context);
      }, textColor)).toList(),
    );
  }

  void _showThemeSheet(BuildContext context, bool isDark, Color cardColor, Color textColor, ThemeMode currentTheme, String lang) {
    final themes = [
      {'mode': ThemeMode.light, 'label': AppTranslations.getText('light_mode', lang), 'icon': Icons.light_mode_rounded},
      {'mode': ThemeMode.dark, 'label': AppTranslations.getText('dark_mode', lang), 'icon': Icons.dark_mode_rounded},
      {'mode': ThemeMode.system, 'label': AppTranslations.getText('system_default', lang), 'icon': Icons.phone_iphone_rounded},
    ];
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: textColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text('Appearance', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: textColor)),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: themes.map((t) {
                  final mode = t['mode'] as ThemeMode;
                  final selected = currentTheme == mode;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () {
                        ref.read(themeProvider.notifier).setTheme(mode);
                        Navigator.pop(context);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: selected ? kPrimary : Colors.transparent,
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: Column(
                          children: [
                            Icon(t['icon'] as IconData, color: selected ? Colors.white : textColor.withOpacity(0.7), size: 22),
                            const SizedBox(height: 6),
                            Text(t['label'] as String,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: selected ? Colors.white : textColor.withOpacity(0.7),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                )),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSheet(BuildContext context, Color cardColor, Color textColor, String title, List<Widget> children) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(0, 12, 0, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: textColor.withOpacity(0.15), borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: textColor)),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _sheetTile(String label, bool selected, VoidCallback onTap, Color textColor) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        child: Row(
          children: [
            Expanded(child: Text(label, style: TextStyle(fontSize: 16, color: textColor, fontWeight: FontWeight.w500))),
            if (selected) const Icon(Icons.check_rounded, color: kPrimary),
          ],
        ),
      ),
    );
  }

  void _confirmReset(BuildContext context, String lang) {
    showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: Text(AppTranslations.getText('reset_confirm_title', lang)),
        content: Text(AppTranslations.getText('factory_reset_desc', lang)),
        actions: [
          CupertinoDialogAction(
              child: Text(AppTranslations.getText('cancel', lang)),
              onPressed: () => Navigator.pop(context)
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () async {
              Navigator.pop(context); // Close dialog

              // සැබෑ දත්ත මැකීමේ ක්‍රියාවලිය
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();

              final db = ref.read(appDatabaseProvider);
              for (final table in db.allTables) {
                await db.delete(table).go();
              }

              ref.invalidate(themeProvider);
              ref.invalidate(languageProvider);
              ref.invalidate(appLockProvider);

              if (mounted) {
                _snack('Factory Reset Successful. Restarting...', isError: true);
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const SplashScreen()),
                      (Route<dynamic> route) => false,
                );
              }
            },
            child: Text(AppTranslations.getText('delete', lang)),
          ),
        ],
      ),
    );
  }
}

class _SettingItem {
  final Color iconBg;
  final Color iconColor;
  final IconData icon;
  final String title;
  final String? subtitle;
  final Color? titleColor;
  final Widget trailing;
  final VoidCallback onTap;

  _SettingItem({
    required this.iconBg,
    required this.iconColor,
    required this.icon,
    required this.title,
    this.subtitle,
    this.titleColor,
    required this.trailing,
    required this.onTap,
  });

  Widget build(BuildContext context, Color textColor) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 38, height: 38,
                decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(11)),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w600,
                        color: titleColor ?? textColor,
                        letterSpacing: -0.2,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: textColor.withOpacity(0.5),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              trailing,
            ],
          ),
        ),
      ),
    );
  }
}