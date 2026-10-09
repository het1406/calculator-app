# Agent Test Drive — working record

Date: October 8, 2026 (America/New_York).
Agent 1: ChatGPT/Codex, main assignment working session.
Agent 2: Google Gemini, public web interface displaying Flash-Lite, signed out.
Both unchanged Test Drive prompts and the reflection 06 question were submitted to Gemini on October 8, 2026. Raw replies are saved in docs/gemini-responses.json; page screenshots are in docs/screenshots/gemini-1.png through gemini-3.png.

## Prompt 01 — unchanged

For a two-operand calculator with +, −, ×, and ÷, propose six test cases with exact inputs and expected outcomes. Include normal, boundary, and invalid sequences. Mark which cases require optional error handling or graduate decimal support. Do not write code.

### ChatGPT response

| Case | Exact taps | Expected outcome | Requirement |
| --- | --- | --- | --- |
| Normal addition | AC, 1, 2, +, 7, = | 19 | Core |
| Negative subtraction result | AC, 3, −, 8, = | −5 | Core |
| Zero multiplication | AC, 0, ×, 9, 8, 7, = | 0 | Core boundary |
| Fractional division result | AC, 9, ÷, 2, = | 4.5 | Core division; does not require a decimal-input button |
| Division by zero and recovery | AC, 7, ÷, 0, =, then 3, +, 2, = | Recoverable division-by-zero message, then 5 under the documented digit-to-restart policy | Optional undergraduate error handling / graduate advanced error handling |
| Missing second operand | AC, 8, +, = | Recoverable incomplete-input message; do not silently reuse 8 | Optional undergraduate error handling / graduate advanced error handling |

These six cases do not require graduate decimal entry. A graduate test suite must
add decimal operands across all four operations and reject a second decimal point.
Recovery wording and repeated-equals behavior are application decisions and must
be documented before asserting exact UI text.

## Prompt 03 — unchanged

A calculator stores displayText, firstOperand, pendingOperator, resultText, and isError. Which values need to be stored, which can be derived, and what bug could happen if resultText and displayText drift apart? Suggest one test that catches it.

### ChatGPT response

Store the active input as text so input editing can preserve partially typed
numbers. Store a first operand and pending operator while a calculation is in
progress. Keep an explicit phase or small set of flags to distinguish entering a
second operand from displaying a completed result. Store an error message when
recovery is needed; whether the app is in an error state can be derived from that
message. Derive the displayed text from the current input or error message, and
avoid an independent resultText copy when the completed result can become the
active input.

If resultText is updated but displayText is not, the screen can show an old number
while the next operation uses a new result. If the screen is updated but the
operand source is stale, the next operation can compute from a number the user
cannot see. A regression test is: AC, 8, ×, 7, = must display 56; then +, 4, = must
display 60. Also verify that entering 2 directly after a result starts at 2 rather
than appending to 56.

## Verification and decisions

- Accept: keep one result/input source of truth. `CalculatorState.display` derives
  from `error ?? input`; there is no second `resultText` field.
- Accept: do not duplicate a missing operand. The test "missing second operand is
  not silently duplicated" exercises 8, +, =.
- Accept with scope clarification: fractional output such as 9 ÷ 2 = 4.5 belongs
  to normal arithmetic; graduate decimal support requires decimal *input* too.
- Adapt: this small app uses `awaitingOperand` and `showingResult` instead of a
  phase enum. An enum would make illegal combinations harder to represent but
  adds restructuring that is unnecessary for this limited two-operand scope.
- Evidence: `test/calculator_state_test.dart` and `test/widget_test.dart` verify
  arithmetic, result reuse, fresh input, error recovery, and theme preservation.

## Reflection 06 — same question to both agents

### Prompt — unchanged

For my calculator implementation, what trade-off should I make between reusing widgets, adding dependencies, and keeping the project small?

### ChatGPT response

Reuse Flutter's built-in controls and make one reusable calculator-button widget for common spacing, labels, colors, and tap behavior. Keep arithmetic in a small separate class so it can be tested without the interface. Reuse should remove meaningful repetition rather than introduce a general component system for one screen.

Use local StatefulWidget/setState for this scope. Add a dependency only when a concrete requirement is harder to implement and maintain correctly with the SDK, such as exact decimal arithmetic or durable history storage. An external expression parser is unnecessary for a calculator limited to two operands and one operator. Avoiding all dependencies is not a universal rule: a well-maintained package can be worthwhile when its correctness benefits outweigh its API, size, and maintenance costs.

For the next developer, I would first centralize button/action definitions and replace related phase booleans with an enum if new states are added. Preserve the arithmetic and widget regression tests through that refactor. Judge package or performance claims using the actual dependency list, tests, and measurements rather than assuming that fewer files or packages automatically makes an app faster.

