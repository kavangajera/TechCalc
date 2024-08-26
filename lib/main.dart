import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:math_expressions/math_expressions.dart';
import 'dart:async';
void main() {
  runApp(TechCalcApp());
}
class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);

    _controller.forward();

    // Navigate to CalculatorHome after the animation completes
    Timer(Duration(seconds: 4), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => CalculatorHome()),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: FadeTransition(
          opacity: _animation,
          child: Image.asset('assets/images/calc2.png'),
        ),
      ),
    );
  }
}
class TechCalcApp extends StatelessWidget {
  const TechCalcApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TechCalc',
      theme: ThemeData.dark().copyWith(
        primaryColor: Colors.teal,
        scaffoldBackgroundColor: Colors.black,
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal,
            foregroundColor: Colors.white,
          ),
        ),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Colors.white),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey[900],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          labelStyle: const TextStyle(color: Colors.teal),
        ),
      ),
      home: SplashScreen(),
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
  bool _isSimple = true;
  bool _isDifferentiation = false;
  bool _isIntegration = false;
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
                child: Text(
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
              flex: 5, // Increased flex for more space
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4, // 4 columns for buttons
                  crossAxisSpacing: 4, // Increased spacing for better visibility
                  mainAxisSpacing: 4, // Increased spacing for better visibility
                  childAspectRatio: 1.8, // Aspect ratio to make buttons more square
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
      margin: const EdgeInsets.all(2),
      child: ElevatedButton(
        onPressed: () => _onButtonPressed(buttonText),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(
          buttonText,
          style: const TextStyle(fontSize: 16, color: Colors.white),
        ),
      ),
    );
  }
}
