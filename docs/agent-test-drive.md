# Agent Test Drive — working record

Date: October 8, 2026 (America/New_York).
Agent 1: ChatGPT, in this assignment working session.
Agent 2: Pending actual Gemini or Microsoft Copilot responses from the student.
No second-agent response or comparison has been fabricated.

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

## Second agent and comparison — pending

Record the actual agent name, date, both unchanged prompts, and both responses.
Compare agreements, differences, accepted/rejected advice, and at least one claim
against source code and an executed test. This required section is incomplete
until a real second agent has been consulted.
