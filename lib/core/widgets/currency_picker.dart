import 'package:flutter/material.dart';
import '../database/currency_model.dart';

/// 货币选择器组件
class CurrencyPicker extends StatefulWidget {
  final String? selectedCode;
  final ValueChanged<String> onSelected;
  final bool showCrypto;
  final String? title;

  const CurrencyPicker({
    super.key,
    this.selectedCode,
    required this.onSelected,
    this.showCrypto = false,
    this.title,
  });

  /// 显示货币选择底部弹窗
  static Future<String?> showPicker(
    BuildContext context, {
    String? selectedCode,
    bool showCrypto = false,
    String? title,
  }) async {
    return await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => _CurrencyPickerContent(
          selectedCode: selectedCode,
          showCrypto: showCrypto,
          title: title,
          scrollController: scrollController,
          onSelected: (code) => Navigator.pop(context, code),
        ),
      ),
    );
  }

  @override
  State<CurrencyPicker> createState() => _CurrencyPickerState();
}

class _CurrencyPickerState extends State<CurrencyPicker> {
  @override
  Widget build(BuildContext context) {
    return _CurrencyPickerContent(
      selectedCode: widget.selectedCode,
      showCrypto: widget.showCrypto,
      title: widget.title,
      onSelected: widget.onSelected,
    );
  }
}

class _CurrencyPickerContent extends StatefulWidget {
  final String? selectedCode;
  final bool showCrypto;
  final String? title;
  final ScrollController? scrollController;
  final ValueChanged<String> onSelected;

  const _CurrencyPickerContent({
    this.selectedCode,
    this.showCrypto = false,
    this.title,
    this.scrollController,
    required this.onSelected,
  });

  @override
  State<_CurrencyPickerContent> createState() => _CurrencyPickerContentState();
}

class _CurrencyPickerContentState extends State<_CurrencyPickerContent> {
  String _searchQuery = '';
  final _searchController = TextEditingController();

  List<Map<String, dynamic>> get _allCurrencies {
    if (widget.showCrypto) {
      return CurrencyDefaults.getAllCurrencies();
    }
    return CurrencyDefaults.fiatCurrencies;
  }

