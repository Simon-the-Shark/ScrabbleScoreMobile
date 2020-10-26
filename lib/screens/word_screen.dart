import 'dart:io';

import 'package:flutter/material.dart';
import 'package:keyboard_actions/keyboard_actions.dart';
import 'package:provider/provider.dart';

import '../helpers/locator.dart';
import '../helpers/scrabble_helper.dart';
import '../providers/game.dart';
import '../providers/scrabble_dictionary.dart';
import '../widgets/blank_lock_button.dart';
import '../widgets/blank_tile.dart';
import '../widgets/dictionary_check_widget.dart';
import '../widgets/scrabble_keyboard.dart';
import '../widgets/scrabble_tile.dart';
import '../widgets/speech_to_text.dart';

class WordScreen extends StatefulWidget {
  WordScreen(this.player, {key}) : super(key: key);
  final int player;
  static const routeName = "/game/word";
  @override
  WordScreenState createState() => WordScreenState();
}

class WordScreenState extends State<WordScreen> {
  final textNode = FocusNode();
  final notifier = ValueNotifier<String>("");
  int score = 0;
  List<String> word = [];
  Map<int, Multipliers> multipliers = {};
  bool bonus50 = false;

  int get wordMultiplyFactor {
    int returnFactor = 1;
    multipliers.values
        .where((element) => element.type == MultipliersType.word)
        .forEach((element) => returnFactor *= element.value);
    return returnFactor;
  }

  int get bonus => bonus50 ? 50 : 0;

  String get multiplyLabel =>
      wordMultiplyFactor > 1 ? " x$wordMultiplyFactor" : "";

  String get bonus50Label => bonus50 ? " +50" : "";

  void addMultiplier(int index, Multipliers multi) => setState(() {
        multipliers[index] = multi;
        score = ScrabbleHelper.calculateScoreWithLetterMultipliers(
            word, multipliers);
      });
  void setWord(String value) {
    setState(() {
      multipliers = {};
      word = value
          .toUpperCase()
          .split("")
          .where((element) =>
              element != " " && ScrabbleHelper.LETTERS[element] != null)
          .toList();
      score =
          ScrabbleHelper.calculateScoreWithLetterMultipliers(word, multipliers);
    });
  }

  void onChanged() {
    var value = notifier.value;
    if (value == "") return;
    if (value == null && word.length > 0) if (word.last == ")")
      setState(() {
        multipliers.remove(word.length - 2);
        word.removeRange(word.length - 3, word.length);
      });
    else
      setState(() {
        multipliers.remove(word.length - 1);
        word.removeAt(word.length - 1);
        score = ScrabbleHelper.calculateScoreWithLetterMultipliers(
            word, multipliers);
      });
    else if (ScrabbleHelper.LETTERS.keys.contains(value)) if (word.length > 0 &&
        word.last == "(")
      setState(() {
        word.add(value.toUpperCase());
        word.add(")");
        locator<GlobalKey<BlankLockButtonState>>()?.currentState?.unpresss();
      });
    else
      setState(() {
        word.add(value.toUpperCase());
        score = ScrabbleHelper.calculateScoreWithLetterMultipliers(
            word, multipliers);
      });
    else if (value == "(")
      setState(() {
        word.add(value);
      });
  }

  @override
  void initState() {
    notifier.addListener(onChanged);
    super.initState();
    WidgetsBinding.instance.addObserver(RefreshOnResume());
    textNode.requestFocus();
    Future.delayed(Duration.zero, rebuild);
  }

  @override
  void dispose() {
    notifier.dispose();
    super.dispose();
  }

  List<Widget> buildTiles() {
    List<Widget> tiles = [];
    for (var i = 0; i < word.length; i++) {
      var char = word[i];
      if (char == "(" && i == word.length - 1)
        tiles.add(BlankTile(tileIndex: i));
      else if (ScrabbleHelper.LETTERS[char] != null) {
        if (i < word.length - 1 && word[i + 1] == ")")
          tiles.add(BlankTile(letter: char, tileIndex: i));
        else
          tiles.add(
            ScrabbleTile(
              letter: char,
              points: ScrabbleHelper.LETTERS[char],
              tileIndex: i,
            ),
          );
      } else
        tiles.add(Container(width: 0, height: 0));
    }
    return tiles;
  }

