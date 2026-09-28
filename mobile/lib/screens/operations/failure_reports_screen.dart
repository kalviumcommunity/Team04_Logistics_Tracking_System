import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/delivery_provider.dart';
import '../../providers/escalation_provider.dart';

class FailureReportsScreen extends StatefulWidget {
  final bool isEmbedded;

  const FailureReportsScreen({super.key, this.isEmbedded = false});

  @override
  State<FailureReportsScreen> createState() => _FailureReportsScreenState();
}

class _FailureReportsScreenState extends State<FailureReportsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Provider.of<DeliveryProvider>(context, listen: false).fetchDeliveries();
        Provider.of<EscalationProvider>(context, listen: false)
            .fetchEscalations();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final deliveryProvider = Provider.of<DeliveryProvider>(context);
    final escalationProvider = Provider.of<EscalationProvider>(context);

    final allDeliveries = deliveryProvider.deliveries;
    final escalations = escalationProvider.escalations;

    final failedDeliveries =
        allDeliveries.where((d) => d.status == 'FAILED').toList();
    final cancelledDeliveries =
        allDeliveries.where((d) => d.status == 'CANCELLED').toList();

    // Reason frequency analysis
    final Map<String, int> reasonCounts = {
      'Customer Unavailable': 0,
      'Incorrect / Incomplete Address': 0,
      'Recipient Refused Parcel': 0,
      'Damaged / Lost Goods': 0,
      'Access / Security Restricted': 0,
      'Weather / Traffic Disruption': 0,
      'Other Exceptions': 0,
    };

    for (var d in failedDeliveries) {
      final r = d.remarks?.toUpperCase() ?? '';
      if (r.contains('UNAVAILABLE') || r.contains('NO ANSWER')) {
        reasonCounts['Customer Unavailable'] =
            (reasonCounts['Customer Unavailable'] ?? 0) + 1;
      } else if (r.contains('ADDRESS') || r.contains('NOT FOUND')) {
        reasonCounts['Incorrect / Incomplete Address'] =
            (reasonCounts['Incorrect / Incomplete Address'] ?? 0) + 1;
      } else if (r.contains('REFUSED') || r.contains('REJECTED')) {
        reasonCounts['Recipient Refused Parcel'] =
            (reasonCounts['Recipient Refused Parcel'] ?? 0) + 1;
      } else if (r.contains('DAMAGED') || r.contains('BROKEN')) {
        reasonCounts['Damaged / Lost Goods'] =
            (reasonCounts['Damaged / Lost Goods'] ?? 0) + 1;
      } else {
        reasonCounts['Other Exceptions'] =
            (reasonCounts['Other Exceptions'] ?? 0) + 1;
      }
    }

    for (var esc in escalations) {
      final r = (esc.reason ?? '').toUpperCase();
      if (r.contains('UNAVAILABLE') || r == 'CUSTOMER_UNAVAILABLE') {
        reasonCounts['Customer Unavailable'] =
            (reasonCounts['Customer Unavailable'] ?? 0) + 1;
      } else if (r.contains('ADDRESS') || r == 'WRONG_ADDRESS') {
        reasonCounts['Incorrect / Incomplete Address'] =
            (reasonCounts['Incorrect / Incomplete Address'] ?? 0) + 1;
      } else if (r.contains('REFUSED') || r == 'CUSTOMER_REFUSED') {
        reasonCounts['Recipient Refused Parcel'] =
            (reasonCounts['Recipient Refused Parcel'] ?? 0) + 1;
      } else if (r.contains('DAMAGED') || r == 'DAMAGED_PARCEL') {
        reasonCounts['Damaged / Lost Goods'] =
            (reasonCounts['Damaged / Lost Goods'] ?? 0) + 1;
      } else if (r.contains('RESTRICTED') || r == 'RESTRICTED_ACCESS') {
        reasonCounts['Access / Security Restricted'] =
            (reasonCounts['Access / Security Restricted'] ?? 0) + 1;
      } else if (r.contains('WEATHER') || r.contains('TRAFFIC') || r == 'WEATHER_TRAFFIC') {
        reasonCounts['Weather / Traffic Disruption'] =
            (reasonCounts['Weather / Traffic Disruption'] ?? 0) + 1;
      } else if (r.isNotEmpty) {
        reasonCounts['Other Exceptions'] =
            (reasonCounts['Other Exceptions'] ?? 0) + 1;
      }
    }

    Widget content = RefreshIndicator(
      onRefresh: () async {
        await deliveryProvider.fetchDeliveries();
        await escalationProvider.fetchEscalations();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Report Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    AppColors.darkNavy,
                    AppColors.purple,
                    AppColors.error
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.assessment_rounded,
                          color: Colors.white, size: 24),
                      SizedBox(width: 10),
                      Text(
                        'Root Cause Failure Analysis',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Operational diagnostic report summarizing delivery attempt exceptions, incident categories, and resolution velocity.',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Summary Metrics Cards
            Row(
              children: [
                Expanded(
                  child: _buildReportCard(
                    title: 'Total Failed',
                    value: '${failedDeliveries.length}',
                    color: AppColors.error,
                    icon: Icons.cancel_outlined,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildReportCard(
                    title: 'Cancelled',
                    value: '${cancelledDeliveries.length}',
                    color: AppColors.warning,
                    icon: Icons.remove_circle_outline,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildReportCard(
                    title: 'Escalations',
                    value: '${escalations.length}',
                    color: AppColors.purple,
                    icon: Icons.warning_amber_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Reason Breakdown Section
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.pie_chart_outline_rounded,
                          size: 18, color: AppColors.purple),
                      SizedBox(width: 8),
                      Text(
                        'Failure Reason Distribution',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColors.darkNavy,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Divider(height: 1, color: AppColors.divider),
                  const SizedBox(height: 14),
                  if (failedDeliveries.isEmpty && escalations.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: const Center(
                        child: Text(
                          'No failure incidents or escalations recorded.',
                          style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    )
                  else
                    ...reasonCounts.entries.map((entry) {
                      final int totalExceptions =
                          failedDeliveries.length + escalations.length;
                      final double pct = totalExceptions > 0
                          ? (entry.value / totalExceptions)
                          : 0.0;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  entry.key,
                                  style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.darkNavy),
                                ),
                                Text(
                                  '${entry.value} cases (${(pct * 100).toStringAsFixed(0)}%)',
                                  style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            LinearProgressIndicator(
                              value: pct,
                              backgroundColor: const Color(0xFFF1F5F9),
                              color: entry.value > 0
                                 ? AppColors.error
                                  : AppColors.border,
                              minHeight: 6,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ],
                        ),
                      );
                    }),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Escalation Resolution Log
            const Text(
              'Recent Escalation Resolution Logs',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: AppColors.darkNavy,
              ),
            ),
            const SizedBox(height: 10),

            if (escalations.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Center(
                  child: Text(
                    'No escalation resolution logs recorded.',
                    style:
                        TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: escalations.length.clamp(0, 5),
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final esc = escalations[index];
                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          esc.status == 'RESOLVED'
                              ? Icons.check_circle_rounded
                              : Icons.warning_amber_rounded,
                          color: esc.status == 'RESOLVED'
                              ? AppColors.success
                              : AppColors.warning,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                esc.delivery?.trackingNumber ??
                                    'Escalation Log',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: AppColors.darkNavy),
                              ),
                              Text(
                                esc.reason ?? 'Failure reported',
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: (esc.status == 'RESOLVED'
                                    ? AppColors.success
                                    : AppColors.warning)
                                .withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            esc.status,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: esc.status == 'RESOLVED'
                                  ? AppColors.success
                                  : AppColors.warning,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );

    if (widget.isEmbedded) {
      return content;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Failure Reports',
            style: TextStyle(
                color: AppColors.darkNavy,
                fontWeight: FontWeight.bold,
                fontSize: 16)),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: AppColors.darkNavy),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              deliveryProvider.fetchDeliveries();
              escalationProvider.fetchEscalations();
            },
          ),
        ],
      ),
      body: content,
    );
  }

  Widget _buildReportCard({
    required String title,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 8),
          Text(value,
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w900, color: color)),
          const SizedBox(height: 2),
          Text(title,
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
