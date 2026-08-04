# Task: Responsive Receipt & UI Fixes

- [x] Fix AppBar overflow in `PosTerminalScreen`
- [x] Optimize thermal printing layout in `PosPaymentSuccessScreen`
    - [x] Dynamic logo scaling based on paper width (Reduced for "more small" look)
    - [x] Refine item row column ratios for 70mm/72mm
- [x] Calibrate PDF generation in `PosPaymentSuccessScreen`
    - [x] Added 70mm support
    - [x] Reduced logo height in PDF
- [x] Update on-screen `_ReceiptCard` styling
- [x] Add 70mm option to `PrintingOptionsScreen`
- [x] Verification
    - [ ] Check terminal AppBar on small screens
    - [ ] Test 72mm print/PDF output
