import 'package:mpos/utils/app_localizations.dart';
import 'package:flutter/material.dart';

class SearchBox extends StatelessWidget {
  final ValueChanged<String> onChanged;
  final VoidCallback onScanTap;
  final List<Map<String, dynamic>> suggestions;
  final ValueChanged<Map<String, dynamic>> onSuggestionSelected;
  final TextEditingController? controller;
  final FocusNode? focusNode;

  const SearchBox({
    super.key,
    required this.onChanged,
    required this.onScanTap,
    required this.suggestions,
    required this.onSuggestionSelected,
    this.controller,
    this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 6),
      child: RawAutocomplete<Map<String, dynamic>>(
        textEditingController: controller,
        focusNode: focusNode,
        optionsBuilder: (TextEditingValue textEditingValue) {
          if (textEditingValue.text.isEmpty) {
            return const Iterable<Map<String, dynamic>>.empty();
          }
          final query = textEditingValue.text.toLowerCase();
          return suggestions.where((Map<String, dynamic> option) {
            final name = option['name'].toString().toLowerCase();
            final sku = option['sku'].toString().toLowerCase();
            return name.contains(query) || sku.contains(query);
          });
        },
        onSelected: onSuggestionSelected,
        fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
          return SizedBox(
            height: 42,
            child: TextField(
              controller: textEditingController,
              focusNode: focusNode,
              onChanged: onChanged,
              onSubmitted: (_) => onFieldSubmitted(),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                hintText: context.tr('search_products'),
                hintStyle: TextStyle(
                  color: Theme.of(context).hintColor.withValues(alpha: 0.5),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                prefixIcon: Icon(Icons.search_rounded, size: 20, color: Theme.of(context).hintColor),
                suffixIcon: IconButton(
                  icon: Icon(Icons.qr_code_scanner_rounded, size: 20, color: Theme.of(context).colorScheme.primary),
                  onPressed: onScanTap,
                ),
                filled: true,
                fillColor: Theme.of(context).cardColor,
                contentPadding: EdgeInsets.zero,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: 0.6)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 1.5),
                ),
              ),
            ),
          );
        },
        optionsViewBuilder: (context, onSelected, options) {
          return Align(
            alignment: Alignment.topLeft,
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(12),
              clipBehavior: Clip.antiAlias,
              color: Theme.of(context).cardColor,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: 300,
                  maxWidth: MediaQuery.of(context).size.width - 28,
                ),
                child: ListView.separated(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  itemCount: options.length,
                  separatorBuilder: (context, index) => Divider(height: 1, color: Theme.of(context).dividerColor.withValues(alpha: 0.5)),
                  itemBuilder: (BuildContext context, int index) {
                    final Map<String, dynamic> option = options.elementAt(index);
                    return InkWell(
                      onTap: () => onSelected(option),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    option['name'].toString(),
                                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                                  ),
                                  Text(
                                    '${context.tr('sku')}: ${option['sku']}  •  ${context.tr('stock')}: ${option['is_weighted'] == true ? (option['stock'] as num).toStringAsFixed(3) : (option['stock'] as num).toInt()} ${option['unit_name'] ?? (option['is_weighted'] == true ? 'kg' : 'pcs')}',
                                    style: TextStyle(color: Theme.of(context).hintColor, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              'LKR ${option['price']}',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
