import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class Employee {
  const Employee({required this.id, required this.name, this.apellido});

  final int id;
  final String name;
  final String? apellido;

  factory Employee.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final name = json['name'];
    final apellido = json['apellido'];

    if (id is! int ||
        name is! String ||
        (apellido != null && apellido is! String)) {
      throw const FormatException(
        'El servidor devolvió un empleado con formato inválido.',
      );
    }

    return Employee(id: id, name: name, apellido: apellido as String?);
  }
}

class EmployeeScreen extends StatefulWidget {
  const EmployeeScreen({super.key});

  @override
  State<EmployeeScreen> createState() => _EmployeeScreenState();
}

class _EmployeeScreenState extends State<EmployeeScreen> {
  static const _apiBaseUrl = String.fromEnvironment('API_BASE_URL');

  String get _baseUrl {
    if (_apiBaseUrl.isNotEmpty) return _apiBaseUrl;
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8080';
    }
    return 'http://localhost:8080';
  }

  List<Employee> employees = [];
  bool isLoading = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    fetchEmployees();
  }

  Future<void> fetchEmployees() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/api/employees'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is! List<dynamic>) {
          throw const FormatException(
            'El servidor no devolvió una lista de empleados.',
          );
        }
        final loadedEmployees = decoded.map((item) {
          if (item is! Map<String, dynamic>) {
            throw const FormatException(
              'El servidor devolvió un empleado con formato inválido.',
            );
          }
          return Employee.fromJson(item);
        }).toList();

        if (!mounted) return;
        setState(() => employees = loadedEmployees);
      } else {
        throw http.ClientException(
          'El servidor respondió con estado ${response.statusCode}.',
          response.request?.url,
        );
      }
    } on Exception catch (exception) {
      if (!mounted) return;
      setState(
        () => errorMessage = 'No se pudieron cargar los empleados: $exception',
      );
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lista de Empleados'),
        actions: [
          IconButton(
            onPressed: isLoading ? null : fetchEmployees,
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(errorMessage!, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: fetchEmployees,
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            )
          : employees.isEmpty
          ? const Center(child: Text('No hay empleados registrados.'))
          : ListView.builder(
              itemCount: employees.length,
              itemBuilder: (context, index) {
                final employee = employees[index];
                final fullName = [
                  employee.name,
                  if (employee.apellido?.isNotEmpty ?? false)
                    employee.apellido!,
                ].join(' ');

                return ListTile(
                  key: ValueKey(employee.id),
                  title: Text(fullName),
                );
              },
            ),
    );
  }
}
