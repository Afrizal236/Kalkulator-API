import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:math' as math;
import 'dart:io';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Bypass certificate untuk development (jangan gunakan di production)
  HttpOverrides.global = MyHttpOverrides();

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  runApp(MyApp());
}

// Custom HTTP overrides untuk bypass SSL certificate (development only)
class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kalkulator API RA',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: Calculator(),
      debugShowCheckedModeBanner: false,
      showPerformanceOverlay: false,
    );
  }
}

class Calculator extends StatefulWidget {
  @override
  _CalculatorState createState() => _CalculatorState();
}

class _CalculatorState extends State<Calculator> {
  String display = '0';
  String previousOperand = '';
  String operator = '';
  bool waitingForOperand = false;
  bool isLoading = false;
  bool isScientific = false;
  bool isDegreeMode = true;
  bool hasNetworkError = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      _testNetworkConnection();
    });
  }

  // Test koneksi network saat aplikasi dimulai
  Future<void> _testNetworkConnection() async {
    try {
      final response = await http.get(
        Uri.parse('https://api.mathjs.org/v4/?expr=1%2B1'),
        headers: {
          'User-Agent': 'Calculator-App/1.0',
          'Accept': 'application/json',
        },
      ).timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        setState(() {
          hasNetworkError = false;
        });
      } else {
        setState(() {
          hasNetworkError = true;
        });
      }
    } catch (e) {
      setState(() {
        hasNetworkError = true;
      });
      print('Network test failed: $e');
    }
  }

  void inputNumber(String num) {
    setState(() {
      if (waitingForOperand) {
        display = num;
        waitingForOperand = false;
      } else {
        display = display == '0' ? num : display + num;
      }
    });
  }

  void inputNegative() {
    setState(() {
      if (display == '0') {
        display = '-';
      } else if (display.startsWith('-')) {
        display = display.substring(1);
      } else {
        display = '-' + display;
      }
    });
  }

  String formatResult(double value) {
    if (value == value.toInt()) {
      return value.toInt().toString();
    }

    String result = value.toStringAsFixed(10);
    if (result.contains('.')) {
      result = result.replaceAll(RegExp(r'0*$'), '');
      result = result.replaceAll(RegExp(r'\.$'), '');
    }
    return result;
  }

  // Improved API call dengan error handling yang lebih baik
  Future<String> calculateWithAPI(String expression) async {
    try {
      // Tambahkan timeout yang lebih lama
      final response = await http.get(
        Uri.parse('https://api.mathjs.org/v4/?expr=${Uri.encodeComponent(expression)}'),
        headers: {
          'User-Agent': 'Calculator-App/1.0',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ).timeout(Duration(seconds: 15));

      if (response.statusCode == 200) {
        String result = response.body.trim();
        // Validasi hasil
        if (result.isEmpty || result == 'null' || result == 'undefined') {
          throw Exception('Invalid API response');
        }
        return result;
      } else {
        throw Exception('API Error: Status ${response.statusCode}');
      }
    } on SocketException {
      throw Exception('Tidak ada koneksi internet');
    } on HttpException {
      throw Exception('HTTP Error');
    } on FormatException {
      throw Exception('Format response tidak valid');
    } catch (e) {
      print('API Error Detail: $e');
      if (e.toString().contains('TimeoutException')) {
        throw Exception('Koneksi timeout');
      } else if (e.toString().contains('SocketException')) {
        throw Exception('Tidak ada koneksi internet');
      } else {
        throw Exception('Koneksi API gagal: ${e.toString()}');
      }
    }
  }

  // Fallback calculation untuk operasi dasar jika API gagal
  double? calculateLocally(String expression) {
    try {
      // Parse expression sederhana
      if (expression.contains('+')) {
        List<String> parts = expression.split('+');
        if (parts.length == 2) {
          return double.parse(parts[0].trim()) + double.parse(parts[1].trim());
        }
      } else if (expression.contains('-') && !expression.startsWith('-')) {
        List<String> parts = expression.split('-');
        if (parts.length == 2) {
          return double.parse(parts[0].trim()) - double.parse(parts[1].trim());
        }
      } else if (expression.contains('*')) {
        List<String> parts = expression.split('*');
        if (parts.length == 2) {
          return double.parse(parts[0].trim()) * double.parse(parts[1].trim());
        }
      } else if (expression.contains('/')) {
        List<String> parts = expression.split('/');
        if (parts.length == 2) {
          double divisor = double.parse(parts[1].trim());
          if (divisor != 0) {
            return double.parse(parts[0].trim()) / divisor;
          }
        }
      }
    } catch (e) {
      print('Local calculation failed: $e');
    }
    return null;
  }

  Future<void> performTrigonometry(String func) async {
    setState(() {
      isLoading = true;
    });

    try {
      double inputValue = double.parse(display);
      String expression = '';

      if (isDegreeMode) {
        double radianValue = inputValue * math.pi / 180;
        expression = '$func($radianValue)';
      } else {
        expression = '$func($inputValue)';
      }

      String result = await calculateWithAPI(expression);
      double numericResult = double.parse(result);

      setState(() {
        display = formatResult(numericResult);
        waitingForOperand = true;
        isLoading = false;
        hasNetworkError = false;
      });
    } catch (e) {
      // Fallback untuk fungsi trigonometri menggunakan dart:math
      try {
        double inputValue = double.parse(display);
        double result;

        if (isDegreeMode) {
          inputValue = inputValue * math.pi / 180;
        }

        switch (func) {
          case 'sin':
            result = math.sin(inputValue);
            break;
          case 'cos':
            result = math.cos(inputValue);
            break;
          case 'tan':
            result = math.tan(inputValue);
            break;
          default:
            throw Exception('Fungsi tidak didukung');
        }

        setState(() {
          display = formatResult(result);
          waitingForOperand = true;
          isLoading = false;
          hasNetworkError = true;
        });

        _showFallbackMessage();
      } catch (fallbackError) {
        setState(() {
          display = 'Error: ${e.toString()}';
          previousOperand = '';
          operator = '';
          waitingForOperand = true;
          isLoading = false;
          hasNetworkError = true;
        });
      }
    }
  }

  Future<void> performMathFunction(String func) async {
    setState(() {
      isLoading = true;
    });

    try {
      String expression = '';

      switch (func) {
        case 'sqrt':
          expression = 'sqrt($display)';
          break;
        case 'log':
          expression = 'log10($display)';
          break;
        case 'ln':
          expression = 'log($display)';
          break;
        case 'exp':
          expression = 'exp($display)';
          break;
        case 'pow2':
          expression = 'pow($display, 2)';
          break;
        case 'pow3':
          expression = 'pow($display, 3)';
          break;
        case 'pi':
          expression = 'pi';
          break;
        case 'e':
          expression = 'e';
          break;
      }

      String result = await calculateWithAPI(expression);
      double numericResult = double.parse(result);

      setState(() {
        display = formatResult(numericResult);
        waitingForOperand = true;
        isLoading = false;
        hasNetworkError = false;
      });
    } catch (e) {
      // Fallback untuk fungsi matematika menggunakan dart:math
      try {
        double inputValue = double.parse(display);
        double result;

        switch (func) {
          case 'sqrt':
            result = math.sqrt(inputValue);
            break;
          case 'log':
            result = math.log(inputValue) / math.ln10;
            break;
          case 'ln':
            result = math.log(inputValue);
            break;
          case 'exp':
            result = math.exp(inputValue);
            break;
          case 'pow2':
            result = math.pow(inputValue, 2).toDouble();
            break;
          case 'pow3':
            result = math.pow(inputValue, 3).toDouble();
            break;
          case 'pi':
            result = math.pi;
            break;
          case 'e':
            result = math.e;
            break;
          default:
            throw Exception('Fungsi tidak didukung');
        }

        setState(() {
          display = formatResult(result);
          waitingForOperand = true;
          isLoading = false;
          hasNetworkError = true;
        });

        _showFallbackMessage();
      } catch (fallbackError) {
        setState(() {
          display = 'Error: ${e.toString()}';
          previousOperand = '';
          operator = '';
          waitingForOperand = true;
          isLoading = false;
          hasNetworkError = true;
        });
      }
    }
  }

  void _showFallbackMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Menggunakan perhitungan lokal (API tidak tersedia)'),
        duration: Duration(seconds: 2),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void inputOperator(String nextOperator) {
    if (previousOperand.isEmpty) {
      previousOperand = display;
    } else if (operator.isNotEmpty && !waitingForOperand) {
      performCalculationWithAPI();
    }

    setState(() {
      waitingForOperand = true;
      operator = nextOperator;
    });
  }

  Future<void> performCalculationWithAPI() async {
    if (previousOperand.isNotEmpty && operator.isNotEmpty && !waitingForOperand) {
      setState(() {
        isLoading = true;
      });

      try {
        String expression = '$previousOperand $operator $display';
        String result = await calculateWithAPI(expression);
        double numericResult = double.parse(result);

        setState(() {
          display = formatResult(numericResult);
          previousOperand = display;
          isLoading = false;
          hasNetworkError = false;
        });
      } catch (e) {
        // Fallback ke perhitungan lokal
        String expression = '$previousOperand $operator $display';
        double? localResult = calculateLocally(expression);

        if (localResult != null) {
          setState(() {
            display = formatResult(localResult);
            previousOperand = display;
            isLoading = false;
            hasNetworkError = true;
          });
          _showFallbackMessage();
        } else {
          setState(() {
            display = 'Error: ${e.toString()}';
            previousOperand = '';
            operator = '';
            waitingForOperand = true;
            isLoading = false;
            hasNetworkError = true;
          });
        }
      }
    }
  }

  Future<void> performFinalCalculation() async {
    if (previousOperand.isNotEmpty && operator.isNotEmpty) {
      setState(() {
        isLoading = true;
      });

      try {
        String expression = '$previousOperand $operator $display';
        String result = await calculateWithAPI(expression);
        double numericResult = double.parse(result);

        setState(() {
          display = formatResult(numericResult);
          previousOperand = '';
          operator = '';
          waitingForOperand = true;
          isLoading = false;
          hasNetworkError = false;
        });
      } catch (e) {
        // Fallback ke perhitungan lokal
        String expression = '$previousOperand $operator $display';
        double? localResult = calculateLocally(expression);

        if (localResult != null) {
          setState(() {
            display = formatResult(localResult);
            previousOperand = '';
            operator = '';
            waitingForOperand = true;
            isLoading = false;
            hasNetworkError = true;
          });
          _showFallbackMessage();
        } else {
          setState(() {
            display = 'Error: ${e.toString()}';
            previousOperand = '';
            operator = '';
            waitingForOperand = true;
            isLoading = false;
            hasNetworkError = true;
          });
        }
      }
    }
  }

  void clear() {
    setState(() {
      display = '0';
      previousOperand = '';
      operator = '';
      waitingForOperand = false;
      isLoading = false;
    });
  }

  void clearEntry() {
    setState(() {
      display = '0';
    });
  }

  void inputDecimal() {
    if (!display.contains('.')) {
      setState(() {
        display = display + '.';
      });
    }
  }

  void toggleScientific() {
    setState(() {
      isScientific = !isScientific;
    });
  }

  void toggleAngleMode() {
    setState(() {
      isDegreeMode = !isDegreeMode;
    });
  }

  Widget buildButton(String text, {Color? color, Color? textColor, double flex = 1, double fontSize = 24}) {
    return Expanded(
      flex: flex.toInt(),
      child: Container(
        margin: EdgeInsets.all(2),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: color ?? Colors.grey[300],
            foregroundColor: textColor ?? Colors.black,
            padding: EdgeInsets.all(isScientific ? 12 : 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onPressed: isLoading ? null : () {
            if (text == 'C') {
              clear();
            } else if (text == 'CE') {
              clearEntry();
            } else if (text == '=') {
              performFinalCalculation();
            } else if (['+', '-', '*', '/', '%', '^'].contains(text)) {
              inputOperator(text);
            } else if (text == '.') {
              inputDecimal();
            } else if (text == '±') {
              inputNegative();
            } else if (text == 'sin') {
              performTrigonometry('sin');
            } else if (text == 'cos') {
              performTrigonometry('cos');
            } else if (text == 'tan') {
              performTrigonometry('tan');
            } else if (['sqrt', 'log', 'ln', 'exp', 'pow2', 'pow3', 'pi', 'e'].contains(text)) {
              performMathFunction(text);
            } else if (text == 'Sci') {
              toggleScientific();
            } else if (text == 'DEG' || text == 'RAD') {
              toggleAngleMode();
            } else if (text == 'Test') {
              _testNetworkConnection();
            } else {
              inputNumber(text);
            }
          },
          child: isLoading && text == '='
              ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(textColor ?? Colors.black),
            ),
          )
              : Text(
            text,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget buildBasicCalculator() {
    return Column(
      children: [
        // Row 1: C, CE, /, *
        Expanded(
          child: Row(
            children: [
              buildButton('C', color: Colors.red[400], textColor: Colors.white),
              buildButton('CE', color: Colors.orange[400], textColor: Colors.white),
              buildButton('/', color: Colors.blue[400], textColor: Colors.white),
              buildButton('*', color: Colors.blue[400], textColor: Colors.white),
            ],
          ),
        ),

        // Row 2: 7, 8, 9, -
        Expanded(
          child: Row(
            children: [
              buildButton('7'),
              buildButton('8'),
              buildButton('9'),
              buildButton('-', color: Colors.blue[400], textColor: Colors.white),
            ],
          ),
        ),

        // Row 3: 4, 5, 6, +
        Expanded(
          child: Row(
            children: [
              buildButton('4'),
              buildButton('5'),
              buildButton('6'),
              buildButton('+', color: Colors.blue[400], textColor: Colors.white),
            ],
          ),
        ),

        // Row 4: 1, 2, 3, =
        Expanded(
          child: Row(
            children: [
              buildButton('1'),
              buildButton('2'),
              buildButton('3'),
              buildButton('=', color: Colors.green[400], textColor: Colors.white),
            ],
          ),
        ),

        // Row 5: ±, 0, ., Sci
        Expanded(
          child: Row(
            children: [
              buildButton('±', color: Colors.purple[300], textColor: Colors.white),
              buildButton('0'),
              buildButton('.'),
              buildButton('Sci', color: Colors.indigo[400], textColor: Colors.white),
            ],
          ),
        ),
      ],
    );
  }

  Widget buildScientificCalculator() {
    return Column(
      children: [
        // Row 1: Functions
        Expanded(
          child: Row(
            children: [
              buildButton('sin', color: Colors.teal[400], textColor: Colors.white, fontSize: 16),
              buildButton('cos', color: Colors.teal[400], textColor: Colors.white, fontSize: 16),
              buildButton('tan', color: Colors.teal[400], textColor: Colors.white, fontSize: 16),
              buildButton('C', color: Colors.red[400], textColor: Colors.white, fontSize: 16),
              buildButton('CE', color: Colors.orange[400], textColor: Colors.white, fontSize: 16),
            ],
          ),
        ),

        // Row 2: More functions
        Expanded(
          child: Row(
            children: [
              buildButton('sqrt', color: Colors.cyan[400], textColor: Colors.white, fontSize: 14),
              buildButton('pow2', color: Colors.cyan[400], textColor: Colors.white, fontSize: 16),
              buildButton('pow3', color: Colors.cyan[400], textColor: Colors.white, fontSize: 16),
              buildButton('/', color: Colors.blue[400], textColor: Colors.white, fontSize: 16),
              buildButton('*', color: Colors.blue[400], textColor: Colors.white, fontSize: 16),
            ],
          ),
        ),

        // Row 3: Numbers and operators
        Expanded(
          child: Row(
            children: [
              buildButton('log', color: Colors.amber[600], textColor: Colors.white, fontSize: 16),
              buildButton('7', fontSize: 16),
              buildButton('8', fontSize: 16),
              buildButton('9', fontSize: 16),
              buildButton('-', color: Colors.blue[400], textColor: Colors.white, fontSize: 16),
            ],
          ),
        ),

        // Row 4: Numbers and operators
        Expanded(
          child: Row(
            children: [
              buildButton('ln', color: Colors.amber[600], textColor: Colors.white, fontSize: 16),
              buildButton('4', fontSize: 16),
              buildButton('5', fontSize: 16),
              buildButton('6', fontSize: 16),
              buildButton('+', color: Colors.blue[400], textColor: Colors.white, fontSize: 16),
            ],
          ),
        ),

        // Row 5: Constants and numbers
        Expanded(
          child: Row(
            children: [
              buildButton('pi', color: Colors.deepPurple[300], textColor: Colors.white, fontSize: 16),
              buildButton('1', fontSize: 16),
              buildButton('2', fontSize: 16),
              buildButton('3', fontSize: 16),
              buildButton('=', color: Colors.green[400], textColor: Colors.white, fontSize: 16),
            ],
          ),
        ),

        // Row 6: Bottom row with angle mode toggle
        Expanded(
          child: Row(
            children: [
              buildButton('e', color: Colors.deepPurple[300], textColor: Colors.white, fontSize: 16),
              buildButton(isDegreeMode ? 'DEG' : 'RAD', color: Colors.pink[400], textColor: Colors.white, fontSize: 12),
              buildButton('0', fontSize: 16),
              buildButton('.', fontSize: 16),
              buildButton('Sci', color: Colors.indigo[400], textColor: Colors.white, fontSize: 14),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isScientific ? 'Kalkulator API RA (Scientific)' : 'Kalkulator API RA'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          if (hasNetworkError)
            Container(
              margin: EdgeInsets.only(right: 8),
              child: Icon(
                Icons.wifi_off,
                color: Colors.orange,
                size: 20,
              ),
            ),
          if (isScientific)
            Container(
              margin: EdgeInsets.only(right: 8),
              child: Center(
                child: Text(
                  isDegreeMode ? 'DEG' : 'RAD',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          IconButton(
            icon: Icon(isScientific ? Icons.calculate : Icons.functions),
            onPressed: toggleScientific,
            tooltip: isScientific ? 'Mode Dasar' : 'Mode Scientific',
          ),
          IconButton(
            icon: Icon(Icons.network_check),
            onPressed: _testNetworkConnection,
            tooltip: 'Test Koneksi',
          ),
        ],
      ),
      body: Column(
        children: [
          // Network status indicator
          if (hasNetworkError)
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 4, horizontal: 16),
              color: Colors.orange[100],
              child: Text(
                'Mode Offline - Menggunakan perhitungan lokal',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.orange[800],
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),

          // Display
          Container(
            padding: EdgeInsets.all(20),
            alignment: Alignment.centerRight,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (isLoading)
                  Container(
                    margin: EdgeInsets.only(bottom: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Menghitung...',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                if (previousOperand.isNotEmpty && operator.isNotEmpty)
                  Text(
                    '$previousOperand $operator',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Text(
                    display,
                    style: TextStyle(
                      fontSize: isScientific ? 36 : 48,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(),

          // Info untuk trigonometri
          if (isScientific)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Text(
                'Mode: ${isDegreeMode ? "Derajat (DEG)" : "Radian (RAD)"} - Tekan DEG/RAD untuk ubah',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),

          // Buttons
          Expanded(
            child: Container(
              padding: EdgeInsets.all(8),
              child: isScientific ? buildScientificCalculator() : buildBasicCalculator(),
            ),
          ),
        ],
      ),
    );
  }
}