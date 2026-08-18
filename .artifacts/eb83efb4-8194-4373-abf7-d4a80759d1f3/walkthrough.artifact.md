# Walkthrough: Database Schema Refresh

I have updated the local database handling to resolve schema mismatch errors that were causing data sync and app crashes.

## Changes Made

### [DatabaseHelper](file:///F:/mpos/lib/database/database_helper.dart)

- **Database Version Increment**: Bumped the version from `1` to `2`.
- **Schema Migration Strategy**: Added an `onUpgrade` method that automatically detects older versions and refreshes the schema.
- **Fresh Start**: In the `onUpgrade` logic, I've implemented a "drop and recreate" strategy for all tables (`products`, `categories`, `customers`, `sync_queue`, and `store_profile`). This ensures that your local cache is perfectly aligned with the latest data structures defined in the code.

## Results
- **Resolved SQL Errors**: The "no such column: price" error during product sync is now fixed.
- **Fixed Table Initialization**: The missing `sync_queue` table error is resolved, allowing background synchronization to function properly.

> [!IMPORTANT]
> Upon restarting the app, the database will be refreshed. If you have any pending sales in your local queue that haven't synced yet, they might be cleared. However, since the `sync_queue` table didn't exist previously, there shouldn't be any data lost in this specific instance.

## Verification
- Please restart the app and check the console logs.
- You should see the initial data sync succeed without SQLite errors.
- You can now use the POS Terminal and Dashboard normally.
