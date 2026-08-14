import 'package:url_launcher/url_launcher.dart';

final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

bool isValidEmployeeEmail(String? email) {
  final trimmed = email?.trim() ?? '';
  if (trimmed.isEmpty) {
    return false;
  }
  return _emailPattern.hasMatch(trimmed);
}

Uri? mailtoUriFor(String? email) {
  if (!isValidEmployeeEmail(email)) {
    return null;
  }
  return Uri(scheme: 'mailto', path: email!.trim());
}

Future<bool> launchEmployeeMailto(String email) async {
  final uri = mailtoUriFor(email);
  if (uri == null) {
    return false;
  }

  return launchUrl(uri, mode: LaunchMode.externalApplication);
}
