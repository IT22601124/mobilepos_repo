# Implementation Plan - User Friendly Login Messages

The goal is to provide clear, helpful feedback to the user when login fails or when inputs are invalid.

## User Review Required

> [!NOTE]
> I will be adding basic validation to the login fields (phone and password). Please let me know if you have specific requirements for phone number length or character constraints.

## Proposed Changes

### [mpos](file:///F:/mpos)

#### [MODIFY] [auth_provider.dart](file:///F:/mpos/lib/provider/auth_provider/auth_provider.dart)
- Update `login` method to handle `DioException`.
- Throw descriptive strings (not just `Exception`) based on the error type and response status code:
    - 401: "Incorrect phone number or password."
    - 404: "User account not found."
    - Network issues: "Network error. Please check your connection."
    - Other: "An unexpected error occurred. Please try again."

#### [MODIFY] [login_screen.dart](file:///F:/mpos/lib/screens/auth_screens/login_screen.dart)
- Add form validation to `TextFormField`s:
    - Phone: Check if empty or too short.
    - Password: Check if empty or too short.
- Update `_handleLogin` to:
    - Show `isLoading` on the `MainButton` using `context.watch<AuthProvider>().isLoading`.
    - Catch errors and display them cleanly (removing `Exception:` prefix if present).
- Ensure the login button is disabled while loading.

## Verification Plan

### Manual Verification
1. **Wrong Credentials:** Try logging in with a wrong password. Verify that "Incorrect phone number or password" appears.
2. **Network Off:** Disable Wi-Fi/Data and try logging in. Verify that "Network error" appears.
3. **Empty Fields:** Try logging in with empty fields. Verify that validation errors appear under the text fields.
4. **Successful Login:** Verify that normal login still works.
5. **Loading State:** Verify that the login button shows a loading spinner during the request.
