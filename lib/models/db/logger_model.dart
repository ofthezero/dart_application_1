import 'package:dart_application_1/models/db/user_model.dart';
import 'package:conduit/conduit.dart';

class LogsEntity extends ManagedObject<_Logs> implements _Logs {}

class _Logs {
  @primaryKey
  int? id;
  @Column(indexed: true)
  DateTime? operationDate;
  @Column(nullable: false)
  String? description;

  @Relate(#logs)
  User? owner;
}
