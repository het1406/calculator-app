# Calculator App — Implementation Rationale

DRAFT — student details, course confirmation, exact reflection questions, and the second-agent comparison are still required.

Name: TO BE PROVIDED
Student ID: TO BE PROVIDED
Course: CSC 4360 undergraduate pathway assumed; enrollment not yet confirmed.
Assignment: 01 — Calculator App
Date: October 8, 2026

## Scope and selected features

The app implements digit entry, addition, subtraction, multiplication, division, and a readable result display. Its three selected undergraduate features are theme toggle, all clear, and error handling. Decimal entry, percentage, sign toggle, history, and advanced chained evaluation are outside this selected scope. Fractional division results are supported.

The light/dark switch updates Material color schemes throughout the calculator with a 250 ms theme transition. All clear resets every calculator field. Invalid calculations show a recoverable message: AC resets everything, while a digit begins a new calculation. Division by zero, missing operands, extra operators after a second operand, and nonfinite arithmetic results are checked.

## Interface and interaction sketch

MaterialApp owns the theme mode. CalculatorScreen is a StatefulWidget that owns a CalculatorState instance. SafeArea contains a scrollable centered column, limited to 520 logical pixels. The column contains the title and theme switch, expression/result panel, recovery guidance, and reusable button rows.

The keypad rows are [AC, ÷], [7, 8, 9, ×], [4, 5, 6, −], [1, 2, 3, +], and [0, =]. Buttons are 68 logical pixels tall. Narrow and landscape screens can scroll instead of overflowing. The display scales long results to fit, while error messages wrap.

A normal interaction is 8 → × → 7 → = → 56. An operator chosen before the second operand replaces the pending operator. A digit after a result begins a fresh calculation; an operator after a result reuses that result. Repeated equals without a new operation reports incomplete input. No arithmetic is performed merely by selecting a second operator after both operands have been entered.

## 01 — State and architecture

The supplied assignment contains this question title but not its complete wording. This response addresses the title and needs review against the full question.

CalculatorState stores the current input string, nullable first operand and pending operator, awaitingOperand, showingResult, and a nullable error message. Its display getter derives the visible text from error or input. The expression getter derives the operation hint. There is no separate resultText field, so the result display and the next calculation cannot use different result copies.

The UI invokes state methods inside setState. CalculatorApp separately owns theme state, which lets theme changes preserve the same calculator screen and arithmetic state. Arithmetic is isolated from widgets so input sequences can be tested without rendering the UI. The mutable model is intentionally small and local rather than using a global state package. A phase enum is an alternative that would make invalid flag combinations less likely if the app gained history, expression editing, or additional modes.

Evidence: lib/calculator_state.dart, CalculatorState.display/clear/digit/selectOperator/equals; lib/main.dart, _CalculatorScreenState._press and _CalculatorAppState.build; theme-preservation widget test.

## 02 — Correctness under pressure

The arithmetic handler checks completeness before reading a second operand and checks a zero denominator before division. The four operations use a switch. Nonfinite results produce a recoverable error. Input is limited to 12 digits; output is rounded to 12 significant digits to avoid displaying binary floating-point noise. This is a deliberate usability/precision trade-off, not an exact decimal arithmetic implementation.

Boundary behavior is explicit. Leading zeroes do not accumulate. Subtraction can produce negative results without a sign-toggle feature. Division can produce a fractional output. A digit after an error clears stale operands, and AC clears input, operands, operator, flags, and errors. A two-operand design avoids silently imposing an undocumented precedence rule.

Evidence: tests cover 12 + 7 = 19; 3 − 8 = −5; 8 × 7 = 56; 9 ÷ 2 = 4.5; 0 × 987 = 0; 1 ÷ 3 rounding; divide-by-zero recovery; incomplete input; operator replacement; result reuse; leading zeroes; and the input limit. These tests support the stated cases, not a claim of exhaustive mathematical correctness.

## 03 — Accessibility is behavior

Operator buttons have spoken action labels such as Multiply and Divide rather than relying on symbol pronunciation. The result/error panel uses a live-region semantic label. The theme switch has a Dark theme label and exposes switch state. A selected operator has semantic selection state as well as a visual color change. The operation hint provides additional context, so selection is not communicated only through color.

