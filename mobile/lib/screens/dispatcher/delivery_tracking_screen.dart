import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/delivery_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/delivery_provider.dart';
import '../../widgets/status_badge.dart';
import 'delivery_details_screen.dart';

class DeliveryTrackingScreen extends StatefulWidget {
  final String? initialTrackingNumber;
  final bool isEmbedded;

  const DeliveryTrackingScreen({
    super.key,
    this.initialTrackingNumber,
    this.isEmbedded = false,
  });

  @override
  State<DeliveryTrackingScreen> createState() => _DeliveryTrackingScreenState();
}

class _DeliveryTrackingScreenState extends State<DeliveryTrackingScreen> {
  final TextEditingController _searchController = TextEditingController();
  DeliveryModel? _trackedDelivery;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.initialTrackingNumber != null &&
        widget.initialTrackingNumber!.isNotEmpty) {
      _searchController.text = widget.initialTrackingNumber!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _searchDelivery(widget.initialTrackingNumber!);
      });
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final provider = Provider.of<DeliveryProvider>(context, listen: false);
        provider.fetchDeliveries();
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchDelivery(String query) async {
    final q = query.trim();
    if (q.isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final provider = Provider.of<DeliveryProvider>(context, listen: false);
    final del = await provider.getDeliveryDetails(q);

    if (!mounted) return;

    if (del != null) {
      setState(() {
        _trackedDelivery = del;
        _isLoading = false;
      });
    } else {
      // If not found by direct ID, search in list
      final match = provider.deliveries
          .where((d) =>
              d.trackingNumber.toLowerCase() == q.toLowerCase() ||
              d.id.toLowerCase() == q.toLowerCase())
          .firstOrNull;

      if (match != null) {
        final fullDel = await provider.getDeliveryDetails(match.id);
        if (!mounted) return;
        setState(() {
          _trackedDelivery = fullDel ?? match;
          _isLoading = false;
        });
      } else {
        setState(() {
          _trackedDelivery = null;
          _isLoading = false;
          _errorMessage =
              'No delivery found matching tracking code "$q". Please check the number and try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final deliveryProvider = Provider.of<DeliveryProvider>(context);

    final user = auth.user;
    final userRole = user?.role.toUpperCase();
    final isExecutive = userRole == 'EXECUTIVE' ||
        userRole == 'DELIVERY_EXECUTIVE' ||
        userRole == 'FIELD_EXECUTIVE';
    final isDispatcher = userRole == 'DISPATCHER';

    List<DeliveryModel> allDeliveries = deliveryProvider.deliveries;
    if (isExecutive && user != null) {
      allDeliveries = allDeliveries
          .where((d) =>
              d.assignedTo == user.id ||
              d.assignedExecutive?.id == user.id)
          .toList();
    } else if (isDispatcher && user != null) {
      final myDeliveries = allDeliveries
          .where((d) =>
              d.assignedDispatcher == user.id ||
              d.createdBy?.id == user.id)
          .toList();
      if (myDeliveries.isNotEmpty) {
        allDeliveries = myDeliveries;
      }
    }

    final activeDeliveries = allDeliveries
        .where((d) =>
            d.status == 'IN_TRANSIT' ||
            d.status == 'ASSIGNED' ||
            d.status == 'PENDING')
        .toList();

    Widget bodyContent = RefreshIndicator(
      onRefresh: () async {
        if (_trackedDelivery != null) {
          await _searchDelivery(_trackedDelivery!.id);
        } else {
          await deliveryProvider.fetchDeliveries();
        }
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Banner
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.darkNavy, AppColors.cyanTeal],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.location_searching_rounded,
                          color: Colors.white, size: 28),
                      SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Live Shipment Tracking',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Track real-time courier transit, delivery stages, and checkpoint history.',
                              style: TextStyle(
                                  color: Color(0xFFE2E8F0), fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Search Input Card
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child: Icon(Icons.search_rounded,
                            color: AppColors.primaryBlue),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onSubmitted: _searchDelivery,
                          decoration: const InputDecoration(
                            hintText: 'Enter Tracking Number (e.g. DS-123456)...',
                            hintStyle: TextStyle(
                                fontSize: 13, color: AppColors.textMuted),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: _isLoading
                            ? null
                            : () => _searchDelivery(_searchController.text),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryBlue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          elevation: 0,
                        ),
                        child: const Text('Track',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                if (_isLoading || (deliveryProvider.isLoading && allDeliveries.isEmpty))
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Column(
                      children: [
                        CircularProgressIndicator(color: AppColors.primaryBlue),
                        SizedBox(height: 16),
                        Text(
                          'Loading live tracking...',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.darkNavy,
                          ),
                        ),
                      ],
                    ),
                  )
                else if (_errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: AppColors.error.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.search_off_rounded,
                            size: 40, color: AppColors.error),
                        const SizedBox(height: 10),
                        Text(
                          _errorMessage!,
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.darkNavy),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: () {
                            setState(() => _errorMessage = null);
                            deliveryProvider.fetchDeliveries();
                          },
                          icon: const Icon(Icons.refresh_rounded, size: 16),
                          label: const Text('View All Active Deliveries'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryBlue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ],
                    ),
                  )
                else if (deliveryProvider.error != null && allDeliveries.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: AppColors.error.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.error_outline_rounded,
                            size: 44, color: AppColors.error),
                        const SizedBox(height: 12),
                        const Text(
                          'Unable to load live tracking data.',
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: AppColors.darkNavy),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          deliveryProvider.error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () => deliveryProvider.fetchDeliveries(),
                          icon: const Icon(Icons.refresh_rounded, size: 16),
                          label: const Text('Retry'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryBlue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ],
                    ),
                  )
                else if (_trackedDelivery != null) ...[
                  // Tracked Delivery Result
                  _buildTrackedDeliveryView(_trackedDelivery!),
                ] else if (activeDeliveries.isEmpty) ...[
                  // Empty state when no active deliveries exist
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: AppColors.primaryBlue.withValues(alpha: 0.08),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.inventory_2_outlined,
                              size: 30, color: AppColors.primaryBlue),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No Active Deliveries',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.darkNavy),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          isExecutive
                              ? 'No deliveries are currently assigned to you.'
                              : isDispatcher
                                  ? 'No deliveries have been assigned/created yet.'
                                  : 'No active deliveries available.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 13, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 18),
                        OutlinedButton.icon(
                          onPressed: () => deliveryProvider.fetchDeliveries(),
                          icon: const Icon(Icons.refresh_rounded, size: 16),
                          label: const Text('Refresh Data'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primaryBlue,
                            side: const BorderSide(color: AppColors.primaryBlue),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  // Quick Tracking Shortcuts (Active Deliveries)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.bolt_rounded,
                              size: 18, color: AppColors.cyanTeal),
                          SizedBox(width: 6),
                          Text(
                            'Active Deliveries',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppColors.darkNavy,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '${activeDeliveries.length} active',
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: activeDeliveries.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final del = activeDeliveries[index];
                      final hasCoords = del.latitude != null && del.longitude != null;
                      return InkWell(
                        onTap: () {
                          _searchController.text = del.trackingNumber;
                          _searchDelivery(del.trackingNumber);
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: AppColors.cyanTeal
                                              .withValues(alpha: 0.1),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: const Icon(
                                            Icons.local_shipping_outlined,
                                            size: 16,
                                            color: AppColors.cyanTeal),
                                      ),
                                      const SizedBox(width: 10),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            del.trackingNumber,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w800,
                                              fontSize: 13,
                                              color: AppColors.primaryBlue,
                                            ),
                                          ),
                                          Text(
                                            '${del.customer?.fullName ?? del.recipientName ?? "Customer"} • ${del.city}',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  StatusBadge(status: del.status),
                                ],
                              ),
                              if (hasCoords || (del.assignedExecutive != null)) ...[
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    if (del.assignedExecutive != null)
                                      Row(
                                        children: [
                                          const Icon(Icons.person_outline_rounded,
                                              size: 13, color: AppColors.textMuted),
                                          const SizedBox(width: 4),
                                          Text(
                                            del.assignedExecutive!.fullName,
                                            style: const TextStyle(
                                                fontSize: 11,
                                                color: AppColors.textSecondary),
                                          ),
                                        ],
                                      )
                                    else
                                      const SizedBox.shrink(),
                                    if (hasCoords)
                                      Row(
                                        children: [
                                          const Icon(Icons.location_on_outlined,
                                              size: 13, color: AppColors.success),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${del.latitude!.toStringAsFixed(4)}, ${del.longitude!.toStringAsFixed(4)}',
                                            style: const TextStyle(
                                                fontSize: 11,
                                                color: AppColors.success,
                                                fontWeight: FontWeight.w600),
                                          ),
                                        ],
                                      )
                                    else
                                      const SizedBox.shrink(),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );

    if (widget.isEmbedded) {
      return bodyContent;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Delivery Status Tracking',
          style: TextStyle(
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
            onPressed: () {
              if (_trackedDelivery != null) {
                _searchDelivery(_trackedDelivery!.id);
              } else {
                deliveryProvider.fetchDeliveries();
              }
            },
          ),
        ],
      ),
      body: bodyContent,
    );
  }

  Widget _buildTrackedDeliveryView(DeliveryModel delivery) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Status Progress Bar Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
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
                  Row(
                    children: [
                      Text(
                        delivery.trackingNumber,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: AppColors.darkNavy,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy_rounded,
                            size: 16, color: AppColors.primaryBlue),
                        onPressed: () {
                          Clipboard.setData(
                              ClipboardData(text: delivery.trackingNumber));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Tracking number copied!'),
                              backgroundColor: AppColors.darkNavy,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  StatusBadge(status: delivery.status, large: true),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Estimated Arrival: ${delivery.eta ?? "Standard Delivery"}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),

              // Multi-step Progress Bar
              _buildStepProgress(delivery.status),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Route Summary Card
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
              const Row(
                children: [
                  Icon(Icons.route_rounded,
                      color: AppColors.primaryBlue, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Transit Waypoints',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.darkNavy,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1, color: AppColors.divider),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.storefront_rounded,
                      size: 16, color: AppColors.primaryBlue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Pickup Hub',
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textSecondary)),
                        Text(delivery.pickupAddress,
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.darkNavy)),
                      ],
                    ),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.only(left: 7, top: 4, bottom: 4),
                child: SizedBox(
                  height: 12,
                  child: VerticalDivider(
                      color: AppColors.border, thickness: 1.5),
                ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.location_on_rounded,
                      size: 16, color: AppColors.cyanTeal),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Final Destination',
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textSecondary)),
                        Text(
                            '${delivery.deliveryAddress}, ${delivery.city}',
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
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

        // Courier & Customer Quick Cards
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Recipient Customer',
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSecondary)),
                    const SizedBox(height: 2),
                    Text(
                      delivery.customer?.fullName ?? 'N/A',
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppColors.darkNavy),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      delivery.customer?.phone ?? '',
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Courier Driver',
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSecondary)),
                    const SizedBox(height: 2),
                    Text(
                      delivery.assignedExecutive?.fullName ??
                          'Unassigned',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: delivery.assignedExecutive != null
                            ? AppColors.darkNavy
                            : AppColors.warning,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      delivery.assignedExecutive?.phone ??
                          'Awaiting assignment',
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // GPS Location Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: delivery.latitude != null && delivery.longitude != null
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.my_location_rounded,
                              size: 16, color: AppColors.success),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'Live GPS Location',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: AppColors.darkNavy),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text('LIVE',
                              style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.success,
                                  letterSpacing: 0.5)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (delivery.currentLocation != null &&
                        delivery.currentLocation!.isNotEmpty)
                      Text(
                        delivery.currentLocation!,
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.darkNavy),
                      ),
                    const SizedBox(height: 4),
                    Text(
                      'Lat: ${delivery.latitude!.toStringAsFixed(6)}, '
                      'Lng: ${delivery.longitude!.toStringAsFixed(6)}',
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                )
              : Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.location_off_rounded,
                          size: 16, color: AppColors.textMuted),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Live GPS Location Unavailable',
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textSecondary)),
                          SizedBox(height: 2),
                          Text(
                            'GPS coordinates have not been reported yet for this delivery.',
                            style: TextStyle(
                                fontSize: 11, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
        ),
        const SizedBox(height: 16),

        // Detailed Checkpoint Milestones
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Checkpoint Milestones',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.darkNavy,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DeliveryDetailsScreen(
                              deliveryId: delivery.id),
                        ),
                      );
                    },
                    child: const Text('View Full Details →',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryBlue)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1, color: AppColors.divider),
              const SizedBox(height: 12),
              if (delivery.statusHistory == null ||
                  delivery.statusHistory!.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('No checkpoint updates recorded yet.',
                        style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary)),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: delivery.statusHistory!.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final item = delivery.statusHistory![index];
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.primaryBlue
                                .withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.check_rounded,
                              size: 14, color: AppColors.primaryBlue),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  StatusBadge(status: item.status),
                                  Text(
                                    _formatTimestamp(item.createdAt),
                                    style: const TextStyle(
                                        fontSize: 10,
                                        color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                              if (item.remarks != null &&
                                  item.remarks!.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  item.remarks!,
                                  style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.darkNavy),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStepProgress(String status) {
    int currentStep = 0;
    if (status == 'PENDING') currentStep = 0;
    if (status == 'ASSIGNED') currentStep = 1;
    if (status == 'IN_TRANSIT') currentStep = 2;
    if (status == 'DELIVERED') currentStep = 3;
    if (status == 'FAILED' || status == 'CANCELLED') currentStep = -1;

    final steps = ['Created', 'Assigned', 'In Transit', 'Delivered'];

    return Row(
      children: List.generate(steps.length, (index) {
        final isCompleted = currentStep >= index;
        final isCurrent = currentStep == index;

        return Expanded(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isCompleted
                            ? AppColors.primaryBlue
                            : isCurrent
                                ? AppColors.cyanTeal
                                : const Color(0xFFE2E8F0),
                      ),
                      child: Center(
                        child: isCompleted
                            ? const Icon(Icons.check,
                                color: Colors.white, size: 16)
                            : Text(
                                '${index + 1}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      steps[index],
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight:
                            isCurrent ? FontWeight.w800 : FontWeight.w600,
                        color: isCurrent
                            ? AppColors.darkNavy
                            : AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              if (index < steps.length - 1)
                Container(
                  height: 2,
                  width: 20,
                  color: isCompleted
                      ? AppColors.primaryBlue
                      : const Color(0xFFE2E8F0),
                ),
            ],
          ),
        );
      }),
    );
  }

  String _formatTimestamp(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr).toLocal();
      return '${dt.day}/${dt.month} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return dateStr;
    }
  }
}