## Gemini response 1 — Bug Hunt

### Prompt — unchanged

For a two-operand calculator with +, −, ×, and ÷, propose six test cases with exact inputs and expected outcomes. Include normal, boundary, and invalid sequences. Mark which cases require optional error handling or graduate decimal support. Do not write code.

### Captured response

Gemini said

Here is a comprehensive set of six test cases designed for a two-operand calculator covering normal, boundary, and invalid operational scenarios.

Calculator Test Cases
| Case ID & Category | Exact Inputs | Expected Outcome | Special Requirements |
| --- | --- | --- | --- |
| 1. Normal | 12 + 8 | 20 | Standard integer support |
| 2. Normal | 7 ÷ 4 | 1.75 | Graduate decimal support |
| 3. Boundary | 1 ÷ 3 | 0.3333 (or rounded per precision rules) | Graduate decimal support & rounding logic |
| 4. Boundary | 0 × 45 | 0 | Standard zero-handling |
| 5. Invalid | 10 ÷ 0 | Error: "Cannot divide by zero" / Undefined | Optional error handling |
| 6. Invalid | 8 + × 3 | Error: "Syntax Error" / Invalid sequence | Optional error handling |
Test Case Breakdown

Normal Cases (1 & 2): Validate standard arithmetic functionality under typical conditions. Case 2 specifically tests whether the calculator can seamlessly transition from whole-number inputs to fractional decimal outputs.

Boundary Cases (3 & 4): Test edge conditions and constraints. Case 3 pushes the decimal precision limits with a recurring fraction, requiring a policy on decimal places or rounding. Case 4 tests zero as a primary operand, ensuring multiplication collapses correctly.

Invalid Cases (5 & 6): Ensure robustness against mathematical violations (division by zero) and syntactic mistakes (malformed operator sequences), preventing app crashes through graceful error handling.

Would you like to explore specific requirements for handling precision limits or overflow errors for large numbers?

## Gemini response 2 — State Design

### Prompt — unchanged

A calculator stores displayText, firstOperand, pendingOperator, resultText, and isError. Which values need to be stored, which can be derived, and what bug could happen if resultText and displayText drift apart? Suggest one test that catches it.

### Captured response

Gemini said

Managing state in a calculator app requires a clear separation between raw data (what the app needs to remember) and UI representation (what the user sees).

Here is the breakdown of what needs to be stored, what can be derived, the risks of state drift, and a test to catch it.

1. Which Values Need to Be Stored (Core State)?

To function correctly, a calculator only needs to store the underlying operational data, not the UI strings themselves:

firstOperand: The numeric value entered before an operator was selected.

pendingOperator: The active operator waiting for a second operand (e.g., +, -, *, /).

currentInput (often replacing or backing displayText): The string representing the numbers currently being typed by the user.

isError: A boolean flag indicating whether an invalid operation (like division by zero) has occurred.

2. Which Values Can Be Derived?

displayText and resultText are fully derived values. They should not be stored as independent state variables.

Instead, what appears on the screen (displayText) should be computed on the fly using a render function or computed property based on the core state:

If isError is true, show "Error".

Else if an operator was just pressed, show firstOperand (or the active buffer).

Else show currentInput.

Storing both displayText and resultText introduces redundant state, which inevitably leads to synchronization issues.

3. What Bug Happens When They Drift Apart?

If displayText and resultText drift out of sync, the user interface lies to the user about the app's internal memory.

The Ghost Calculation Bug: The screen shows one number (displayText = "5"), but the internal memory or resultText holds a stale value ("8"). If the user presses an operator or equals (=) next, the calculator performs the math using the hidden resultText instead of what the user actually sees on the screen, resulting in bizarre, unpredictable calculations.

Visual Desync: The user hits a button, the internal state updates, but the UI fails to re-render, leaving the user typing into a frozen display while the calculator processes background actions blindly.

4. A Test to Catch the Bug

An End-to-End (E2E) or Integration Test can verify that the screen content always matches the internal calculation state.

Test Case Name: Should synchronize display text with calculation results after equals

Test Steps:

Press 5, +, 3, =.

Assert that displayText equals "8".

Press +, 2, =.

Assert that displayText equals "10" (proving it used the visible result 8 as the new base, rather than a drifted resultText or stale buffer).

Why it catches the bug: If displayText and resultText have drifted, step 4 will fail because the calculator will pull the desynced value instead of the active screen value, yielding an incorrect total (like 7 + 2 = 9 or an error).

## Gemini response 3 — Trade-offs

### Prompt — unchanged

For my calculator implementation, what trade-off should I make between reusing widgets, adding dependencies, and keeping the project small?

### Captured response

Gemini said
1. Reusing Widgets: Maintainability vs. Over-Engineering

