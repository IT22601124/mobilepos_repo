# Implementation Plan - Role-Based Visibility for Management Sections

This plan describes how to hide sensitive management sections (Roles, Users, and Branches) for users with the "Cashier" role.

## User Review Required

> [!NOTE]
> The app will now check the logged-in user's role before building the management tabs. Users who are not Super Admins (including Cashiers) will no longer see the Branches, Roles, and Users tabs.

## Proposed Changes

### [Component Name] POS Management Screen

#### [MODIFY] [pos_management_screen.dart](file:///F:/mpos/lib/screens/pos_management_screen/pos_management_screen.dart)
- Update `_buildResources()` to conditionally include sections based on `isSuperAdmin`.
- Hide the following tabs if `isSuperAdmin` is false:
    - **Branches**
    - **Roles**
    - **Users**
- This ensures cashiers can focus on products, stocks, and sales without accessing administrative configuration.

## Verification Plan

### Manual Verification
1.  Log in as a **Super Admin**.
2.  Navigate to **Management**.
3.  Verify that **Branches**, **Roles**, and **Users** tabs are visible.
4.  Log out and log in as a **Cashier**.
5.  Navigate to **Management**.
6.  Verify that the **Branches**, **Roles**, and **Users** tabs are **hidden**.
7.  Verify that other sections like **Products**, **Stocks**, and **POS Sales** are still accessible.