  List<Map<String, dynamic>> get _filteredCurrencies {
    if (_searchQuery.isEmpty) return _allCurrencies;
    final query = _searchQuery.toLowerCase();
    return _allCurrencies.where((c) {
      final code = (c['code'] as String).toLowerCase();
      final name = (c['name'] as String).toLowerCase();
      final nameZh = (c['nameZh'] as String).toLowerCase();
      return code.contains(query) ||
          name.contains(query) ||
          nameZh.contains(query);
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fiatList = _filteredCurrencies
        .where((c) => c['isCrypto'] != true)
        .toList();
    final cryptoList = widget.showCrypto
        ? _filteredCurrencies.where((c) => c['isCrypto'] == true).toList()
        : <Map<String, dynamic>>[];

    return Column(
      children: [
        // 顶部拖拽指示器
        Container(
          margin: const EdgeInsets.only(top: 12, bottom: 8),
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        // 标题
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Text(
                widget.title ?? '选择货币',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
        // 搜索框
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: '搜索货币代码或名称',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              filled: true,
              fillColor: Colors.grey.shade100,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (value) => setState(() => _searchQuery = value),
          ),
        ),
        // 货币列表
        Expanded(
          child: ListView(
            controller: widget.scrollController,
            padding: const EdgeInsets.only(bottom: 20),
            children: [
              if (fiatList.isNotEmpty) ...[
                _buildSectionHeader('法定货币'),
                ...fiatList.map((c) => _buildCurrencyTile(c)),
              ],
              if (cryptoList.isNotEmpty) ...[
                _buildSectionHeader('加密货币'),
                ...cryptoList.map((c) => _buildCurrencyTile(c)),
              ],
              if (fiatList.isEmpty && cryptoList.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(
                    child: Text(
                      '未找到匹配的货币',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade600,
        ),
      ),
    );
  }

  Widget _buildCurrencyTile(Map<String, dynamic> currency) {
    final code = currency['code'] as String;
    final name = currency['name'] as String;
    final nameZh = currency['nameZh'] as String;
    final symbol = currency['symbol'] as String;
    final flag = currency['flag'] as String?;
    final isSelected = code == widget.selectedCode;

    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).primaryColor.withValues(alpha: 0.1)
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          flag ?? symbol,
          style: const TextStyle(fontSize: 20),
        ),
      ),
      title: Row(
        children: [
          Text(
            code,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isSelected
                  ? Theme.of(context).primaryColor
                  : Colors.black87,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            symbol,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
      subtitle: Text(
        '$nameZh / $name',
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey.shade500,
        ),
      ),
      trailing: isSelected
          ? Icon(
              Icons.check_circle,
              color: Theme.of(context).primaryColor,
            )
          : null,
      onTap: () => widget.onSelected(code),
    );
  }
}

/// 货币显示组件（用于表单中展示已选货币）
class CurrencyDisplay extends StatelessWidget {
  final String currencyCode;
  final VoidCallback? onTap;
  final bool showArrow;

  const CurrencyDisplay({
    super.key,
    required this.currencyCode,
    this.onTap,
    this.showArrow = true,
  });

  @override
  Widget build(BuildContext context) {
    final currency = CurrencyDefaults.getAllCurrencies().firstWhere(
      (c) => c['code'] == currencyCode,
      orElse: () => {
        'code': currencyCode,
        'symbol': currencyCode,
        'nameZh': currencyCode,
        'flag': null,
      },
    );

    final flag = currency['flag'] as String?;
    final symbol = currency['symbol'] as String;
    final nameZh = currency['nameZh'] as String;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              flag ?? symbol,
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  currencyCode,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  nameZh,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            if (showArrow && onTap != null) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.arrow_drop_down,
                color: Colors.grey.shade600,
                size: 20,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 货币金额输入组件（带货币选择）
class CurrencyAmountField extends StatelessWidget {
  final TextEditingController controller;
  final String currencyCode;
  final ValueChanged<String>? onCurrencyChanged;
  final String? label;
  final bool readOnly;
  final bool showCrypto;

  const CurrencyAmountField({
    super.key,
    required this.controller,
    required this.currencyCode,
    this.onCurrencyChanged,
    this.label,
    this.readOnly = false,
    this.showCrypto = false,
  });

  @override
  Widget build(BuildContext context) {
    final symbol = CurrencyDefaults.getSymbol(currencyCode);
    final decimals = CurrencyDefaults.getDecimalPlaces(currencyCode);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              label!,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
          ),
        Row(
          children: [
            // 货币选择器
            GestureDetector(
              onTap: onCurrencyChanged == null
                  ? null
                  : () async {
                      final selected = await CurrencyPicker.showPicker(
                        context,
                        selectedCode: currencyCode,
                        showCrypto: showCrypto,
                      );
                      if (selected != null) {
                        onCurrencyChanged!(selected);
                      }
                    },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      symbol,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (onCurrencyChanged != null) ...[
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_drop_down,
                        color: Colors.grey.shade600,
                        size: 20,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            // 金额输入框
            Expanded(
              child: TextField(
                controller: controller,
                readOnly: readOnly,
                keyboardType: TextInputType.numberWithOptions(
                  decimal: decimals > 0,
                ),
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                decoration: InputDecoration(
                  hintText: '0${decimals > 0 ? '.${'0' * decimals}' : ''}',
                  hintStyle: TextStyle(
                    color: Colors.grey.shade400,
                    fontWeight: FontWeight.normal,
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  border: const OutlineInputBorder(
                    borderRadius: BorderRadius.horizontal(
                      right: Radius.circular(12),
                    ),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