The scrollable layout is tested at 320 × 568 and 568 × 320 with 200% text scaling. Controls remain available by scrolling; result text scales down when needed. This preserves fit but can reduce very long result readability, a limitation that would benefit from testing with users. Automated semantics and Android tap-target checks pass. These automated checks do not replace a human TalkBack listening test or a color-vision review; those are not claimed as completed.

Evidence: CalculatorButton semantic labels and dimensions, result Semantics/liveRegion, and widget tests for small layouts and accessibility guidelines.

## 04 — Performance without visual loss

Each tap mutates only local calculator state and rebuilds a small widget tree. There are no network calls, external fonts, large image assets, or background operations in the application. Buttons are reusable widgets and stable content uses const where practical. Layout uses bounded width and simple rows rather than a complex custom renderer. The theme transition is 250 ms and is handled by MaterialApp.

A larger app could isolate the display and controls behind narrower rebuild boundaries or add profiling before optimizing. For this small screen, added state-management dependencies would increase maintenance without demonstrated benefit. The release APK is used for device verification; no frame-time benchmark is claimed.

## 05 — AI output under review

The assignment explicitly requires a two-agent test drive. The available ChatGPT responses are recorded with the unchanged Bug Hunt and State Design prompts in docs/agent-test-drive.md. A real response from Gemini or Microsoft Copilot is still needed for each prompt. The comparison is incomplete until those responses are available.

The recommendation to avoid duplicated display/result state was accepted and checked against CalculatorState.display, which derives from a single input string or error message. The recommendation to treat a missing second operand as invalid was accepted and verified by a test of 8, +, =. Fractional division output was distinguished from graduate decimal input; 9 ÷ 2 = 4.5 is tested even though this undergraduate keypad has no decimal-entry button.

## 06 — AI advice, trade-offs, and maintainability

Advice is evaluated against the selected pathway and executed behavior. The implementation uses local StatefulWidget/setState and a small testable arithmetic model. A more elaborate provider or expression parser would add concepts unrelated to this assignment's two-operand requirement. The first-agent suggestion of explicit phase handling is implemented through two flags; an enum is a reasonable future alternative if the state machine grows.

The implementation favors a documented two-operand flow over undocumented chaining. Twelve-significant-digit formatting favors a readable result over full double precision. A scrollable layout favors reachable controls over fixed full-screen placement on every orientation. These trade-offs are visible in source and tests. Acceptance or rejection of the second agent's advice cannot be described until its actual responses are obtained.

## Challenges and verification

The existing Flutter download contained Windows executables. A macOS ARM64 Flutter 3.35.7 SDK was installed separately. The available Java 25 runtime was incompatible with this project's Gradle version, so Flutter was configured to use Java 21. The initial accessibility test exposed a test-helper lifecycle problem; disposing the semantics handle before the test ended corrected the test setup.

Static analysis and 25 automated tests passed. The tests include arithmetic state transitions, UI interaction, two theme directions, error recovery, small-screen layout at 200% text scaling, semantic labels, and Android tap targets. The release APK was built, installed, and exercised on the Pixel_4a Android emulator. Eight device checks passed: all four operations, theme state preservation, division-by-zero feedback, recovery by digit entry, and incomplete-input recovery with AC. The device log and screenshots are included in the appendix and in docs/device-verification.md.

## Assistance and review

ChatGPT/Codex assisted with implementation, test creation and execution, environment setup, and this rationale draft. The assignment's explicit agent-comparison section is documented separately. The student must review the implementation and this document, supply personal details and actual second-agent responses, and apply any additional course disclosure rules. No claim is made that the student independently performed work or verification that has not been confirmed.

## References

Flutter manual installation: https://docs.flutter.dev/install/manual
Flutter Android release build guidance: https://docs.flutter.dev/deployment/android
Flutter test APIs available in the installed SDK: packages/flutter_test/lib/src/accessibility.dart and widget_tester.dart.
Assignment requirements: the assignment text supplied for this project.

## Required completion before upload

Confirm course pathway and provide the student's name and ID. Check responses 01–06 against the complete question wording. Obtain the second agent's actual responses, add the comparison, and verify an agreed or disputed claim. Authenticate GitHub and publish the source repository, then create github_link.txt with its verified accessible URL. Rename the APK and Word document with the confirmed name. Upload all three deliverables to the designated course LMS and verify receipt.
