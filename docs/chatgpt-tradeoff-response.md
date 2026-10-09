# ChatGPT — reflection 06 response

Date: October 8, 2026. Agent: ChatGPT/Codex, main working session.

## Prompt — unchanged

For my calculator implementation, what trade-off should I make between reusing widgets, adding dependencies, and keeping the project small?

## Response

Reuse Flutter's built-in controls and make one reusable calculator-button widget for common spacing, labels, colors, and tap behavior. Keep arithmetic in a small separate class so it can be tested without the interface. Reuse should remove meaningful repetition rather than introduce a general component system for one screen.

Use local StatefulWidget/setState for this scope. Add a dependency only when a concrete requirement is harder to implement and maintain correctly with the SDK, such as exact decimal arithmetic or durable history storage. An external expression parser is unnecessary for a calculator limited to two operands and one operator. Avoiding all dependencies is not a universal rule: a well-maintained package can be worthwhile when its correctness benefits outweigh its API, size, and maintenance costs.

For the next developer, I would first centralize button/action definitions and replace related phase booleans with an enum if new states are added. Preserve the arithmetic and widget regression tests through that refactor. Judge package or performance claims using the actual dependency list, tests, and measurements rather than assuming that fewer files or packages automatically makes an app faster.
