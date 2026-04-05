import 'package:flutter/material.dart';
import '../../core/service/stats_share_service.dart';

class ShareStatsButton extends StatefulWidget {
  final DateTime month;
  final String? currencyCode;
  final int? bookId;

  const ShareStatsButton({
    super.key,
    required this.month,
    this.currencyCode,
    this.bookId,
  });

  @override
  State<ShareStatsButton> createState() => _ShareStatsButtonState();
}

class _ShareStatsButtonState extends State<ShareStatsButton> {
  bool _isLoading = false;

  Future<void> _share() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      final service = await StatsShareService.create();
      await service.shareMonthlyStats(
        widget.month,
        currencyCode: widget.currencyCode,
        bookId: widget.bookId,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('分享失败: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: _isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.share),
      onPressed: _isLoading ? null : _share,
      tooltip: '分享月度统计',
    );
  }
}
