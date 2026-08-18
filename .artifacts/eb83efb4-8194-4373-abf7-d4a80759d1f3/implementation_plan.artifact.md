# Implementation Plan: Fix Database Schema Out of Sync

The app is experiencing database errors because the local SQLite schema (`mpos_offline.db`) does not match the current code definition. Specifically, the `products` table is missing the `price` column, and the `sync_queue` table does not exist at all on the user's device.

## Proposed Changes

### [DatabaseHelper](file:///F:/mpos/lib/database/database_helper.dart)

- [MODIFY] Increment the database version from `1` to `2`.
- [MODIFY] Implement the `onUpgrade` callback in `openDatabase`.
- [NEW] In `onUpgrade`, drop all existing tables (`products`, `categories`, `customers`, `sync_queue`, `store_profile`) and call `_onCreate` to recreate them with the correct schema.

> [!NOTE]
> Since this database primarily serves as a local cache for offline capabilities, dropping and recreating tables on upgrade is an acceptable strategy to ensure schema consistency.

## Verification Plan

### Manual Verification
1. Restart the app.
2. Observe the logs to ensure the database version upgrade triggers.
3. Verify that the "Sync failed" error regarding the `price` column no longer appears.
4. Verify that the "Unhandled Exception: DatabaseException(no such table: sync_queue ...)" error is resolved.
5. Perform a test sale and verify it can be added to the `sync_queue` if offline, or processed normally if online.
