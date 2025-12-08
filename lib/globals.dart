import 'dart:async';
import 'dart:io';

import 'package:io/io.dart';
import 'package:mason_logger/mason_logger.dart';

Future runCatching(Logger logger, FutureOr Function() func) async {
  final completer = Completer<void>();
  runZonedGuarded(
    () async {
      await func();
      completer.complete();
    },
    (error, stack) {
      try {
        if (error is ArgumentError) {
          logger.err(error.message);
          exitCode = ExitCode.usage.code;
        } else if (error is FormatException) {
          logger.err('Format error: ${error.message}');
          exitCode = ExitCode.data.code;
        } else if (error is IOException) {
          logger.err('I/O error: $error');
          exitCode = ExitCode.ioError.code;
        } else {
          logger.err('Zone Error: $error');
          logger.err('Stack Trace:\n$stack');
          exitCode = ExitCode.software.code;
        }
      } finally {
        if (!completer.isCompleted) {
          completer.completeError(error, stack);
        }
      }
    },
  );

  return completer.future;
}

Future<bool> runCommand(
  Logger? logger,
  String command, {
  bool useProgress = true,
  Map<String, String>? environment,
}) async {
  var commands = shellSplit(command);
  if (commands.isEmpty) {
    logger?.err('Excepted non empty command');
    return false;
  }
  Progress? progress;
  if (useProgress) progress = logger?.progress("Running command '$command'");
  try {
    var result = await Process.run(
      "/bin/bash",
      [
        "-c",
        """
bash << 'EOF'
$command
EOF
""",
      ],
      runInShell: true,
      includeParentEnvironment: true,
      environment: environment,
    );
    var exitCode = result.exitCode;
    if (exitCode != 0) {
      progress?.fail('Command failed with exit code $exitCode');
      logger?.detail(result.stdout);
      logger?.err(result.stderr);
      return false;
    }
    progress?.complete();
  } catch (e) {
    progress?.fail('Command failed with error');
    rethrow;
  }
  return true;
}

Future<bool> runCommandInteractive(
  Logger? logger,
  String command, {
  Map<String, String>? environment,
}) async {
  var commands = shellSplit(command);
  if (commands.isEmpty) {
    logger?.err('Excepted non empty command');
    return false;
  }
  logger?.detail("Running command '$command' interactively");
  try {
    var process = await Process.start(
      "/bin/bash",
      [
        "-c",
        """
bash << 'EOF'
$command
EOF
""",
      ],
      runInShell: true,
      includeParentEnvironment: true,
      mode: ProcessStartMode.inheritStdio,
      environment: environment,
    );
    var exitCode = await process.exitCode;
    if (exitCode != 0) {
      logger?.err('Command failed with exit code $exitCode');
      return false;
    }
  } catch (e) {
    logger?.err('Command failed with error: $e');
    return false;
  }
  return true;
}

Future<bool> commandExists(String command) async {
  return await runCommand(null, "command -v $command");
}
