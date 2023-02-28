import 'dart:ffi';
import 'dart:io';

import 'package:dart_application_1/models/db/user_model.dart';
import 'package:dart_application_1/models/service/logger.dart';
import 'package:dart_application_1/utils/app_response.dart';
import 'package:dart_application_1/utils/app_utils.dart';
import 'package:conduit/conduit.dart';

class AppOperationController extends ResourceController {
  AppOperationController(this.context);
  ManagedContext context;

  @Operation.get("page")
  Future<Response> getMarks(@Bind.path("page") int page,
      @Bind.header(HttpHeaders.authorizationHeader) String header) async {
    var id = AppsUtils.getIdFromHeader(header);
    var currentOperations = await (Query<Marks>(context)
          ..returningProperties(
              (x) => [x.name, x.content, x.cathegory, x.createDate, x.editDate])
          ..where((x) => x.isntDeleted).equalTo(true)
          ..where((x) => x.creator!.id).equalTo(id)
          ..sortBy((x) => x.createDate, QuerySortOrder.descending)
          ..offset = page * 20
          ..fetchLimit = 20)
        .fetch();
    if (currentOperations.isEmpty) {
      return Response.noContent();
    }
    var listToReturn = currentOperations.map((e) => e.asMap()).toList();
    var currentUser = await context.fetchObjectWithID<User>(id);
    LogHistory.writeLog(
        description: "Осуществление вывода страницы $page операций",
        owner: currentUser!,
        context: context);
    return Response.ok(listToReturn);
  }

  @Operation.get()
  Future<Response> searchMark(
      @Bind.header(HttpHeaders.authorizationHeader) String header,
      {@Bind.query('name') String? markName}) async {
    var currentOperations = await (Query<Marks>(context)
          ..returningProperties(
              (x) => [x.name, x.content, x.cathegory, x.createDate, x.editDate])
          ..where((x) => x.isntDeleted).equalTo(true)
          ..where((x) => x.name).contains(markName ?? '')
          ..sortBy((x) => x.createDate, QuerySortOrder.descending))
        .fetch();
    if (currentOperations.isEmpty) {
      return Response.noContent();
    }
    var id = AppsUtils.getIdFromHeader(header);
    var listToReturn = currentOperations.map((e) => e.asMap()).toList();
    var currentUser = await context.fetchObjectWithID<User>(id);
    LogHistory.writeLog(
        description: markName == null
            ? "Осуществление вывода всех заметок"
            : "Осуществление поиска замток по ключевому слову '$markName'",
        owner: currentUser!,
        context: context);
    return Response.ok(listToReturn);
  }

  @Operation.post()
  Future<Response> addMark(
    @Bind.header(HttpHeaders.authorizationHeader) String header,
    @Bind.body() Marks mark,
  ) async {
    try {
      if (mark.name!.isEmpty ||
          mark.cathegory!.isEmpty ||
          mark.content!.isEmpty) {
        return Response.serverError(
            body: "Введённые данные не корректны, проверьте что вы ввели");
      }
      var id = AppsUtils.getIdFromHeader(header);
      var posted = await context.fetchObjectWithID<User>(id);
      if (posted == null) {
        return Response.serverError(
            body: "Извните, но у вас нет прав на данное действие");
      }

      var displayedData = await context.transaction<Marks>(
          (transaction) async => await (Query<Marks>(transaction)
                ..where((x) => x.isntDeleted).equalTo(true)
                ..values.createDate = DateTime.now()
                ..values.editDate = DateTime.now()
                ..values.name = mark.name
                ..values.cathegory = mark.cathegory
                ..values.creator = posted
                ..values.content = mark.content)
              .insert());
      LogHistory.writeLog(
          description: "Добавление заметки", owner: posted, context: context);
      return Response.ok(displayedData!.asMap());
    } on QueryException catch (e) {
      return Response.serverError(body: e.message);
    }
  }

  @Operation.put("page")
  Future<Response> editMark(
      @Bind.header(HttpHeaders.authorizationHeader) String header,
      @Bind.path("page") int id,
      @Bind.body() Marks mark) async {
    try {
      if (mark.name!.isEmpty ||
          mark.cathegory!.isEmpty ||
          mark.content!.isEmpty) {
        return Response.serverError(body: "Вы ввели данные не корректно");
      }
      var userId = AppsUtils.getIdFromHeader(header);
      var posted = await context.fetchObjectWithID<User>(userId);
      if (posted == null) {
        return Response.serverError(
            body: "Извните, но у вас нет прав на данное действие");
      }

      var displayedData = await context.transaction<Marks>((transaction) async {
        return await (Query<Marks>(transaction)
              ..where((x) => x.isntDeleted).equalTo(true)
              ..where((x) => x.id).equalTo(id)
              ..values.editDate = DateTime.now()
              ..values.content = mark.content
              ..values.name = mark.name
              ..values.cathegory = mark.cathegory)
            .updateOne();
      });
      LogHistory.writeLog(
          description: "Обновление замекти №$id",
          owner: posted,
          context: context);
      return Response.ok(displayedData!.asMap());
    } on QueryException catch (e) {
      return Response.serverError(body: e.response.body);
    }
  }

  @Operation.delete("page")
  Future<Response> deleteMark(
      @Bind.header(HttpHeaders.authorizationHeader) String header,
      @Bind.path("page") int id,
      {@Bind.query("logical") int? logical}) async {
    try {
      var userId = AppsUtils.getIdFromHeader(header);
      var posted = await context.fetchObjectWithID<User>(userId);
      if (posted == null) {
        return Response.serverError(
            body: "Извните, но у вас нет прав на данное действие");
      }
      await context.transaction<Marks>((transaction) async {
        late Future<dynamic> dataNeeded;
        if (logical != null) {
          dataNeeded =
              ((Query<Marks>(transaction)..where((x) => x.id).equalTo(id))
                    ..values.isntDeleted = logical == 1)
                  .updateOne();
        } else {
          dataNeeded = (Query<Marks>(transaction)
                ..where((x) => x.id).equalTo(id))
              .delete();
        }

        return await dataNeeded;
      });
      LogHistory.writeLog(
          description: logical != null
              ? "Логическое ${logical == 1 ? 'восстановление' : 'удаление'} заметки №$id"
              : "Удаление заметки №$id",
          owner: posted,
          context: context);
      return Response.noContent();
    } on QueryException catch (e) {
      return Response.serverError(body: e.response.body);
    }
  }
}
