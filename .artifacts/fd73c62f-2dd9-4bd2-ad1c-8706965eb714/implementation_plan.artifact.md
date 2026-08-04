# Implementation Plan - 100% Functional Offline Mode

The goal is to enable the POS system to function fully without an internet connection by implementing local data persistence and a background synchronization mechanism.

## User Review Required

> [!IMPORTANT]
> **Stock Accuracy:** In offline mode, stock levels are only as accurate as the last time the app was online. If multiple devices are used offline, overselling might occur until all devices sync.
> **Sale Numbers:** Offline sales will use temporary local IDs (e.g., `OFFLINE-timestamp`) until the server assigns a permanent Sale No. during synchronization.

## Proposed Changes

### Dependencies
Add the following to `pubspec.yaml`:
- `sqflite`: Local database storage.
- `connectivity_plus`: Real-time internet connection monitoring.
- `path`: Helper for database file paths.

---

### [Component] Local Database Layer
#### [NEW] [database_helper.dart](file:///F:/mpos/lib/database/database_helper.dart)
- Singleton class to manage SQLite database.
- Tables:
    - `products`: Cache for the product catalog.
    - `categories`: Cache for product categories.
    - `customers`: Cache for customer list.
    - `sync_queue`: Queue for sales made while offline.

---

### [Component] Connectivity & Sync Logic
#### [NEW] [connectivity_provider.dart](file:///F:/mpos/lib/provider/connectivity_provider.dart)
- Monitors connection status using `connectivity_plus`.
- Provides a `isOnline` boolean to the entire app.

#### [NEW] [sync_provider.dart](file:///F:/mpos/lib/provider/sync_provider.dart)
- **Catalog Sync:** Fetches from API when online and updates the local cache. Returns local cache when offline.
- **Sale Handling:**
    - If `isOnline`, sends directly to API.
    - If `isOffline`, saves to `sync_queue`.
- **Background Sync:** Listens for connection restoration and automatically pushes all items in `sync_queue` to the server.

---

### [Component] UI Integration
#### [MODIFY] [pos_terminal_screen.dart](file:///F:/mpos/lib/screens/pos_screen/pos_terminal_screen.dart)
- Update `_loadCatalog` to use `SyncProvider`.
- Add an "Offline Mode" badge in the header when disconnected.
- Show "Pending Sync" count in the header.

#### [MODIFY] [pos_payment_screen.dart](file:///F:/mpos/lib/screens/pos_screen/pos_payment_screen.dart)
- Update `completePayment` to use `SyncProvider`.
- Allow "Walk-in" sales to complete without an internet connection.

---

## Verification Plan

### Automated Tests
- Unit tests for `DatabaseHelper` CRUD operations.
- Mock connectivity tests to ensure `SyncProvider` switches modes correctly.

### Manual Verification
1. **Catalog Cache:** Open app online, then close and reopen in Airplane Mode. Catalog should still load.
2. **Offline Sale:** Complete a sale while offline. Verify it's saved locally.
3. **Automatic Sync:** Turn on internet. Verify the "Pending Sync" count goes to 0 and the sale appears in the Web Admin.
4. **Resilience:** Interrupted sync should retry on the next connection event.
