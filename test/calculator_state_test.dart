import 'package:flutter_test/flutter_test.dart';
import 'package:calculator_app/calculator_state.dart';

void main() {
  late CalculatorState calculator;
  setUp(() => calculator = CalculatorState());
  void enter(String number) {
    for (final digit in number.split('')) {
      calculator.digit(digit);
    }
  }

  void calculate(String a, String operator, String b) {
    enter(a);
    calculator.selectOperator(operator);
    enter(b);
    calculator.equals();
  }

  for (final example in [
    ['12', '+', '7', '19'],
    ['3', '−', '8', '-5'],
    ['8', '×', '7', '56'],
    ['9', '÷', '2', '4.5'],
    ['0', '×', '987', '0'],
    ['1', '÷', '3', '0.333333333333'],
  ]) {
    test('${example[0]} ${example[1]} ${example[2]} = ${example[3]}', () {
      calculate(example[0], example[1], example[2]);
      expect(calculator.display, example[3]);
      expect(calculator.error, isNull);
    });
  }
  test('all clear removes a pending operation and every state flag', () {
    enter('42');
    calculator.selectOperator('+');
    calculator.clear();
    expect(calculator.input, '0');
    expect(calculator.firstOperand, isNull);
    expect(calculator.pendingOperator, isNull);
    expect(calculator.awaitingOperand, isFalse);
    expect(calculator.showingResult, isFalse);
    expect(calculator.error, isNull);
    calculate('2', '×', '3');
    expect(calculator.display, '6');
  });
  test('division by zero recovers with a digit', () {
    calculate('7', '÷', '0');
    expect(calculator.error, 'Cannot divide by zero');
    enter('3');
    expect(calculator.display, '3');
    expect(calculator.pendingOperator, isNull);
    calculator.selectOperator('+');
    enter('2');
    calculator.equals();
    expect(calculator.display, '5');
  });
  test('all clear recovers from an error', () {
    calculator.equals();
    calculator.clear();
    expect(calculator.display, '0');
    expect(calculator.error, isNull);
  });
  test('equals on empty input reports incomplete input', () {
    calculator.equals();
    expect(calculator.error, isNotNull);
  });
  test('equals with only one operand reports incomplete input', () {
    enter('8');
    calculator.equals();
    expect(calculator.error, isNotNull);
  });
  test('missing second operand is not silently duplicated', () {
    enter('8');
    calculator.selectOperator('+');
    calculator.equals();
    expect(calculator.error, isNotNull);
  });
  test('operator can be replaced before second operand', () {
    enter('8');
    calculator.selectOperator('+');
    calculator.selectOperator('×');
    enter('7');
    calculator.equals();
    expect(calculator.display, '56');
  });
  test('extra operation after second operand reports recovery instruction', () {
    enter('8');
    calculator.selectOperator('+');
    enter('7');
    calculator.selectOperator('×');
    expect(calculator.error, 'Press = before another operation');
  });
  test('digit after result starts fresh', () {
    calculate('8', '×', '7');
    enter('2');
    expect(calculator.display, '2');
    expect(calculator.showingResult, isFalse);
  });
  test('result can be first operand of next calculation', () {
    calculate('3', '−', '8');
    calculator.selectOperator('×');
    enter('2');
    calculator.equals();
    expect(calculator.display, '-10');
  });
  test('leading zeroes do not accumulate', () {
    enter('00042');
    expect(calculator.display, '42');
  });
  test('input is limited to twelve digits', () {
    enter('123456789012345');
    expect(calculator.display, '123456789012');
  });
  test('unknown buttons cannot corrupt state', () {
    calculator.digit('x');
    calculator.selectOperator('?');
    expect(calculator.display, '0');
    expect(calculator.pendingOperator, isNull);
  });
}
