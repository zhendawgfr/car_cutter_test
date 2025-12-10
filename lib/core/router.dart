import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../features/employees/presentation/screens/employee_details_screen.dart';
import '../features/employees/presentation/screens/employee_form_screen.dart';
import '../features/employees/presentation/screens/employee_list_screen.dart';

part 'router.g.dart';

// App navigation routes
@riverpod
GoRouter router(Ref ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const EmployeeListScreen(),
      ),
      GoRoute(
        path: '/details/:id',
        name: 'details',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return EmployeeDetailsScreen(employeeId: id);
        },
      ),
      GoRoute(
        path: '/create',
        name: 'create',
        builder: (context, state) => const EmployeeFormScreen(),
      ),
      GoRoute(
        path: '/edit/:id',
        name: 'edit',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return EmployeeFormScreen(employeeId: id);
        },
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Error')),
      body: Center(child: Text('Page not found: ${state.uri}')),
    ),
  );
}
