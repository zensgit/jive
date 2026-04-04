import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../core/service/stock_quote_service.dart';

/// Compact card displaying a live stock quote with price change info.
class StockQuoteCard extends StatelessWidget {
  final String ticker;
  final String name;
  final StockQuote? quote;
  final bool isLoading;
  final VoidCallback? onRefresh;

  const StockQuoteCard({
    super.key,
    required this.ticker,
    required this.name,
    this.quote,
    this.isLoading = false,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPositive = (quote?.change ?? 0) >= 0;
    final changeColor = quote == null
        ? Colors.grey
        : isPositive
            ? const Color(0xFF2E7D32)
            : Colors.red;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row: ticker + name + refresh button.
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ticker,
                        style: GoogleFonts.rubik(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      Text(
                        name,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (isLoading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else if (onRefresh != null)
                  InkWell(
                    onTap: onRefresh,
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Text(
                        '刷新',
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            // Price row.
            if (quote != null) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    quote!.price.toStringAsFixed(2),
                    style: GoogleFonts.rubik(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: changeColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Text(
                      '${isPositive ? "+" : ""}${quote!.change.toStringAsFixed(2)}'
                      ' (${isPositive ? "+" : ""}${quote!.changePercent.toStringAsFixed(2)}%)',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: changeColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              // Timestamp.
              Text(
                '更新于 ${DateFormat('HH:mm:ss').format(quote!.timestamp)}',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              ),
            ] else ...[
              Text(
                isLoading ? '加载中...' : '暂无行情数据',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
