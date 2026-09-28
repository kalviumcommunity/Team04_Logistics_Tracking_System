import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/phone_caller.dart';
import '../../models/delivery_model.dart';
import '../../providers/delivery_provider.dart';
import '../../widgets/status_badge.dart';

class EditDeliveryScreen extends StatefulWidget {
  final DeliveryModel delivery;

  const EditDeliveryScreen({super.key, required this.delivery});

  @override
  State<EditDeliveryScreen> createState() => _EditDeliveryScreenState();
}

class _EditDeliveryScreenState extends State<EditDeliveryScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _customerNameController;
  late TextEditingController _customerPhoneController;
  late TextEditingController _customerEmailController;
  late TextEditingController _pickupController;
  late TextEditingController _deliveryController;
  late TextEditingController _cityController;
  late TextEditingController _remarksController;
  late TextEditingController _etaController;

  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;

  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final d = widget.delivery;

    _customerNameController =
        TextEditingController(text: d.customer?.fullName ?? '');
    _customerPhoneController =
        TextEditingController(text: d.customer?.phone ?? '');
    _customerEmailController =
        TextEditingController(text: d.customer?.email ?? '');
    _pickupController = TextEditingController(text: d.pickupAddress);
    _deliveryController = TextEditingController(text: d.deliveryAddress);
    _cityController = TextEditingController(text: d.city);
    _remarksController = TextEditingController(text: d.remarks ?? '');
    _etaController = TextEditingController(text: d.eta ?? '45 mins');

    try {
      _selectedDate = DateTime.parse(d.deliveryDate);
    } catch (_) {
      _selectedDate = DateTime.now();
    }

    try {
      final parts = d.deliveryTime.split(':');
      _selectedTime = TimeOfDay(
          hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    } catch (_) {
      _selectedTime = const TimeOfDay(hour: 14, minute: 0);
    }
  }

  @override
  void dispose() {
    _customerNameController.dispose();
    _customerPhoneController.dispose();
    _customerEmailController.dispose();
    _pickupController.dispose();
    _deliveryController.dispose();
    _cityController.dispose();
    _remarksController.dispose();
    _etaController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryBlue,
              onPrimary: Colors.white,
              onSurface: AppColors.darkNavy,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryBlue,
              onPrimary: Colors.white,
              onSurface: AppColors.darkNavy,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  String _formatTime(TimeOfDay t) {
    return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }

  void _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final provider = Provider.of<DeliveryProvider>(context, listen: false);
    final rawPhone = _customerPhoneController.text.trim();
    final normalizedPhone = PhoneCaller.normalizePhoneNumber(rawPhone) ?? rawPhone;

    final payload = {
      'customerName': _customerNameController.text.trim(),
      'customerPhone': normalizedPhone,
      'customerEmail': _customerEmailController.text.trim().isNotEmpty
          ? _customerEmailController.text.trim()
          : null,
      'pickupAddress': _pickupController.text.trim(),
      'deliveryAddress': _deliveryController.text.trim(),
      'city': _cityController.text.trim(),
      'deliveryDate': _formatDate(_selectedDate),
      'deliveryTime': _formatTime(_selectedTime),
      'remarks': _remarksController.text.trim(),
      'eta': _etaController.text.trim().isNotEmpty
          ? _etaController.text.trim()
          : '45 mins',
    };

    final ok = await provider.updateDelivery(widget.delivery.id, payload);

    if (!mounted) return;

    setState(() => _isSubmitting = false);

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded,
                  color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Delivery ${widget.delivery.trackingNumber} updated successfully!',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context);
    } else {
      setState(() {
        _errorMessage = provider.actionError ??
            'Failed to update delivery details. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.delivery;
    final isEditable = d.status != 'DELIVERED' && d.status != 'CANCELLED';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Edit Delivery ${d.trackingNumber}',
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
          Padding(
            padding: const EdgeInsets.only(right: 14.0),
            child: Center(child: StatusBadge(status: d.status)),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 800;

          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isWide ? (constraints.maxWidth - 760) / 2 : 16,
              vertical: 20,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (!isEditable)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: AppColors.warning.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.lock_outline_rounded,
                              color: AppColors.warning, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Orders marked as "${d.status}" are locked from modifications.',
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.darkNavy),
                            ),
                          ),
                        ],
                      ),
                    ),

                  if (_errorMessage != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: AppColors.error.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline_rounded,
                              color: AppColors.error, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(_errorMessage!,
                                style: const TextStyle(
                                    color: AppColors.error,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600)),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close,
                                size: 16, color: AppColors.error),
                            onPressed: () =>
                                setState(() => _errorMessage = null),
                          ),
                        ],
                      ),
                    ),

                  // Section 1: Customer Info
                  _buildSectionCard(
                    title: 'Customer Information',
                    icon: Icons.person_outline_rounded,
                    children: [
                      TextFormField(
                        controller: _customerNameController,
                        enabled: isEditable,
                        decoration: _inputDecoration(
                          label: 'Customer Full Name *',
                          icon: Icons.person_rounded,
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Please enter customer name'
                            : null,
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: TextFormField(
                              controller: _customerPhoneController,
                              enabled: isEditable,
                              keyboardType: TextInputType.phone,
                              decoration: _inputDecoration(
                                label: 'Phone Number *',
                                icon: Icons.phone_rounded,
                              ),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'Please enter phone';
                                }
                                if (!PhoneCaller.isValidPhoneNumber(v)) {
                                  return 'Please enter a valid phone number';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 4,
                            child: TextFormField(
                              controller: _customerEmailController,
                              enabled: isEditable,
                              keyboardType: TextInputType.emailAddress,
                              decoration: _inputDecoration(
                                label: 'Email Address',
                                icon: Icons.email_outlined,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Section 2: Route & Destination
                  _buildSectionCard(
                    title: 'Route & Destination',
                    icon: Icons.alt_route_rounded,
                    children: [
                      TextFormField(
                        controller: _pickupController,
                        enabled: isEditable,
                        decoration: _inputDecoration(
                          label: 'Pickup Address *',
                          icon: Icons.storefront_rounded,
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Please enter pickup location'
                            : null,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _deliveryController,
                        enabled: isEditable,
                        decoration: _inputDecoration(
                          label: 'Delivery Destination Address *',
                          icon: Icons.location_on_rounded,
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Please enter delivery destination'
                            : null,
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _cityController,
                              enabled: isEditable,
                              decoration: _inputDecoration(
                                label: 'City *',
                                icon: Icons.location_city_rounded,
                              ),
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? 'Please enter city'
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _etaController,
                              enabled: isEditable,
                              decoration: _inputDecoration(
                                label: 'Estimated Delivery Time',
                                icon: Icons.timer_outlined,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Section 3: Schedule & Instructions
                  _buildSectionCard(
                    title: 'Schedule & Instructions',
                    icon: Icons.schedule_rounded,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: isEditable ? _pickDate : null,
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.calendar_today_rounded,
                                        size: 18, color: AppColors.primaryBlue),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Delivery Date',
                                            style: TextStyle(
                                                fontSize: 10,
                                                color: AppColors.textSecondary,
                                                fontWeight: FontWeight.w600),
                                          ),
                                          Text(
                                            _formatDate(_selectedDate),
                                            style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.darkNavy),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: InkWell(
                              onTap: isEditable ? _pickTime : null,
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.access_time_rounded,
                                        size: 18, color: AppColors.cyanTeal),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Delivery Slot',
                                            style: TextStyle(
                                                fontSize: 10,
                                                color: AppColors.textSecondary,
                                                fontWeight: FontWeight.w600),
                                          ),
                                          Text(
                                            _formatTime(_selectedTime),
                                            style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.darkNavy),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _remarksController,
                        enabled: isEditable,
                        maxLines: 2,
                        decoration: _inputDecoration(
                          label: 'Instructions & Remarks',
                          icon: Icons.notes_rounded,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  if (isEditable)
                    ElevatedButton(
                      onPressed: _isSubmitting ? null : _saveChanges,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Save Changes',
                              style: TextStyle(
                                  fontWeight: FontWeight.w800, fontSize: 14),
                            ),
                    ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
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
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: AppColors.primaryBlue),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
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
          ...children,
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 18, color: AppColors.textSecondary),
      filled: true,
      fillColor: const Color(0xFFFBFDFF),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primaryBlue, width: 1.5),
      ),
    );
  }
}
