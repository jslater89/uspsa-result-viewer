import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter
import 'package:uspsa_result_viewer/html_or/html_or.dart';

import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:uspsa_result_viewer/data/practiscore_parser.dart';
import 'package:uspsa_result_viewer/main.dart';
import 'package:uspsa_result_viewer/route/practiscore_url.dart';
import 'package:uspsa_result_viewer/ui/empty_scaffold.dart';

class MatchSelectPage extends StatefulWidget {
  @override
  _MatchSelectPageState createState() => _MatchSelectPageState();
}

class _MatchSelectPageState extends State<MatchSelectPage> {
  late BuildContext _innerContext;
  bool _operationInProgress = false;
  bool _launchingFromParam = false;

  @override
  void initState() {
    super.initState();

    if(globals.practiscoreId != null) {
      _launchingFromParam = true;
      _launchPresetPractiscore(url: "https://practiscore.com/results/new/${globals.practiscoreId}");
    }
    else if(globals.practiscoreUrl != null) {
      _launchingFromParam = true;
      _launchPresetPractiscore(url: globals.practiscoreUrl);
    }
    else if(globals.resultsFileUrl != null) {
      _launchingFromParam = true;
      _launchNonPractiscoreFile(url: globals.resultsFileUrl!);
    }
  }

  void _launchPresetPractiscore({String? url}) async {
    var matchId = await _getMatchId(presetUrl: url);
    if(matchId != null) {
      HtmlOr.navigateTo(context, "/web/$matchId");
    }
  }

  void _launchNonPractiscoreFile({required String url}) async {
    var urlBytes = Base64Codec.urlSafe().encode(url.codeUnits);
    HtmlOr.navigateTo(context, "/webfile/$urlBytes");
  }

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;

    return EmptyScaffold(
      operationInProgress: _operationInProgress,
      onInnerContextAssigned: (context) {
        _innerContext = context;
      },
      child: _launchingFromParam ? Center(child: Text("Launching...")) : SizedBox(
        height: size.height,
        width: size.width,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () async {
                _uploadResultsFile((contents) async {
                  if(contents != null) {
                    await Navigator.of(context).pushNamed('/local', arguments: contents);
                  }
                  else {
                    debugPrint("Null file contents");
                  }
                });
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(height: 150),
                  Icon(Icons.cloud_upload, size: 230, color: Colors.grey,),
                  Text("Click to upload a report.txt file from your device", style: Theme
                      .of(context)
                      .textTheme
                      .subtitle1!
                      .apply(color: Colors.grey)),
                ],
              ),
            ),
            GestureDetector(
              onTap: () async {
                setState(() {
                  _operationInProgress = true;
                });
                var matchId = await _getMatchId();
                setState(() {
                  _operationInProgress = false;
                });

                if(matchId != null) {
                  await Navigator.of(context).pushNamed('/web/$matchId');
                }
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(height: 150),
                  Icon(Icons.cloud_download, size: 230, color: Colors.grey,),
                  Text("Click to download a report.txt file from PractiScore", style: Theme
                      .of(context)
                      .textTheme
                      .subtitle1!
                      .apply(color: Colors.grey)),
                ],
              ),
            ),
          ],
        ),
      )
    );
  }

  Future<void> _uploadResultsFile(Function(String?) onFileContents) async {
    HtmlOr.pickAndReadFile(context, onFileContents);
  }

  Future<String?> _getMatchId({String? presetUrl}) async {
    var proxyUrl = getProxyUrl();

    var matchUrl = presetUrl ?? await showDialog<String>(context: context, builder: (context) {
      var controller = TextEditingController();
      return AlertDialog(
        title: Text("Enter PractiScore match URL"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Copy the URL to the match's PractiScore results page and paste it in the field below.",
              softWrap: true,),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: "https://practiscore.com/results/new/...",
              ),
            ),
          ],
        ),
        actions: [
          FlatButton(
              child: Text("CANCEL"),
              onPressed: () {
                Navigator.of(context).pop();
              }
          ),
          FlatButton(
              child: Text("OK"),
              onPressed: () {
                Navigator.of(context).pop(controller.text);
              }
          ),
        ],
      );
    });

    if(matchUrl == null) {
      return null;
    }

    var matchUrlParts = matchUrl.split("/");
    var matchId = matchUrlParts.last;

    // It's probably a short ID—the long IDs are UUID-style, with dashes separating
    // blocks of alphanumeric characters
    if(!matchId.contains(r"-")) {
      try {
        debugPrint("Trying to get match from URL: $matchUrl");
        var response = await http.get(Uri.parse("$proxyUrl$matchUrl"));
        if(response.statusCode == 404) {
          Scaffold.of(_innerContext).showSnackBar(SnackBar(content: Text("Match not found.")));
          return null;
        }
        else if(response.statusCode == 200) {
          var foundUrl = getPractiscoreWebReportUrl(response.body);
          if(foundUrl != null) {
            matchId = foundUrl.split("/").last;
          }
          else {
            Scaffold.of(_innerContext).showSnackBar(SnackBar(content: Text("Unable to determine web report URL.")));
            return null;
          }
        }
        else {
          debugPrint("${response.statusCode} ${response.body}");
          Scaffold.of(_innerContext).showSnackBar(SnackBar(content: Text("Unable to download match file.")));
          return null;
        }
      }
      catch(err) {
        debugPrint("$err");
        Scaffold.of(_innerContext).showSnackBar(SnackBar(content: Text("Unable to download match file.")));
        return null;
      }
    }

    return matchId;
  }
}