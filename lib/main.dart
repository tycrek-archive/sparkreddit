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
  var _initial = false;
  var _loadingNew = false;
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
    if (!_initial) {
      makeRequest('https://old.reddit.com/hot/.json?limit=50');
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
          print(_after);
          print(_data.length);
          print(index);
          if (index >= _data.length - 30 && !_loadingNew) {
            _loadingNew = true;
            print('!! Loading new posts');
            makeRequest('https://old.reddit.com/hot/.json?limit=50&after=$_after');
          }
          try {
            var data = _data[index]['data'];
            return _buildTile(context, data);
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
    if (!_initial) {
      setState(() {
        _data = json.decode(response.body)['data']['children'];
        _initial = true;
        _after = json.decode(response.body)['data']['after'];
      });
    } else {
      setState(() {
        _data.addAll(json.decode(response.body)['data']['children']);
        _after = json.decode(response.body)['data']['after'];
        _loadingNew = false;
      });
    }
  }

  Widget _buildTile(BuildContext context, var data) {
    var author = data['author'];
    var title  = data['title'];
    var sub    = data['subreddit'];
    var score  = data['score'];

    var post_hint = data['post_hint']; //image, self

    // is_video, is_self, stickied, visited, locked, spoiler, can_gild, over_18, pinned, archived, edited, clicked, saved, hidden, post_hint
    return Slidable(
      child: new Container(
        child: new ListTile(
          title: Text(title),
          subtitle: _buildSubtitle(context, data),
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
  }

  Widget _buildSubtitle(BuildContext context, var data) {
    if (data['post_hint'] == 'self') {
      return Row(
        children: <Widget>[
          Expanded(child: Text(data['author'])),
          Expanded(child: Text(data['score'].toString())),
          Expanded(child: Text(data['subreddit_name_prefixed']))
        ],
      );
    } else if (data['post_hint'] == 'image') {
      return Column(
        children: <Widget>[
          FadeInImage.assetNetwork(
            placeholder: 'assets/loading.gif',
            image: data['url'],
            fadeInDuration: const Duration(milliseconds: 2),
          ),
          Row(
            children: <Widget>[
              Expanded(child: Text(data['author'])),
              Expanded(child: Text(data['score'].toString())),
              Expanded(child: Text(data['subreddit_name_prefixed']))
            ],
          )
        ],
      );
    }
    return Row(
      children: <Widget>[
        Expanded(child: Text(data['author'])),
        Expanded(child: Text(data['score'].toString())),
        Expanded(child: Text(data['subreddit_name_prefixed']))
      ],
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