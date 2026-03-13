import 'package:mason_logger/mason_logger.dart';

import 'globals.dart';

Future execute(Logger logger, String key, Map<String, dynamic> data) async {
  logger.info(styleBold.wrap("Executing block '$key'..."));
  if (data['command_target'] != null) {
    var condition = data['command_target'].toString();
    var exists = await commandExists(condition);
    if (exists) {
      logger.info(
        "Skipping block '$key' because command '$condition' aleady exists.",
      );
      return true;
    }
  }

  var environment = (data['environment'] as Map<String, dynamic>?)?.map(
    (key, value) => MapEntry(key, value.toString()),
  );
  bool isInteractive = data['interactive'] as bool? ?? false;
  bool isTemplate = data['template'] as bool? ?? false;
  ExecBlock exec = switch (data['exec']) {
    String s => ExecBlock(
      lines: [s],
      isInteractive: isInteractive,
      isTemplate: isTemplate,
      environment: environment,
    ),
    List<dynamic> l => ExecBlock(
      lines: l.map((e) => e.toString()).toList(),
      isInteractive: isInteractive,
      isTemplate: isTemplate,
      environment: environment,
    ),
    _ => throw ArgumentError('Invalid exec type for $key'),
  };
  var list = data['list'] as List<dynamic>?;
  if (list != null) {
    var join = data['list_join']?.toString();
    if (join != null) {
      var joined = list.map((e) => e.toString()).join(join);
      return await exec.runItem(logger, joined);
    } else {
      for (var item in list) {
        await exec.runItem(logger, item.toString());
      }
    }
  } else {
    return await exec.run(logger);
  }
}

class ExecBlock {
  List<String> lines;
  bool isInteractive;
  bool isTemplate;
  Map<String, String>? environment;

  ExecBlock({
    required this.lines,
    this.isInteractive = false,
    this.isTemplate = false,
    this.environment,
  });

  Future<bool> run(Logger logger) async {
    bool result = true;
    for (final line in lines) {
      if (isInteractive) {
        result = await runCommandInteractive(
          logger,
          line,
          environment: environment,
        );
      } else {
        result = await runCommand(logger, line, environment: environment);
      }
      if (!result) return false;
    }
    return result;
  }

  Future runItem(Logger logger, String item) async {
    bool result = true;
    var first = true;
    for (final line in lines) {
      String command = line;
      if (isTemplate) {
        command = line.replaceAll("{{item}}", item);
      } else if (first) {
        command = "$line $item";
      }
      first = false;

      if (isInteractive) {
        result = await runCommandInteractive(
          logger,
          command,
          environment: environment,
        );
      } else {
        result = await runCommand(logger, command, environment: environment);
      }
      if (!result) return false;
    }
    return result;
  }
}
