import 'dart:convert';
import 'dart:core';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/animation.dart';

void main() => runApp(new MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Crypto Prices',
      theme: new ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or press Run > Flutter Hot Reload in IntelliJ). Notice that the
        // counter didn't reset back to zero; the application is not restarted.
        primarySwatch: Colors.green,
        brightness: Brightness.dark,
      ),
      home: new MyHomePage(title: 'Prices'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  _MyHomePageState createState() => new _MyHomePageState();
}

enum DialogDemoAction {
  cancel,
  discard,
  disagree,
  agree,
}

const String _alertWithoutTitleText = 'Discard draft?';

const String _alertWithTitleText =
    'Let Google help apps determine location. This means sending anyonmous location '
    'data to Google, even when no apps are running.';

class _MyHomePageState extends State<MyHomePage>
    with SingleTickerProviderStateMixin {
  Animation<double> animation;
  AnimationController controller;

  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      new GlobalKey<RefreshIndicatorState>();
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  var client = createHttpClient();
  var prices = [];

  @override
  initState() {
    super.initState();
    getPrices();
    controller = new AnimationController(
        duration: const Duration(milliseconds: 2000), vsync: this);
    animation = new Tween(begin: 0.0, end: 300.0).animate(controller)
      ..addListener(() {
        setState(() {
          // the state that has changed here is the animation object’s value
        });
      });
//    controller.forward();
  }

  dispose() {
    controller.dispose();
    super.dispose();
  }

  getPrices() async {
    var versionHeader = new Map<String, String>();
    versionHeader["CB-VERSION"] = "2017-12-16";
    var yesterdayDay = new DateTime.now();
    var yesterday =
        "https://api.coinbase.com/v2/prices/LTC-USD/spot?date=${yesterdayDay
        .year}-${yesterdayDay.month}-${yesterdayDay.day - 1}";
    var now = "https://api.coinbase.com/v2/prices/LTC-USD/spot";
    var respYes = await client.read(yesterday, headers: versionHeader);
    var respNow = await client.read(now, headers: versionHeader);
    var pricesYes = JSON.decode(respYes);
    var pricesToday = JSON.decode(respNow);
    setState(() {
      var percentChanged = (double.parse(pricesToday["data"]["amount"])) /
              (double.parse(pricesYes["data"]["amount"])) -
          1;
      this.prices = [
        {
          "today": pricesToday,
          "yesterday": pricesYes,
          "percent": percentChanged,
          "color": percentChanged > 0 ? Colors.green : Colors.red
        }
      ];
      print(this.prices.toString());
    });
  }

  onEditCoin(TextStyle dialogTextStyle) {}

  void showDemoDialog<T>({BuildContext context, Widget child}) {
    controller.forward();
//    showDialog<T>(
//      context: context,
//      child: child,
//    ).then<Null>((T value) {
//      controller.forward();
//      // The value passed to Navigator.pop() or null.
//      if (value != null) {
//        _scaffoldKey.currentState.showSnackBar(
//            new SnackBar(content: new Text('You selected: $value')));
//      }
//    });
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextStyle dialogTextStyle =
        theme.textTheme.subhead.copyWith(color: theme.textTheme.caption.color);
    print(animation.value);
    return new Scaffold(
        floatingActionButton: new FloatingActionButton(
            backgroundColor: Colors.green,
            onPressed: () {
              showDemoDialog<DialogDemoAction>(
                  context: context,
                  child: new Container(
                      child: new AlertDialog(
                          content: new Text(_alertWithoutTitleText,
                              style: dialogTextStyle),
                          actions: <Widget>[
                        new FlatButton(
                            child: const Text('CANCEL'),
                            onPressed: () {
                              Navigator.pop(context, DialogDemoAction.cancel);
                            }),
                        new FlatButton(
                            child: const Text('DISCARD'),
                            onPressed: () {
                              Navigator.pop(context, DialogDemoAction.discard);
                            })
                      ])));
            },
            child: new Icon(Icons.add)),
        appBar: new AppBar(title: new Text(widget.title)),
        body: new Container(
            alignment: Alignment.bottomCenter,
            child: new RefreshIndicator(
                key: _refreshIndicatorKey,
                child: new Container(
                    margin: const EdgeInsets.all(100.00),
                    alignment: Alignment.bottomCenter,
                    child: new ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: this.prices.length,
                        itemBuilder: (BuildContext ctx, int index) {
                          return new Column(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                new Text("LTC",
                                    style: new TextStyle(fontSize: 44.00)),
                                new Text(
                                    "\$${this
                                        .prices[index]["today"]["data"]["amount"]} now",
                                    style: new TextStyle(fontSize: 24.00)),
                                new Text("\$${this
                                    .prices[index]["yesterday"]["data"]["amount"]} 24hr"),
                                new Text(
                                    "%${(this
                                        .prices[index]["percent"] as double)
                                        .toStringAsFixed(5)}",
                                    style: new TextStyle(
                                        fontSize: 20.00,
                                        color: this.prices[index]["color"]))
                              ]);
                        })),
                onRefresh: getPrices)));
  }
}
