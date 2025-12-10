import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/api/api_client.dart';
import '../../data/employee_model.dart';
import '../providers/employee_provider.dart';

class EmployeeFormScreen extends ConsumerStatefulWidget {
  final int? employeeId;

  const EmployeeFormScreen({super.key, this.employeeId});

  @override
  ConsumerState<EmployeeFormScreen> createState() => _EmployeeFormScreenState();
}

class _EmployeeFormScreenState extends ConsumerState<EmployeeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _salaryController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.employeeId != null) {
      _loadEmployee();
    }
  }

  void _loadEmployee() {
    ref.listenManual(employeeByIdProvider(widget.employeeId!), (
      previous,
      next,
    ) {
      next.when(
        data: (employee) {
          if (employee != null && mounted) {
            _nameController.text = employee.name;
            _ageController.text = employee.age.toString();
            _salaryController.text = employee.salary.toString();
          }
        },
        loading: () {},
        error: (_, _) {},
      );
    }, fireImmediately: true);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _salaryController.dispose();
    super.dispose();
  }

  Future<void> _saveEmployee() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final mutations = ref.read(employeeMutationsProvider.notifier);
    final employee = Employee(
      id: widget.employeeId,
      name: _nameController.text.trim(),
      age: int.parse(_ageController.text.trim()),
      salary: int.parse(_salaryController.text.trim()),
      isSynced: false,
    );

    final isCreate = widget.employeeId == null;
    final employeeName = employee.name;

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final errorColor = Theme.of(context).colorScheme.error;

    if (mounted) {
      context.pop();
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(
            isCreate
                ? 'Creating $employeeName...'
                : 'Updating $employeeName...',
          ),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }

    final mutationFuture = isCreate
        ? mutations.createEmployee(employee)
        : mutations.updateEmployee(employee);

    mutationFuture
        .then((_) {
          // Success - the optimistic update is now confirmed
          // No need to do anything, the stream will update automatically
        })
        .catchError((e) {
          // Error - the repository has already rolled back
          // Show error message to user using the captured ScaffoldMessenger
          final errorMessage = e is ApiException
              ? e.userMessage
              : 'Failed to save employee';

          scaffoldMessenger.clearSnackBars();

          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: errorColor,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 4),
            ),
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    final isEditMode = widget.employeeId != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditMode ? 'Edit Employee' : 'Add Employee'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                hintText: 'Enter employee name',
                prefixIcon: Icon(Icons.person_outline),
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a name';
                }
                if (value.trim().length < 2) {
                  return 'Name must be at least 2 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _ageController,
              decoration: const InputDecoration(
                labelText: 'Age',
                hintText: 'Enter employee age',
                prefixIcon: Icon(Icons.cake_outlined),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter an age';
                }
                final age = int.tryParse(value.trim());
                if (age == null) {
                  return 'Please enter a valid number';
                }
                if (age < 18 || age > 100) {
                  return 'Age must be between 18 and 100';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _salaryController,
              decoration: const InputDecoration(
                labelText: 'Salary',
                hintText: 'Enter annual salary',
                prefixIcon: Icon(Icons.attach_money),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a salary';
                }
                final salary = int.tryParse(value.trim());
                if (salary == null) {
                  return 'Please enter a valid number';
                }
                if (salary < 0) {
                  return 'Salary must be a positive number';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            FilledButton.icon(
              onPressed: _saveEmployee,
              icon: const Icon(Icons.save),
              label: Text(isEditMode ? 'Update Employee' : 'Create Employee'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 12),

            OutlinedButton(
              onPressed: () => context.pop(),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }
}
