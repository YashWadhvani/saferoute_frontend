// lib/screens/reports/reports_screen.dart
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/api/api_response.dart';
import '../../core/theme/app_text_styles.dart';
import '../../services/report_service.dart';
import '../../models/report_model.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final ReportService _reportService = ReportService();
  final TextEditingController _descController = TextEditingController();

  late Future<ApiResponse<List<Report>>> _reportsFuture;
  String _selectedType = 'suspicious_activity';
  int _severity = 3;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _reportsFuture = _reportService.getUserReports();
  }

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }

  void _refreshReports() {
    setState(() {
      _reportsFuture = _reportService.getUserReports();
    });
  }

  Future<void> _submitReport() async {
    if (_descController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a description')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      final res = await _reportService.submitReport(
        type: _selectedType,
        description: _descController.text.trim(),
        latitude: pos.latitude,
        longitude: pos.longitude,
        severity: _severity,
      );

      if (!mounted) return;
      if (res.isSuccess) {
        _descController.clear();
        _severity = 3;
        _selectedType = 'suspicious_activity';
        _refreshReports();
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Report submitted successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res.error ?? 'Failed to submit report')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to submit report: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reports')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Report an incident',
                        style: AppTextStyles.titleMedium),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: _selectedType,
                      decoration:
                          const InputDecoration(labelText: 'Issue Type'),
                      items: const [
                        DropdownMenuItem(
                            value: 'harassment', child: Text('Harassment')),
                        DropdownMenuItem(value: 'theft', child: Text('Theft')),
                        DropdownMenuItem(
                            value: 'accident', child: Text('Accident')),
                        DropdownMenuItem(
                            value: 'dark_area', child: Text('Dark Area')),
                        DropdownMenuItem(
                            value: 'suspicious_activity',
                            child: Text('Suspicious Activity')),
                      ],
                      onChanged: (v) => setState(
                          () => _selectedType = v ?? 'suspicious_activity'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _descController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                          labelText: 'Description',
                          hintText: 'Describe what happened...'),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Text('Severity'),
                        Expanded(
                          child: Slider(
                            min: 1,
                            max: 5,
                            divisions: 4,
                            value: _severity.toDouble(),
                            label: '$_severity',
                            onChanged: (v) =>
                                setState(() => _severity = v.round()),
                          ),
                        ),
                        Text('$_severity'),
                      ],
                    ),
                    const SizedBox(height: 6),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isSubmitting ? null : _submitReport,
                        icon: _isSubmitting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.send),
                        label: Text(
                            _isSubmitting ? 'Submitting...' : 'Submit Report'),
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<ApiResponse<List<Report>>>(
              future: _reportsFuture,
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
                        style: AppTextStyles.bodyLarge),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async => _refreshReports(),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: reports.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final r = reports[i];
                      return ListTile(
                        title: Text(r.type.replaceAll('_', ' ')),
                        subtitle: Text('${r.description}\n${r.createdAt}'),
                        trailing: Text('S${r.severity}'),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
