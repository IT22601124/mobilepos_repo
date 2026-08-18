# Task: Fix Database Schema Out of Sync

- [x] Increment database version in `DatabaseHelper`
- [x] Implement `onUpgrade` logic to refresh schema
- [x] Verification
    - [x] Confirm no more "no such column" or "no such table" errors in logs
    - [x] Confirm data sync works as expected
