import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/delivery_model.dart';
import '../../providers/delivery_provider.dart';
import '../../widgets/status_badge.dart';

class FailureReportScreen extends StatefulWidget {
  final DeliveryModel? delivery;
  final bool isEmbedded;

  const FailureReportScreen({
    super.key,
    this.delivery,
    this.isEmbedded = false,
  });

  @override
  State<FailureReportScreen> createState() => _FailureReportScreenState();
}

class _FailureReportScreenState extends State<FailureReportScreen> {
  String? _selectedDeliveryId;
  String _selectedReason = 'CUSTOMER_UNAVAILABLE';
  final _remarksController = TextEditingController();
  bool _calledCustomer = false;
  bool _verifiedAddress = false;
  bool _isSubmitting = false;

  Uint8List? _selectedImageBytes;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? file =
          await _picker.pickImage(source: source, imageQuality: 70);
      if (file != null) {
        final bytes = await file.readAsBytes();
        setState(() {
          _selectedImageBytes = bytes;
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  final List<Map<String, dynamic>> _reasons = [
    {
      'value': 'CUSTOMER_UNAVAILABLE',
      'label': 'Customer Unavailable',
      'description': 'Customer did not answer calls / door after 2+ attempts',
      'icon': Icons.person_off_rounded,
    },
    {
      'value': 'WRONG_ADDRESS',
      'label': 'Incorrect / Incomplete Address',
      'description': 'House/Street number does not exist or missing pin code',
      'icon': Icons.location_off_rounded,
    },
    {
      'value': 'CUSTOMER_REJECTED',
      'label': 'Customer Rejected Package',
      'description': 'Customer refused to accept delivery or cancelled order',
      'icon': Icons.cancel_outlined,
    },
    {
      'value': 'ADDRESS_INACCESSIBLE',
      'label': 'Address Inaccessible',
      'description': 'Security gate locked, roadblock, or access denied',
      'icon': Icons.block_rounded,
    },
    {
      'value': 'VEHICLE_ISSUE',
      'label': 'Vehicle Breakdown',
      'description': 'Flat tire, mechanical failure, or courier emergency',
      'icon': Icons.car_crash_rounded,
    },
    {
      'value': 'WEATHER_DELAY',
      'label': 'Severe Weather / Flood',
      'description': 'Road impassable due to extreme weather or storm',
      'icon': Icons.thunderstorm_rounded,
    },
    {
      'value': 'OTHER',
      'label': 'Other Operational Exception',
      'description': 'Other unexpected field logistics issue',
      'icon': Icons.help_outline_rounded,
    },
  ];

  @override
  void initState() {
    super.initState();
    if (widget.delivery != null) {
      _selectedDeliveryId = widget.delivery!.id;
    }
  }

  @override
  void dispose() {
    _remarksController.dispose();
    super.dispose();
  }

  Future<void> _submitFailure(DeliveryModel del) async {
    if (_remarksController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter detailed remarks explaining the failure.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    final provider = Provider.of<DeliveryProvider>(context, listen: false);
    final messenger = ScaffoldMessenger.of(context);

    String? proofUrl;
    if (_selectedImageBytes != null) {
      proofUrl = await provider.uploadImageBytes(
        storagePath: 'failure_proofs/${del.id}_${DateTime.now().millisecondsSinceEpoch}.jpg',
        bytes: _selectedImageBytes!,
      );
    }

    final success = await provider.submitFailure(
      del.id,
      _selectedReason,
      _remarksController.text.trim(),
      proofImageUrl: proofUrl,
    );

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (success) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text(
                'Failure report logged and escalated to Operations Manager.'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
        if (!widget.isEmbedded && Navigator.canPop(context)) {
          Navigator.pop(context);
        }
      } else {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
                provider.actionError ?? 'Failed to submit failure report.'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final deliveryProvider = Provider.of<DeliveryProvider>(context);
    final allDeliveries = deliveryProvider.deliveries;

    // Delivery being reported
    DeliveryModel? targetDelivery = widget.delivery;
    if (targetDelivery == null && _selectedDeliveryId != null) {
      try {
        targetDelivery =
            allDeliveries.firstWhere((d) => d.id == _selectedDeliveryId);
      } catch (_) {
        targetDelivery = null;
      }
    }

    final activeInTransit = allDeliveries
        .where((d) => d.status == 'IN_TRANSIT' || d.status == 'ASSIGNED')
        .toList();

    if (targetDelivery == null && activeInTransit.isNotEmpty) {
      targetDelivery = activeInTransit.first;
      _selectedDeliveryId = targetDelivery.id;
    }

    final content = SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Warning Banner
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: AppColors.error.withValues(alpha: 0.25)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.warning_amber_rounded,
                    color: AppColors.error, size: 22),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Escalation Notice',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: AppColors.error),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Submitting a failure report changes the shipment status to FAILED and immediately alerts the Operations Manager for investigation.',
                        style: TextStyle(
                            fontSize: 11, color: AppColors.darkNavy),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Shipment Summary Card ──────────────────────────────
          if (widget.delivery == null && activeInTransit.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Select Failed Shipment',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.darkNavy),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedDeliveryId,
                    isExpanded: true,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    items: activeInTransit.map((d) {
                      return DropdownMenuItem(
                        value: d.id,
                        child: Text(
                          '${d.trackingNumber} — ${d.customer?.fullName ?? "Customer"}',
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.darkNavy),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) =>
                        setState(() => _selectedDeliveryId = val),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          if (targetDelivery != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        targetDelivery.trackingNumber,
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: AppColors.primaryBlue),
                      ),
                      StatusBadge(status: targetDelivery.status),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    targetDelivery.customer?.fullName ?? 'Recipient Name',
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.darkNavy),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '📍 ${targetDelivery.deliveryAddress}, ${targetDelivery.city}',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // ── Failure Reason Selection ───────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Reason for Failure *',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppColors.darkNavy),
                ),
                const SizedBox(height: 12),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _reasons.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, index) {
                    final item = _reasons[index];
                    final isSelected = _selectedReason == item['value'];

                    return InkWell(
                      onTap: () =>
                          setState(() => _selectedReason = item['value']),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.error.withValues(alpha: 0.06)
                              : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.error
                                : AppColors.border,
                            width: isSelected ? 1.5 : 1.0,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              item['icon'] as IconData,
                              color: isSelected
                                  ? AppColors.error
                                  : AppColors.textSecondary,
                              size: 18,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['label'] as String,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: isSelected
                                          ? AppColors.error
                                          : AppColors.darkNavy,
                                    ),
                                  ),
                                  Text(
                                    item['description'] as String,
                                    style: const TextStyle(
                                        fontSize: 10,
                                        color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.error
                                      : AppColors.textMuted,
                                  width: isSelected ? 6 : 2,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Pre-flight Verification Checklist ──────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Courier Verification Checklist',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppColors.darkNavy),
                ),
                const SizedBox(height: 8),
                CheckboxListTile(
                  value: _calledCustomer,
                  activeColor: AppColors.primaryBlue,
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: const Text(
                    'I attempted to call the customer at least twice',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.darkNavy),
                  ),
                  onChanged: (val) =>
                      setState(() => _calledCustomer = val ?? false),
                ),
                CheckboxListTile(
                  value: _verifiedAddress,
                  activeColor: AppColors.primaryBlue,
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: const Text(
                    'I checked neighboring buildings / street numbers on map',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.darkNavy),
                  ),
                  onChanged: (val) =>
                      setState(() => _verifiedAddress = val ?? false),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Detailed Remarks Text Area ─────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Detailed Failure Remarks *',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppColors.darkNavy),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _remarksController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText:
                        'State specific circumstances (e.g. Arrived at 14:15, gate locked, called customer 3 times with no answer)...',
                    hintStyle: const TextStyle(
                        fontSize: 12, color: AppColors.textMuted),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 14),

                // Proof / Exception Photo attachment
                const Text(
                  'Exception Photo Evidence (Optional)',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.darkNavy),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => _pickImage(ImageSource.camera),
                      icon: const Icon(Icons.camera_alt_rounded, size: 18),
                      label: const Text('Take Photo'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: () => _pickImage(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library_rounded, size: 18),
                      label: const Text('Gallery'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF64748B),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
                if (_selectedImageBytes != null) ...[
                  const SizedBox(height: 10),
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.memory(
                          _selectedImageBytes!,
                          height: 110,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedImageBytes = null),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close, size: 16, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── Submit Button ──────────────────────────────────────
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: (_isSubmitting || targetDelivery == null)
                  ? null
                  : () => _submitFailure(targetDelivery!),
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.report_problem_rounded),
              label: Text(
                _isSubmitting
                    ? 'Submitting Report...'
                    : 'Submit Failure & Escalate',
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );

    if (widget.isEmbedded) {
      return content;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Report Delivery Failure',
          style: TextStyle(
            color: AppColors.error,
            fontWeight: FontWeight.w900,
            fontSize: 16,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: AppColors.error),
      ),
      body: content,
    );
  }
}
