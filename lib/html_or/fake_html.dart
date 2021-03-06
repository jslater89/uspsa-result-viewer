import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:uspsa_result_viewer/html_or/html_or.dart';

Controller _controller = Controller();
Controller get controller => _controller;

class Controller extends ControlInterface {
  @override
  void navigateTo(String namedRoute) {
    Navigator.of(HtmlOr.lastContext).pushNamed(namedRoute);
  }

  @override
  Map<String, String> getQueryParams() {
    return {};
  }

  @override
  void pickAndReadFile(Function(String? p1) onFileContents) async {
    var result = await FilePicker.platform.pickFiles();
    if(result != null) {
      var f = result.files[0];
      var nativeFile = File(f.path ?? "/error!");
      debugPrint("File: ${nativeFile.path} ${await nativeFile.length()}");
      onFileContents(await nativeFile.readAsString());
    }
    else {
    onFileContents(null);
    }
  }

  @override
  bool get needsProxy => false;
}