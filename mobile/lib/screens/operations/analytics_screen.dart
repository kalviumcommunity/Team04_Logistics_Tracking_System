import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/delivery_provider.dart';

class AnalyticsScreen extends StatefulWidget {
  final bool isEmbedded;

  const AnalyticsScreen({super.key, this.isEmbedded = false});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  Map<String, dynamic>? _data;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchAnalytics();
    });
  }

  Future<void> _fetchAnalytics() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final deliveryProvider = Provider.of<DeliveryProvider>(context, listen: false);
      await deliveryProvider.fetchDeliveries();
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final deliveryProvider = Provider.of<DeliveryProvider>(context);
    final allDeliveries = deliveryProvider.deliveries;

    // Fallback analytics calculations if backend endpoint fails or is partial
    final total = allDeliveries.length;
    final delivered =
        allDeliveries.where((d) => d.status == 'DELIVERED').length;
    final failed = allDeliveries.where((d) => d.status == 'FAILED').length;
    final inTransit =
        allDeliveries.where((d) => d.status == 'IN_TRANSIT').length;

    final completedTotal = delivered + failed;
    final calculatedSuccessRate = completedTotal > 0
        ? ((delivered / completedTotal) * 100).toStringAsFixed(1)
        : '100.0';
    final calculatedFailureRate = completedTotal > 0
        ? ((failed / completedTotal) * 100).toStringAsFixed(1)
        : '0.0';

    final successRateStr =
        _data?['metrics']?['successRate'] ?? '$calculatedSuccessRate%';
    final failureRateStr =
        _data?['metrics']?['failureRate'] ?? '$calculatedFailureRate%';

    Widget bodyContent;

    if (_isLoading) {
      bodyContent = const Center(
        child: Padding(
          padding: EdgeInsets.all(48.0),
          child: CircularProgressIndicator(),
        ),
      );
    } else if (_errorMessage != null && allDeliveries.isEmpty) {
      bodyContent = Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.signal_wifi_off_rounded,
                  size: 44, color: AppColors.error),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkNavy,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _fetchAnalytics,
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Retry Connection'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.purple,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      final execList = (_data?['executivePerformance'] as List?);

      bodyContent = RefreshIndicator(
        onRefresh: () async {
          await _fetchAnalytics();
          await deliveryProvider.fetchDeliveries();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Metric Cards Strip
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: AppColors.success.withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('SUCCESS RATE',
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.success)),
                          const SizedBox(height: 4),
                          Text(successRateStr,
                              style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.success)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: AppColors.error.withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('FAILURE RATE',
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.error)),
                          const SizedBox(height: 4),
                          Text(failureRateStr,
                              style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.error)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Breakdown Summary Cards
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Volume & Telemetry Breakdown',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColors.darkNavy),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildStatItem('Total Orders', '$total', AppColors.purple),
                        _buildStatItem('In Transit', '$inTransit', AppColors.warning),
                        _buildStatItem('Delivered', '$delivered', AppColors.success),
                        _buildStatItem('Failed', '$failed', AppColors.error),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              const Text('Executive Performance Leaderboard',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: AppColors.darkNavy)),
              const SizedBox(height: 10),

              if (execList != null && execList.isNotEmpty)
                ...execList.map((exec) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const CircleAvatar(
                                radius: 14,
                                backgroundColor: AppColors.background,
                                child: Icon(Icons.person,
                                    size: 16, color: AppColors.textSecondary),
                              ),
                              const SizedBox(width: 10),
                              Text(exec['name'] ?? 'Executive Courier',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: AppColors.darkNavy)),
                            ],
                          ),
                          Text('${exec['successRate']}% Success',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.primaryBlue,
                                  fontSize: 12)),
                        ],
                      ),
                    ))
              else
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
                      'No executive telemetry available yet.',
                      style: TextStyle(
                          fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ),
                ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      );
    }

    if (widget.isEmbedded) {
      return bodyContent;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('System Telemetry & Analytics',
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
            onPressed: _fetchAnalytics,
          ),
        ],
      ),
      body: bodyContent,
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w900, color: color)),
        const SizedBox(height: 2),
        Text(label,
            style: const TextStyle(
                fontSize: 10,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600)),
      ],
    );
  }
}