  void rebuild() => setState(() {});
  @override
  Widget build(BuildContext context) {
    MediaQuery.of(context).orientation;
    return Scaffold(
      appBar: AppBar(
        title: Text("Punkty: $score$multiplyLabel$bonus50Label"),
        actions: <Widget>[
          if (!bonus50)
            IconButton(
                icon: const Text("+50"),
                onPressed: () async {
                  hideKeyboard();
                  var confirmation = await showDialog(
                      context: context,
                      child: AlertDialog(
                        title: const Text("Premia +50"),
                        content: const Text(
                            "Czy chcesz dodać premię 50 punktów za wyłożenie wszytskich płytek ze stojaczka podczas jednej tury? "),
                        actions: <Widget>[
                          FlatButton(
                            child: const Text("Nie"),
                            onPressed: () => Navigator.of(context).pop(false),
                          ),
                          FlatButton(
                            child: const Text("Tak"),
                            onPressed: () => Navigator.of(context).pop(true),
                          ),
                        ],
                      ));
                  if (confirmation == true)
                    setState(() {
                      bonus50 = true;
                    });
                }),
        ],
      ),
      floatingActionButton: textNode.hasFocus
          ? null
          : FloatingActionButton(
              key: ValueKey("keyboard"),
              heroTag: "keyboard",
              child: const Icon(Icons.keyboard),
              onPressed: () => setState(() {
                textNode.requestFocus();
              }),
            ),
      body: GestureDetector(
        onTap: () {
          setState(() {
            if (!textNode.hasFocus)
              textNode.requestFocus();
            else
              textNode.unfocus();
          });
        },
        child: WillPopScope(
          onWillPop: () async {
            if (!textNode.hasFocus) return true;
            hideKeyboard();
            return false;
          },
          child: KeyboardActions(
            config: KeyboardActionsConfig(
              keyboardActionsPlatform: KeyboardActionsPlatform.ALL,
              keyboardBarColor: Colors.grey[200],
              nextFocus: false,
              actions: [
                KeyboardAction(
                  focusNode: textNode,
                  displayActionBar: false,
                  footerBuilder: (_) => ScrabbleKeyboard(
                    notifier: notifier,
                    hideKeyboard: hideKeyboard,
                  ),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: <Widget>[
                KeyboardCustomInput<String>(
                  focusNode: textNode,
                  height: 0,
                  notifier: notifier,
                  builder: (context, val, hasFocus) {
                    return Container();
                  },
                ),
                if (word.length > 0)
                  Column(
                    children: <Widget>[
                      Wrap(children: buildTiles()),
                      const SizedBox(height: 7),
                      Text(
                        "Kliknij na płytkę, aby dodać premię",
                        style: Theme.of(context).textTheme.caption,
                      ),
                    ],
                  ),
                if (word.length > 0 &&
                    Provider.of<ScrabbleDictionary>(context).source !=
                        DictionarySources.none)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: DictionaryCheckWidget(word),
                  ),
                if (word.length == 0)
                  Text(
                    "Wpisz ułożone słowo",
                    style: Theme.of(context)
                        .textTheme
                        .headline5
                        .copyWith(fontStyle: FontStyle.italic),
                  ),
                if ((word.length != 0 || bonus50) && !textNode.hasFocus)
                  Positioned(
                    bottom: MediaQuery.of(context).orientation ==
                            Orientation.portrait
                        ? 50
                        : 20,
                    child: RaisedButton(
                      child: const Text("Dolicz słowo"),
                      onPressed: () {
                        Provider.of<Game>(context, listen: false).addPoints(
                            player: widget.player,
                            points: (score * wordMultiplyFactor) + bonus);
                        Navigator.of(context).pop();
                      },
                    ),
                  ),
                Positioned(
                  bottom: textNode.hasFocus ? 4 : 75,
                  right: 4,
                  child: const SpeechToTextWidget(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  hideKeyboard() => setState(() {
        textNode.unfocus();
      });
}

class RefreshOnResume extends WidgetsBindingObserver {
  @override
  Future<Null> didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.resumed)
      locator<GlobalKey<WordScreenState>>()?.currentState?.rebuild();
  }
}
