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
  List<Widget> textBlankWIdget = [];
  TextEditingController controller = TextEditingController();
  ScrollController _scrollController = ScrollController();
  List<Map> messages = [];

  @override
  void initState() {
    super.initState();
    connect();
  }

  void renderTextBlank(String text) {
    textBlankWIdget.clear();
    for (int i = 0; i < text.length; i++) {
      textBlankWIdget.add(const Text(
        '_',
        style: TextStyle(fontSize: 30),
      ));
    }
  }

  //socket to client connection
  void connect() {
    print('Attempting to connect...');
    _socket = IO.io('http://192.168.83.71:5000', <String, dynamic>{
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
        print(roomData['word']);
        if (mounted) {
          setState(() {
            renderTextBlank(roomData['word']);
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

      _socket.on('msg', (msgData) {
        print('Received message: $msgData');
        setState(() {
          messages.add(msgData);
        });
        _scrollController.animateTo(
            _scrollController.position.maxScrollExtent + 40,
            duration: Duration(milliseconds: 20),
            curve: Curves.easeInOut);
      });
      _socket.on('color-change', (colorString) {
        int value = int.parse(colorString, radix: 16);
        Color otherColor = Color(value);
        setState(() {
          selectedColor = otherColor;
        });
      });

      _socket.on('stroke-width', (value) {
        setState(() {
          strokeWidth = value.toDouble();
        });
      });
      _socket.on('clean-screen', (data) {
        setState(() {
          points.clear();
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
                      child: const Text('Close'))
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
                      onChanged: (double value) {
                        Map map = {
                          'value': value,
                          'roomName': dataOfRoom['name']
                        };
                        _socket.emit('stroke-width', map);
                      },
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      _socket.emit('clean-screen', dataOfRoom['name']);
                    },
                    icon: Icon(
                      Icons.layers_clear,
                      color: selectedColor,
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: textBlankWIdget,
              ),

              //Displaying messages
              Container(
                height: MediaQuery.of(context).size.height * 0.3,
                child: ListView.builder(
                    controller: _scrollController,
                    shrinkWrap: true,
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      var msg = messages[index].values;
                      return ListTile(
                        // title: Text(
                        //   msg.elementAt(0),
                        //   style: TextStyle(
                        //       color: Colors.black,
                        //       fontSize: 19,
                        //       fontWeight: FontWeight.bold),
                        // ),
                        title: Text(
                          msg.elementAt(0),
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                      );
                    }),
              )
            ],
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
                margin: EdgeInsets.symmetric(horizontal: 20),
                child: TextField(
                  controller: controller,
                  onSubmitted: (value) {
                    if (value.trim().isNotEmpty) {
                      Map map = {
                        //'username': widget.data['username'],
                        'msg': value.trim(),
                        'word': dataOfRoom['word'],
                        'roomName': widget.data['name'],
                      };
                      _socket.emit('msg', map);
                      controller.clear();
                    }
                  },
                  autocorrect: false,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.transparent),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    filled: false,
                    fillColor: Theme.of(context).primaryColorDark,
                    hintText: 'Your Guess',
                    hintStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  textInputAction: TextInputAction.done,
                )),
          )
        ],
      ),
    );
  }
}
