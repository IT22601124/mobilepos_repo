# Walkthrough - Printer Connectivity and Settings

I have implemented a comprehensive printing options system for NovaPOS, supporting both Bluetooth and USB thermal printers.

## Changes Made

### 1. Hardware Communication & Utilities
- Added `flutter_pos_printer_platform`, `esc_pos_utils_plus`, and `permission_handler` to `pubspec.yaml`.
- Resolved dependency conflicts between `image` v3 (used by printer) and `image` v4 (used by utils) using `dependency_overrides`.
- Configured `AndroidManifest.xml` with permissions for Bluetooth (Scan & Connect), Location (Discovery), and USB.

### 2. Printing State Management
- Created [PrintingProvider](file:///F:/mpos/lib/provider/printing_provider.dart) which handles:
    - Scanning for Bluetooth and USB devices.
    - Managing connection lifecycle.
    - Persistent settings for connection type (Bluetooth/USB) and paper size (58mm/80mm).
    - ESC/POS command generation for test printing.

### 3. Settings UI
- Created [PrintingOptionsScreen](file:///F:/mpos/lib/screens/settings/printing_options_screen.dart):
    - **Connection Toggle:** Switch between Bluetooth and USB modes.
    - **Paper Size Selection:** Support for 58mm and 80mm thermal paper.
    - **Device Discovery:** Real-time scanning for available printers.
    - **Connectivity Status:** Visual feedback when a printer is connected.
    - **Testing:** "Print Test Page" button to verify the setup.

### 4. Integration
- Registered `PrintingProvider` in `main.dart`.
- Enabled the `/printing-options` route in `router_chekcer.dart`.
- **Receipt Printing:** Updated `PosPaymentSuccessScreen` to automatically use the connected thermal printer. If no printer is connected, it falls back to the system PDF print dialog.

## Verification Results

> [!NOTE]
> Testing requires physical hardware (Bluetooth/USB thermal printer). The UI has been verified to correctly trigger scanning and connection requests.

- **Permissions:** The app correctly requests Bluetooth and Location permissions when opening the settings.
- **Scanning:** Tap the refresh icon in "Available Devices" to start a 10-second discovery cycle.
- **Persistence:** Selecting a paper size or connection type saves the preference immediately via `SharedPreferences`.
