import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/app_lock_provider.dart';
import '../../providers/language_provider.dart';
import '../../../utils/app_translations.dart';
import 'theme_configuration_screen.dart';

class SecuritySetupScreen extends ConsumerStatefulWidget {
  const SecuritySetupScreen({super.key});

  @override
  ConsumerState<SecuritySetupScreen> createState() => _SecuritySetupScreenState();
}

class _SecuritySetupScreenState extends ConsumerState<SecuritySetupScreen> {
  bool _enableAppLock = false;

  @override
  Widget build(BuildContext context) {
    final currentLanguage = ref.watch(languageProvider);

    final mainTitle = AppTranslations.getText('secure_data_title', currentLanguage);
    final subTitle = AppTranslations.getText('secure_data_desc', currentLanguage);
    final lockTitle = AppTranslations.getText('enable_app_lock', currentLanguage);
    final lockDesc = AppTranslations.getText('app_lock_desc', currentLanguage);
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
                child: IconButton(icon: const Icon(Icons.arrow_back_ios, size: 24), onPressed: () => Navigator.pop(context), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
              ),
              const SizedBox(height: 24),

              Center(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(color: Theme.of(context).primaryColor.withOpacity(0.1), shape: BoxShape.circle),
                  child: Icon(Icons.security_rounded, size: 80, color: Theme.of(context).primaryColor),
                ),
              ),
              const SizedBox(height: 40),

              Text(mainTitle, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, height: 1.3)),
              const SizedBox(height: 12),
              Text(subTitle, style: TextStyle(fontSize: 16, color: Colors.grey.shade600)),
              const SizedBox(height: 40),

              InkWell(
                onTap: () {
                  setState(() { _enableAppLock = !_enableAppLock; });
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: _enableAppLock ? Theme.of(context).primaryColor.withOpacity(0.1) : Colors.grey.withOpacity(0.05),
                    border: Border.all(color: _enableAppLock ? Theme.of(context).primaryColor : Colors.grey.shade300, width: 2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.fingerprint, color: _enableAppLock ? Theme.of(context).primaryColor : Colors.grey.shade600, size: 32),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(lockTitle, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _enableAppLock ? Theme.of(context).primaryColor : null)),
                            const SizedBox(height: 4),
                            Text(lockDesc, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                          ],
                        ),
                      ),
                      Switch(
                        value: _enableAppLock,
                        onChanged: (value) { setState(() { _enableAppLock = value; }); },
                        activeColor: Theme.of(context).primaryColor,
                      ),
                    ],
                  ),
                ),
              ),

              const Spacer(),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    ref.read(appLockProvider.notifier).setLock(_enableAppLock);
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const ThemeConfigurationScreen()));
                  },
                  style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), backgroundColor: Theme.of(context).primaryColor, foregroundColor: Colors.white),
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