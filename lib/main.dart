import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WebSocket Video Stream',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'WebSocket Video Stream'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with TickerProviderStateMixin {
  WebSocketChannel? _channel;
  Uint8List? _imageData;
  Uint8List? _previousImageData;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  double batteryVoltage = 12.5;
  int batteryPercentage = 85;

  bool isLightOn = false;
  String selectedSpeed = '1';
  final List<String> speedOptions = ['1', '2', '3', '4', '5'];

  @override
  void initState() {
    super.initState();
    _connectWebSocket();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );

    FocusScope.of(context).requestFocus(FocusNode());
    RawKeyboard.instance.addListener(_handleKeyPress);
  }

  void _connectWebSocket() {
    _channel = IOWebSocketChannel.connect('ws://localhost:8000/ws');
    _channel?.stream.listen((data) {
      setState(() {
        _previousImageData = _imageData;
        _imageData = data;
        if (_previousImageData != null) {
          _fadeController.forward(from: 0);
        }
      });
    });
  }

  @override
  void dispose() {
    _channel?.sink.close();
    _fadeController.dispose();
    RawKeyboard.instance.removeListener(_handleKeyPress);
    super.dispose();
  }

  void _toggleLights() {
    setState(() {
      isLightOn = !isLightOn;
    });
  }

  void _handleKeyPress(RawKeyEvent event) {
    if (event is RawKeyDownEvent) {
      switch (event.logicalKey.keyLabel) {
        case 'Arrow Up':
          _sendDirectionCommand('up');
          break;
        case 'Arrow Down':
          _sendDirectionCommand('down');
          break;
        case 'Arrow Left':
          _sendDirectionCommand('left');
          break;
        case 'Arrow Right':
          _sendDirectionCommand('right');
          break;
      }
    }
  }

  void _sendDirectionCommand(String direction) {
    print("Direction: $direction");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            color: Colors.black,
            child: Center(
              child: _imageData != null
                  ? Stack(
                children: [
                  if (_previousImageData != null)
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Image.memory(
                        _previousImageData!,
                        fit: BoxFit.contain,
                      ),
                    ),
                  Image.memory(
                    _imageData!,
                    fit: BoxFit.contain,
                    color: Colors.transparent,
                    colorBlendMode: BlendMode.multiply,
                  ),
                ],
              )
                  : const Text(
                'Oczekiwanie na klatki wideo...',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          Positioned(
            top: 20,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  BatteryIndicator(
                    voltage: batteryVoltage,
                    percentage: batteryPercentage,
                  ),
                  Column(
                    children: [
                      ElevatedButton(
                        onPressed: _toggleLights,
                        style: ElevatedButton.styleFrom(
                          primary: isLightOn ? Colors.yellow : Colors.grey,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 8,
                          shadowColor: Colors.black,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 10),
                        ),
                        child: Icon(
                          isLightOn
                              ? Icons.lightbulb
                              : Icons.lightbulb_outline,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  SpeedSelection(
                    speedOptions: speedOptions,
                    selectedSpeed: selectedSpeed,
                    onSpeedSelected: (String speed) {
                      setState(() {
                        selectedSpeed = speed;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 40,
            right: 20,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                DirectionButton(
                  icon: Icons.arrow_drop_up,
                  onPressed: () => _sendDirectionCommand('up'),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    DirectionButton(
                      icon: Icons.arrow_left,
                      onPressed: () => _sendDirectionCommand('left'),
                    ),
                    const SizedBox(width: 20),
                    DirectionButton(
                      icon: Icons.arrow_right,
                      onPressed: () => _sendDirectionCommand('right'),
                    ),
                  ],
                ),
                DirectionButton(
                  icon: Icons.arrow_drop_down,
                  onPressed: () => _sendDirectionCommand('down'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class DirectionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const DirectionButton({Key? key, required this.icon, required this.onPressed})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(6.0),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.all(16),
          primary: Colors.grey[850],
          shadowColor: Colors.black,
          elevation: 6,
        ),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
    );
  }
}

class BatteryIndicator extends StatelessWidget {
  final double voltage;
  final int percentage;

  const BatteryIndicator(
      {Key? key, required this.voltage, required this.percentage})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.centerLeft,
          children: [
            Container(
              width: 50,
              height: 25,
              decoration: BoxDecoration(
                color: Colors.black,
                border: Border.all(color: Colors.white),
              ),
            ),
            Container(
              width: (50 - 4) * (percentage / 100),
              height: 22,
              decoration: BoxDecoration(
                color: percentage > 20 ? Colors.green : Colors.red,
              ),
            ),
            Positioned.fill(
              child: Center(
                child: Text(
                  '$percentage%',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 8),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${voltage.toStringAsFixed(1)} V',
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ],
        ),
      ],
    );
  }
}

class SpeedSelection extends StatelessWidget {
  final List<String> speedOptions;
  final String selectedSpeed;
  final ValueChanged<String> onSpeedSelected;

  const SpeedSelection({
    Key? key,
    required this.speedOptions,
    required this.selectedSpeed,
    required this.onSpeedSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: speedOptions.map((String speed) {
        final isSelected = speed == selectedSpeed;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: ElevatedButton(
            onPressed: () => onSpeedSelected(speed),
            style: ElevatedButton.styleFrom(
              primary: isSelected ? Colors.blue : Colors.grey,
            ),
            child: Row(
              children: [
                Icon(Icons.directions_car, color: Colors.white),
                const SizedBox(width: 5),
                Text(
                  speed,
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
