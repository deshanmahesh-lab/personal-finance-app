import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/language_provider.dart';
import '../../../utils/app_translations.dart';
import 'permissions_screen.dart';

class LanguageSelectionScreen extends ConsumerStatefulWidget {
  const LanguageSelectionScreen({super.key});

  @override
  ConsumerState<LanguageSelectionScreen> createState() => _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends ConsumerState<LanguageSelectionScreen> {
  // තාවකාලිකව තෝරාගෙන ඇති භාෂාව
  String _tempSelectedLanguage = 'English';

  @override
  Widget build(BuildContext context) {
    // අපගේ අලුත් Translation ශ්‍රිතය භාවිතා කර වචන ලබා ගැනීම
    final mainTitle = AppTranslations.getText('select_language', _tempSelectedLanguage);
    final subTitle = AppTranslations.getText('language_desc', _tempSelectedLanguage);
    final btnText = AppTranslations.getText('continue_btn', _tempSelectedLanguage);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              Text(
                mainTitle,
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, height: 1.2),
              ),
              const SizedBox(height: 12),
              Text(
                subTitle,
                style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 40),

              // Language Options
              _buildLanguageCard('English', 'English', 'A'),
              const SizedBox(height: 16),
              _buildLanguageCard('සිංහල', 'Sinhala', 'අ'),
              const SizedBox(height: 16),
              _buildLanguageCard('தமிழ்', 'Tamil', 'அ'),

              const Spacer(),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    // 1. තේරූ භාෂාව Provider හරහා දුරකථනයේ ස්ථිරව Save කිරීම
                    ref.read(languageProvider.notifier).setLanguage(_tempSelectedLanguage);

                    // 2. ඊළඟ තිරයට යාම (දැන් Parameter යවන්න අවශ්‍ය නැත)
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PermissionsScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
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

  Widget _buildLanguageCard(String languageName, String subtitle, String letter) {
    final isSelected = _tempSelectedLanguage == languageName;

    return InkWell(
      onTap: () {
        setState(() {
          _tempSelectedLanguage = languageName;
        });
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).primaryColor.withOpacity(0.1) : Colors.grey.withOpacity(0.05),
          border: Border.all(
            color: isSelected ? Theme.of(context).primaryColor : Colors.grey.shade300,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected ? Theme.of(context).primaryColor : Colors.grey.shade300,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  letter,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : Colors.black54),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(languageName, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isSelected ? Theme.of(context).primaryColor : null)),
                  Text(subtitle, style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: Theme.of(context).primaryColor, size: 28),
          ],
        ),
      ),
    );
  }
}