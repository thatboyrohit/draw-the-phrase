import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:skribbl/models/my_custom_painter.dart';
import 'package:skribbl/models/touch_points.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class PaintScreen extends StatefulWidget {
  final Map<String, String> data;
  final String screenFrom;
  PaintScreen({required this.data, required this.screenFrom});

  @override
  State<PaintScreen> createState() => _PaintScreenState();
}

class _PaintScreenState extends State<PaintScreen> {
  late IO.Socket _socket;
  Map dataOfRoom = {};
  List<TouchPoints> points = [];
  StrokeCap strokeType = StrokeCap.round;
  Color selectedColor = Colors.black;
  double opacity = 1;
  double strokeWidth = 2;

  @override
  void initState() {
    super.initState();
    connect();
  }

  //socket to client connection
  void connect() {
    print('Attempting to connect...');
    _socket = IO.io('http://172.20.10.9:5000', <String, dynamic>{
      "transports": ["websocket"],
      "autoConnect": false
    });

    _socket.on('connect_error', (error) {
      print('Connection error: $error');
    });
    _socket.connect();

    if (widget.screenFrom == 'createRoom') {
      print('Emitting create-game event.');
      _socket.emit('create-game', widget.data);
    } else {
      _socket.emit('join-game', widget.data);
    }

    _socket.onConnect((data) {
      print('Connected!!!');
      _socket.on('updateRoom', (roomData) {
        if (mounted) {
          setState(() {
            dataOfRoom = roomData;
          });
        }
      });
      _socket.on('points', (point) {
        if (point['details'] != null) {
          setState(() {
            points.add(TouchPoints(
                points: Offset((point['details']['dx']).toDouble(),
                    (point['details']['dy']).toDouble()),
                paint: Paint()
                  ..strokeCap = strokeType
                  ..isAntiAlias = true
                  ..color = selectedColor.withOpacity(opacity)
                  ..strokeWidth = strokeWidth));
          });
        }
      });
      _socket.on('color-change', (colorString) {
        int value = int.parse(colorString, radix: 16);
        Color otherColor = new Color(value);
        setState(() {
          selectedColor = otherColor;
        });
      });
    });
    print(_socket.connected);
  }

  @override
  void dispose() {
    // Cancel any ongoing socket operations or timers here
    _socket.disconnect(); // Disconnect the socket
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    // Color pickerColor = Color(0xff443a49);
    // Color currentColor = Color(0xff443a49);
    // void changeColor(Color color) {
    //   setState(() => pickerColor = color);
    // }

    void selectColor() {
      showDialog(
          context: context,
          builder: (context) => AlertDialog(
                title: const Text('Choose Color'),
                content: SingleChildScrollView(
                    child: BlockPicker(
                        pickerColor: selectedColor,
                        onColorChanged: (color) {
                          String colorString = color.toString();
                          String valueString =
                              colorString.split('(0x')[1].split(')')[0];
                          print(colorString);
                          print(valueString);
                          Map map = {
                            'color': valueString,
                            'roomName': dataOfRoom['name']
                          };
                          _socket.emit('color-change', map);
                        })),
                actions: [
                  TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: Text('Close'))
                ],
              ));
    }

    return Scaffold(
      body: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Container(
                width: width,
                height: height * 0.55,
                child: GestureDetector(
                  onPanStart: (details) {
                    if (mounted) {
                      // Check if the widget is still mounted
                      _socket.emit('paint', {
                        'details': {
                          'dx': details.localPosition.dx,
                          'dy': details.localPosition.dy,
                        },
                        'roomName': widget.data['name'],
                      });
                    }
                  },
                  onPanUpdate: (details) {
                    if (mounted) {
                      // Check if the widget is still mounted
                      _socket.emit('paint', {
                        'details': {
                          'dx': details.localPosition.dx,
                          'dy': details.localPosition.dy,
                        },
                        'roomName': widget.data['name'],
                      });
                    }
                  },
                  onPanEnd: (details) {
                    if (mounted) {
                      // Check if the widget is still mounted
                      _socket.emit('paint', {
                        'details': null,
                        'roomName': widget.data['name'],
                      });
                    }
                  },
                  child: SizedBox.expand(
                    child: ClipRRect(
                      borderRadius: BorderRadius.all(Radius.circular(20)),
                      child: RepaintBoundary(
                        child: CustomPaint(
                          size: Size.infinite,
                          painter: MyCustomPainter(pointsList: points),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: selectColor,
                    icon: Icon(Icons.color_lens),
                  ),
                  Expanded(
                    child: Slider(
                      min: 1.0,
                      max: 10,
                      activeColor: selectedColor,
                      label: "Strokewidth $strokeWidth",
                      value: strokeWidth,
                      onChanged: (double value) {},
                    ),
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: Icon(
                      Icons.layers_clear,
                      color: selectedColor,
                    ),
                  ),
                ],
              )
            ],
          )
        ],
      ),
    );
  }
}
