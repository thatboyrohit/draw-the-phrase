import 'package:flutter/material.dart';
import 'package:skribbl/widgets/custom_text_field.dart';
import 'package:skribbl/widgets/paint_screen.dart';

class CreateRoomScreen extends StatefulWidget {
  const CreateRoomScreen({super.key});

  @override
  State<CreateRoomScreen> createState() => _CreateRoomScreenState();
}

class _CreateRoomScreenState extends State<CreateRoomScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _roomNameController = TextEditingController();
  late String? _maxRoundsValue;
  late String? _roomSizeValue;
  void createRoom() {
    if (_nameController.text.isNotEmpty &&
        _roomNameController.text.isNotEmpty &&
        _maxRoundsValue != null &&
        _roomSizeValue != null) {
      Map<String, String> data = {
        "nickname": _nameController.text,
        "name": _roomNameController.text,
        "occupancy": _roomSizeValue!,
        "maxRounds": _maxRoundsValue!,
      };
      Navigator.of(context).push(MaterialPageRoute(
          builder: (context) =>
              PaintScreen(data: data, screenFrom: 'createRoom')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Text(
          'Create Room',
          style: TextStyle(
            fontSize: 30,
            color: Colors.black,
          ),
        ),
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.08,
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          child: CustomtextField(
            controller: _nameController,
            hintText: "Enter your Name",
          ),
        ),
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.08,
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          child: CustomtextField(
            controller: _roomNameController,
            hintText: "Enter Room Name",
          ),
        ),
        const SizedBox(
          height: 20,
        ),
        DropdownButton<String>(
          focusColor: const Color(0xff5F6fA),
          items: <String>[
            "2",
            "3",
            "5",
            "10",
            "15",
          ]
              .map<DropdownMenuItem<String>>(
                (String value) => DropdownMenuItem(
                  value: value,
                  child: Text(
                    value,
                    style: const TextStyle(color: Colors.black),
                  ),
                ),
              )
              .toList(),
          hint: const Text(
            'Select Max Rounds',
            style: TextStyle(
                color: Colors.black, fontSize: 14, fontWeight: FontWeight.w500),
          ),
          onChanged: (String? value) {
            setState(() {
              _maxRoundsValue = value;
            });
          },
        ),
        const SizedBox(height: 40),
        DropdownButton<String>(
          focusColor: const Color(0xff5F6fA),
          items: <String>[
            "2",
            "3",
            "4",
            "5",
            "6",
            "7",
            "8",
          ]
              .map<DropdownMenuItem<String>>(
                (String value) => DropdownMenuItem(
                  value: value,
                  child: Text(
                    value,
                    style: const TextStyle(color: Colors.black),
                  ),
                ),
              )
              .toList(),
          hint: const Text(
            'Select Room Size',
            style: TextStyle(
              color: Colors.black,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          onChanged: (String? value) {
            setState(() {
              _roomSizeValue = value;
            });
          },
        ),
        const SizedBox(
          height: 40,
        ),
        ElevatedButton(
          onPressed: createRoom,
          child: Text(
            "Create ",
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
          style: ButtonStyle(
            backgroundColor: MaterialStateProperty.all(Colors.blue),
            textStyle: MaterialStateProperty.all(
              const TextStyle(color: Colors.white),
            ),
            minimumSize: MaterialStateProperty.all(
              Size(
                MediaQuery.of(context).size.width / 2.5,
                50,
              ),
            ),
          ),
        ),
      ]),
    );
  }
}
