class AppTranslations {
  static const Map<String, Map<String, String>> translations = {
    // --- Onboarding ---
    'select_language': {'English': 'Select Language', 'සිංහල': 'භාෂාව තෝරන්න', 'தமிழ்': 'மொழியைத் தேர்ந்தெடுக்கவும்'},
    'language_desc': {'English': 'You can change this later in settings.', 'සිංහල': 'ඔබට මෙය පසුව Settings මඟින් වෙනස් කළ හැක.', 'தமிழ்': 'இதை நீங்கள் பிறகு அமைப்புகளில் மாற்றலாம்.'},
    'continue_btn': {'English': 'Continue', 'සිංහල': 'ඉදිරියට යන්න', 'தமிழ்': 'தொடரவும்'},
    'permissions_title': {'English': 'We need some permissions', 'සිංහල': 'අපට යම් අවසරයන් අවශ්‍යයි', 'தமிழ்': 'எங்களுக்கு சில அனுமதிகள் தேவை'},
    'permissions_desc': {'English': 'To track your expenses, this app needs the following permissions.', 'සිංහල': 'වියදම් සටහන් කරගැනීමට, පහත අවසරයන් අනිවාර්ය වේ.', 'தமிழ்': 'உங்கள் செலவுகளைக் கண்காணிக்க, பின்வரும் அனுமதிகள் தேவை.'},
    'sms_perm_title': {'English': 'SMS Permission', 'සිංහල': 'SMS අවසරය', 'தமிழ்': 'SMS அனுமதி'},
    'sms_perm_desc': {'English': 'We read bank SMS to categorize transactions locally.', 'සිංහල': 'ගනුදෙනු හඳුනාගැනීමට අපි බැංකු SMS පමණක් කියවමු.', 'தமிழ்': 'பரிவர்த்தனைகளை வகைப்படுத்த வங்கி SMS ஐப் படிக்கிறோம்.'},
    'noti_perm_title': {'English': 'Notifications', 'සිංහල': 'දැනුම්දීම්', 'தமிழ்': 'அறிவிப்புகள்'},
    'noti_perm_desc': {'English': 'We send instant budget alerts.', 'සිංහල': 'වියදම් පිළිබඳ දැනුම්දීම් ලබාදීමට මෙය භාවිතා වේ.', 'தமிழ்': 'உடனடி பட்ஜெட் விழிப்பூட்டல்களை அனுப்புகிறோம்.'},
    'secure_data_title': {'English': 'Secure your data', 'සිංහල': 'ඔබගේ දත්ත ආරක්ෂා කරන්න', 'தமிழ்': 'உங்கள் தரவைப் பாதுகாக்கவும்'},
    'secure_data_desc': {'English': 'Enable App Lock to protect information.', 'සිංහල': 'මූල්‍ය තොරතුරු ආරක්ෂා කිරීමට App Lock සක්‍රිය කරන්න.', 'தமிழ்': 'தகவலைப் பாதுகாக்க App Lock ஐ இயக்கவும்.'},
    'enable_app_lock': {'English': 'Enable App Lock', 'සිංහල': 'App Lock සක්‍රිය කරන්න', 'தமிழ்': 'App Lock ஐ இயக்கவும்'},
    'app_lock_desc': {'English': 'Require PIN or Fingerprint.', 'සිංහල': 'PIN හෝ Fingerprint අවශ්‍ය වේ.', 'தமிழ்': 'PIN அல்லது கைரேகை தேவை.'},
    'choose_theme': {'English': 'Choose your theme', 'සිංහල': 'තේමාව තෝරන්න', 'தமிழ்': 'தீம் தேர்ந்தெடுக்கவும்'},
    'choose_theme_desc': {'English': 'Select how you want the app to look.', 'සිංහල': 'ඔබට වඩාත් පහසු පෙනුමක් තෝරාගන්න.', 'தமிழ்': 'பயன்பாடு எப்படி இருக்க வேண்டும் என்பதைத் தேர்ந்தெடுக்கவும்.'},
    'light_mode': {'English': 'Light Mode', 'සිංහල': 'ආලෝකමත් තේමාව', 'தமிழ்': 'வெளிச்சமான தீம்'},
    'dark_mode': {'English': 'Dark Mode', 'සිංහල': 'අඳුරු තේමාව', 'தமிழ்': 'இருண்ட தீம்'},
    'system_default': {'English': 'System Default', 'සිංහල': 'දුරකථනයේ සැකසුම (System)', 'தமிழ்': 'கணினி இயல்புநிலை'},
    'select_banks': {'English': 'Select Your Banks', 'සිංහල': 'ඔබගේ බැංකු තෝරන්න', 'தமிழ்': 'உங்கள் வங்கிகளைத் தேர்ந்தெடுக்கவும்'},
    'select_banks_desc': {'English': 'Select the banks you use.', 'සිංහල': 'ඔබ භාවිතා කරන බැංකු තෝරන්න.', 'தமிழ்': 'நீங்கள் பயன்படுத்தும் வங்கிகளைத் தேர்ந்தெடுக்கவும்.'},
    'scanning_inbox': {'English': 'Scanning Inbox...', 'සිංහල': 'SMS පරීක්ෂා කරමින්...', 'தமிழ்': 'SMS சரிபார்க்கிறது...'},
    'extracting_tx': {'English': 'Extracting Transactions...', 'සිංහල': 'ගනුදෙනු හඳුනාගනිමින්...', 'தமிழ்': 'பரிவர்த்தனைகளைப் பிரித்தெடுக்கிறது...'},
    'setting_wallets': {'English': 'Setting up Wallets...', 'සිංහල': 'ගිණුම් සකසමින්...', 'தமிழ்': 'கணக்குகளை அமைக்கிறது...'},
    'saving_data': {'English': 'Saving Data...', 'සිංහල': 'දත්ත සුරකිමින්...', 'தமிழ்': 'தரவைச் சேமிக்கிறது...'},
    'ready': {'English': 'Ready!', 'සිංහල': 'සූදානම්!', 'தமிழ்': 'தயார்!'},
    'please_wait': {'English': 'Please wait. This might take a few seconds.', 'සිංහල': 'කරුණාකර රැඳී සිටින්න. මෙයට තත්පර කිහිපයක් ගතවිය හැක.', 'தமிழ்': 'தயவுசெய்து காத்திருக்கவும். இதற்கு சில வினாடிகள் ஆகலாம்.'},

    // --- Main Screen & Nav Bar ---
    'nav_home': {'English': 'Home', 'සිංහල': 'මුල් පිටුව', 'தமிழ்': 'முகப்பு'},
    'nav_analytics': {'English': 'Analytics', 'සිංහල': 'විශ්ලේෂණ', 'தமிழ்': 'பகுப்பாய்வு'},
    'nav_categories': {'English': 'Categories', 'සිංහල': 'කාණ්ඩ', 'தமிழ்': 'வகைகள்'},
    'title_dashboard': {'English': 'Dashboard', 'සිංහල': 'මුල් පිටුව', 'தமிழ்': 'முகப்பு'},
    'title_analytics': {'English': 'Analytics', 'සිංහල': 'විශ්ලේෂණ', 'தமிழ்': 'பகுப்பாய்வு'},
    'title_categories': {'English': 'Categories', 'සිංහල': 'කාණ්ඩ', 'தமிழ்': 'வகைகள்'},

    // --- Dashboard ---
    'my_accounts': {'English': 'My Accounts', 'සිංහල': 'මගේ ගිණුම්', 'தமிழ்': 'என் கணக்குகள்'},
    'no_accounts': {'English': 'No accounts found.', 'සිංහල': 'ගිණුම් කිසිවක් හමු නොවීය.', 'தமிழ்': 'கணக்குகள் எதுவும் இல்லை.'},
    'recent_tx': {'English': 'Recent Transactions', 'සිංහල': 'මෑත ගනුදෙනු', 'தமிழ்': 'சமீபத்திய பரிவர்த்தனைகள்'},
    'no_tx': {'English': 'No transactions yet.', 'සිංහල': 'තවමත් ගනුදෙනු නොමැත.', 'தமிழ்': 'பரிவர்த்தனைகள் எதுவும் இல்லை.'},
    'net_balance': {'English': 'Net Balance', 'සිංහල': 'ශුද්ධ ශේෂය', 'தமிழ்': 'நிகர இருப்பு'},
    'income': {'English': 'Income', 'සිංහල': 'ආදායම්', 'தமிழ்': 'வருமானம்'},
    'expense': {'English': 'Expense', 'සිංහල': 'වියදම්', 'தமிழ்': 'செலவு'},
    'monthly_budgets': {'English': 'Monthly Budgets', 'සිංහල': 'මාසික අයවැය', 'தமிழ்': 'மாதாந்திர பட்ஜெட்'},
    'edit_tx': {'English': 'Edit Transaction?', 'සිංහල': 'ගනුදෙනුව වෙනස් කරනවාද?', 'தமிழ்': 'பரிவர்த்தனையை திருத்தவா?'},
    'del_tx': {'English': 'Delete Transaction?', 'සිංහල': 'ගනුදෙනුව මකා දමනවාද?', 'தமிழ்': 'பரிவர்த்தனையை நீக்கவா?'},
    'cancel': {'English': 'Cancel', 'සිංහල': 'අවලංගු කරන්න', 'தமிழ்': 'ரத்துசெய்'},
    'delete': {'English': 'Delete', 'සිංහල': 'මකන්න', 'தமிழ்': 'நீக்கு'},
    'edit': {'English': 'Edit', 'සිංහල': 'වෙනස් කරන්න', 'தமிழ்': 'திருத்து'},

    // --- Settings Screen ---
    'settings': {'English': 'Settings', 'සිංහල': 'සැකසුම්', 'தமிழ்': 'அமைப்புகள்'},
    'preferences': {'English': 'Preferences', 'සිංහල': 'මනාපයන්', 'தமிழ்': 'விருப்பங்கள்'},
    'language': {'English': 'Language / භාෂාව', 'සිංහල': 'Language / භාෂාව', 'தமிழ்': 'Language / மொழி'},
    'security_data': {'English': 'Security & Data', 'සිංහල': 'ආරක්ෂාව සහ දත්ත', 'தமிழ்': 'பாதுகாப்பு & தரவு'},
    'sync_sms': {'English': 'Sync Bank SMS', 'සිංහල': 'බැංකු SMS යාවත්කාලීන කරන්න', 'தமிழ்': 'வங்கி SMS ஒத்திசை'},
    'sync_sms_desc': {'English': 'Scan recent messages for transactions', 'සිංහල': 'අලුත් ගනුදෙනු සඳහා SMS පරීක්ෂා කරන්න', 'தமிழ்': 'பரிவர்த்தனைகளுக்கான புதிய SMSகளைச் சரிபார்க்கவும்'},
    'factory_reset': {'English': 'Factory Reset', 'සිංහල': 'සියලු දත්ත මකන්න (Reset)', 'தமிழ்': 'எல்லா தரவையும் அழி'},
    'factory_reset_desc': {'English': 'Delete all transactions & reset balances', 'සිංහල': 'ගනුදෙනු මකා දමා ශේෂය 0 කරන්න', 'தமிழ்': 'பரிவர்த்தனைகளை நீக்கி இருப்பை மீட்டமைக்கவும்'},
    'dev_tools': {'English': 'Developer Tools', 'සිංහල': 'සංවර්ධක මෙවලම්', 'தமிழ்': 'டெவலப்பர் கருவிகள்'},
    'reset_confirm_title': {'English': 'Reset All Data?', 'සිංහල': 'සියලු දත්ත මකනවාද?', 'தமிழ்': 'எல்லா தரவையும் அழிக்கவா?'},

    // --- Add Transaction ---
    'how_much': {'English': 'How much?', 'සිංහල': 'කොපමණද?', 'தமிழ்': 'எவ்வளவு?'},
    'transfer': {'English': 'Transfer', 'සිංහල': 'මුදල් මාරුව', 'தமிழ்': 'பரிமாற்றம்'},
    'from_wallet': {'English': 'From Wallet', 'සිංහල': 'මෙම ගිණුමෙන්', 'தமிழ்': 'இந்த கணக்கிலிருந்து'},
    'to_wallet': {'English': 'To Wallet', 'සිංහල': 'මෙම ගිණුමට', 'தமிழ்': 'இந்த கணக்கிற்கு'},
    'select_wallet': {'English': 'Select Wallet', 'සිංහල': 'ගිණුම තෝරන්න', 'தமிழ்': 'கணக்கைத் தேர்ந்தெடுக்கவும்'},
    'select_category': {'English': 'Select Category', 'සිංහල': 'කාණ්ඩය තෝරන්න', 'தமிழ்': 'வகையைத் தேர்ந்தெடுக்கவும்'},
    'add_note': {'English': 'Add a note', 'සිංහල': 'සටහනක් එක් කරන්න', 'தமிழ்': 'ஒரு குறிப்பைச் சேர்க்கவும்'},
    'save_tx': {'English': 'Save Transaction', 'සිංහල': 'ගනුදෙනුව සුරකින්න', 'தமிழ்': 'பரிவர்த்தனையை சேமிக்கவும்'},
    'tx_saved': {'English': 'Transaction Saved', 'සිංහල': 'ගනුදෙනුව සුරැකිණි', 'தமிழ்': 'பரிவர்த்தனை சேமிக்கப்பட்டது'},
    'tx_updated': {'English': 'Transaction Updated', 'සිංහල': 'ගනුදෙනුව යාවත්කාලීන කෙරිණි', 'தமிழ்': 'பரிவர்த்தனை புதுப்பிக்கப்பட்டது'},
    'valid_amount_err': {'English': 'Please enter a valid amount!', 'සිංහල': 'කරුණාකර නිවැරදි මුදලක් ඇතුළත් කරන්න!', 'தமிழ்': 'சரியான தொகையை உள்ளிடவும்!'},
    'wallet_err': {'English': 'Please select a wallet!', 'සිංහල': 'කරුණාකර ගිණුමක් තෝරන්න!', 'தமிழ்': 'கணக்கைத் தேர்ந்தெடுக்கவும்!'},
    'cat_err': {'English': 'Please select a category!', 'සිංහල': 'කරුණාකර කාණ්ඩයක් තෝරන්න!', 'தமிழ்': 'வகையைத் தேர்ந்தெடுக்கவும்!'},
    'budget_exceeded': {'English': 'Budget Exceeded!', 'සිංහල': 'අයවැය සීමාව ඉක්මවා ඇත!', 'தமிழ்': 'பட்ஜெட் மீறப்பட்டது!'},
    'save_anyway': {'English': 'Save Anyway', 'සිංහල': 'කෙසේ හෝ සුරකින්න', 'தமிழ்': 'எப்படியும் சேமிக்கவும்'},

    // --- Analytics ---
    'period': {'English': 'Period:', 'සිංහල': 'කාලය:', 'தமிழ்': 'காலம்:'},
    'monthly': {'English': 'Monthly', 'සිංහල': 'මාසික', 'தமிழ்': 'மாதாந்திர'},
    'yearly': {'English': 'Yearly', 'සිංහල': 'වාර්ෂික', 'தமிழ்': 'வருடாந்திர'},
    'type': {'English': 'Type:', 'සිංහල': 'වර්ගය:', 'தமிழ்': 'வகை:'},
    'total': {'English': 'Total', 'සිංහල': 'එකතුව', 'தமிழ்': 'மொத்தம்'},
    'no_data': {'English': 'No data available.', 'සිංහල': 'දත්ත කිසිවක් නොමැත.', 'தமிழ்': 'தரவு எதுவும் இல்லை.'},

    // --- Manage Wallets & Categories ---
    'my_wallets': {'English': 'My Wallets', 'සිංහල': 'මගේ ගිණුම්', 'தமிழ்': 'என் கணக்குகள்'},
    'add_wallet': {'English': 'Add Wallet', 'සිංහල': 'ගිණුමක් එක් කරන්න', 'தமிழ்': 'கணக்கைச் சேர்க்கவும்'},
    'edit_wallet': {'English': 'Edit Wallet', 'සිංහල': 'ගිණුම වෙනස් කරන්න', 'தமிழ்': 'கணக்கைத் திருத்தவும்'},
    'new_wallet': {'English': 'New Wallet', 'සිංහල': 'නව ගිණුමක්', 'தமிழ்': 'புதிய கணக்கு'},
    'wallet_name': {'English': 'Wallet Name', 'සිංහල': 'ගිණුමේ නම', 'தமிழ்': 'கணக்கின் பெயர்'},
    'start_balance': {'English': 'Starting Balance', 'සිංහල': 'ආරම්භක ශේෂය', 'தமிழ்': 'ஆரம்ப இருப்பு'},
    'adj_balance': {'English': 'Adjust Balance', 'සිංහල': 'ශේෂය වෙනස් කරන්න', 'தமிழ்': 'இருப்பை சரிசெய்யவும்'},
    'wallet_type': {'English': 'Wallet Type', 'සිංහල': 'ගිණුම් වර්ගය', 'தமிழ்': 'கணக்கு வகை'},
    'save_wallet': {'English': 'Save Wallet', 'සිංහල': 'ගිණුම සුරකින්න', 'தமிழ்': 'கணக்கை சேமிக்கவும்'},
    'del_wallet_confirm': {'English': 'Delete Wallet?', 'සිංහල': 'ගිණුම මකනවාද?', 'தமிழ்': 'கணக்கை நீக்கவா?'},
    'add_category': {'English': 'Add Category', 'සිංහල': 'කාණ්ඩයක් එක් කරන්න', 'தமிழ்': 'வகையைச் சேர்க்கவும்'},
    'new_category': {'English': 'New Category', 'සිංහල': 'නව කාණ්ඩයක්', 'தமிழ்': 'புதிய வகை'},
    'cat_name': {'English': 'Category Name', 'සිංහල': 'කාණ්ඩයේ නම', 'தமிழ்': 'வகையின் பெயர்'},
    'monthly_budget_opt': {'English': 'Monthly Budget (Optional)', 'සිංහල': 'මාසික අයවැය (විකල්ප)', 'தமிழ்': 'மாதாந்திர பட்ஜெட் (விருப்பம்)'},
    'save_cat': {'English': 'Save Category', 'සිංහල': 'කාණ්ඩය සුරකින්න', 'தமிழ்': 'வகையை சேமிக்கவும்'},
    'edit_cat': {'English': 'Edit Category', 'සිංහල': 'කාණ්ඩය වෙනස් කරන්න', 'தமிழ்': 'வகையைத் திருத்தவும்'},
    'del_cat_confirm': {'English': 'Delete Category?', 'සිංහල': 'කාණ්ඩය මකනවාද?', 'தமிழ்': 'வகையை நீக்கவா?'},
    'update': {'English': 'Update', 'සිංහල': 'යාවත්කාලීන කරන්න', 'தமிழ்': 'புதுப்பிக்கவும்'},
  };

  static String getText(String key, String languageCode) {
    if (translations.containsKey(key)) {
      if (translations[key]!.containsKey(languageCode)) {
        return translations[key]![languageCode]!;
      }
    }
    return translations[key]?['English'] ?? key;
  }
}