import 'package:flutter/material.dart';
import 'package:hr_portal/core/constants/app_constants.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 80});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Icon(
        Icons.business,
        size: size * 0.5,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}

class AppBarTitle extends StatelessWidget {
  const AppBarTitle({super.key, this.subtitle});

  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          AppConstants.appName,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        if (subtitle != null)
          Text(
            subtitle!,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
          ),
      ],
    );
  }
}
