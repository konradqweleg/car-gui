import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

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
  Uint8List? _previousImageData; // Store previous image data
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _connectWebSocket();

    // Set up animation controller
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
  }

  void _connectWebSocket() {
    _channel = IOWebSocketChannel.connect('ws://localhost:8000/ws');

    // Listening to the WebSocket stream
    _channel?.stream.listen((data) {
      setState(() {
        _previousImageData = _imageData; // Save the current image
        _imageData = data; // Set the new image data

        if (_previousImageData != null) {
          _fadeController.forward(from: 0); // Reset animation on new frame
        }
      });
    });
  }

  @override
  void dispose() {
    _channel?.sink.close();
    _fadeController.dispose(); // Close the animation controller
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Container(
        color: Colors.black, // Set background color to black
        child: Center(
          child: _imageData != null
              ? Stack(
            children: [
              // Display the previous image
              if (_previousImageData != null)
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Image.memory(
                    _previousImageData!,
                    fit: BoxFit.contain,
                  ),
                ),
              // Display the new image
              Image.memory(
                _imageData!,
                fit: BoxFit.contain,
                color: Colors.transparent, // Prevent flickering
                colorBlendMode: BlendMode.multiply,
              ),
            ],
          )
              : const Text(
            'Oczekiwanie na klatki wideo...',
            style: TextStyle(fontSize: 18, color: Colors.white), // Set text color to white for contrast
          ),
        ),
      ),
    );
  }
}
