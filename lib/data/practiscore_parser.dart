import 'package:collection/collection.dart' show IterableExtension;

String getClubNameToken(String source) {
  var tokenLine = source.split("\n").firstWhere((element) => element.startsWith('<meta name="csrf-token"'), orElse: () => "");
  var token = tokenLine.split('"')[3];
  return token;
}

String? getPractiscoreWebReportUrl(String source) {
  var webReportLine = source.split("\n").firstWhere((element) => element.contains("/reports/web"));
  return webReportLine.split('"').firstWhereOrNull((element) => element.contains("reports/web"));
}