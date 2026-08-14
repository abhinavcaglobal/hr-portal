import 'dart:io';

void main() {
  final lines = File('Create.csv').readAsLinesSync();
  final seen = <String>{};
  final employees = <String>[];

  for (final line in lines) {
    if (!line.contains(',') || line.startsWith('Transaction') || line.startsWith('Export')) {
      continue;
    }
    if (line.startsWith('Name,')) continue;
    if (line.startsWith('Operator:')) continue;
    if (line.startsWith('Time Period:')) continue;

    final parts = line.split(',');
    if (parts.length < 7) continue;
    final name = parts[0].trim();
    final id = parts[1].trim();
    if (name.isEmpty || id.isEmpty || !RegExp(r'^\d+$').hasMatch(id)) continue;

    final key = '$id|$name';
    if (seen.add(key)) {
      employees.add('$id: $name');
    }
  }

  employees.sort();
  for (final e in employees) {
    print(e);
  }
  print('Total: ${employees.length}');
}
