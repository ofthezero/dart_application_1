import 'dart:io';

import 'package:dart_application_1/models/db/user_model.dart';
import 'package:dart_application_1/models/service/logger.dart';
import 'package:dart_application_1/utils/app_utils.dart';
import 'package:conduit/conduit.dart';

class AppUserController extends ResourceController {
  AppUserController(this.context);

  final ManagedContext context;

  @Operation.get()
  Future<Response> getUserByID(
      @Bind.header(HttpHeaders.authorizationHeader) String header) async {
    try {
      final userId = AppsUtils.getIdFromHeader(header);
      var currentUser = await context.fetchObjectWithID<User>(userId);

      if (currentUser == null) {
        return Response.serverError(body: "Пользователь не найден");
      }

      currentUser
          .removePropertiesFromBackingMap(['refreshToken', 'accessToken']);

      LogHistory.writeLog(
          description: "Получение списка пользователей по ID",
          owner: currentUser,
          context: context);

      return Response.ok(currentUser.asMap());
    } on QueryException catch (e) {
      return Response.serverError(body: e.message);
    }
  }

  @Operation.post()
  Future<Response> editUser(@Bind.body() User user,
      @Bind.header(HttpHeaders.authorizationHeader) String header) async {
    try {
      final id = AppsUtils.getIdFromHeader(header);

      final foundedUser = await context.fetchObjectWithID<User>(id);

      if (foundedUser == null) {
        return Response.serverError(body: "Пользователь не найден");
      }
      final qUpdateUser = Query<User>(context)
        ..where((x) => x.id).equalTo(id)
        ..values.userName = user.userName ?? foundedUser.userName
        ..values.email = user.email ?? foundedUser.email;
      await qUpdateUser.updateOne();

      final findUser = await context.fetchObjectWithID<User>(id);

      findUser!.removePropertiesFromBackingMap(['refreshToken', 'accessToken']);
      LogHistory.writeLog(
          description: "Изменение данных пользователя",
          owner: foundedUser,
          context: context);
      return Response.ok(findUser.asMap());
    } on QueryException catch (e) {
      return Response.serverError(body: e.message);
    }
  }
}
