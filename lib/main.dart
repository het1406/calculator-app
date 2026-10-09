import 'package:flutter/material.dart';
import 'calculator_state.dart';

void main() => runApp(const CalculatorApp());

class CalculatorApp extends StatefulWidget {
  const CalculatorApp({super.key});
  @override
  State<CalculatorApp> createState() => _CalculatorAppState();
}

class _CalculatorAppState extends State<CalculatorApp> {
  bool _dark = false;

  ThemeData _theme(Brightness brightness) => ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF276457),
      brightness: brightness,
    ),
    splashFactory: NoSplash.splashFactory,
  );

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Calculator',
    debugShowCheckedModeBanner: false,
    theme: _theme(Brightness.light),
    darkTheme: _theme(Brightness.dark),
    themeMode: _dark ? ThemeMode.dark : ThemeMode.light,
    themeAnimationDuration: const Duration(milliseconds: 250),
    home: CalculatorScreen(
      dark: _dark,
      onThemeChanged: (value) => setState(() => _dark = value),
    ),
  );
}

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({
    super.key,
    required this.dark,
    required this.onThemeChanged,
  });
  final bool dark;
  final ValueChanged<bool> onThemeChanged;
  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  final _calculator = CalculatorState();

  void _press(String label) => setState(() {
    if (label == 'AC') {
      _calculator.clear();
    } else if (label == '=') {
      _calculator.equals();
    } else if (['+', '−', '×', '÷'].contains(label)) {
      _calculator.selectOperator(label);
    } else {
      _calculator.digit(label);
    }
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Calculator',
                                style: Theme.of(context).textTheme.headlineSmall
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                            ),
                            Semantics(
                              label: 'Dark theme',
                              child: Switch(
                                value: widget.dark,
                                onChanged: widget.onThemeChanged,
                                thumbIcon: WidgetStatePropertyAll(
                                  Icon(
                                    widget.dark
                                        ? Icons.dark_mode
                                        : Icons.light_mode,
                                    size: 18,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'A little clarity in every calculation.',
                          style: TextStyle(color: colors.onSurfaceVariant),
                        ),
                        const SizedBox(height: 24),
                        Container(
                          constraints: const BoxConstraints(minHeight: 150),
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: colors.surfaceContainer,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                _calculator.expression,
                                key: const Key('expression'),
                                style: TextStyle(
                                  color: colors.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Semantics(
                                liveRegion: true,
                                label: _calculator.error == null
                                    ? 'Display ${_calculator.display}'
                                    : 'Error: ${_calculator.error}',
                                child: ExcludeSemantics(
                                  child: _calculator.error == null
                                      ? SizedBox(
                                          width: double.infinity,
                                          child: FittedBox(
                                            fit: BoxFit.scaleDown,
                                            alignment: Alignment.centerRight,
                                            child: Text(
                                              _calculator.display,
                                              key: const Key('display'),
                                              style: TextStyle(
                                                fontSize: 52,
                                                fontWeight: FontWeight.w500,
                                                color: colors.onSurface,
                                              ),
                                            ),
                                          ),
                                        )
                                      : Text(
                                          _calculator.display,
                                          key: const Key('display'),
                                          textAlign: TextAlign.right,
                                          style: TextStyle(
                                            fontSize: 22,
                                            color: colors.error,
                                          ),
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _calculator.error != null
                              ? 'Tap a number to start again, or AC to reset.'
                              : 'Two numbers. One operation. A clear result.',
                          style: TextStyle(
                            color: colors.onSurfaceVariant,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 20),
                        _row(['AC', '÷']),
                        _row(['7', '8', '9', '×']),
                        _row(['4', '5', '6', '−']),
                        _row(['1', '2', '3', '+']),
                        _row(['0', '=']),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _row(List<String> labels) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      children: [
        for (var i = 0; i < labels.length; i++) ...[
          if (i > 0) const SizedBox(width: 10),
          Expanded(
            child: CalculatorButton(
              label: labels[i],
              selected: _calculator.pendingOperator == labels[i],
              onPressed: () => _press(labels[i]),
            ),
          ),
        ],
      ],
    ),
  );
}

class CalculatorButton extends StatelessWidget {
  const CalculatorButton({
    super.key,
    required this.label,
    required this.selected,
    required this.onPressed,
  });
  final String label;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final operator = ['+', '−', '×', '÷'].contains(label);
    final description =
        {
          'AC': 'All clear',
          '÷': 'Divide',
          '×': 'Multiply',
          '−': 'Subtract',
          '+': 'Add',
          '=': 'Equals',
        }[label] ??
        label;
    return Semantics(
      label: description,
      onTap: onPressed,
      button: true,
      selected: operator ? selected : null,
      excludeSemantics: true,
      child: SizedBox(
        height: 68,
        child: FilledButton(
          key: ValueKey('button_$label'),
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            backgroundColor: label == '=' || selected
                ? colors.primary
                : operator || label == 'AC'
                ? colors.secondaryContainer
                : colors.surfaceContainerHighest,
            foregroundColor: label == '=' || selected
                ? colors.onPrimary
                : operator || label == 'AC'
                ? colors.onSecondaryContainer
                : colors.onSurface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ),
    );
  }
}
