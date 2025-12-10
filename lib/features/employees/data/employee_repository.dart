import 'dart:developer' as developer;

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/api/api_client.dart';
import '../../../core/database/app_database.dart';
import 'employee_model.dart';

part 'employee_repository.g.dart';

// Provider for ApiClient
@riverpod
ApiClient apiClient(Ref ref) {
  return ApiClient();
}

// Provider for EmployeeApi
@riverpod
EmployeeApi employeeApi(Ref ref) {
  final apiClient = ref.watch(apiClientProvider);
  return EmployeeApi(apiClient);
}

// Provider for AppDatabase
@riverpod
AppDatabase appDatabase(Ref ref) {
  return AppDatabase();
}

// Provider for EmployeeRepository
@riverpod
EmployeeRepository employeeRepository(Ref ref) {
  final database = ref.watch(appDatabaseProvider);
  final api = ref.watch(employeeApiProvider);
  return EmployeeRepository(database, api);
}

// Repository implementing Optimistic UI pattern for Employee CRUD operations
class EmployeeRepository {
  final AppDatabase _database;
  final EmployeeApi _api;

  EmployeeRepository(this._database, this._api);

  // Fetches employees from DB immediately while sinking with API in background
  Stream<List<Employee>> fetchEmployees() {
    // Start background API fetch (unawaited)
    _fetchAndUpdateFromApi();

    // Return stream from database immediately
    return _database.watchAllEmployees();
  }

  // Background fetch from API and update database
  Future<void> _fetchAndUpdateFromApi() async {
    try {
      final response = await _api.getEmployees();

      // Parse API response
      // The API returns: { "status": "success", "data": [...] }
      if (response['status'] == 'success' && response['data'] != null) {
        final employeesData = response['data'] as List;

        // Clear existing data and insert fresh data from API
        await _database.transaction(() async {
          // Delete all existing employees
          await _database.delete(_database.employees).go();

          // Insert all employees from API
          for (final employeeJson in employeesData) {
            final employee = _parseEmployeeFromApi(employeeJson);
            await _database.insertEmployee(employee);
          }
        });
      }
    } catch (e) {
      // Silently fail - the stream will continue showing local data
      developer.log(
        '⚠️ Background API fetch failed: ',
        name: 'EmployeeRepository',
        error: e,
      );
    }
  }

  // Creates employee using optimistic UI: insert locally first, then sync with API
  Future<Employee> createEmployee(Employee employee) async {
    // Optimistic insert
    final optimisticEmployee = employee.copyWith(isSynced: false);
    final tempId = await _database.insertEmployee(optimisticEmployee);

    try {
      // Call API
      final response = await _api.createEmployee({
        'name': employee.name,
        'age': employee.age,
        'salary': employee.salary,
      });

      // Update with real ID from server
      if (response['status'] == 'success' && response['data'] != null) {
        final serverEmployee = _parseEmployeeFromApi(response['data']);

        // Delete the temporary entry
        await _database.deleteEmployee(tempId);

        // Insert with real server ID and isSynced = true
        final syncedEmployee = serverEmployee.copyWith(isSynced: true);
        await _database.insertEmployee(syncedEmployee);

        return syncedEmployee;
      } else {
        throw Exception('Failed to create employee: Invalid API response');
      }
    } catch (e) {
      // Revert the optimistic insert
      await _database.deleteEmployee(tempId);
      rethrow;
    }
  }

  // Updates employee with optimistic UI pattern
  Future<Employee> updateEmployee(Employee employee) async {
    if (employee.id == null) {
      throw ArgumentError('Employee id cannot be null for update');
    }

    // Store original employee for rollback
    Employee? originalEmployee;
    try {
      // Get original employee from database for potential rollback
      final allEmployees = await _database.watchAllEmployees().first;
      originalEmployee = allEmployees.firstWhere(
        (e) => e.id == employee.id,
        orElse: () => throw Exception('Employee not found in database'),
      );
    } catch (e) {
      throw Exception('Failed to get original employee for update: $e');
    }

    try {
      // Optimistic update
      final optimisticEmployee = employee.copyWith(isSynced: false);
      await _database.updateEmployee(optimisticEmployee);

      // Call API
      final response = await _api.updateEmployee(employee.id!, {
        'name': employee.name,
        'age': employee.age,
        'salary': employee.salary,
      });

      // Update sync status on success
      if (response['status'] == 'success') {
        final syncedEmployee = employee.copyWith(isSynced: true);
        await _database.updateEmployee(syncedEmployee);
        return syncedEmployee;
      } else {
        throw Exception('Failed to update employee: Invalid API response');
      }
    } catch (e) {
      // Rollback to original data
      await _database.updateEmployee(originalEmployee);
      rethrow;
    }
  }

  // Deletes employee with optimistic UI pattern
  Future<void> deleteEmployee(int id) async {
    // Store employee for potential re-insertion
    Employee? deletedEmployee;
    try {
      // Get employee before deletion for potential rollback
      final allEmployees = await _database.watchAllEmployees().first;
      deletedEmployee = allEmployees.firstWhere(
        (e) => e.id == id,
        orElse: () => throw Exception('Employee not found in database'),
      );
    } catch (e) {
      throw Exception('Failed to get employee for deletion: $e');
    }

    try {
      // Delete from DB immediately
      await _database.deleteEmployee(id);

      // Call API
      final response = await _api.deleteEmployee(id);

      // Check if deletion was successful
      if (response['status'] != 'success') {
        throw Exception('Failed to delete employee: Invalid API response');
      }

      // Success - deletion is complete
    } catch (e) {
      // Re-insert the employee
      await _database.insertEmployee(deletedEmployee);
      rethrow;
    }
  }

  // Helper method to parse Employee from API response
  Employee _parseEmployeeFromApi(dynamic data) {
    // API returns: { "id": "1", "employee_name": "...", "employee_age": "...", "employee_salary": "..." }
    // or: { "id": 1, "name": "...", "age": ..., "salary": ... }

    final id = data['id'] is String
        ? int.tryParse(data['id'])
        : data['id'] as int?;

    final name =
        data['employee_name'] as String? ?? data['name'] as String? ?? '';

    final age = data['employee_age'] is String
        ? int.tryParse(data['employee_age']) ?? 0
        : data['employee_age'] as int? ?? data['age'] as int? ?? 0;

    final salary = data['employee_salary'] is String
        ? int.tryParse(data['employee_salary']) ?? 0
        : data['employee_salary'] as int? ?? data['salary'] as int? ?? 0;

    return Employee(
      id: id,
      name: name,
      age: age,
      salary: salary,
      isSynced: true,
    );
  }
}
