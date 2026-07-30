# Implementation Plan - Expanded Paper Size Support (including Ultra-Small)

This plan adds support for a wide range of paper sizes, including ultra-small sizes like **30mm** and **44mm**, to ensure compatibility with specialized handheld and mobile thermal printers.

## Proposed Changes

### State Management

#### [MODIFY] [printing_provider.dart](file:///F:/mpos/lib/provider/printing_provider.dart)
- Update `_loadSettings` to handle more paper size values:
    - 0: 30mm (Ultra-Micro)
    - 1: 44mm (Micro)
    - 2: 57mm
    - 3: 58mm
    - 4: 72mm
    - 5: 80mm
- Update `setPaperSize` to persist these values.
- Map 30mm and 44mm to `PaperSize.mm58` for the thermal generator (as it's the minimum standard), but we will adjust the content layout manually.

### UI Components

#### [MODIFY] [printing_options_screen.dart](file:///F:/mpos/lib/screens/settings/printing_options_screen.dart)
- Update the Paper Size section to use a `Wrap` or `SingleChildScrollView` row to fit: **30mm, 44mm, 57mm, 58mm, 72mm, 80mm**.

### Receipt & PDF Generation

#### [MODIFY] [pos_payment_success_screen.dart](file:///F:/mpos/lib/screens/pos_screen/pos_payment_success_screen.dart)
- **Dynamic PDF Page Format:**
    - **30mm:** `PdfPageFormat(30 * PdfPageFormat.mm, ...)` with minimal margins.
    - **44mm:** `PdfPageFormat(44 * PdfPageFormat.mm, ...)`
- **Condensed Layout Strategy:**
    - For 30mm and 44mm, automatically reduce the base font size (e.g., from 12 to 8 or 9) and use single-line rows for items to prevent overlapping.
    - Remove large headers or center-align text if it saves space on narrow paper.

## Verification Plan

### Manual Verification
1.  **Settings Selection:** Verify all sizes from 30mm to 80mm are selectable and saved.
2.  **30mm PDF:** Generate a 30mm PDF and ensure text is resized correctly to fit the 1.18-inch width.
3.  **44mm PDF:** Verify layout on the 1.73-inch width.
4.  **Print Test:** Verify thermal commands generate readable text on the smallest widths.
