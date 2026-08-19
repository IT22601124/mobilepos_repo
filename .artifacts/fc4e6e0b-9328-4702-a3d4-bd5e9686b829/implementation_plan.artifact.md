# Implementation Plan - Dual Printer Support (Receipt & Label)

This plan refactors the printing system to allow connecting and remembering two separate printer configurations: one for receipts and one for product labels.

## User Review Required

> [!IMPORTANT]
> This change will allow you to assign a specific printer to "Receipts" and another (or the same one) to "Labels". The app will remember both connections.

## Proposed Changes

#### [MODIFY] [printing_provider.dart](file:///F:/mpos/lib/provider/printing_provider.dart)
- Add `PrinterRole` enum: `receipt`, `label`.
- Refactor printer storage to support two roles:
    - `_receiptPrinter`: The device assigned to receipts.
    - `_labelPrinter`: The device assigned to labels.
- Update `connect` and `disconnect` methods to accept a `PrinterRole`.
- Add `isReceiptConnected` and `isLabelConnected` getters.
- Persist both assignments in `SharedPreferences`.
- Update `printBarcodeLabel` to use the label printer.
- Add `printReceiptData` method to handle receipt printing centrally using the receipt printer.

### [Component Name] Printing Options Screen

#### [MODIFY] [printing_options_screen.dart](file:///F:/mpos/lib/screens/settings/printing_options_screen.dart)
- Add a **Role Selector** (e.g., Toggle Buttons or Tabs) at the top of the screen: **[Receipt Printer]** | **[Label Printer]**.
- Display the connection status and available devices for the *active* role.
- Allow the user to connect a different device for each role.

### [Component Name] POS Payment Success Screen

#### [MODIFY] [pos_payment_success_screen.dart](file:///F:/mpos/lib/screens/pos_screen/pos_payment_success_screen.dart)
- Update `printReceipt` to use the new `PrintingProvider.printReceiptData` method (or ensure it targets the receipt role).

## Verification Plan

### Manual Verification
1.  Navigate to **Settings** > **Printing Options**.
2.  Select **Receipt Printer** role and connect a device.
3.  Select **Label Printer** role and connect a (possibly different) device.
4.  Switch back and forth to verify the app remembers which device is assigned to which role.
5.  Perform a sale and verify it prints on the **Receipt Printer**.
6.  Navigate to a product and click **Print Label**: verify it prints on the **Label Printer**.
7.  Restart the app and verify both printers are still assigned correctly.
