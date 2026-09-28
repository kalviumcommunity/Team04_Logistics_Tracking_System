import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/escalation_provider.dart';
import '../../widgets/status_badge.dart';

class EscalationCenterScreen extends StatefulWidget {
  final bool isEmbedded;

  const EscalationCenterScreen({super.key, this.isEmbedded = false});

  @override
  State<EscalationCenterScreen> createState() => _EscalationCenterScreenState();
}

class _EscalationCenterScreenState extends State<EscalationCenterScreen> {
  String _selectedFilter = 'ALL';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Provider.of<EscalationProvider>(context, listen: false)
            .fetchEscalations();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showResolveDialog(String escalationId) {
    final notesController = TextEditingController();
    final provider = Provider.of<EscalationProvider>(context, listen: false);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Resolve Escalation',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter resolution action notes to mark this issue as resolved:',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: notesController,
              decoration: InputDecoration(
                hintText: 'e.g., Contacted customer, arranged re-delivery...',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              maxLines: 3,
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
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.purple,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              await provider.updateEscalation(
                  escalationId, 'RESOLVED', notesController.text.trim());
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Mark Resolved',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<EscalationProvider>(context);

    final q = _searchQuery.toLowerCase();
    final escalations = provider.escalations.where((e) {
      final matchesFilter =
          _selectedFilter == 'ALL' || e.status == _selectedFilter;
      final tracking = e.delivery?.trackingNumber.toLowerCase() ?? '';
      final reason = e.reason?.toLowerCase() ?? '';
      final remarks = e.remarks?.toLowerCase() ?? '';
      final matchesSearch = q.isEmpty ||
          tracking.contains(q) ||
          reason.contains(q) ||
          remarks.contains(q);
      return matchesFilter && matchesSearch;
    }).toList();

    Widget content = Column(
      children: [
        // Filter & Search Controls
        Container(
          color: Colors.white,
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              // Search Input
              TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _searchQuery = val),
                decoration: InputDecoration(
                  hintText: 'Search escalations by tracking # or reason...',
                  hintStyle: const TextStyle(
                      fontSize: 12, color: AppColors.textMuted),
                  prefixIcon: const Icon(Icons.search_rounded, size: 18),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 16),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: AppColors.background,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children:
                      ['ALL', 'OPEN', 'IN_PROGRESS', 'RESOLVED'].map((filter) {
                    final isSelected = _selectedFilter == filter;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6.0),
                      child: ChoiceChip(
                        label: Text(
                          filter.replaceAll('_', ' '),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color:
                                isSelected ? Colors.white : AppColors.darkNavy,
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: AppColors.purple,
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                              color: isSelected
                                  ? AppColors.purple
                                  : AppColors.border),
                        ),
                        onSelected: (_) =>
                            setState(() => _selectedFilter = filter),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: RefreshIndicator(
            onRefresh: () => provider.fetchEscalations(),
            child: provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : provider.error != null && provider.escalations.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.error_outline_rounded,
                                size: 40, color: AppColors.error),
                            const SizedBox(height: 10),
                            Text(provider.error!,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: () => provider.fetchEscalations(),
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.purple,
                                  foregroundColor: Colors.white),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : escalations.isEmpty
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(32.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.done_all_rounded,
                                      size: 40, color: AppColors.success),
                                  SizedBox(height: 10),
                                  Text(
                                    'No escalations found for selected criteria.',
                                    style: TextStyle(
                                        color: AppColors.textSecondary,
                                        fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: escalations.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final esc = escalations[index];
                              return Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: AppColors.border),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.02),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                            esc.delivery?.trackingNumber ??
                                                'DS-ESCALATION',
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w900,
                                                fontSize: 14,
                                                color: AppColors.purple)),
                                        StatusBadge(status: esc.status),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                        'Failure Reason: ${esc.reason ?? "N/A"}',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 13,
                                            color: AppColors.error)),
                                    const SizedBox(height: 4),
                                    Text('Remarks: "${esc.remarks ?? "None"}"',
                                        style: const TextStyle(
                                            fontSize: 12,
                                            fontStyle: FontStyle.italic,
                                            color: AppColors.textSecondary)),
                                    if (esc.resolutionNotes != null &&
                                        esc.resolutionNotes!.isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: AppColors.success
                                              .withValues(alpha: 0.08),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          border: Border.all(
                                              color: AppColors.success
                                                  .withValues(alpha: 0.3)),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(
                                                Icons.check_circle_rounded,
                                                size: 14,
                                                color: AppColors.success),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Text(
                                                'Resolution: ${esc.resolutionNotes}',
                                                style: const TextStyle(
                                                    fontSize: 11,
                                                    fontWeight:
                                                        FontWeight.bold,
                                                    color: AppColors.success),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                    if (esc.status != 'RESOLVED') ...[
                                      const SizedBox(height: 12),
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppColors.purple,
                                            foregroundColor: Colors.white,
                                            elevation: 0,
                                            shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(10)),
                                          ),
                                          onPressed: () =>
                                              _showResolveDialog(esc.id),
                                          icon: const Icon(
                                              Icons.task_alt_rounded,
                                              size: 14),
                                          label: const Text('Resolve Escalation',
                                              style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold)),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              );
                            },
                          ),
          ),
        ),
      ],
    );

    if (widget.isEmbedded) {
      return content;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Escalation Center',
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
            onPressed: () => provider.fetchEscalations(),
          ),
        ],
      ),
      body: content,
    );
  }
}
