import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_slidable/flutter_slidable.dart';
import 'dart:convert';
import 'dart:async';

void main() => runApp(Spark());

Map allPosts;

class Spark extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Spark for Reddit',
      theme: new ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.deepPurple,
        accentColor: Colors.deepPurpleAccent,
        backgroundColor: Colors.grey[850],
        bottomAppBarColor: Colors.grey[900],
      ),
      home: SparkReddit(),
    );
  }
}

class SparkReddit extends StatefulWidget {
  @override
  SparkRedditState createState() => new SparkRedditState();
}

class SparkRedditState extends State<SparkReddit> {
  var _data;
  var loaded = false;
  var _after;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Spark for Reddit'),
      ),
      body: _buildSplash(context),
    );
  }
  Widget _buildSplash(BuildContext context) {
    if (!loaded) {
      makeRequest('https://old.reddit.com/hot/.json');
      return new Scaffold(
          body: new Center(
            child: new Text('Loading :)')
          )
      );
    } else {
      return _buildHome(context);
    }
  }
  
  Widget _buildHome(BuildContext context) {
    return ListView.builder(
      itemBuilder: (context, i) {
        if (i.isOdd) {
          return Divider();
        } else {
          final index = i ~/ 2;
          print(_data.length);
          if (index >= _data.length) {
            makeRequest('https://old.reddit.com/hot/.json?after=$_after');
          }
          try {
            var author = _data[index]['data']['author'];
            var sub    = _data[index]['data']['subreddit'];
            var title  = _data[index]['data']['title'];
            var score  = _data[index]['data']['score'];
            return _buildTile(context, author, title, sub, score);
          } catch (exception) {
            print(exception);
            return Center(
              child: new Text('Loading :)'),
            );
          }
        }
      },
    );
  }

  Future<String> makeRequest(String url) async {
    var response = await http.get(Uri.encodeFull(url), headers: {"Accept": "Application/json"});
    print(response.body);
    if (!loaded) {
      setState(() {
        _data = json.decode(response.body)['data']['children'];
        loaded = true;
        _after = json.decode(response.body)['data']['after'];
      });
    } else {
      setState(() {
        _data.addAll(json.decode(response.body)['data']['children']);
        _after = json.decode(response.body)['data']['after'];
      });
    }
  }

  Widget _buildTile(BuildContext context, var a, b, c, d) {
    var author = a;
    var title  = b;
    var sub    = c;
    var score  = d;

    // is_video, is_self, stickied, visited, locked, spoiler, can_gild, over_18, pinned, archived, edited, clicked, saved, hidden,
    return Slidable(
      child: new Container(
        child: new ListTile(
          title: Text(title),
          subtitle: Text("$author - $score - $sub"),
        ),
      ),
      delegate: new SlidableStrechDelegate(),
      actionExtentRatio: 0.75,
      actions: <Widget>[
        new IconSlideAction(
          icon: Icons.keyboard_arrow_down,
          caption: "Downvote",
          color: Colors.blue,
          onTap: () => _showSnack(context, 'Downvoted.'),
        ),
      ],
      secondaryActions: <Widget>[
        new IconSlideAction(
          icon: Icons.keyboard_arrow_up,
          caption: "Upvote",
          color: Colors.deepOrange,
          onTap: () => _showSnack(context, 'Upvoted!'),
        )
      ],
    );
    return ListTile(
      title: Text(title),
      subtitle: Text("$author - $score - $sub"),
    );
  }

  _showSnack(BuildContext context, String text) {
    final scaffold = Scaffold.of(context);
    scaffold.showSnackBar(
      SnackBar(
        content: Text('$text')
      )
    );
  }
}

class Post {
  final String author;
  final String sub;
  final String title;
  final int score;
  
  Post({this.author, this.sub, this.title, this.score});
  
  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      author: json['data']['author'],
      sub: json['data']['subreddit'],
      title: json['data']['title'],
      score: json['data']['score']
    );
  }
}