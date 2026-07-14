import 'package:flutter/material.dart';


class SearchBox extends StatelessWidget {
  final ValueChanged<String> onChanged;

  const SearchBox({
    super.key,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(14),
      child: TextField(
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: 'Search product or scan barcode',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: const Icon(Icons.qr_code_scanner),
          filled: true,
          fillColor: const Color(0xFFF3F4F6),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}
