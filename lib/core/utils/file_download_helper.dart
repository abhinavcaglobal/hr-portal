import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

class FileDownloadHelper {
  FileDownloadHelper._();

  static Future<bool> saveBytes({
    required Uint8List bytes,
    required String fileName,
    List<String> allowedExtensions = const ['xlsx'],
  }) async {
    final path = await FilePicker.platform.saveFile(
      fileName: fileName,
      bytes: bytes,
      type: FileType.custom,
      allowedExtensions: allowedExtensions,
    );

    return path != null;
  }
}
