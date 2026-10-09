# Calculator

A Flutter calculator for Assignment 01. The current implementation follows the
CSC 4360 undergraduate pathway, pending confirmation of course enrollment.

## Selected features

1. **Theme toggle** — light and dark color schemes with a 250 ms transition.
2. **All clear** — resets input, stored operand, operator, result phase, and error.
3. **Error handling** — rejects division by zero and incomplete calculations;
   entering a digit starts a new calculation, and AC resets everything.

## Use

Tap the first number, an operator, the second number, and equals. Selecting a
replacement operator before the second number changes the pending operator.
After a result, a digit starts a new calculation; an operator reuses the result.
This is a two-operand calculator: finish one calculation with equals before
starting another. There is no precedence parser or decimal-input button.
Division can produce fractional results. Entry is limited to 12 digits and
results use 12 significant digits; this is ordinary double arithmetic, not
arbitrary-precision or financial arithmetic. Repeated equals without a new
operation reports incomplete input.

## Run and verify

Tested toolchain: Flutter 3.35.7, Dart 3.9.2, Java 21.

```sh
flutter pub get
flutter analyze
flutter test
flutter run
flutter build apk --release
```

Android SDK and a compatible JDK must be configured. The APK is written to
`build/app/outputs/flutter-apk/app-release.apk`. The classroom release uses the
Flutter project's debug signing configuration and is suitable for sideloading;
store distribution would require a private release key.

## Code and evidence

- `lib/main.dart`: StatefulWidget, setState, reusable button, responsive scrolling,
  semantic button labels, live result announcement, and themes.
- `lib/calculator_state.dart`: input and arithmetic state transitions.
- `test/calculator_state_test.dart`: arithmetic and boundary/error sequences.
- `test/widget_test.dart`: UI interaction, theme state preservation, small portrait
  and landscape layouts at 200% text scale, semantic labels, and tap targets.
- `docs/test-results.txt`: latest automated test output.
- `docs/build-results.txt`: release build output.
- `docs/agent-test-drive.md`: required test-drive prompts and available responses.

## Submission

The assignment calls for `github_link.txt`, `YourName_CalculatorApp.apk`, and
`YourName_Implementation.docx`. Local submission artifacts are kept outside Git
in `submission/`, so student IDs are not published to the repository.
The rationale needs the student's confirmed name/ID, course level, complete
reflection questions, and the actual second-agent responses before submission.
