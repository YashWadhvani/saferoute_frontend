// lib/screens/reports/reports_screen.dart
import 'package:flutter/material.dart';
import '../../core/api/api_response.dart';
import '../../core/theme/app_text_styles.dart';
import '../../services/report_service.dart';
import '../../models/report_model.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Reports')),
      body: FutureBuilder<ApiResponse<List<Report>>>(
        future: ReportService().getUserReports(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final res = snapshot.data;
          if (res == null || !res.isSuccess) {
            return Center(child: Text(res?.error ?? 'No reports found'));
          }

          final reports = res.data ?? [];
          if (reports.isEmpty) {
            return Center(
                child: Text('No reports submitted yet',
                    style: AppTextStyles.bodyLarge));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: reports.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final r = reports[i];
              return ListTile(
                title: Text(r.type),
                subtitle: Text('${r.description}\n${r.createdAt}'),
                trailing: Text('${r.severity}'),
              );
            },
          );
        },
      ),
    );
  }
}