The Trade-Off: Reusing UI components standardizes your design and cuts down code duplication, but premature abstraction can create rigid structures that are hard to adapt for unique calculator buttons (e.g., scientific functions vs. basic digits).

Best Practice: Create a single flexible base button component, but avoid excessive nesting or complex wrapper components early in development.

2. Adding Dependencies: Velocity vs. Bloat

The Trade-Off: Third-party libraries speed up feature delivery, but they increase binary size, add startup overhead, and expose your project to maintenance or security risks from unmaintained packages.

Best Practice: Write your own evaluation and state logic for standard calculations; reserve dependencies strictly for complex mathematical parsing if it saves significant development time.

3. Keeping the Project Small: Simplicity vs. Scalability

The Trade-Off: A minimalist project is fast, easy to debug, and simple to understand, but an overly tight focus can make it painful to add features like calculation history, unit conversion, or themes later.

Best Practice: Keep your core dependency tree near zero, but use a clean modular file structure so you can scale features without rewriting the entire architecture.

Summary Recommendation: For a calculator app, lean heavily toward zero dependencies and moderate widget reuse. The core arithmetic logic is self-contained enough that external packages usually introduce more overhead than value.

What programming language or UI framework are you using to build your calculator?

## Comparison and verified decisions

### Bug Hunt

Both agents propose ordinary arithmetic, zero boundaries, and divide-by-zero cases. ChatGPT includes a missing second operand; Gemini includes consecutive operators. Gemini provides arithmetic expressions rather than complete button sequences and leaves the rounding result conditional. Before testing, each expression was interpreted as AC, its listed keys, then equals; the app's documented 12-significant-digit rounding supplied the exact recurring-fraction expectation.

Accepted and verified: Gemini's 12 + 8 = 20, 7 ÷ 4 = 1.75, 0 × 45 = 0, and 10 ÷ 0 error. The existing 1 ÷ 3 test verifies 0.333333333333. All are executed in test/calculator_state_test.dart.

Rejected classification: Gemini marks 7 ÷ 4 and 1 ÷ 3 as requiring graduate decimal support. Both use integer input; the undergraduate core division implementation can show fractional output without implementing graduate decimal entry. The 7 ÷ 4 = 1.75 and 1 ÷ 3 tests verify this implementation behavior. The assignment text separately specifies decimal input as the graduate requirement.

Revised expectation: Gemini expects a syntax error for 8, +, ×, 3. This app intentionally replaces an operator before the second operand, so the expected result after equals is 24. The test “Gemini repeated-operator case follows documented replacement policy” passes. This does not prove Gemini's policy is universally wrong; it shows why test expectations must match the chosen interaction contract. An operator after a fully entered second operand remains invalid in this app.

### State Design

Both agents recommend one authoritative input/result value and warn that separate display and result strings can become inconsistent. ChatGPT's proposed sequence produces 56 then reuses it to reach 60. Gemini's produces 8 then reuses it to reach 10. Both exact sequences now have passing regression tests. Those tests would expose a stale operand that a single final-display assertion could miss.

ChatGPT derives error state from a nullable error message. Gemini proposes storing isError. This implementation uses the message itself, retaining useful recovery wording while avoiding a separate boolean that could disagree with it. Gemini's statement that redundant state “inevitably” produces synchronization issues is too absolute: careful code can synchronize copies, but unnecessary copies create more opportunities for defects. Its state-drift example also assumes this class of bug occurs; no single test can detect every possible synchronization defect.

### Trade-offs and maintainability

Both agents support a reusable calculator button, a separate arithmetic model, and limited dependencies. This matches CalculatorButton and CalculatorState and is supported by the passing state/widget tests. ChatGPT allows a dependency when a specific correctness or persistence requirement justifies it. Gemini recommends near-zero dependencies and reserving packages strictly for complex parsing. That restriction is too narrow for future exact decimal arithmetic or persistent history.

Gemini's blanket claim that third-party dependencies add startup overhead was not accepted as a measured fact about this app. Runtime effect depends on which code is retained and executed, and no before/after package benchmark was performed. The package manifest contains Flutter, the generated cupertino_icons runtime dependency, and development test/lint dependencies; the project is not literally dependency-free. No custom parser or state-management package is used.

The first maintainability refactor would centralize button definitions and actions so labels, semantics, and operator detection do not depend on repeated string lists. The existing tests would protect behavior. I would then remove the unused cupertino_icons dependency and replace phase flags with an enum when adding more input states. These are proposed improvements, not completed changes or claimed speedups.

Evidence: docs/test-results.txt, test/calculator_state_test.dart, test/widget_test.dart, lib/main.dart, lib/calculator_state.dart, and pubspec.yaml. The full suite has 35 passing tests after adding the specific agent-verification cases.
