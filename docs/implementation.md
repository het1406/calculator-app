# Calculator App — Implementation Rationale

Repository: https://github.com/het1406/calculator-app

Add the student ID before submission.

Name: HetJani
Student ID: ____________________
Course: CSC 4360 — Undergraduate
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

Question: Which values belong in widget state, and which can be derived? How would your design change if the calculator supported a long expression or calculation history?

The widget state holds values that must survive a rebuild: the light/dark preference in CalculatorApp and the CalculatorState instance in CalculatorScreen. The calculator model stores the current input string, first operand, pending operator, awaitingOperand, showingResult, and a nullable error message. Input stays as text while typing. Display text is derived from error ?? input, and the expression hint is derived from the stored operand and operator. A separate resultText or isError is unnecessary because the result becomes input and the presence of an error message already identifies an error.

Every calculator action is performed inside setState, so the visible screen follows the model. Separating arithmetic from widgets makes input sequences independently testable. Keeping theme state outside the arithmetic model means switching themes does not erase a pending calculation.

For long expressions, I would replace the two-operand model with a token list and explicit parser that defines precedence, parentheses, and invalid syntax. I would derive the displayed expression from the tokens rather than maintain another editable copy. For history, I would store immutable records containing the expression, result, and optional timestamp, then derive the visible history list. Tapping a record would intentionally load its result into the input. Persistence would belong in a separate storage layer if history must survive restarting the app. I would also replace the two phase flags with an enum as the number of transitions grows; a global state-management package is not automatically required.

Evidence: lib/calculator_state.dart, especially display, expression, clear, digit, selectOperator, and equals; lib/main.dart, _press; test/widget_test.dart, theme preservation.

## 02 — Correctness under pressure

Question: How does your calculator respond to division by zero, repeated operators, pressing equals too early, or entering another number after a result? What tests distinguish a correct result from a plausible-looking one?

For both 7 ÷ 0 and 0 ÷ 0, the app shows Cannot divide by zero. It checks the denominator before calculating, so NaN or Infinity is never presented as a valid result. Pressing a digit after an error starts a fresh calculation; AC resets all arithmetic state. A nonfinite result also has an error guard.

Repeated operators before the second operand replace the pending operator: 8, +, ×, 7, = gives 56. After a second operand is entered, another operator produces an error because this app requires equals before starting the next calculation. Pressing equals at startup, after only a number, or after 8, + reports incomplete input. Pressing equals again after a completed result also reports incomplete input; repeated-operation behavior is not implemented. Entering 2 immediately after a result starts at 2 rather than appending it. Choosing an operator instead reuses the displayed result.

Exact expected-value tests distinguish correctness from a plausible display. For example, 3 − 8 must be −5, which detects reversed subtraction operands; 9 ÷ 2 must be 4.5, which detects accidental integer division. The sequence 8 × 7 = followed by + 4 = must display 56 and then 60, detecting a stale internal result even when the first display looks correct. Tests also assert that recovery clears the pending operator and operand. A display that merely contains a number would not be sufficient evidence.

Input is limited to 12 digits and results to 12 significant digits. The 1 ÷ 3 test asserts the documented rounded result, 0.333333333333, rather than assuming infinite precision. Evidence: test/calculator_state_test.dart and docs/test-results.txt.

## 03 — Accessibility is behavior

Question: How would you make the calculator usable with TalkBack, large text, and users who cannot distinguish color? Identify a concrete control or status message you changed or tested.

TalkBack needs meaningful names and actions. The multiplication control exposes Multiply, a button role, and a semantic tap action rather than relying only on the × glyph. During review, I revised the button's semantic wrapper to include onTap explicitly because a spoken label alone does not make the control actionable. The automated test verifies that Multiply has a tap action. The result/error panel is a live region with a spoken label such as Error: Cannot divide by zero, and the theme switch is labeled Dark theme.

All keys are 68 logical pixels tall. The interface scrolls on a small display rather than making controls unreachable, and tests exercise 320 × 568 and 568 × 320 layouts at 200% text scale. Error text wraps. Long numeric results scale down to fit, which is a readability trade-off that warrants further user testing. Android tap-target and semantic-label checks pass.

Users do not need to distinguish color to identify operations: each button has a symbol, the pending operation is written above the result, and errors contain explicit words plus recovery guidance. Selected operators also expose semantic selection state. On a device with TalkBack, I would additionally listen to focus order and result announcements, activate every key, and test whether announcements become noisy during entry. That human listening test and a color-vision review have not been claimed as completed.

Evidence: CalculatorButton in lib/main.dart, result Semantics/liveRegion, and accessibility/layout tests in test/widget_test.dart.

## 04 — Performance without visual loss

Question: If the interface felt slow on an older device, how would you find the cause and improve startup or rendering speed without removing useful visual feedback? What would you measure before and after?

I would first reproduce the slowdown on the same older physical device in profile mode, using a fixed sequence of cold launches, digit entry, calculations, and theme switches. Flutter DevTools can separate UI-thread work from raster-thread work. I would inspect slow frames, CPU work, rebuilds, and memory before choosing a fix; debug-mode timing would not be my performance baseline. Flutter's profiling guidance recommends physical-device profiling and examining individual frames: https://docs.flutter.dev/perf/ui-performance.

Before and after each change, I would record cold-start time to a usable first screen, UI/raster frame durations, the percentage of frames missing the display's refresh deadline, tap-to-visible-result latency, and memory use. I would repeat the same workload several times and compare medians and slow-tail results under similar device conditions. On a 60 Hz display the frame interval is approximately 16.7 ms; higher-refresh displays have a smaller interval.

