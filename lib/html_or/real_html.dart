import 'dart:convert';
import 'dart:html';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:uspsa_result_viewer/html_or/html_or.dart';

Controller _controller = Controller();
Controller get controller => _controller;

class Controller extends ControlInterface {
  @override
  void navigateTo(String namedRoute) {
    window.location.href = "$redirectRoot#$namedRoute";
  }

  @override
  Map<String, String> getQueryParams() {
    return Uri.parse(window.location.href).queryParameters;
  }

  @override
  void pickAndReadFile(Function(String? p1) onFileContents) async {
    var result = await FilePicker.platform.pickFiles();
    if(result != null) {
      var f = result.files[0];
      onFileContents(Utf8Decoder().convert(f.bytes?.toList() ?? []));
    }
    else {
    onFileContents(null);
    }
  }

  @override
  bool get needsProxy => true;
}