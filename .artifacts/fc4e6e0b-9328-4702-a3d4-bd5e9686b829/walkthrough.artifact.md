# Walkthrough - Dual Printer Support (Receipt & Label)

I have implemented support for connecting two separate printers simultaneously: one for **Sales Receipts** and another for **Product Labels**.

## New Features

### 1. Dual Printer Roles
The app now differentiates between a **Receipt Printer** and a **Label Printer**.
- **Independent Configuration**: You can use different connection types (Bluetooth/USB) and different paper widths for each role.
- **Persistent Memory**: The app remembers which printer is assigned to which job even after a restart.

### 2. Tabbed Printing Setup
The **Printing Options** screen has been updated with a tab bar:
- **Receipt Printer Tab**: Configure your main bill printer (typically 80mm).
- **Label Printer Tab**: Configure your barcode/price tag printer (typically 58mm).
- **Status Visibility**: Each tab shows the connection status specifically for that role.

### 3. Automatic Intelligent Routing
- **Sales Flow**: Receipts are automatically sent to the assigned **Receipt Printer**.
- **Product Management**: Barcode labels are automatically sent to the assigned **Label Printer**.
- **Smart Fallbacks**: If a label printer is not connected, the app will warn you specifically about the label printer without affecting receipt functionality.

## How to Set Up
1. Go to **Settings** > **Printing Options**.
2. Tap the **Receipt Printer** tab, scan, and connect your bill printer.
3. Tap the **Label Printer** tab, scan, and connect your label printer.
4. (Optional) Run a **Test Print** in each tab to verify both are working.

> [!TIP]
> You can assign the same printer to both roles if you use a single machine for all tasks. The app will handle the switching logic automatically.

> [!IMPORTANT]
> If you previously had a printer connected, you will need to reconnect it in the new tabbed interface to assign it a role.
