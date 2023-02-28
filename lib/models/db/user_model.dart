import 'package:dart_application_1/models/db/logger_model.dart';
import 'package:conduit/conduit.dart';

class User extends ManagedObject<_User> implements _User {}

class _User {
  @primaryKey
  int? id;
  @Column(unique: true, indexed: true)
  String? userName;
  @Column(unique: true, indexed: true)
  String? email;
  @Serialize(input: true, output: false)
  String? password;
  @Column(nullable: true)
  String? accesTokent;
  @Column(nullable: true)
  String? refreshTokent;

  @Column(omitByDefault: true)
  String? salt;
  @Column(omitByDefault: true)
  String? hashedPassword;

  ManagedSet<Marks>? marks;

  ManagedSet<LogsEntity>? logs;
}

class Marks extends ManagedObject<_Marks> implements _Marks {}

class _Marks {
  @primaryKey
  int? id;
  @Column()
  String? name;
  @Column()
  String? content;
  @Column()
  String? cathegory;
  @Column(defaultValue: "now()", indexed: true)
  DateTime? createDate;
  @Column(defaultValue: "now()", indexed: true)
  DateTime? editDate;
  @Column(defaultValue: "true")
  bool? isntDeleted;
  @Relate(#marks, onDelete: DeleteRule.cascade, isRequired: true)
  User? creator;
}
