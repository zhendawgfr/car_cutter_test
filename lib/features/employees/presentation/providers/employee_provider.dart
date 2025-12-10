import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/employee_model.dart';
import '../../data/employee_repository.dart';

part 'employee_provider.g.dart';

// Stream of all employees from repository
@riverpod
Stream<List<Employee>> employeeList(Ref ref) {
  final repository = ref.watch(employeeRepositoryProvider);
  return repository.fetchEmployees();
}

// Stream of single employee by ID
@riverpod
Stream<Employee?> employeeById(Ref ref, int id) {
  final employeeListStream = ref.watch(employeeListProvider);

  return employeeListStream.when(
    data: (employees) {
      try {
        final employee = employees.firstWhere((e) => e.id == id);
        return Stream.value(employee);
      } catch (e) {
        return Stream.value(null);
      }
    },
    loading: () => Stream.value(null),
    error: (_, _) => Stream.value(null),
  );
}

// Manages employee mutations (create, update, delete)
@riverpod
class EmployeeMutations extends _$EmployeeMutations {
  @override
  FutureOr<void> build() {
    // No initial state needed
  }

  // Creates employee with optimistic UI pattern
  Future<Employee> createEmployee(Employee employee) async {
    state = const AsyncLoading();

    try {
      final repository = ref.read(employeeRepositoryProvider);
      final createdEmployee = await repository.createEmployee(employee);

      if (!ref.mounted) return createdEmployee;

      state = const AsyncData(null);
      return createdEmployee;
    } catch (error, stackTrace) {
      if (!ref.mounted) rethrow;

      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }

  // Updates employee with optimistic UI pattern
  Future<Employee> updateEmployee(Employee employee) async {
    state = const AsyncLoading();

    try {
      final repository = ref.read(employeeRepositoryProvider);
      final updatedEmployee = await repository.updateEmployee(employee);

      if (!ref.mounted) return updatedEmployee;

      state = const AsyncData(null);
      return updatedEmployee;
    } catch (error, stackTrace) {
      if (!ref.mounted) rethrow;

      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }

  // Deletes employee with optimistic UI pattern
  Future<void> deleteEmployee(int id) async {
    state = const AsyncLoading();

    try {
      final repository = ref.read(employeeRepositoryProvider);
      await repository.deleteEmployee(id);

      if (!ref.mounted) return;

      state = const AsyncData(null);
    } catch (error, stackTrace) {
      if (!ref.mounted) rethrow;

      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }
}
