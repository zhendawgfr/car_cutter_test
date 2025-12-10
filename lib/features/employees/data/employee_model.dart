import 'package:freezed_annotation/freezed_annotation.dart';

part 'employee_model.freezed.dart';
part 'employee_model.g.dart';

@freezed
abstract class Employee with _$Employee {
  const factory Employee({
    int? id,
    required String name,
    required int age,
    required int salary,
    @Default(true) bool isSynced,
  }) = _Employee;

  factory Employee.fromJson(Map<String, dynamic> json) =>
      _$EmployeeFromJson(json);
}
