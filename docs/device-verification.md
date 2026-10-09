# Release APK verification

Date: October 8, 2026 (America/New_York).

Device: Pixel_4a Android emulator, ARM64. Release APK installed using adb install -r and launched successfully.

PASS: All clear → 1 → 2 → Add → 7 → Equals → Display 19

PASS: All clear → 3 → Subtract → 8 → Equals → Display -5

PASS: All clear → 8 → Multiply → 7 → Equals → Display 56

PASS: All clear → 9 → Divide → 2 → Equals → Display 4.5

PASS: theme switch preserves result 4.5

PASS: division by zero shows recoverable error

PASS: digit after error starts fresh; 3 + 2 = 5

PASS: incomplete operation reports error; AC resets display

Screenshots: docs/screenshots/result.png, dark.png, error.png.

Tests used Android UI automation against the installed release APK. Human TalkBack listening, physical-device testing, and LMS upload have not been performed.
