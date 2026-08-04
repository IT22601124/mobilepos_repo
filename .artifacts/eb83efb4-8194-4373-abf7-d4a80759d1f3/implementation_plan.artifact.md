# Implementation Plan: Responsive Receipt & UI Fixes

The goal is to optimize the receipt layout for different paper widths (especially 72mm) and fix a UI overflow in the POS Terminal screen.

## User Review Required

> [!IMPORTANT]
> The thermal printer library `esc_pos_utils_plus` supports specific `PaperSize` enums. I will ensure that the 72mm layout uses the available library capabilities while maximizing the printable area.

## Proposed Changes

### [PosTerminalScreen](file:///F:/mpos/lib/screens/pos_screen/pos_terminal_screen.dart)

- [MODIFY] Fix `AppBar` title overflow by wrapping the `Row` content in `Flexible` or using a more compact layout.
- [MODIFY] Adjust `_TerminalHeader` to prevent overflow when `pendingCount` or long totals are displayed.

### [PosPaymentSuccessScreen](file:///F:/mpos/lib/screens/pos_screen/pos_payment_success_screen.dart)

- [MODIFY] **Thermal Printing Optimization**:
    - Update `targetWidth` for the logo to scale appropriately for 58mm, 72mm, and 80mm.
    - Refine column ratios in `generator.row` if needed for narrower papers.
    - Ensure font sizes for headers and items are adjusted based on paper width.
- [MODIFY] **PDF Generation**:
    - Ensure `PdfPageFormat` for 72mm is perfectly calibrated.
    - Adjust margins and font sizes in the PDF to match the thermal print feel.
- [MODIFY] **On-Screen Receipt Card**:
    - Potentially adjust the width of the `_ReceiptCard` to visually represent the selected paper size (e.g. 58mm, 72mm, 80mm) to give the user a preview.

### [PrintingProvider](file:///F:/mpos/lib/provider/printing_provider.dart)

- [MODIFY] (Optional) Ensure `PaperSize.mm72` is correctly mapped and supported if it's a custom addition.

## Verification Plan

### Automated Tests
- N/A

### Manual Verification
1.  **UI Fix**: Open POS Terminal on a small device (or emulator with small width) and verify the `AppBar` no longer overflows.
2.  **Thermal Print**: Select 72mm in Printing Options, then print a receipt. Verify the logo is appropriately sized and the text is well-aligned.
3.  **PDF/Share**: Generate a PDF for 72mm and verify it looks professional and "responsive" to the width.
4.  **On-Screen Preview**: Verify the `_ReceiptCard` on the success screen looks good across different screen sizes.
