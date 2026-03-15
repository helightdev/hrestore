import 'dart:async';
import 'dart:collection';
import 'dart:io';

import 'package:hrestore/execution.dart';
import 'package:hrestore/globals.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:toml/toml.dart';
import 'package:path/path.dart' as path;

Future main(List<String> arguments) async {
  final logger = Logger();
  var map = <String, dynamic>{};
  var orderedArgs = arguments.toList();
  orderedArgs.sort((a, b) {
    var ap = priorityByFilename(a);
    var bp = priorityByFilename(b);
    if (ap != bp) {
      return -ap.compareTo(bp);
    } else {
      return 0;
    }
  });

  for (var file in orderedArgs) {
    final fileMap = TomlDocument.loadSync(file).toMap();
    map.addAll(fileMap);
  }

  logger.info("Found following blocks: [${map.keys.join(', ')}]");
  var doContinue = logger.confirm("Proceed with restoration?");
  if (!doContinue) {
    logger.info('Aborting restoration.');
    return;
  }

  logger.info('Trying to restore blocks...');
  for (final entry in map.entries) {
    await runCatching(logger, () async {
      final key = entry.key;
      final value = entry.value;
      if (value is Map<String, dynamic>) {
        await execute(logger, key, value);
      }
    });
  }
  logger.info('All done!');
}

RegExp fileNamePriorityRegex = RegExp(r'^(\d+)_');

int priorityByFilename(String name) {
  name = path.basename(name);
  var match = fileNamePriorityRegex.matchAsPrefix(name);
  if (match != null) {
    return int.parse(match.group(1)!);
  } else {
    return name.startsWith("_") ? 1 : 0;
  }
}
