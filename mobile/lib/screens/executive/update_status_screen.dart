import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/delivery_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/delivery_provider.dart';
import '../../widgets/status_badge.dart';
import 'failure_report_screen.dart';

class UpdateStatusScreen extends StatefulWidget {
  final bool isEmbedded;
  final String? preselectedDeliveryId;

  const UpdateStatusScreen({
    super.key,
    this.isEmbedded = false,
    this.preselectedDeliveryId,
  });

  @override
  State<UpdateStatusScreen> createState() => _UpdateStatusScreenState();
}

class _UpdateStatusScreenState extends State<UpdateStatusScreen> {
  String? _selectedDeliveryId;
  String _selectedNextStatus = 'DELIVERED';
  final _proofController = TextEditingController(text: 'Handed to customer');
  final _remarksController = TextEditingController();
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

  @override
  void initState() {
    super.initState();
    _selectedDeliveryId = widget.preselectedDeliveryId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Provider.of<DeliveryProvider>(context, listen: false).fetchDeliveries();
      }
    });
  }

  @override
  void dispose() {
    _proofController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  Future<void> _submitStatusUpdate(DeliveryModel del) async {
    if (_selectedNextStatus == 'FAILED') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => FailureReportScreen(delivery: del),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    final provider = Provider.of<DeliveryProvider>(context, listen: false);
    final messenger = ScaffoldMessenger.of(context);

    final combinedRemarks = [
      if (_proofController.text.trim().isNotEmpty)
        'Proof: ${_proofController.text.trim()}',
      if (_remarksController.text.trim().isNotEmpty)
        _remarksController.text.trim(),
    ].join(' | ');

    String? proofUrl;
    if (_selectedImageBytes != null) {
      proofUrl = await provider.uploadImageBytes(
        storagePath: 'delivery_proofs/${del.id}_${DateTime.now().millisecondsSinceEpoch}.jpg',
        bytes: _selectedImageBytes!,
      );
    }

    final success = await provider.updateStatus(
      del.id,
      _selectedNextStatus,
      remarks: combinedRemarks.isNotEmpty ? combinedRemarks : null,
      proofImageUrl: proofUrl,
    );

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (success) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
                'Status updated to ${_selectedNextStatus.replaceAll('_', ' ')}!'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        _remarksController.clear();
      } else {
        messenger.showSnackBar(
          SnackBar(
            content: Text(provider.actionError ?? 'Failed to update status.'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final deliveryProvider = Provider.of<DeliveryProvider>(context);
    final currentUserId = auth.user?.id;
    final allDeliveries = currentUserId != null
        ? deliveryProvider.deliveries
            .where((d) => d.assignedExecutive?.id == currentUserId)
            .toList()
        : deliveryProvider.deliveries;

    // Available deliveries to update (assigned or in transit)
    final activeOrders = allDeliveries
        .where((d) => d.status == 'ASSIGNED' || d.status == 'IN_TRANSIT')
        .toList();

    // Safely resolve selected delivery without mutating state during build
    DeliveryModel? selectedDelivery;
    if (_selectedDeliveryId != null) {
      final matches = activeOrders.where((d) => d.id == _selectedDeliveryId);
      if (matches.isNotEmpty) {
        selectedDelivery = matches.first;
      }
    }
    selectedDelivery ??= activeOrders.isNotEmpty ? activeOrders.first : null;
    final currentSelectedId = selectedDelivery?.id;

    final content = RefreshIndicator(
      onRefresh: () => deliveryProvider.fetchDeliveries(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 1. Order Selector Card ───────────────────────────────
            Container(
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
                  const Text(
                    'Select Shipment to Update',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.darkNavy,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (activeOrders.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline_rounded,
                              size: 18, color: AppColors.textSecondary),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'No active or assigned shipments currently available for status update.',
                              style: TextStyle(
                                  fontSize: 12, color: AppColors.textSecondary),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    DropdownButtonFormField<String>(
                      initialValue: currentSelectedId,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: 'Shipment Order',
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      items: activeOrders.map((d) {
                        return DropdownMenuItem(
                          value: d.id,
                          child: Text(
                            '${d.trackingNumber} — ${d.customer?.fullName ?? "Customer"} (${d.status})',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.darkNavy,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedDeliveryId = val;
                          if (val != null) {
                            final chosen =
                                activeOrders.firstWhere((d) => d.id == val);
                            if (chosen.status == 'ASSIGNED') {
                              _selectedNextStatus = 'IN_TRANSIT';
                            } else {
                              _selectedNextStatus = 'DELIVERED';
                            }
                          }
                        });
                      },
                    ),
                ],
              ),
            ),

            if (selectedDelivery != null) ...[
              const SizedBox(height: 16),

              // ── 2. Order Preview Card ────────────────────────────────
              Container(
                width: double.infinity,
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
                          selectedDelivery.trackingNumber,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: AppColors.primaryBlue,
                          ),
                        ),
                        StatusBadge(status: selectedDelivery.status),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      selectedDelivery.customer?.fullName ?? 'Recipient',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.darkNavy,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '📍 ${selectedDelivery.deliveryAddress}, ${selectedDelivery.city}',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ── 3. Target Status Selection ───────────────────────────
              Container(
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
                    const Text(
                      'Target Status Transition',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.darkNavy,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (selectedDelivery.status == 'ASSIGNED') ...[
                      _buildStatusOption(
                        status: 'IN_TRANSIT',
                        title: 'Start Route (In Transit)',
                        subtitle:
                            'Package picked up from hub and courier is heading to customer',
                        icon: Icons.local_shipping_rounded,
                        color: AppColors.primaryBlue,
                      ),
                    ] else if (selectedDelivery.status == 'IN_TRANSIT') ...[
                      _buildStatusOption(
                        status: 'DELIVERED',
                        title: 'Mark as Delivered',
                        subtitle:
                            'Successfully arrived and handed package to recipient',
                        icon: Icons.check_circle_rounded,
                        color: AppColors.success,
                      ),
                      const SizedBox(height: 10),
                      _buildStatusOption(
                        status: 'FAILED',
                        title: 'Report Delivery Failure',
                        subtitle:
                            'Customer unavailable, wrong address, or delivery exception',
                        icon: Icons.report_problem_rounded,
                        color: AppColors.error,
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ── 4. Proof & Remarks ──────────────────────────────────
              if (_selectedNextStatus == 'DELIVERED')
                Container(
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
                      const Text(
                        'Delivery Proof & Notes',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColors.darkNavy,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _proofController,
                        decoration: InputDecoration(
                          labelText: 'Proof of Delivery / Handover Note',
                          hintText: 'e.g. Handed to customer at door',
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _remarksController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          labelText: 'Additional Remarks (Optional)',
                          hintText: 'Any extra delivery comments...',
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Photo attachment
                      Row(
                        children: [
                          OutlinedButton.icon(
                            onPressed: () => _pickImage(ImageSource.camera),
                            icon: const Icon(Icons.camera_alt_rounded, size: 18),
                            label: const Text('Take Photo'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primaryBlue,
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

              const SizedBox(height: 20),

              // ── 5. Submit Button ────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _isSubmitting
                      ? null
                      : () => _submitStatusUpdate(selectedDelivery!),
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : Icon(
                          _selectedNextStatus == 'DELIVERED'
                              ? Icons.check_circle_rounded
                              : _selectedNextStatus == 'FAILED'
                                  ? Icons.report_problem_rounded
                                  : Icons.play_arrow_rounded,
                        ),
                  label: Text(
                    _isSubmitting
                        ? 'Updating Status...'
                        : _selectedNextStatus == 'DELIVERED'
                            ? 'Submit Delivery Confirmation'
                            : _selectedNextStatus == 'FAILED'
                                ? 'Proceed to Failure Report'
                                : 'Start Delivery Route',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _selectedNextStatus == 'DELIVERED'
                        ? AppColors.success
                        : _selectedNextStatus == 'FAILED'
                            ? AppColors.error
                            : AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 80),
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
        title: const Text(
          'Update Delivery Status',
          style: TextStyle(
            color: AppColors.darkNavy,
            fontWeight: FontWeight.w900,
            fontSize: 17,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: AppColors.darkNavy),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => deliveryProvider.fetchDeliveries(),
          ),
        ],
      ),
      body: content,
    );
  }

  Widget _buildStatusOption({
    required String status,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    final isSelected = _selectedNextStatus == status;

    return InkWell(
      onTap: () => setState(() => _selectedNextStatus = status),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.08)
              : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : AppColors.border,
            width: isSelected ? 1.8 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected
                    ? color
                    : color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                size: 20,
                color: isSelected ? Colors.white : color,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: isSelected ? color : AppColors.darkNavy,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textSecondary),
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
                  color: isSelected ? color : AppColors.textMuted,
                  width: isSelected ? 6 : 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
