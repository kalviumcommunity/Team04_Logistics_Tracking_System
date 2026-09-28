import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/phone_caller.dart';
import '../../models/delivery_model.dart';
import '../../providers/delivery_provider.dart';
import '../../widgets/status_badge.dart';
import 'active_delivery_screen.dart';
import 'failure_report_screen.dart';

class ExecutiveDeliveryDetailsScreen extends StatefulWidget {
  final String deliveryId;
  final DeliveryModel? initialDelivery;

  const ExecutiveDeliveryDetailsScreen({
    super.key,
    required this.deliveryId,
    this.initialDelivery,
  });

  @override
  State<ExecutiveDeliveryDetailsScreen> createState() =>
      _ExecutiveDeliveryDetailsScreenState();
}

class _ExecutiveDeliveryDetailsScreenState
    extends State<ExecutiveDeliveryDetailsScreen> {
  DeliveryModel? _delivery;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _delivery = widget.initialDelivery;
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final provider = Provider.of<DeliveryProvider>(context, listen: false);
    final del = await provider.getDeliveryDetails(widget.deliveryId);

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (del != null) {
          _delivery = del;
        } else if (_delivery == null) {
          _errorMessage = provider.actionError ??
              'Unable to retrieve delivery details. Please check network.';
        }
      });
    }
  }

  Future<void> _launchNavigation(String address, String city) async {
    final query = Uri.encodeComponent('$address, $city');
    final googleMapsUrl =
        Uri.parse('https://www.google.com/maps/search/?api=1&query=$query');
    final geoUrl = Uri.parse('geo:0,0?q=$query');

    try {
      if (await canLaunchUrl(geoUrl)) {
        await launchUrl(geoUrl);
      } else if (await canLaunchUrl(googleMapsUrl)) {
        await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open map navigation for "$address"'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    await PhoneCaller.makePhoneCall(context, phoneNumber, roleLabel: 'Customer');
  }

  Future<void> _sendSms(String phoneNumber) async {
    await PhoneCaller.sendSms(context, phoneNumber, roleLabel: 'Customer');
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied to clipboard'),
        backgroundColor: AppColors.darkNavy,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showCompleteDialog() {
    final remarksController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.check_circle_rounded,
                color: AppColors.success, size: 22),
            SizedBox(width: 8),
            Text('Complete Delivery',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Confirm that package has been safely handed over to the recipient.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: remarksController,
              decoration: InputDecoration(
                labelText: 'Delivery Notes / Recipient Proof',
                hintText: 'e.g. Handed to customer at front door',
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(ctx);
              final provider =
                  Provider.of<DeliveryProvider>(context, listen: false);
              final success = await provider.updateStatus(
                _delivery!.id,
                'DELIVERED',
                remarks: remarksController.text.trim().isNotEmpty
                    ? remarksController.text.trim()
                    : 'Delivered successfully by executive',
              );
              if (mounted) {
                if (success) {
                  _loadDetails();
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Delivery marked as DELIVERED! 🎉'),
                      backgroundColor: AppColors.success,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                } else {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(provider.actionError ??
                          'Failed to update delivery status.'),
                      backgroundColor: AppColors.error,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirm Delivery',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final del = _delivery;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          del?.trackingNumber ?? 'Delivery Details',
          style: const TextStyle(
            color: AppColors.darkNavy,
            fontWeight: FontWeight.w900,
            fontSize: 16,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: AppColors.darkNavy),
        actions: [
          if (del != null)
            IconButton(
              icon: const Icon(Icons.copy_rounded, size: 18),
              tooltip: 'Copy Tracking ID',
              onPressed: () =>
                  _copyToClipboard(del.trackingNumber, 'Tracking Number'),
            ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: _loadDetails,
          ),
        ],
      ),
      bottomNavigationBar: del != null ? _buildBottomActions(del) : null,
      body: _isLoading && del == null
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null && del == null
              ? _buildErrorView()
              : del != null
                  ? RefreshIndicator(
                      onRefresh: _loadDetails,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ── 1. Status & Overview Card ─────────────
                            _buildOverviewCard(del),
                            const SizedBox(height: 16),

                            // ── 2. Route & Navigation Card ───────────
                            _buildRouteCard(del),
                            const SizedBox(height: 16),

                            // ── 3. Customer Contact Card ─────────────
                            _buildCustomerCard(del),
                            const SizedBox(height: 16),

                            // ── 4. Milestone Timeline ────────────────
                            _buildTimelineCard(del),
                            const SizedBox(height: 80),
                          ],
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
    );
  }

  Widget _buildOverviewCard(DeliveryModel del) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Tracking Number',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary)),
                  const SizedBox(height: 2),
                  Text(del.trackingNumber,
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primaryBlue)),
                ],
              ),
              StatusBadge(status: del.status, large: true),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _metaBlock(
                  label: 'ETA',
                  value: del.eta ?? 'Standard (45 mins)',
                  icon: Icons.schedule_rounded,
                ),
              ),
              Expanded(
                child: _metaBlock(
                  label: 'City Zone',
                  value: del.city,
                  icon: Icons.location_city_rounded,
                ),
              ),
            ],
          ),
          if (del.remarks != null && del.remarks!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline_rounded,
                      size: 16, color: AppColors.primaryBlue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Remarks: ${del.remarks!}',
                      style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.darkNavy,
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _metaBlock(
      {required String label,
      required String value,
      required IconData icon}) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600)),
            Text(value,
                style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.darkNavy,
                    fontWeight: FontWeight.w700)),
          ],
        ),
      ],
    );
  }

  Widget _buildRouteCard(DeliveryModel del) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.route_rounded, size: 18, color: AppColors.primaryBlue),
              SizedBox(width: 6),
              Text(
                'Delivery Route & Navigation',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.darkNavy),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Route timeline
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  const Icon(Icons.radio_button_checked,
                      size: 14, color: AppColors.primaryBlue),
                  Container(width: 2, height: 38, color: AppColors.border),
                  const Icon(Icons.location_on,
                      size: 16, color: AppColors.error),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('PICKUP LOCATION',
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSecondary)),
                    const SizedBox(height: 2),
                    Text(del.pickupAddress,
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.darkNavy)),
                    const SizedBox(height: 14),
                    const Text('DELIVERY DESTINATION',
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSecondary)),
                    const SizedBox(height: 2),
                    Text('${del.deliveryAddress}, ${del.city}',
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: AppColors.darkNavy)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Open Maps Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () =>
                  _launchNavigation(del.deliveryAddress, del.city),
              icon: const Icon(Icons.navigation_rounded, size: 16),
              label: const Text('Open in Navigation App (Maps)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerCard(DeliveryModel del) {
    final customer = del.customer;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.person_outline_rounded,
                  size: 18, color: AppColors.primaryBlue),
              SizedBox(width: 6),
              Text(
                'Customer Information',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.darkNavy),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.primaryBlue.withValues(alpha: 0.1),
                child: Text(
                  customer?.fullName.isNotEmpty == true
                      ? customer!.fullName[0].toUpperCase()
                      : 'C',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryBlue,
                      fontSize: 16),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customer?.fullName ?? 'Customer Name',
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.darkNavy),
                    ),
                    Text(
                      (customer?.phone.isNotEmpty == true)
                          ? customer!.phone
                          : 'Phone not available',
                      style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500),
                    ),
                    if (customer?.email != null && (customer?.email?.isNotEmpty ?? false))
                      Text(
                        customer!.email!,
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textMuted),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: 12),

          // Call & SMS Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _makePhoneCall(customer?.phone ?? ''),
                  icon: const Icon(Icons.phone_rounded, size: 16),
                  label: const Text('Call Customer'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryBlue,
                    side: const BorderSide(color: AppColors.primaryBlue),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _sendSms(customer?.phone ?? ''),
                  icon: const Icon(Icons.sms_rounded, size: 16),
                  label: const Text('Send SMS'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.darkNavy,
                    side: const BorderSide(color: AppColors.border),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineCard(DeliveryModel del) {
    final history = del.statusHistory ?? [];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.history_rounded,
                  size: 18, color: AppColors.primaryBlue),
              SizedBox(width: 6),
              Text(
                'Status Milestone History',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.darkNavy),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (history.isEmpty)
            Text(
              'Initial order status: ${del.status}',
              style:
                  const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: history.length,
              itemBuilder: (_, index) {
                final item = history[index];
                final isLast = index == history.length - 1;

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: const BoxDecoration(
                            color: AppColors.primaryBlue,
                            shape: BoxShape.circle,
                          ),
                        ),
                        if (!isLast)
                          Container(
                              width: 2, height: 36, color: AppColors.border),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  item.status.replaceAll('_', ' '),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13,
                                      color: AppColors.darkNavy),
                                ),
                                Text(
                                  item.createdAt.length >= 16
                                      ? item.createdAt.substring(0, 16)
                                      : item.createdAt,
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                            if (item.remarks != null &&
                                item.remarks!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 2.0),
                                child: Text(
                                  item.remarks!,
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textSecondary),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildBottomActions(DeliveryModel del) {
    final isAssigned = del.status == 'ASSIGNED';
    final isInTransit = del.status == 'IN_TRANSIT';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: AppColors.border)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            if (isAssigned)
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    final provider =
                        Provider.of<DeliveryProvider>(context, listen: false);
                    final success = await provider.updateStatus(
                      del.id,
                      'IN_TRANSIT',
                      remarks: 'Executive started delivery route',
                    );
                    if (mounted) {
                      if (success) {
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text('Delivery started! Now in transit.'),
                            backgroundColor: AppColors.success,
                          ),
                        );
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                ActiveDeliveryScreen(deliveryId: del.id),
                          ),
                        );
                      } else {
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(provider.actionError ??
                                'Failed to start delivery.'),
                            backgroundColor: AppColors.error,
                          ),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.play_arrow_rounded, size: 18),
                  label: const Text('Start Delivery Route'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 46),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              )
            else if (isInTransit) ...[
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => FailureReportScreen(delivery: del),
                      ),
                    ).then((_) => _loadDetails());
                  },
                  icon: const Icon(Icons.report_problem_rounded, size: 16),
                  label: const Text('Report Issue'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: BorderSide(
                        color: AppColors.error.withValues(alpha: 0.4)),
                    minimumSize: const Size(double.infinity, 46),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: _showCompleteDialog,
                  icon: const Icon(Icons.check_circle_rounded, size: 18),
                  label: const Text('Mark Delivered'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 46),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ] else ...[
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Order status is ${del.status.replaceAll('_', ' ')}',
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 48, color: AppColors.error),
            const SizedBox(height: 12),
            Text(
              _errorMessage ?? 'Failed to load details',
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: AppColors.darkNavy),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadDetails,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
              ),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}
