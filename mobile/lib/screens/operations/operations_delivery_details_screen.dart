import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/phone_caller.dart';
import '../../models/delivery_model.dart';
import '../../providers/delivery_provider.dart';
import '../../widgets/status_badge.dart';

class OperationsDeliveryDetailsScreen extends StatefulWidget {
  final String deliveryId;
  final DeliveryModel? initialDelivery;
  final bool isEmbedded;

  const OperationsDeliveryDetailsScreen({
    super.key,
    required this.deliveryId,
    this.initialDelivery,
    this.isEmbedded = false,
  });

  @override
  State<OperationsDeliveryDetailsScreen> createState() =>
      _OperationsDeliveryDetailsScreenState();
}

class _OperationsDeliveryDetailsScreenState
    extends State<OperationsDeliveryDetailsScreen> {
  DeliveryModel? _delivery;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.initialDelivery != null) {
      _delivery = widget.initialDelivery;
      _isLoading = false;
    }
    _loadDeliveryDetails();
  }

  Future<void> _loadDeliveryDetails() async {
    final provider = Provider.of<DeliveryProvider>(context, listen: false);
    try {
      final fetched = await provider.getDeliveryDetails(widget.deliveryId);
      if (!mounted) return;
      setState(() {
        _delivery = fetched ?? _delivery;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        if (_delivery == null) {
          _errorMessage = 'Could not retrieve delivery telemetry.';
        }
      });
    }
  }

  Future<void> _makePhoneCall(String phone) async {
    await PhoneCaller.makePhoneCall(context, phone, roleLabel: 'Customer');
  }

  Future<void> _sendSms(String phone) async {
    await PhoneCaller.sendSms(context, phone, roleLabel: 'Customer');
  }

  @override
  Widget build(BuildContext context) {
    Widget bodyContent;

    if (_isLoading && _delivery == null) {
      bodyContent = const Center(
        child: Padding(
          padding: EdgeInsets.all(48.0),
          child: CircularProgressIndicator(),
        ),
      );
    } else if (_errorMessage != null && _delivery == null) {
      bodyContent = Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded,
                  size: 40, color: AppColors.error),
              const SizedBox(height: 10),
              Text(_errorMessage!,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 14),
              ElevatedButton(
                onPressed: _loadDeliveryDetails,
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.purple,
                    foregroundColor: Colors.white),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    } else {
      final del = _delivery!;
      final customer = del.customer;
      final executive = del.assignedExecutive;

      bodyContent = RefreshIndicator(
        onRefresh: _loadDeliveryDetails,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      AppColors.darkNavy,
                      AppColors.primaryBlue,
                      AppColors.purple
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.purple.withValues(alpha: 0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          del.trackingNumber,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                        StatusBadge(status: del.status, large: true),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(Icons.schedule_rounded,
                            size: 14, color: Colors.white70),
                        const SizedBox(width: 6),
                        Text(
                          'Estimated Delivery: ${del.eta ?? "Standard"}',
                          style: const TextStyle(
                              fontSize: 12, color: Colors.white70),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Route & Addresses Card
              _buildSectionCard(
                title: 'Shipment Route & Hub Destination',
                icon: Icons.map_rounded,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          children: [
                            const Icon(Icons.radio_button_checked,
                                size: 14, color: AppColors.purple),
                            Container(
                                width: 2, height: 32, color: AppColors.border),
                            const Icon(Icons.location_on,
                                size: 16, color: AppColors.error),
                          ],
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Pickup Hub Warehouse',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textSecondary,
                                      fontWeight: FontWeight.w600)),
                              Text(del.pickupAddress,
                                  style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.darkNavy)),
                              const SizedBox(height: 16),
                              const Text('Destination Address',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textSecondary,
                                      fontWeight: FontWeight.w600)),
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
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Customer Details Card
              _buildSectionCard(
                title: 'Customer Contact Details',
                icon: Icons.person_rounded,
                child: Column(
                  children: [
                    Row(
                      children: [
                        const CircleAvatar(
                          radius: 20,
                          backgroundColor: AppColors.background,
                          child: Icon(Icons.person,
                              size: 20, color: AppColors.textSecondary),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                customer?.fullName ?? 'Customer Name',
                                style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.darkNavy),
                              ),
                              Text(
                                (customer?.phone.isNotEmpty == true)
                                    ? customer!.phone
                                    : 'Phone not available',
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary),
                              ),
                              if (customer?.email != null &&
                                  (customer?.email?.isNotEmpty ?? false))
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
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () =>
                                _makePhoneCall(customer?.phone ?? ''),
                            icon: const Icon(Icons.phone_rounded, size: 16),
                            label: const Text('Call Customer'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.purple,
                              side: const BorderSide(color: AppColors.purple),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
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
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Assigned Field Executive Card
              _buildSectionCard(
                title: 'Assigned Field Courier',
                icon: Icons.two_wheeler_rounded,
                child: executive != null
                    ? Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor:
                                AppColors.cyanTeal.withValues(alpha: 0.15),
                            child: Text(executive.initials,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.cyanTeal)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(executive.fullName,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        color: AppColors.darkNavy)),
                                Text(executive.email,
                                    style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textSecondary)),
                              ],
                            ),
                          ),
                          if (executive.phone.isNotEmpty)
                            IconButton.filledTonal(
                              icon: const Icon(Icons.phone,
                                  size: 16, color: AppColors.cyanTeal),
                              onPressed: () => _makePhoneCall(executive.phone),
                            ),
                        ],
                      )
                    : const Text(
                        'Unassigned — Pending dispatcher courier allocation.',
                        style: TextStyle(
                            fontSize: 12,
                            color: AppColors.warning,
                            fontWeight: FontWeight.bold),
                      ),
              ),
              const SizedBox(height: 16),

              // Milestone History
              _buildSectionCard(
                title: 'Status Event Audit Trail',
                icon: Icons.history_rounded,
                child: (del.statusHistory == null || del.statusHistory!.isEmpty)
                    ? Text(
                        'Current order status: ${del.status}',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: del.statusHistory!.length,
                        itemBuilder: (context, index) {
                          final item = del.statusHistory![index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10.0),
                            child: Row(
                              children: [
                                const Icon(Icons.check_circle_outline_rounded,
                                    size: 16, color: AppColors.purple),
                                const SizedBox(width: 8),
                                Text(item.status,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                        color: AppColors.darkNavy)),
                                const Spacer(),
                                Text(
                                  item.createdAt.length >= 10
                                      ? item.createdAt.substring(0, 10)
                                      : item.createdAt,
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textMuted),
                                ),
                              ],
                            ),
                          );
                        },
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
        title: Text(
          _delivery?.trackingNumber ?? 'Delivery Details',
          style: const TextStyle(
            color: AppColors.darkNavy,
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: AppColors.darkNavy),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadDeliveryDetails,
          ),
        ],
      ),
      body: bodyContent,
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
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
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.purple),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.darkNavy),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
