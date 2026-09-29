import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../models/delivery_model.dart';
import '../models/user_model.dart';
import '../providers/delivery_provider.dart';
import 'status_badge.dart';

class AssignDeliveryDialog extends StatefulWidget {
  final DeliveryModel delivery;

  const AssignDeliveryDialog({
    super.key,
    required this.delivery,
  });

  /// Static helper to show the dialog
  static Future<bool?> show(BuildContext context, DeliveryModel delivery) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AssignDeliveryDialog(delivery: delivery),
    );
  }

  @override
  State<AssignDeliveryDialog> createState() => _AssignDeliveryDialogState();
}

class _AssignDeliveryDialogState extends State<AssignDeliveryDialog> {
  UserModel? _selectedExecutive;
  String _searchQuery = '';
  bool _isSubmitting = false;
  bool _isLoadingExecutives = true;
  String? _errorMessage;
  String? _executiveLoadError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadExecutives();
    });
  }

  Future<void> _loadExecutives() async {
    final provider = Provider.of<DeliveryProvider>(context, listen: false);
    debugPrint(
        '[AssignDialog] Loading executives for delivery ${widget.delivery.id}');

    setState(() {
      _isLoadingExecutives = true;
      _executiveLoadError = null;
    });

    try {
      await provider.fetchExecutives();

      if (!mounted) return;

      if (widget.delivery.assignedTo != null) {
        final match = provider.executives
            .where((e) => e.id == widget.delivery.assignedTo)
            .firstOrNull;
        if (match != null) {
          _selectedExecutive = match;
        }
      }

      setState(() {
        _isLoadingExecutives = false;
        _executiveLoadError = provider.actionError;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoadingExecutives = false;
        _executiveLoadError = error.toString();
      });
    }
  }

  Future<void> _handleAssign() async {
    if (_selectedExecutive == null) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final currentDispatcherUid = FirebaseAuth.instance.currentUser?.uid;
    final provider = Provider.of<DeliveryProvider>(context, listen: false);

    try {
      final success = await provider.assignExecutive(
        widget.delivery.id,
        _selectedExecutive!.id,
        dispatcherId: currentDispatcherUid,
      );

      if (!mounted) return;

      setState(() => _isSubmitting = false);

      if (success) {
        final messenger = ScaffoldMessenger.of(context);
        Navigator.of(context).pop(true);
        messenger.showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded,
                    color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Delivery assigned successfully to ${_selectedExecutive!.fullName}.',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        setState(() {
          _errorMessage = provider.actionError ??
              'Unable to assign delivery. Please try again.';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _errorMessage = 'Assignment failed: $e';
      });
      debugPrint('[AssignDialog] Assignment error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final delivery = widget.delivery;
    final isReassign =
        delivery.assignedTo != null && delivery.assignedTo!.isNotEmpty;
    final provider = Provider.of<DeliveryProvider>(context);
    final mediaSize = MediaQuery.sizeOf(context);
    final dialogHeight =
        (mediaSize.height * 0.9).clamp(240.0, 680.0).toDouble();
    final allDeliveries = provider.deliveries;

    // Workload calculation
    int getWorkload(String execId) {
      return allDeliveries
          .where((d) =>
              (d.assignedTo == execId || d.assignedExecutive?.id == execId) &&
              (d.status == 'ASSIGNED' || d.status == 'IN_TRANSIT'))
          .length;
    }

    final filteredExecutives = provider.executives.where((e) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase().trim();
      return e.fullName.toLowerCase().contains(q) ||
          e.email.toLowerCase().contains(q) ||
          e.phone.contains(q);
    }).toList();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540, maxHeight: 680),
        child: SizedBox(
          height: dialogHeight,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isReassign
                            ? AppColors.warning.withValues(alpha: 0.12)
                            : AppColors.primaryBlue.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isReassign
                            ? Icons.swap_horiz_rounded
                            : Icons.assignment_ind_rounded,
                        color: isReassign
                            ? AppColors.warning
                            : AppColors.primaryBlue,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isReassign
                                ? 'Reassign Delivery'
                                : 'Assign Delivery',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: AppColors.darkNavy,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Tracking: ${delivery.trackingNumber}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryBlue,
                            ),
                          ),
                        ],
                      ),
                    ),
                    StatusBadge(status: delivery.status),
                  ],
                ),
                const SizedBox(height: 16),

                // Delivery Summary Box
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.person_outline,
                              size: 14, color: AppColors.textMuted),
                          const SizedBox(width: 6),
                          const Text('Recipient: ',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary)),
                          Expanded(
                            child: Text(
                              delivery.customer?.fullName ??
                                  delivery.recipientName ??
                                  'Customer',
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.darkNavy),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.location_on_outlined,
                              size: 14, color: AppColors.textMuted),
                          const SizedBox(width: 6),
                          const Text('Destination: ',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary)),
                          Expanded(
                            child: Text(
                              '${delivery.deliveryAddress}, ${delivery.city}',
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.darkNavy),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      if (isReassign && delivery.assignedExecutive != null) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.badge_outlined,
                                size: 14, color: AppColors.warning),
                            const SizedBox(width: 6),
                            const Text('Current Driver: ',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.warning)),
                            Expanded(
                              child: Text(
                                delivery.assignedExecutive!.fullName,
                                style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.darkNavy),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Select Field Executive Title & Search
                const Text(
                  'Select Field Executive',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.darkNavy,
                  ),
                ),
                const SizedBox(height: 8),

                // Search field
                Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: TextField(
                    onChanged: (val) => setState(() => _searchQuery = val),
                    style: const TextStyle(fontSize: 13),
                    decoration: const InputDecoration(
                      hintText: 'Search executive by name, phone, or email...',
                      hintStyle:
                          TextStyle(fontSize: 12, color: AppColors.textMuted),
                      prefixIcon: Icon(Icons.search,
                          size: 18, color: AppColors.textMuted),
                      border: InputBorder.none,
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Error Banner
                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(10),
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: AppColors.error.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline_rounded,
                            color: AppColors.error, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(
                                color: AppColors.error,
                                fontSize: 11,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Executives List Content
                Expanded(
                  child: _isLoadingExecutives
                      ? const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 28,
                                height: 28,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2.5),
                              ),
                              SizedBox(height: 12),
                              Text(
                                'Loading executives...',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        )
                      : _executiveLoadError != null
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.error_outline_rounded,
                                      size: 36, color: AppColors.error),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Unable to load delivery executives.',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.darkNavy,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _executiveLoadError!,
                                    style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textSecondary),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 10),
                                  ElevatedButton.icon(
                                    onPressed: _loadExecutives,
                                    icon: const Icon(Icons.refresh, size: 14),
                                    label: const Text('Retry'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primaryBlue,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 14, vertical: 8),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : filteredExecutives.isEmpty
                              ? Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.person_off_outlined,
                                            size: 36,
                                            color: AppColors.textMuted),
                                        const SizedBox(height: 8),
                                        const Text(
                                          'No delivery executives available.',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.darkNavy,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          provider.executives.isEmpty
                                              ? 'Please register a delivery executive account first.'
                                              : 'No executives match your search.',
                                          style: const TextStyle(
                                              fontSize: 11,
                                              color: AppColors.textSecondary),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 10),
                                        TextButton.icon(
                                          onPressed: _loadExecutives,
                                          icon: const Icon(Icons.refresh,
                                              size: 14),
                                          label: const Text('Retry'),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              : ListView.separated(
                                  shrinkWrap: true,
                                  itemCount: filteredExecutives.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(height: 8),
                                  itemBuilder: (context, index) {
                                    final exec = filteredExecutives[index];
                                    final isSelected =
                                        _selectedExecutive?.id == exec.id;
                                    final workload = getWorkload(exec.id);

                                    return InkWell(
                                      onTap: _isSubmitting
                                          ? null
                                          : () => setState(
                                              () => _selectedExecutive = exec),
                                      borderRadius: BorderRadius.circular(12),
                                      child: Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? AppColors.primaryBlue
                                                  .withValues(alpha: 0.06)
                                              : Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                            color: isSelected
                                                ? AppColors.primaryBlue
                                                : AppColors.border,
                                            width: isSelected ? 1.5 : 1,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            CircleAvatar(
                                              radius: 18,
                                              backgroundColor: isSelected
                                                  ? AppColors.primaryBlue
                                                  : AppColors.primaryBlue
                                                      .withValues(alpha: 0.1),
                                              child: Text(
                                                exec.initials,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w800,
                                                  color: isSelected
                                                      ? Colors.white
                                                      : AppColors.primaryBlue,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Flexible(
                                                        child: Text(
                                                          exec.fullName,
                                                          style:
                                                              const TextStyle(
                                                            fontSize: 13,
                                                            fontWeight:
                                                                FontWeight.w800,
                                                            color: AppColors
                                                                .darkNavy,
                                                          ),
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 6),
                                                      Container(
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                                horizontal: 6,
                                                                vertical: 1.5),
                                                        decoration:
                                                            BoxDecoration(
                                                          color: (exec.status ==
                                                                      'ON_DUTY'
                                                                  ? AppColors
                                                                      .warning
                                                                  : AppColors
                                                                      .success)
                                                              .withValues(
                                                                  alpha: 0.12),
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(6),
                                                        ),
                                                        child: Text(
                                                          exec.status ??
                                                              'ACTIVE',
                                                          style: TextStyle(
                                                            fontSize: 9,
                                                            fontWeight:
                                                                FontWeight.w800,
                                                            color: exec.status ==
                                                                    'ON_DUTY'
                                                                ? AppColors
                                                                    .warning
                                                                : AppColors
                                                                    .success,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    exec.phone.isNotEmpty
                                                        ? '${exec.phone} • ${exec.email}'
                                                        : exec.email,
                                                    style: const TextStyle(
                                                      fontSize: 11,
                                                      color: AppColors
                                                          .textSecondary,
                                                    ),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4),
                                              decoration: BoxDecoration(
                                                color: workload == 0
                                                    ? AppColors.success
                                                        .withValues(alpha: 0.1)
                                                    : AppColors.warning
                                                        .withValues(alpha: 0.1),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                workload == 0
                                                    ? 'Available'
                                                    : '$workload active',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w700,
                                                  color: workload == 0
                                                      ? AppColors.success
                                                      : AppColors.warning,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Container(
                                              width: 20,
                                              height: 20,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: isSelected
                                                      ? AppColors.primaryBlue
                                                      : AppColors.textMuted,
                                                  width: 2,
                                                ),
                                              ),
                                              child: isSelected
                                                  ? Center(
                                                      child: Container(
                                                        width: 10,
                                                        height: 10,
                                                        decoration:
                                                            const BoxDecoration(
                                                          shape:
                                                              BoxShape.circle,
                                                          color: AppColors
                                                              .primaryBlue,
                                                        ),
                                                      ),
                                                    )
                                                  : null,
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                ),

                const SizedBox(height: 16),
                const Divider(height: 1, color: AppColors.divider),
                const SizedBox(height: 16),

                // Dialog Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isSubmitting
                          ? null
                          : () => Navigator.of(context).pop(false),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: (_selectedExecutive == null || _isSubmitting)
                          ? null
                          : _handleAssign,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isReassign
                            ? AppColors.warning
                            : AppColors.primaryBlue,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: AppColors.border,
                        disabledForegroundColor: AppColors.textMuted,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                      child: _isSubmitting
                          ? const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Assigning Delivery...',
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            )
                          : Text(
                              isReassign
                                  ? 'Reassign Delivery'
                                  : 'Assign Delivery',
                              style: const TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
