import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:flutter_riverpod/flutter_riverpod.dart';

// [ආරක්ෂණ ක්‍රියාවලිය] - Google Drive වෙත පිවිසීමට අවශ්‍ය අවසර (Auth Headers) ලබා දෙන HTTP Client එක
class GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = http.Client();

  GoogleAuthClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    return _client.send(request..headers.addAll(_headers));
  }
}

class GoogleDriveBackupService {
  // Google Drive හි සැඟවුණු 'appDataFolder' වෙත පමණක් ප්‍රවේශ වීමට අවසර ඉල්ලීම
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [drive.DriveApi.driveAppdataScope],
  );

  // Google Drive API එක Authentication සමගින් සූදානම් කිරීම
  Future<drive.DriveApi?> _getDriveApi() async {
    try {
      final GoogleSignInAccount? account = await _googleSignIn.signIn();
      if (account == null) return null; // පරිශීලකයා ලොග් වීම ප්‍රතික්ෂේප කළහොත්

      final headers = await account.authHeaders;
      final client = GoogleAuthClient(headers);
      return drive.DriveApi(client);
    } catch (e) {
      throw Exception('Google Sign-In Failed: $e');
    }
  }

  // දුරකථනයේ ඇති Local Database ගොනුව සොයාගැනීම
  Future<File> _getDbFile() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    return File(p.join(dbFolder.path, 'finance_app.sqlite'));
  }

  // දත්ත Upload කිරීමේ ක්‍රියාවලිය (Backup)
  Future<bool> backupDatabase() async {
    try {
      final api = await _getDriveApi();
      if (api == null) return false;

      final dbFile = await _getDbFile();
      if (!await dbFile.exists()) throw Exception('Database file not found!');

      // අතීතයේ දැමූ Backup එකක් දැනටමත් තිබේදැයි සෙවීම
      final fileList = await api.files.list(
        spaces: 'appDataFolder',
        q: "name = 'finance_app.sqlite'",
      );

      final media = drive.Media(dbFile.openRead(), dbFile.lengthSync());

      if (fileList.files != null && fileList.files!.isNotEmpty) {
        // පරණ Backup එකක් ඇත්නම් එය අලුත් ගොනුවෙන් යාවත්කාලීන කිරීම (Update)
        final fileId = fileList.files!.first.id!;
        await api.files.update(drive.File(), fileId, uploadMedia: media);
      } else {
        // පරණ එකක් නැත්නම් අලුතින්ම ගොනුව Drive එකට දැමීම (Create)
        final driveFile = drive.File()
          ..name = 'finance_app.sqlite'
          ..parents = ['appDataFolder']; // සැඟවුණු ෆෝල්ඩරයට දැමීම
        await api.files.create(driveFile, uploadMedia: media);
      }
      return true;
    } catch (e) {
      throw Exception('Backup failed: $e');
    }
  }

  // දත්ත Download කර Restore කිරීමේ ක්‍රියාවලිය
  Future<bool> restoreDatabase() async {
    try {
      final api = await _getDriveApi();
      if (api == null) return false;

      // Drive එකේ Backup එකක් තිබේදැයි සෙවීම
      final fileList = await api.files.list(
        spaces: 'appDataFolder',
        q: "name = 'app_database.sqlite'",
      );

      if (fileList.files == null || fileList.files!.isEmpty) {
        throw Exception('No backup found on Google Drive!');
      }

      final fileId = fileList.files!.first.id!;

      // ගොනුව සම්පූර්ණයෙන්ම බාගත කිරීම (Download)
      final drive.Media media = await api.files.get(
          fileId,
          downloadOptions: drive.DownloadOptions.fullMedia
      ) as drive.Media;

      // පරණ Database එක මතින් අලුත් ගොනුව ලිවීම (Overwrite)
      final dbFile = await _getDbFile();
      final sink = dbFile.openWrite();
      await media.stream.pipe(sink);
      await sink.close();

      return true;
    } catch (e) {
      throw Exception('Restore failed: $e');
    }
  }

  // Google ගිණුමෙන් ඉවත් වීම
  Future<void> signOut() async {
    await _googleSignIn.signOut();
  }
}

// UI එකට සම්බන්ධ කිරීමට Riverpod Provider එක
final backupServiceProvider = Provider<GoogleDriveBackupService>((ref) {
  return GoogleDriveBackupService();
});