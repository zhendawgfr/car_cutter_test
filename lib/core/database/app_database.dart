import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../../features/employees/data/employee_model.dart' as model;

part 'app_database.g.dart';

// Employee table schema
@DataClassName('EmployeeEntity')
class Employees extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  IntColumn get age => integer()();
  IntColumn get salary => integer()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(true))();
}

// Database with employee CRUD operations
@DriftDatabase(tables: [Employees])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  // DAO Methods

  // Stream of all employees
  Stream<List<model.Employee>> watchAllEmployees() {
    return select(employees).watch().map((rows) {
      return rows.map((EmployeeEntity row) {
        return model.Employee(
          id: row.id,
          name: row.name,
          age: row.age,
          salary: row.salary,
          isSynced: row.isSynced,
        );
      }).toList();
    });
  }

  // Insert a new employee
  Future<int> insertEmployee(model.Employee employee) {
    return into(employees).insert(
      EmployeesCompanion.insert(
        name: employee.name,
        age: employee.age,
        salary: employee.salary,
        isSynced: Value(employee.isSynced),
        id: employee.id != null ? Value(employee.id!) : const Value.absent(),
      ),
    );
  }

  // Update an existing employee
  Future<bool> updateEmployee(model.Employee employee) {
    if (employee.id == null) {
      throw ArgumentError('Employee id cannot be null for update');
    }

    return update(employees).replace(
      EmployeesCompanion(
        id: Value(employee.id!),
        name: Value(employee.name),
        age: Value(employee.age),
        salary: Value(employee.salary),
        isSynced: Value(employee.isSynced),
      ),
    );
  }

  // Delete an employee by id
  Future<int> deleteEmployee(int id) {
    return (delete(employees)..where((tbl) => tbl.id.equals(id))).go();
  }
}

// Opens the database connection
QueryExecutor _openConnection() {
  return driftDatabase(name: 'employee_database');
}
