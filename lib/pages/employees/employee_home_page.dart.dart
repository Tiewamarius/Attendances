import 'dart:async';

import 'package:attendance/controllers/employee/employee_controller.dart';
import 'package:flutter/material.dart';

class EmployeHome extends StatefulWidget {
  const EmployeHome({super.key});

  @override
  State<EmployeHome> createState() => _EmployeHomeState();
}

class _EmployeHomeState extends State<EmployeHome> {
  final EmployeeController _employeeController =
      EmployeeController();

  String _currentTime = '';
  Timer? _timer;

  @override
  void initState() {
    super.initState();

    _updateTime();

    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _updateTime(),
    );

    _loadData();
  }

  Future<void> _loadData() async {
    await _employeeController.loadProfile();

    if (mounted) {
      setState(() {});
    }
  }

  void _updateTime() {
    if (!mounted) return;

    final now = DateTime.now();

    setState(() {
      _currentTime =
          '${now.hour.toString().padLeft(2, '0')}:'
          '${now.minute.toString().padLeft(2, '0')}:'
          '${now.second.toString().padLeft(2, '0')}';
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _employeeController.dispose();
    super.dispose();
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Color(0xFFEF4444),
              size: 56,
            ),
            const SizedBox(height: 16),
            const Text(
              'Unable to load your profile',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Please check your connection and try again.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadData,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHome(dynamic employee) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Welcome${employee != null ? ' back' : ''}',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              employee is dynamic ? (employee.name ?? 'Employee') : 'Employee',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                color: Color(0xFF334155),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _currentTime,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w600,
                color: Color(0xFF4F46E5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final employee = _employeeController.employee;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: _employeeController.loading && employee == null
            ? const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF4F46E5),
                ),
              )
            : employee == null
                ? _buildErrorState()
                : _buildHome(employee),
      ),
    );
  }
}