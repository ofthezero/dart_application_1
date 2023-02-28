import 'package:dart_application_1/models/db/logger_model.dart';
import 'package:dart_application_1/models/db/user_model.dart';
import 'package:conduit/conduit.dart';

abstract class LogHistory {
  static Future<void> writeLog(
          {required String description,
          required User owner,
          required ManagedContext context}) async =>
      await context.transaction(
          (transaction) async => await (Query<LogsEntity>(transaction)
                ..values.owner = owner
                ..values.operationDate = DateTime.now()
                ..values.description = description)
              .insert());
}
