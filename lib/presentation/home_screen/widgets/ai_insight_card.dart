import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../theme/app_theme.dart';
import '../../../core/services/gemini_ai_service.dart';
import '../../../services/hive_cache_service.dart';

class AiInsightCard extends StatefulWidget {
  const AiInsightCard({super.key});

  @override
  State<AiInsightCard> createState() => _AiInsightCardState();
}

class _AiInsightCardState extends State<AiInsightCard> {
  String _insight = 'Menganalisis transaksimu...';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInsight();
  }

  Future<void> _loadInsight({bool forceRefresh = false}) async {
    setState(() => _isLoading = true);

    if (!forceRefresh) {
      final cached = HiveCacheService.get('ai_insight');
      if (cached != null) {
        setState(() {
          _insight = cached;
          _isLoading = false;
        });
        return;
      }
    }

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final snapshot = await FirebaseFirestore.instance
          .collection('transactions')
          .where(Filter.or(
            Filter('senderUid', isEqualTo: user.uid),
            Filter('recipientUid', isEqualTo: user.uid),
          ))
          .orderBy('timestamp', descending: true)
          .limit(5)
          .get();

      final transactions = snapshot.docs.map((d) => d.data()).toList();
      final insight = await GeminiAiService.instance.analyzeTransactions(transactions);

      HiveCacheService.set('ai_insight', insight);
      
      if (mounted) {
        setState(() {
          _insight = insight;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _insight = 'Tetap pantau pengeluaran lo ya biar tujuan cepat tercapai!';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface.withAlpha(153),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primary.withAlpha(76), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withAlpha(25),
            blurRadius: 15,
            spreadRadius: 2,
          )
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
                  const Icon(Icons.auto_awesome, color: AppTheme.primary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Neo Insight',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.refresh, size: 20, color: AppTheme.primary),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: _isLoading ? null : () => _loadInsight(forceRefresh: true),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _isLoading
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Center(
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary),
                  ),
                )
              : Text(
                  _insight,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                    height: 1.5,
                  ),
                ),
        ],
      ),
    );
  }
}
