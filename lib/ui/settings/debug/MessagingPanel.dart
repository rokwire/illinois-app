/*
 * Copyright 2020 Board of Trustees of the University of Illinois.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import "package:flutter/material.dart";
import 'package:fluttertoast/fluttertoast.dart';

import 'package:illinois/service/FirebaseMessaging.dart';
import 'package:illinois/service/Localization.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/TabBarWidget.dart';
import 'package:illinois/service/Styles.dart';

class MessagingPanel extends StatefulWidget {
  @override
  _DropDownButtonState createState() => _DropDownButtonState();
}

class _DropDownButtonState extends State<MessagingPanel> {
  var _topic = "event_reminders";

  DropdownButton _itemDown() => DropdownButton<String>(
        items: [
          DropdownMenuItem(
            value: "event_reminders",
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text("notification"),
                SizedBox(width: 10),
                Text(
                  "event_reminders",
                ),
              ],
            ),
          ),
          DropdownMenuItem(
            value: "athletic_updates",
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text("notification"),
                SizedBox(width: 10),
                Text(
                  "athletic_updates",
                ),
              ],
            ),
          ),
          DropdownMenuItem(
            value: "dinning_specials",
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text("notification"),
                SizedBox(width: 10),
                Text(
                  "dinning_specials",
                ),
              ],
            ),
          ),
          DropdownMenuItem(
            value: "football",
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text("data"),
                SizedBox(width: 10),
                Text(
                  "football",
                ),
              ],
            ),
          ),
          DropdownMenuItem(
            value: "mbball",
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text("data"),
                SizedBox(width: 10),
                Text(
                  "mbball",
                ),
              ],
            ),
          ),
          DropdownMenuItem(
            value: "wbball",
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text("data"),
                SizedBox(width: 10),
                Text(
                  "wbball",
                ),
              ],
            ),
          ),
          DropdownMenuItem(
            value: "mvball",
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text("data"),
                SizedBox(width: 10),
                Text(
                  "mvball",
                ),
              ],
            ),
          ),
          DropdownMenuItem(
            value: "wvball",
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text("data"),
                SizedBox(width: 10),
                Text(
                  "wvball",
                ),
              ],
            ),
          ),
          DropdownMenuItem(
            value: "mtennis",
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text("data"),
                SizedBox(width: 10),
                Text(
                  "mtennis",
                ),
              ],
            ),
          ),
          DropdownMenuItem(
            value: "wtennis",
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text("data"),
                SizedBox(width: 10),
                Text(
                  "wtennis",
                ),
              ],
            ),
          ),
          DropdownMenuItem(
            value: "baseball",
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text("data"),
                SizedBox(width: 10),
                Text(
                  "baseball",
                ),
              ],
            ),
          ),
          DropdownMenuItem(
            value: "softball",
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text("data"),
                SizedBox(width: 10),
                Text(
                  "softball",
                ),
              ],
            ),
          ),
        ],
        onChanged: (value) {
          setState(() {
            _topic = value;
          });
        },
        value: _topic,
        isExpanded: true,
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SimpleHeaderBarWithBack(
        context: context,
        titleWidget: Text(
          Localization().getStringEx("panel.debug_messaging.header.title", "Messaging"),
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.0),
        ),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: <Widget>[
                  SizedBox(height: 10),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: _itemDown(),
                  ),
                  SizedBox(height: 10),
                  Visibility(
                    visible: _isScoreContent(),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: _ScoreMessageWidget(topic: _topic),
                    ),
                  ),
                  Visibility(
                    visible: _isGenericMessageContent(),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: _GenericMessageWidget(topic: _topic),
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
      backgroundColor: Styles().colors.background,
      bottomNavigationBar: TabBarWidget(),
    );
  }

  bool _isGenericMessageContent() {
    return _topic == "event_reminders" || _topic == "athletic_updates" || _topic == "dinning_specials";
  }

  bool _isScoreContent() {
    return _topic == "football" ||
        _topic == "mbball" ||
        _topic == "wbball" ||
        _topic == "mvball" ||
        _topic == "wvball" ||
        _topic == "mtennis" ||
        _topic == "wtennis" ||
        _topic == "baseball" ||
        _topic == "softball";
  }
}

class _GenericMessageWidget extends StatefulWidget {
  final String _topic;
  _GenericMessageWidget({String topic}) : this._topic = topic;

  @override
  _GenericMessageWidgetState createState() {
    return _GenericMessageWidgetState();
  }
}

class _GenericMessageWidgetState extends State<_GenericMessageWidget> {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 25.0),
                child: Text(widget._topic),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 1.0),
                child: TextFormField(
                  validator: (value) => validate(value),
                  decoration: InputDecoration(hintText: 'Enter title'),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 1.0),
                child: TextFormField(
                  keyboardType: TextInputType.multiline,
                  maxLines: 3,
                  validator: (value) => validate(value),
                  decoration: InputDecoration(hintText: 'Enter message'),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: RaisedButton(
                  onPressed: () {
                    // Validate returns true if the form is valid, or false
                    // otherwise.
                    if (_formKey.currentState.validate()) {
                      _formKey.currentState.save();

                      _showDialog();
                    }
                  },
                  child: Text('Submit'),
                ),
              ),
            ],
          ),
        ));
  }

  void _showDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: new Text("Notification type message"),
          content: new Text("Currently there is no availability to test notification type messages here. "
              "Please use the Firebase console."),
          actions: <Widget>[
            // usually buttons at the bottom of the dialog
            new FlatButton(
              child: new Text("Close"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  validate(value) {
    if (value.isEmpty) {
      return 'Enter some text';
    }
    return null;
  }

  onSubmitResult(value) {
    String result = value ? "The message was sent to Firebase successfully" : "An error occured";
    Fluttertoast.showToast(msg: result, toastLength: Toast.LENGTH_SHORT, gravity: ToastGravity.CENTER);
  }
}

class _ScoreMessageWidget extends StatefulWidget {
  final String _topic;
  _ScoreMessageWidget({String topic}) : this._topic = topic;

  @override
  _ScoreMessageWidgetState createState() {
    return _ScoreMessageWidgetState();
  }
}

class _ScoreData {
  String gameId;
  String path;
  String hasStarted;
  String isComplete;
  String clockSeconds;
  String period;
  String homeScore;
  String visitingScore;
}

class _ScoreMessageWidgetState extends State<_ScoreMessageWidget> {
  final _formKey = GlobalKey<FormState>();
  _ScoreData _data = new _ScoreData();

  @override
  void initState() {
    _data.path = widget._topic;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 25.0),
                child: Text(widget._topic),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 1.0),
                child: TextFormField(
                    initialValue: "16689",
                    validator: (value) => validate(value),
                    decoration: InputDecoration(hintText: 'Enter a game id'),
                    onSaved: (String value) {
                      this._data.gameId = value;
                    }),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 1.0),
                child: TextFormField(
                    initialValue: "true",
                    validator: (value) => validate(value),
                    decoration: InputDecoration(hintText: 'Has started'),
                    onSaved: (String value) {
                      this._data.hasStarted = value;
                    }),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 1.0),
                child: TextFormField(
                    initialValue: "false",
                    validator: (value) => validate(value),
                    decoration: InputDecoration(hintText: 'Is completed'),
                    onSaved: (String value) {
                      this._data.isComplete = value;
                    }),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 1.0),
                child: TextFormField(
                    initialValue: "100",
                    validator: (value) => validate(value),
                    decoration: InputDecoration(hintText: 'Enter clock seconds'),
                    onSaved: (String value) {
                      this._data.clockSeconds = value;
                    }),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 1.0),
                child: TextFormField(
                    initialValue: "1",
                    validator: (value) => validate(value),
                    decoration: InputDecoration(hintText: 'Enter a period'),
                    onSaved: (String value) {
                      this._data.period = value;
                    }),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 1.0),
                child: TextFormField(
                    initialValue: "2",
                    validator: (value) => validate(value),
                    decoration: InputDecoration(hintText: 'Enter a home score'),
                    onSaved: (String value) {
                      this._data.homeScore = value;
                    }),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 1.0),
                child: TextFormField(
                    initialValue: "1",
                    validator: (value) => validate(value),
                    decoration: InputDecoration(hintText: 'Enter a visiting score'),
                    onSaved: (String value) {
                      this._data.visitingScore = value;
                    }),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: RaisedButton(
                  onPressed: () {
                    // Validate returns true if the form is valid, or false
                    // otherwise.
                    if (_formKey.currentState.validate()) {
                      _formKey.currentState.save();

                      FirebaseMessaging().send(topic: widget._topic, message: _constructMessage()).then((value) => onSubmitResult(value));
                    }
                  },
                  child: Text('Submit'),
                ),
              ),
            ],
          ),
        ));
  }

  dynamic _constructMessage() {
    return {
      'ClockSeconds': _data.clockSeconds,
      'GameId': _data.gameId,
      'HomeScore': _data.homeScore,
      'Period': _data.period,
      'HasStarted': _data.hasStarted,
      'IsComplete': _data.isComplete,
      'VisitingScore': _data.visitingScore,
      'Path': _data.path
    };
  }

  validate(value) {
    //Disable the validation but leave it here for reference
    /*if (value.isEmpty) {
      return 'Enter some text';
    } */
    return null;
  }

  onSubmitResult(value) {
    String result = value ? "The message was sent to Firebase successfully" : "An error occured";
    Fluttertoast.showToast(msg: result, toastLength: Toast.LENGTH_SHORT, gravity: ToastGravity.CENTER);
  }
}
