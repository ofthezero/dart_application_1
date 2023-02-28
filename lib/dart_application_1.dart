import 'dart:developer';
import 'dart:io';

import 'package:dart_application_1/controllers/app_auth_controller.dart';
import 'package:dart_application_1/controllers/app_log_controller.dart';
import 'package:dart_application_1/controllers/app_marks_controller.dart';
import 'package:dart_application_1/controllers/app_token_controller.dart';
import 'package:dart_application_1/controllers/app_user_controller.dart';
import 'package:dart_application_1/models/service/response_model.dart';
import 'package:conduit/conduit.dart';

class AppService extends ApplicationChannel {
  late final ManagedContext managedContext;

  PostgreSQLPersistentStore _initDatabase() {
    final username = Platform.environment['DB_SERNAME'] ?? 'postgres';
    final password = Platform.environment['DB_PASSWORD'] ?? 'awerty';
    final host = Platform.environment['DB_HOST'] ?? '127.0.0.1';
    final port = int.parse(Platform.environment['DB_PORT'] ?? '5432');
    final databasename = Platform.environment['DB_NAME'] ?? 'postgres';

    return PostgreSQLPersistentStore(
        username, password, host, port, databasename);
  }

  @override
  Future prepare() {
    managedContext = ManagedContext(
        ManagedDataModel.fromCurrentMirrorSystem(), _initDatabase());
    return super.prepare();
  }

  @override
  Controller get entryPoint {
    var currentRouter = Router();
    currentRouter
        .route("token/[:refresh]")
        .link(() => AppAuthController(managedContext));
    currentRouter
        .route('user')
        .link(AppTokencontroller.new)!
        .link(() => AppUserController(managedContext));
    currentRouter.route('marks/[:page]').link(AppTokencontroller.new)!.link(() {
      return AppOperationController(managedContext);
    });
    currentRouter
        .route('log')
        .link(AppTokencontroller.new)!
        .link(() => AppLogController(managedContext));
    return currentRouter;
  }
}
