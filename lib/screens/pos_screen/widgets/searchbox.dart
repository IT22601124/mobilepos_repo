import 'package:flutter/material.dart';

class SearchBox extends StatelessWidget {
  final ValueChanged<String> onChanged;

  const SearchBox({super.key, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 6),
      child: SizedBox(
        height: 42,
        child: TextField(
          onChanged: onChanged,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            hintText: 'Search products or SKU...',
            hintStyle: TextStyle(
              color: Theme.of(context).hintColor.withValues(alpha: 0.5),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
            prefixIcon: Icon(Icons.search_rounded, size: 20, color: Theme.of(context).hintColor),
            suffixIcon: Icon(Icons.qr_code_scanner_rounded, size: 20, color: Theme.of(context).colorScheme.primary),
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
      ),
    );
  }
}
