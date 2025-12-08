import 'dart:async';

import 'package:hrestore/execution.dart';
import 'package:hrestore/globals.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:toml/toml.dart';

Future main(List<String> arguments) async {
  final logger = Logger();
  var map = {};
  for (var file in arguments) {
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
