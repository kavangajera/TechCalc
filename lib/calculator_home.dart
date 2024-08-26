import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:math_expressions/math_expressions.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'widgets/calculator_buttons.dart'; // Import your custom widget file

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
  bool _isSimple = true;
  bool _isDifferentiation = false;
  bool _isIntegration = false;
  bool _isLoading = false;
  String _currentMode = 'Simple';
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

    setState(() {
      _isLoading = true; // Start loading animation
    });

    final url = Uri.parse(_isDifferentiation
        ? 'http://10.0.2.2:5000/differentiate'
        : 'http://10.0.2.2:5000/integrate');

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
    } finally {
      setState(() {
        _isLoading = false; // Stop loading animation
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
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Mode: $_currentMode',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.teal),
            ),
          ),
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.all(16),
              alignment: Alignment.bottomRight,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Text(
                  _isSimple ? expression : (_isDifferentiation ? _diffExpressionController.text : _intExpressionController.text),
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.teal),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.all(16),
              alignment: Alignment.bottomRight,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: _isLoading
                    ? const SpinKitCircle(color: Colors.teal, size: 50.0)
                    : Text(
                  _isSimple ? result : (_isDifferentiation ? derivativeResult : integralResult),
                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.teal),
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
                      labelText: 'Enter variable (e.g., x)',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _isDifferentiation ? _diffExpressionController : _intExpressionController,
                    decoration: InputDecoration(
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
              flex: 5,
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 4,
                  mainAxisSpacing: 4,
                  childAspectRatio: 1.8,
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
                  return CalculatorButton(buttons[index], _onButtonPressed);
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
}
