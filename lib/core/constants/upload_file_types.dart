class UploadFileTypes {
  UploadFileTypes._();

  static const List<String> allowedExtensions = ['csv', 'xlsx', 'xls'];

  static String contentTypeFor(String fileName) {
    final extension = fileName.contains('.')
        ? fileName.split('.').last.toLowerCase()
        : '';

    return switch (extension) {
      'csv' => 'text/csv',
      'xls' => 'application/vnd.ms-excel',
      'xlsx' =>
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      _ => 'application/octet-stream',
    };
  }
}
