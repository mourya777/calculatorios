import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../utils/AppConstants.dart';
import '../utils/CircularButton.dart';
import '../utils/StorageService.dart';
import 'UserListScreen.dart';

class CalculatorScreen extends StatefulWidget {
  @override
  _CalculatorScreenState createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  String _display = '0';
  String _expression = '';
  double _num1 = 0;
  double _num2 = 0;
  String _operator = '';
  bool _isNewOperation = true;

  // Secret code detection
  String _secretBuffer = '';
  String _myId = '';

  @override
  void initState() {
    super.initState();
    _loadMyId();
  }

  Future<void> _loadMyId() async {
    _myId = await StorageService.getMyId();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.primaryDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Calculator',
          style: TextStyle(color: Colors.white70),
        ),
      ),
      body: Column(
        children: [
          // Display
          Expanded(
            flex: 1,
            child: Container(
              padding: EdgeInsets.all(20),
              alignment: Alignment.bottomRight,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _expression,
                    style: TextStyle(fontSize: 24, color: Colors.white54),
                  ),
                  SizedBox(height: 10),
                  Text(
                    _display,
                    style: TextStyle(
                      fontSize: 64,
                      fontWeight: FontWeight.w300,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Circular Buttons
          Expanded(
            flex: 2,
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      CircularButton(
                        text: 'C',
                        color: AppConstants.buttonLightGray,
                        textColor: Colors.black,
                        onPressed: () => _onButtonPressed('C'),
                      ),
                      CircularButton(
                        text: '+/-',
                        color: AppConstants.buttonLightGray,
                        textColor: Colors.black,
                        onPressed: () => _onButtonPressed('+/-'),
                      ),
                      CircularButton(
                        text: '%',
                        color: AppConstants.buttonLightGray,
                        textColor: Colors.black,
                        onPressed: () => _onButtonPressed('%'),
                      ),
                      CircularButton(
                        text: '÷',
                        color: AppConstants.accentColor,
                        onPressed: () => _onButtonPressed('÷'),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      CircularButton(text: '7', onPressed: () => _onButtonPressed('7')),
                      CircularButton(text: '8', onPressed: () => _onButtonPressed('8')),
                      CircularButton(text: '9', onPressed: () => _onButtonPressed('9')),
                      CircularButton(
                        text: '×',
                        color: AppConstants.accentColor,
                        onPressed: () => _onButtonPressed('×'),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      CircularButton(text: '4', onPressed: () => _onButtonPressed('4')),
                      CircularButton(text: '5', onPressed: () => _onButtonPressed('5')),
                      CircularButton(text: '6', onPressed: () => _onButtonPressed('6')),
                      CircularButton(
                        text: '-',
                        color: AppConstants.accentColor,
                        onPressed: () => _onButtonPressed('-'),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      CircularButton(text: '1', onPressed: () => _onButtonPressed('1')),
                      CircularButton(text: '2', onPressed: () => _onButtonPressed('2')),
                      CircularButton(text: '3', onPressed: () => _onButtonPressed('3')),
                      CircularButton(
                        text: '+',
                        color: AppConstants.accentColor,
                        onPressed: () => _onButtonPressed('+'),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      CircularButton(
                        text: '0',
                        size: 70,
                        onPressed: () => _onButtonPressed('0'),
                      ),
                      CircularButton(
                        text: '.',
                        onPressed: () => _onButtonPressed('.'),
                      ),
                      CircularButton(
                        text: '#',
                        color: Colors.green,
                        onPressed: () => _onButtonPressed('#'),
                      ),
                      CircularButton(
                        text: '=',
                        color: AppConstants.accentColor,
                        onPressed: () => _onButtonPressed('='),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onButtonPressed(String value) {
    setState(() {
      // Secret code detection
      _secretBuffer += value;

      if (_secretBuffer.contains(AppConstants.secretCode)) {
        _openUserList();
        _secretBuffer = '';
        return;
      }
      if (_secretBuffer.length > AppConstants.secretCode.length) {
        _secretBuffer = _secretBuffer.substring(1);
      }

      // Calculator logic
      if (value == 'C') {
        _clearAll();
      } else if (value == '=') {
        _calculateResult();
      } else if (['+', '-', '×', '÷'].contains(value)) {
        _handleOperator(value);
      } else if (value == '+/-') {
        _toggleSign();
      } else if (value == '%') {
        _convertToPercentage();
      } else if (value != '#') {
        _handleNumber(value);
      }
    });
  }

  void _openUserList() {
    HapticFeedback.heavyImpact();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => UserListScreen()),
    );
  }

  void _clearAll() {
    _display = '0';
    _expression = '';
    _num1 = 0;
    _num2 = 0;
    _operator = '';
    _isNewOperation = true;
  }

  void _handleOperator(String op) {
    if (_display.isNotEmpty && _display != '0') {
      _num1 = double.parse(_display);
      _operator = op;
      _expression = '$_num1 $op ';
      _isNewOperation = true;
    }
  }

  void _calculateResult() {
    if (_operator.isNotEmpty && _display.isNotEmpty) {
      _num2 = double.parse(_display);
      double result = 0;

      switch (_operator) {
        case '+': result = _num1 + _num2; break;
        case '-': result = _num1 - _num2; break;
        case '×': result = _num1 * _num2; break;
        case '÷': result = _num2 != 0 ? _num1 / _num2 : double.nan; break;
      }

      if (result.isNaN) {
        _display = 'Error';
      } else {
        _display = result.toString();
        if (_display.endsWith('.0')) {
          _display = _display.substring(0, _display.length - 2);
        }
      }

      _expression = '$_num1 $_operator $_num2 =';
      _operator = '';
      _isNewOperation = true;
    }
  }

  void _handleNumber(String value) {
    if (_isNewOperation || _display == '0') {
      _display = value;
      _isNewOperation = false;
    } else {
      _display += value;
    }
    _expression += value;
  }

  void _toggleSign() {
    if (_display != '0') {
      double num = double.parse(_display);
      _display = (-num).toString();
      if (_display.endsWith('.0')) {
        _display = _display.substring(0, _display.length - 2);
      }
    }
  }

  void _convertToPercentage() {
    double num = double.parse(_display);
    _display = (num / 100).toString();
    if (_display.endsWith('.0')) {
      _display = _display.substring(0, _display.length - 2);
    }
  }
}