If profiling showed excessive widget work, I would narrow rebuild boundaries around the display and retain reusable/const widgets. If raster work dominated, I would simplify the measured expensive decoration or effect. If startup work dominated, I would defer nonessential initialization. I would preserve visible button feedback, selection state, readable error messages, and the 250 ms theme transition while measuring whether the change actually helps. This app has no network startup calls or large image assets. No older-device benchmark or measured speedup is claimed here; this is the proposed diagnostic plan.

## 05 — AI output under review

Question: Suppose an AI assistant suggests a calculation function that passes 8 ÷ 2 but mishandles 0 ÷ 0 or repeated input. How would you expose the defect, verify a fix, and explain what you learned? Which AI-generated suggestions did you reject or revise, and why?

Passing 8 ÷ 2 = 4 only checks a normal path. I would add a failing regression for 0 ÷ 0, require a useful error rather than NaN, and then enter 4 + 2 = to verify recovery gives 6 without a stale operand. I would also test repeated operators, equals before the second operand, repeated equals after a result, and a digit after a result. The intended policy must be written down before judging the output: operator replacement before the second operand is intentional here.

The current test suite now explicitly includes 8 ÷ 2, 0 ÷ 0 with recovery, repeated equals, and 56 + 4 = 60 after producing 56. All pass against the existing implementation. These are additional checks of the current code, not evidence that an earlier arithmetic defect was reproduced. If a proposed function failed them, I would keep the failing tests, add completeness/denominator guards and correct phase transitions, then rerun both the focused cases and the full suite to avoid breaking valid arithmetic.

I revised an actual generated UI suggestion that used an unsupported semanticLabel argument on Switch by using a Semantics wrapper. I also added an explicit semantic tap action to the reusable button after reviewing the accessibility behavior. These revisions show that syntactically plausible code and plausible advice still need analyzer and behavioral checks. I also rejected Gemini's graduate-only classification for fractional outputs from integer inputs and revised its expected syntax error for repeated operators: this app replaces the pending operator, and its exact 8, +, ×, 3, = test produces 24. The appendix gives the full comparisons.

The main lesson is to test sequences and recovery state, not just isolated arithmetic. Evidence: test/calculator_state_test.dart, test/widget_test.dart, docs/analysis-results.txt, and docs/test-results.txt.

## 06 — AI advice, trade-offs, and maintainability

Question sent unchanged to both agents: For my calculator implementation, what trade-off should I make between reusing widgets, adding dependencies, and keeping the project small?

ChatGPT recommends a reusable calculator-button widget, a separate testable arithmetic class, and local StatefulWidget/setState for the current scope. It would add a package when a specific requirement, such as exact decimal arithmetic or durable history, justifies the maintenance cost. Gemini recommends a flexible base button, modular files, and a near-zero dependency tree; it suggests reserving dependencies strictly for complex parsing. Their full responses and the two Test Drive comparisons are in the appendix.

The shared advice about moderate widget reuse is useful: CalculatorButton centralizes appearance and semantics, while CalculatorState isolates arithmetic. Passing widget tests and state tests verify behavior without an added parser or state-management package. A general component library would add indirection without solving a current requirement.

I would revise Gemini's dependency advice. Packages are not useful only for parsing; a vetted exact-decimal or storage library could be justified by a future requirement. Its claim that dependencies increase startup overhead is not established for this app without measuring retained/executed code. The current pubspec still contains the generated cupertino_icons dependency plus Flutter and development tooling, so calling the app dependency-free would be inaccurate. No performance improvement from removing a package has been measured.

The first refactor for the next developer would centralize typed button/action definitions so button labels, accessibility descriptions, and operator detection cannot drift across repeated string lists. I would retain the regression suite while doing that, remove the unused icon dependency, and introduce a phase enum if the interaction model grows. This preserves the small project structure while making future changes easier to reason about.

Verified evidence: 35 passing tests, including both agents' result-reuse sequences; lib/main.dart; lib/calculator_state.dart; pubspec.yaml; and docs/agent-test-drive.md.

## Challenges and verification

The existing Flutter download contained Windows executables. A macOS ARM64 Flutter 3.35.7 SDK was installed separately. The available Java 25 runtime was incompatible with this project's Gradle version, so Flutter was configured to use Java 21. The initial accessibility test exposed a test-helper lifecycle problem; disposing the semantics handle before the test ended corrected the test setup.

Static analysis and 35 automated tests passed. The tests include arithmetic state transitions, UI interaction, two theme directions, error recovery, small-screen layout at 200% text scaling, semantic labels, and Android tap targets. The release APK was built, installed, and exercised on the Pixel_4a Android emulator. Eight device checks passed: all four operations, theme state preservation, division-by-zero feedback, recovery by digit entry, and incomplete-input recovery with AC. The device log and screenshots are included in the appendix and in docs/device-verification.md.

## Assistance and review

ChatGPT/Codex assisted with implementation, environment setup, tests, and document drafting. Google Gemini supplied the second set of responses for the required comparison through its public web interface. Source code and executed tests were used to check the advice. The student should review the submitted work and follow any additional course disclosure requirements.

## References

Flutter manual installation: https://docs.flutter.dev/install/manual
Flutter Android release build guidance: https://docs.flutter.dev/deployment/android
Flutter test APIs available in the installed SDK: packages/flutter_test/lib/src/accessibility.dart and widget_tester.dart.
Assignment requirements: the assignment text supplied for this project.

## Required completion before upload

Add the student ID. The repository URL is provided in github_link.txt. Review the document, then upload github_link.txt, HetJani_CalculatorApp.apk, and HetJani_Implementation.docx to the designated LMS and verify receipt.
