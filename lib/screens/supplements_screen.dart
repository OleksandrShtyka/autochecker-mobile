import 'dart:ui';
import 'package:flutter/material.dart';

import '../models/models.dart';
import '../services/api_service.dart';
import '../theme.dart';
import '../widgets/glass_card.dart';

class SupplementsScreen extends StatefulWidget {
  const SupplementsScreen({super.key});

  @override
  SupplementsScreenState createState() => SupplementsScreenState();
}

class SupplementsScreenState extends State<SupplementsScreen> {
  List<Supplement> _supps = [];
  List<SupplementStatus> _statuses = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await ApiService.instance.getSupplements();
      final suppList = (data['supplements'] as List?)
              ?.map((e) => Supplement.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [];
      final statusList = (data['statuses'] as List?)
              ?.map((e) =>
                  SupplementStatus.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [];
      if (mounted) {
        setState(() {
          _supps = suppList;
          _statuses = statusList;
        });
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Map<String, SupplementStatus> get _statusMap =>
      {for (final s in _statuses) s.id: s};

  Color _pctColor(double pct) {
    if (pct > 40) return teal;
    if (pct > 15) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  void showAdd([Supplement? existing]) {
    final nameCtrl =
        TextEditingController(text: existing?.name ?? '');
    final totalCtrl = TextEditingController(
        text: existing != null ? '${existing.totalWeightG}' : '');
    final servSizeCtrl = TextEditingController(
        text: existing != null ? '${existing.servingSizeG}' : '');
    final spdCtrl = TextEditingController(
        text: existing != null ? '${existing.servingsPerDay}' : '1');
    final priceCtrl = TextEditingController(
        text: existing != null ? '${existing.price}' : '0');
    final dateCtrl = TextEditingController(
        text: existing?.purchaseDate ??
            DateTime.now().toIso8601String().substring(0, 10));
    final notesCtrl =
        TextEditingController(text: existing?.notes ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ClipRRect(
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(28)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.13),
                  Colors.white.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28)),
              border: Border.all(
                  color: Colors.white.withValues(alpha: 0.12)),
            ),
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 28,
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: teal.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.science_outlined,
                          color: teal, size: 14),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      existing == null
                          ? 'Add Supplement'
                          : 'Edit Supplement',
                      style: const TextStyle(
                          color: textPrimary,
                          fontSize: 17,
                          fontWeight: FontWeight.w700),
                    ),
                  ]),
                  const SizedBox(height: 16),
                  _field('Name', nameCtrl),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(
                        child: _field('Total weight (g)', totalCtrl,
                            numeric: true)),
                    const SizedBox(width: 10),
                    Expanded(
                        child: _field('Serving size (g)', servSizeCtrl,
                            numeric: true)),
                  ]),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(
                        child: _field('Servings/day', spdCtrl,
                            numeric: true)),
                    const SizedBox(width: 10),
                    Expanded(
                        child: _field('Price (\$)', priceCtrl,
                            numeric: true)),
                  ]),
                  const SizedBox(height: 12),
                  _field('Purchase date (YYYY-MM-DD)', dateCtrl),
                  const SizedBox(height: 12),
                  _field('Notes (optional)', notesCtrl),
                  const SizedBox(height: 20),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: teal.withValues(alpha: 0.3),
                          blurRadius: 16,
                          spreadRadius: -4,
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () async {
                        final data = {
                          'name': nameCtrl.text.trim(),
                          'totalWeightG':
                              double.tryParse(totalCtrl.text) ?? 0,
                          'servingSizeG':
                              double.tryParse(servSizeCtrl.text) ?? 0,
                          'servingsPerDay':
                              double.tryParse(spdCtrl.text) ?? 1,
                          'price':
                              double.tryParse(priceCtrl.text) ?? 0,
                          'purchaseDate': dateCtrl.text.trim(),
                          if (notesCtrl.text.trim().isNotEmpty)
                            'notes': notesCtrl.text.trim(),
                        };
                        Navigator.pop(ctx);
                        if (existing == null) {
                          await ApiService.instance
                              .createSupplement(data);
                        } else {
                          await ApiService.instance
                              .updateSupplement(existing.id, data);
                        }
                        _load();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: teal,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                      ),
                      child: Text(
                        existing == null ? 'Add' : 'Save',
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 15),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController ctrl,
      {bool numeric = false}) {
    return TextField(
      controller: ctrl,
      keyboardType: numeric
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      decoration: InputDecoration(labelText: label),
      style: const TextStyle(color: textPrimary, fontSize: 14),
    );
  }

  @override
  Widget build(BuildContext context) {
    final topPad =
        kToolbarHeight + MediaQuery.of(context).padding.top + 16;

    if (_loading) {
      return const Center(
          child:
              CircularProgressIndicator(color: teal, strokeWidth: 2));
    }

    if (_supps.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                shape: BoxShape.circle,
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.10)),
              ),
              child: const Icon(Icons.science_outlined,
                  color: textMuted, size: 32),
            ),
            const SizedBox(height: 16),
            const Text('No supplements tracked yet.',
                style: TextStyle(color: textMuted, fontSize: 15)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: teal,
      backgroundColor: const Color(0xFF0C1525),
      onRefresh: _load,
      child: ListView.separated(
        padding: EdgeInsets.only(
            top: topPad, left: 16, right: 16, bottom: 120),
        itemCount: _supps.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) {
          final s = _supps[i];
          final st = _statusMap[s.id];
          return GlassCard(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                if (st != null)
                  SizedBox(
                    width: 56,
                    height: 56,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CircularProgressIndicator(
                          value: st.remainingPct / 100,
                          strokeWidth: 5,
                          backgroundColor:
                              Colors.white.withValues(alpha: 0.08),
                          color: _pctColor(st.remainingPct),
                        ),
                        Center(
                          child: Text(
                            '${st.remainingPct.round()}%',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.name,
                        style: const TextStyle(
                          color: textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      if (st != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          '${st.remainingG.toStringAsFixed(0)} g · ${st.daysLeft} days left',
                          style: const TextStyle(
                              color: textMuted, fontSize: 12),
                        ),
                        Text(
                          'Depletes ${st.depletionDate} · \$${st.costPerServing}/serving',
                          style: const TextStyle(
                              color: textMuted, fontSize: 12),
                        ),
                      ],
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  color: const Color(0xFF0C1525),
                  icon: const Icon(Icons.more_vert,
                      color: textMuted, size: 20),
                  onSelected: (v) async {
                    if (v == 'edit') showAdd(s);
                    if (v == 'delete') {
                      await ApiService.instance.deleteSupplement(s.id);
                      _load();
                    }
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                        value: 'edit', child: Text('Edit')),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('Delete',
                          style:
                              TextStyle(color: Color(0xFFEF4444))),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
