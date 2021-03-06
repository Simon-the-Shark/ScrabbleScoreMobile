import 'package:flutter/material.dart';

import '../helpers/scrabble_helper.dart';

class UserInputWidget extends StatelessWidget {
  UserInputWidget(this.number, this.parentValues, this.parentDeleteFunction,
      {this.textController, this.focusNode});

  final int number;
  final List<String> parentValues;
  final Function(int) parentDeleteFunction;
  final TextEditingController textController;
  final FocusNode focusNode;

  static const adjectives = {
    1: "pierwszego",
    2: "drugiego",
    3: "trzeciego",
    4: "czwartego",
  };
  static const colors = {
    1: Colors.green,
    2: Colors.orange,
    3: Colors.blue,
    4: Colors.pink,
  };
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
      color: ScrabbleHelper.DIRTY_WHITE,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ListTile(
        leading: Container(
          decoration: BoxDecoration(
              shape: BoxShape.circle,
              border:
                  Border.all(width: 1, color: UserInputWidget.colors[number])),
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Text(
              number.toString(),
              style: ScrabbleHelper.textStyle
                  .copyWith(color: UserInputWidget.colors[number]),
            ),
          ),
        ),
        title: TextField(
          controller: textController,
          decoration: InputDecoration(
            labelText: 'Imię ${UserInputWidget.adjectives[number]} gracza',
          ),
          onChanged: (value) => parentValues[number] = value,
          focusNode: focusNode,
        ),
        contentPadding: const EdgeInsets.only(left: 16),
        trailing: Opacity(
          opacity: parentDeleteFunction != null ? 1 : 0,
          child: IconButton(
            padding: const EdgeInsets.all(0),
            icon: const Icon(Icons.close),
            iconSize: 20,
            onPressed: () {
              if (parentDeleteFunction != null) parentDeleteFunction(number);
            },
          ),
        ),
      ),
    );
  }
}
