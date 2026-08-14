import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hr_portal/core/router/app_router.dart';
import 'package:hr_portal/core/widgets/app_logo.dart';
import 'package:hr_portal/core/widgets/error_view.dart';
import 'package:hr_portal/core/widgets/loading_overlay.dart';
import 'package:hr_portal/core/widgets/responsive_layout.dart';
import 'package:hr_portal/models/holiday_calendar_document.dart';
import 'package:hr_portal/providers/holiday_calendar_providers.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class HolidayCalendarPage extends ConsumerWidget {
  const HolidayCalendarPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final calendarAsync = ref.watch(holidayCalendarProvider);

    return Scaffold(
      appBar: AppBar(
        title: const AppBarTitle(subtitle: 'Holiday Calendar'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back to dashboard',
          onPressed: () => context.go(AppRoutes.attendanceLeaves),
        ),
      ),
      body: ResponsivePadding(
        child: calendarAsync.when(
          loading: () =>
              const AppLoadingIndicator(message: 'Loading holiday calendar...'),
          error: (error, _) => ErrorView(message: error.toString()),
          data: (calendar) => calendar == null
              ? const _BundledCalendar()
              : _CalendarDocumentCard(calendar: calendar),
        ),
      ),
    );
  }
}

class _BundledCalendar extends StatelessWidget {
  const _BundledCalendar();

  Future<void> _openPdf(BuildContext context) async {
    final opened = await launchUrl(
      Uri.base.resolve('/holiday-calendar-2026.pdf'),
      mode: LaunchMode.externalApplication,
    );
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the holiday calendar.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.picture_as_pdf_outlined,
                size: 52,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                '2026 Holiday Calendar',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'India Team Holiday Calendar_2026.pdf',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => _openPdf(context),
                icon: const Icon(Icons.open_in_new),
                label: const Text('View Holiday Calendar PDF'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CalendarDocumentCard extends StatelessWidget {
  const _CalendarDocumentCard({required this.calendar});

  final HolidayCalendarDocument calendar;

  Future<void> _openPdf(BuildContext context) async {
    final opened = await launchUrl(
      Uri.parse(calendar.downloadUrl),
      mode: LaunchMode.externalApplication,
    );
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the holiday calendar.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasUploadDate = calendar.uploadedAt.millisecondsSinceEpoch > 0;
    final uploadedLabel = hasUploadDate
        ? DateFormat('dd MMM yyyy, hh:mm a').format(calendar.uploadedAt)
        : 'just now';

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  Icons.picture_as_pdf_outlined,
                  size: 64,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 20),
                Text(
                  '${calendar.year} Holiday Calendar',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  calendar.fileName,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Published $uploadedLabel',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.65),
                  ),
                ),
                const SizedBox(height: 28),
                ElevatedButton.icon(
                  onPressed: () => _openPdf(context),
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('View Holiday Calendar PDF'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
