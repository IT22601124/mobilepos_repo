# Add "Quick Create Customer" to Payment Screen

Allow users to create a new credit customer directly from the `PosPaymentScreen` to streamline the checkout process when a new customer wants to buy on credit.

## User Review Required

> [!IMPORTANT]
> A new "Add Customer" button will be added next to the customer selection dropdown. Tapping this will open a dialog to enter basic customer details.

## Proposed Changes

### [POS Payment Screen]

#### [MODIFY] [pos_payment_screen.dart](file:///F:/mpos/lib/screens/pos_screen/pos_payment_screen.dart)

- **State Management**:
    - Add `_showCreateCustomerDialog()` method to handle the customer creation UI.
    - Add `_handleCreateCustomer(Map<String, dynamic> data)` to call the API and update the list.
- **UI Update**:
    - Update `_CreditBox` widget to include an `IconButton` next to the `DropdownButtonFormField`.
    - Pass a callback `onAddCustomer` to `_CreditBox`.
- **Navigation**:
    - Add a "Manage Customers" button/link in the dialog or near the dropdown as a fallback to POS Management.

## Verification Plan

### Automated Tests
- Run `flutter analyze` to ensure no syntax errors or missing parameters.

### Manual Verification
1. Navigate to **POS Terminal** -> **Pay**.
2. Select **Credit** as the payment method.
3. Tap the **"+" (Add Customer)** icon next to the dropdown.
4. Fill in the name and phone number in the dialog and save.
5. Verify that the new customer is created, the list is reloaded, and the new customer is automatically selected.
6. Verify that the "Credit Amount" and "Available Credit" are correctly updated.
