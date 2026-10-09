/// Two-operand calculator with explicit input, operator, and result phases.
/// Arithmetic is performed only after a second operand and equals are entered.
class CalculatorState {
  String input = '0';
  double? firstOperand;
  String? pendingOperator;
  bool awaitingOperand = false;
  bool showingResult = false;
  String? error;

  String get display => error ?? input;
  String get expression => firstOperand == null
      ? (showingResult ? 'Result' : 'Enter a number')
      : '${format(firstOperand!)} $pendingOperator';

  void clear() {
    input = '0';
    firstOperand = null;
    pendingOperator = null;
    awaitingOperand = false;
    showingResult = false;
    error = null;
  }

  void digit(String digit) {
    if (!RegExp(r'^\d$').hasMatch(digit)) return;
    if (error != null || showingResult) clear();
    if (awaitingOperand) {
      input = digit;
      awaitingOperand = false;
    } else if (input == '0') {
      input = digit;
    } else if (input.length < 12) {
      input += digit;
    }
  }

  void selectOperator(String operator) {
    if (!['+', '−', '×', '÷'].contains(operator) || error != null) return;
    if (pendingOperator != null && !awaitingOperand) {
      error = 'Press = before another operation';
      return;
    }
    firstOperand = double.parse(input);
    pendingOperator = operator;
    awaitingOperand = true;
    showingResult = false;
  }

  void equals() {
    if (error != null) return;
    if (pendingOperator == null || firstOperand == null || awaitingOperand) {
      error = 'Enter two numbers and an operator';
      return;
    }
    final second = double.parse(input);
    if (pendingOperator == '÷' && second == 0) {
      error = 'Cannot divide by zero';
      return;
    }
    final double result;
    switch (pendingOperator) {
      case '+':
        result = firstOperand! + second;
        break;
      case '−':
        result = firstOperand! - second;
        break;
      case '×':
        result = firstOperand! * second;
        break;
      case '÷':
        result = firstOperand! / second;
        break;
      default:
        return;
    }
    if (!result.isFinite) {
      error = 'Result is too large';
      return;
    }
    input = format(result);
    firstOperand = null;
    pendingOperator = null;
    awaitingOperand = false;
    showingResult = true;
  }

  static String format(double value) {
    if (value == 0) return '0';
    // Twelve significant digits avoid exposing binary floating-point noise.
    final rounded = double.parse(value.toStringAsPrecision(12));
    if (rounded.abs() < 1e12 && rounded == rounded.truncateToDouble()) {
      return rounded.toInt().toString();
    }
    return rounded.toString();
  }
}
