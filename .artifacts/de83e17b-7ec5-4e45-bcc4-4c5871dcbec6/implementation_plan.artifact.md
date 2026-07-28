# Implementation Plan - Expanded Paper Size Support

The user wants to support more paper sizes for printing. I will expand the current support (58mm/80mm) to include 72mm and ensure the UI allows for easy selection between these standard sizes.

## Proposed Changes

### State Management

#### [MODIFY] [printing_provider.dart](file:///F:/mpos/lib/provider/printing_provider.dart)
- Update `_loadSettings` to correctly handle `PaperSize` values (1, 2, 3) from `SharedPreferences`.
- Update `setPaperSize` to persist the specific `PaperSize` value.
- Ensure `testPrint` uses the updated paper size.

### UI Layer

#### [MODIFY] [printing_options_screen.dart](file:///F:/mpos/lib/screens/settings/printing_options_screen.dart)
- Update `_buildPaperSizeSection` to include a 72mm option.
- Ensure the UI correctly reflects the selected size.

#### [MODIFY] [pos_payment_success_screen.dart](file:///F:/mpos/lib/screens/pos_screen/pos_payment_success_screen.dart)
- Update `_buildReceiptPdf` to use a PDF page format that matches the selected paper size (58mm, 72mm, or 80mm).
- Note: Thermal printing via ESC/POS already respects `provider.paperSize`.

## Verification Plan

### Manual Verification
- **Settings Check:** Navigate to Printing Options and verify that 58mm, 72mm, and 80mm are available and selectable.
- **Persistence:** Change the size, restart the app, and verify the selection is remembered.
- **Printing:** Perform a test print and a receipt print with different sizes selected to ensure the commands are sent correctly.
- **PDF Preview:** Verify that the "Download" or PDF preview respects the width of the selected paper size.
