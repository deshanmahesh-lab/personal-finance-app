import '../../domain/entities/bank_transaction.dart';
import 'base_bank_parser.dart';
import 'boc_parser.dart';
import 'nsb_parser.dart';
import 'peoples_bank_parser.dart';

class SmsParserRegistry {
  // ලියාපදිංචි කර ඇති සියලුම බැංකු Parsers
  static final List<BaseBankParser> _parsers = [
    BocParser(),
    NsbParser(),
    PeoplesBankParser(),
  ];

  /// SMS එකක් ලැබුණු විට අදාළ බැංකුවේ Parser එක සොයා එය හරහා දත්ත ලබා දෙයි
  static BankTransaction? parseSms(String sender, String body) {
    for (var parser in _parsers) {
      if (parser.canParse(sender)) {
        return parser.parse(body);
      }
    }

    // සහාය නොදක්වන බැංකුවක් හෝ Sender ID එකක් නම්
    return null;
  }

  /// App එකේ සහාය දක්වන බැංකු ලැයිස්තුව ලබා ගැනීම සඳහා
  static List<String> getSupportedBanks() {
    return _parsers.map((p) => p.bankName).toList();
  }
}