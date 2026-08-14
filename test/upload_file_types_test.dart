import 'package:flutter_test/flutter_test.dart';
import 'package:hr_portal/core/constants/upload_file_types.dart';

void main() {
  test('allows csv, xlsx, and xls extensions', () {
    expect(UploadFileTypes.allowedExtensions, contains('csv'));
    expect(UploadFileTypes.allowedExtensions, contains('xlsx'));
    expect(UploadFileTypes.allowedExtensions, contains('xls'));
  });

  test('returns correct content type for csv', () {
    expect(UploadFileTypes.contentTypeFor('attendance.csv'), 'text/csv');
  });

  test('returns correct content type for xlsx', () {
    expect(
      UploadFileTypes.contentTypeFor('balance.xlsx'),
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    );
  });
}
