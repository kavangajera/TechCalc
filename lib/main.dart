import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:math_expressions/math_expressions.dart';

void main() {
  runApp(TechCalcApp());
}

class TechCalcApp extends StatelessWidget {
  const TechCalcApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TechCalc',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: CalculatorHome(),
    );
  }
}

class CalculatorHome extends StatefulWidget {
  const CalculatorHome({super.key});

  @override
  _CalculatorHomeState createState() => _CalculatorHomeState();
}

class _CalculatorHomeState extends State<CalculatorHome> {
  String expression = '';
  String result = '';
  String derivativeResult = '';
  String integralResult = '';
  bool _isSimple = true; // Default to simple mode
  bool _isDifferentiation = false; // Differentiation mode flag
  bool _isIntegration = false; // Integration mode flag
  String _currentMode = 'Simple'; // Display current mode
  final TextEditingController _diffExpressionController = TextEditingController();
  final TextEditingController _diffVariableController = TextEditingController();
  final TextEditingController _intExpressionController = TextEditingController();
  final TextEditingController _intVariableController = TextEditingController();

  void _onButtonPressed(String value) {
    setState(() {
      if (_isSimple) {
        if (value == 'C') {
          expression = '';
          result = '';
        } else if (value == '=') {
          try {
            Parser parser = Parser();
            Expression exp = parser.parse(expression);
            ContextModel cm = ContextModel();
            result = '${exp.evaluate(EvaluationType.REAL, cm)}';
          } catch (e) {
            result = 'Error';
          }
        } else if (value == '⌫') {
          if (expression.isNotEmpty) {
            expression = expression.substring(0, expression.length - 1);
          }
        } else {
          expression += value;
        }
      } else if (_isDifferentiation || _isIntegration) {
        if (value == 'Solve') {
          _computeResult();
        }
      }
    });
  }

  Future<void> _computeResult() async {
    final expression = _isDifferentiation ? _diffExpressionController.text : _intExpressionController.text;
    final variable = _isDifferentiation ? _diffVariableController.text : _intVariableController.text;

    if (expression.isEmpty || variable.isEmpty) {
      setState(() {
        if (_isDifferentiation) {
          derivativeResult = 'Please enter both expression and variable.';
        } else {
          integralResult = 'Please enter both expression and variable.';
        }
      });
      return;
    }

    final url = Uri.parse(_isDifferentiation
        ? 'http://10.0.2.2:5000/differentiate'
        : 'http://10.0.2.2:5000/integrate'); // Use correct URL

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'expression': expression,
          'variable': variable,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          if (_isDifferentiation) {
            derivativeResult = data['derivative'];
          } else {
            integralResult = data['integral'];
          }
        });
      } else {
        setState(() {
          if (_isDifferentiation) {
            derivativeResult = 'Error: ${response.statusCode} ${response.reasonPhrase}';
          } else {
            integralResult = 'Error: ${response.statusCode} ${response.reasonPhrase}';
          }
        });
      }
    } catch (e) {
      setState(() {
        if (_isDifferentiation) {
          derivativeResult = 'Error: $e';
        } else {
          integralResult = 'Error: $e';
        }
      });
    }
  }

  void _toggleMode(String mode) {
    setState(() {
      if (mode == 'Simple') {
        _isSimple = true;
        _isDifferentiation = false;
        _isIntegration = false;
        _currentMode = 'Simple';
        expression = '';
        result = '';
        derivativeResult = '';
        integralResult = '';
      } else if (mode == 'Differentiate') {
        _isSimple = false;
        _isDifferentiation = true;
        _isIntegration = false;
        _currentMode = 'Differentiation';
        expression = '';
        result = '';
        derivativeResult = '';
        integralResult = '';
      } else if (mode == 'Integrate') {
        _isSimple = false;
        _isDifferentiation = false;
        _isIntegration = true;
        _currentMode = 'Integration';
        expression = '';
        result = '';
        derivativeResult = '';
        integralResult = '';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TechCalc'),
      ),
      body: Column(
        children: <Widget>[
          // Display current mode (Simple, Integration, Differentiation)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Mode: $_currentMode',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
          // Display for expression
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.all(16),
              alignment: Alignment.bottomRight,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Text(
                  _isSimple ? expression : (_isDifferentiation ? _diffExpressionController.text : _intExpressionController.text),
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
          // Display for result
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.all(16),
              alignment: Alignment.bottomRight,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Text(
                  _isSimple ? result : (_isDifferentiation ? derivativeResult : integralResult),
                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
          if (!_isSimple) ...[
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextField(
                    controller: _isDifferentiation ? _diffVariableController : _intVariableController,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Enter variable (e.g., x)',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _isDifferentiation ? _diffExpressionController : _intExpressionController,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Enter expression (e.g., x**2)',
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => _onButtonPressed('Solve'),
                    child: const Text('Solve'),
                  ),
                ],
              ),
            ),
          ],
          if (_isSimple) ...[
            const Divider(),
            Expanded(
              flex: 4,
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 4,
                  mainAxisSpacing: 4,
                ),
                itemCount: 20,
                itemBuilder: (context, index) {
                  List<String> buttons = [
                    'C', '⌫', '%', '/',
                    '7', '8', '9', '*',
                    '4', '5', '6', '-',
                    '1', '2', '3', '+',
                    '00', '0', '.', '='
                  ];
                  return _buildButton(buttons[index]);
                },
              ),
            ),
          ],
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            if (!_isDifferentiation)
              ElevatedButton(
                onPressed: () => _toggleMode('Differentiate'),
                child: const Text('Differentiate'),
              ),
            if (!_isIntegration)
              ElevatedButton(
                onPressed: () => _toggleMode('Integrate'),
                child: const Text('Integrate'),
              ),
            if (!_isSimple)
              ElevatedButton(
                onPressed: () => _toggleMode('Simple'),
                child: const Text('Simple'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildButton(String buttonText) {
    return Container(
      margin: const EdgeInsets.all(4),
      child: ElevatedButton(
        onPressed: () => _onButtonPressed(buttonText),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.all(12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(
          buttonText,
          style: const TextStyle(fontSize: 16, color: Colors.black),
        ),
      ),
    );
  }
}
