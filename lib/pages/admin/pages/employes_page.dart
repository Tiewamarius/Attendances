import 'dart:convert';

import 'package:attendance/core/auth/auth_service.dart';
import 'package:attendance/core/network/api_endpoints.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class EmployeesPage extends StatefulWidget {
  const EmployeesPage({super.key});

  @override
  State<EmployeesPage> createState() => _EmployeesPageState();
}

class _EmployeesPageState extends State<EmployeesPage> {
  // ===========================================================================
  // COULEURS
  // ===========================================================================

  static const Color bgLight = Color(0xFFF3F2F1);
  static const Color panelLight = Colors.white;
  static const Color textDark = Color(0xFF201F1E);
  static const Color textGrey = Color(0xFF605E5C);
  static const Color accentBlue = Color(0xFF0078D4);
  static const Color successGreen = Color(0xFF107C10);
  static const Color warningOrange = Color(0xFFD83B01);
  static const Color dangerRed = Color(0xFFD13438);
  static const Color borderColor = Color(0xFFEDEBE9);
  static const Color hoverColor = Color(0xFFE8F1FB);

  // ===========================================================================
  // DONNÉES
  // ===========================================================================

  List<Map<String, dynamic>> employees = [];
  List<Map<String, dynamic>> departments = [];

  bool isLoading = true;
  bool isLoadingDepartments = false;
  bool isSaving = false;

  String? errorMessage;
  String? departmentError;

  String selectedFilter = 'Toutes';
  int? selectedEmployeeId;

  String searchQuery = '';

  // ===========================================================================
  // CONTRÔLEURS
  // ===========================================================================

  final TextEditingController _searchController =
      TextEditingController();

  final TextEditingController _codeController =
      TextEditingController();

  final TextEditingController _firstNameController =
      TextEditingController();

  final TextEditingController _lastNameController =
      TextEditingController();

  final TextEditingController _positionController =
      TextEditingController();

  final TextEditingController _phoneController =
      TextEditingController();

  final TextEditingController _emailController =
      TextEditingController();

  final TextEditingController _passwordController =
      TextEditingController();

  final GlobalKey<FormState> _formKey =
      GlobalKey<FormState>();

  int? _selectedDepartmentId;

  // ===========================================================================
  // INITIALISATION
  // ===========================================================================

  @override
  void initState() {
    super.initState();

    _searchController.addListener(_onSearchChanged);

    fetchEmployees();
    fetchDepartments();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);

    _searchController.dispose();
    _codeController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _positionController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();

    super.dispose();
  }

  // ===========================================================================
  // RECHERCHE
  // ===========================================================================

  void _onSearchChanged() {
    if (!mounted) return;

    setState(() {
      searchQuery = _searchController.text.trim().toLowerCase();
    });
  }

  List<Map<String, dynamic>> get filteredEmployees {
    Iterable<Map<String, dynamic>> result = employees;

    if (selectedFilter != 'Toutes') {
      result = result.where((employee) {
        return _getEmployeeStatus(employee).toLowerCase() ==
            selectedFilter.toLowerCase();
      });
    }

    if (searchQuery.isNotEmpty) {
      result = result.where((employee) {
        final firstName =
            _stringValue(employee['first_name']).toLowerCase();

        final lastName =
            _stringValue(employee['last_name']).toLowerCase();

        final code =
            _stringValue(employee['employee_code']).toLowerCase();

        final email =
            _stringValue(employee['email']).toLowerCase();

        final phone =
            _stringValue(employee['phone']).toLowerCase();

        final position =
            _stringValue(employee['position']).toLowerCase();

        final department =
            _departmentName(employee).toLowerCase();

        final fullName =
            '$firstName $lastName'.trim();

        return firstName.contains(searchQuery) ||
            lastName.contains(searchQuery) ||
            fullName.contains(searchQuery) ||
            code.contains(searchQuery) ||
            email.contains(searchQuery) ||
            phone.contains(searchQuery) ||
            position.contains(searchQuery) ||
            department.contains(searchQuery);
      });
    }

    return result.toList();
  }

  // ===========================================================================
  // API - EMPLOYÉS
  // ===========================================================================

  Future<void> fetchEmployees() async {
    if (mounted) {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });
    }

    try {
      final token = await AuthService.getToken();

      if (token == null || token.isEmpty) {
        if (!mounted) return;

        setState(() {
          isLoading = false;
          errorMessage =
              'Session expirée. Veuillez vous reconnecter.';
        });

        return;
      }

      final organizationId =
          await AuthService.getOrganizationId();

      if (organizationId == null) {
        if (!mounted) return;

        setState(() {
          isLoading = false;
          errorMessage =
              'Aucune organisation active.';
        });

        return;
      }

      final uri = Uri.parse(ApiConfig.employees);

      debugPrint('[EMPLOYEES] GET: $uri');
      debugPrint(
        '[EMPLOYEES] ORGANIZATION: $organizationId',
      );

      final response = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'X-Organization-Id': organizationId.toString(),
        },
      );

      debugPrint(
        '[EMPLOYEES] STATUS: ${response.statusCode}',
      );

      debugPrint(
        '[EMPLOYEES] BODY: ${response.body}',
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final decoded = _decodeResponse(response.body);

        if (decoded == null) {
          setState(() {
            isLoading = false;
            errorMessage =
                'La réponse du serveur est invalide.';
          });

          return;
        }

        final fetchedList = _extractList(decoded);

        final normalizedEmployees = fetchedList
            .whereType<Map>()
            .map<Map<String, dynamic>>(
              (employee) => _normalizeEmployee(
                Map<String, dynamic>.from(employee),
              ),
            )
            .toList();

        setState(() {
          employees = normalizedEmployees;
          isLoading = false;
          errorMessage = null;
        });

        _restoreSelectedEmployee();

        return;
      }

      if (response.statusCode == 401) {
        setState(() {
          isLoading = false;
          errorMessage =
              'Votre session a expiré. Veuillez vous reconnecter.';
        });

        return;
      }

      if (response.statusCode == 400 ||
          response.statusCode == 403) {
        setState(() {
          isLoading = false;
          errorMessage = _extractApiError(
            response.body,
            fallback:
                'Accès refusé pour l’organisation active.',
          );
        });

        return;
      }

      setState(() {
        isLoading = false;
        errorMessage = _extractApiError(
          response.body,
          fallback:
              'Impossible de récupérer la liste des employés.',
        );
      });
    } catch (e) {
      debugPrint(
        '[EMPLOYEES] fetchEmployees ERROR: $e',
      );

      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage =
            'Impossible de contacter le serveur. Vérifiez votre connexion.';
      });
    }
  }

  // ===========================================================================
  // API - DÉPARTEMENTS
  // ===========================================================================

  Future<void> fetchDepartments() async {
    if (mounted) {
      setState(() {
        isLoadingDepartments = true;
        departmentError = null;
      });
    }

    try {
      final token = await AuthService.getToken();

      if (token == null || token.isEmpty) {
        if (!mounted) return;

        setState(() {
          isLoadingDepartments = false;
          departmentError = 'Session expirée.';
        });

        return;
      }

      final organizationId =
          await AuthService.getOrganizationId();

      if (organizationId == null) {
        if (!mounted) return;

        setState(() {
          isLoadingDepartments = false;
          departmentError =
              'Aucune organisation active.';
        });

        return;
      }

      final uri = Uri.parse(ApiConfig.departments);

      debugPrint('[DEPARTMENTS] GET: $uri');
      debugPrint(
        '[DEPARTMENTS] ORGANIZATION: $organizationId',
      );

      final response = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'X-Organization-Id': organizationId.toString(),
        },
      );

      debugPrint(
        '[DEPARTMENTS] STATUS: ${response.statusCode}',
      );

      debugPrint(
        '[DEPARTMENTS] BODY: ${response.body}',
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final decoded = _decodeResponse(response.body);

        if (decoded == null) {
          setState(() {
            isLoadingDepartments = false;
            departmentError =
                'Réponse des départements invalide.';
          });

          return;
        }

        final list = _extractList(decoded);

        final normalized = list
            .whereType<Map>()
            .map<Map<String, dynamic>>(
              (department) => _normalizeDepartment(
                Map<String, dynamic>.from(department),
              ),
            )
            .toList();

        setState(() {
          departments = normalized;
          isLoadingDepartments = false;
          departmentError = null;
        });

        debugPrint(
          '[DEPARTMENTS] Nombre reçu: ${departments.length}',
        );

        return;
      }

      if (response.statusCode == 401) {
        setState(() {
          isLoadingDepartments = false;
          departmentError =
              'Session expirée.';
        });

        return;
      }

      setState(() {
        isLoadingDepartments = false;
        departmentError = _extractApiError(
          response.body,
          fallback:
              'Impossible de récupérer les départements.',
        );
      });
    } catch (e) {
      debugPrint(
        '[DEPARTMENTS] ERROR: $e',
      );

      if (!mounted) return;

      setState(() {
        isLoadingDepartments = false;
        departmentError =
            'Impossible de charger les départements.';
      });
    }
  }

  // ===========================================================================
  // NORMALISATION EMPLOYÉ
  // ===========================================================================

  Map<String, dynamic> _normalizeEmployee(
    Map<String, dynamic> employee,
  ) {
    final user =
        employee['user'] is Map
            ? Map<String, dynamic>.from(
                employee['user'],
              )
            : <String, dynamic>{};

    final firstName = _stringValue(
      employee['first_name'] ??
          user['first_name'],
    );

    final lastName = _stringValue(
      employee['last_name'] ??
          user['last_name'],
    );

    final email = _stringValue(
      employee['email'] ??
          user['email'],
    );

    final phone = _stringValue(
      employee['phone'] ??
          user['phone'],
    );

    final avatar =
        employee['avatar'] ??
        employee['photo'] ??
        employee['profile_photo'] ??
        employee['avatar_url'] ??
        user['avatar'] ??
        user['profile_photo_url'];

    final department =
        employee['department'];

    int? departmentId =
        _toInt(
      employee['department_id'],
    );

    String departmentName = '';

    if (department is Map) {
      departmentId ??=
          _toInt(department['id']);

      departmentName =
          _stringValue(
        department['name'],
      );
    } else {
      departmentName =
          _stringValue(
        employee['department_name'],
      );
    }

    final status =
        employee['status'] ??
        employee['attendance_status'] ??
        employee['presence_status'];

    return {
      ...employee,

      'id':
          _toInt(
            employee['id'] ??
                user['id'],
          ),

      'user_id':
          _toInt(
            employee['user_id'] ??
                user['id'],
          ),

      'employee_code':
          _stringValue(
        employee['employee_code'],
      ),

      'first_name':
          firstName,

      'last_name':
          lastName,

      'email':
          email,

      'phone':
          phone,

      'position':
          _stringValue(
        employee['position'],
        fallback: 'Non spécifié',
      ),

      'department_id':
          departmentId,

      'department_name':
          departmentName,

      'avatar':
          avatar,

      'initial':
          _buildInitials(
        firstName,
        lastName,
      ),

      'status':
          status,

      'message':
          employee['message'],

      'time':
          employee['time'],

      'unread':
          employee['unread'] == true,
    };
  }

  // ===========================================================================
  // NORMALISATION DÉPARTEMENT
  // ===========================================================================

  Map<String, dynamic> _normalizeDepartment(
    Map<String, dynamic> department,
  ) {
    return {
      ...department,
      'id':
          _toInt(
            department['id'],
          ),
      'name':
          _stringValue(
        department['name'] ??
            department['title'],
        fallback:
            'Département',
      ),
    };
  }

  // ===========================================================================
  // EXTRACTION LISTE
  // ===========================================================================

  List<dynamic> _extractList(
    dynamic decoded,
  ) {
    if (decoded is List) {
      return decoded;
    }

    if (decoded is! Map) {
      return [];
    }

    final data = decoded['data'];

    if (data is List) {
      return data;
    }

    if (data is Map) {
      final nestedData = data['data'];

      if (nestedData is List) {
        return nestedData;
      }

      final employeesData = data['employees'];

      if (employeesData is List) {
        return employeesData;
      }

      final departmentsData = data['departments'];

      if (departmentsData is List) {
        return departmentsData;
      }

      if (nestedData is Map) {
        final nestedEmployees =
            nestedData['employees'];

        if (nestedEmployees is List) {
          return nestedEmployees;
        }

        final nestedDepartments =
            nestedData['departments'];

        if (nestedDepartments is List) {
          return nestedDepartments;
        }
      }
    }

    final employeesData =
        decoded['employees'];

    if (employeesData is List) {
      return employeesData;
    }

    final departmentsData =
        decoded['departments'];

    if (departmentsData is List) {
      return departmentsData;
    }

    final results =
        decoded['results'];

    if (results is List) {
      return results;
    }

    return [];
  }

  // ===========================================================================
  // CRÉATION EMPLOYÉ
  // ===========================================================================

  Future<void> _createEmployee() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (isSaving) {
      return;
    }

    setState(() {
      isSaving = true;
    });

    try {
      final token =
          await AuthService.getToken();

      if (token == null || token.isEmpty) {
        if (!mounted) return;

        setState(() {
          isSaving = false;
        });

        _showError(
          'Votre session a expiré. Veuillez vous reconnecter.',
        );

        return;
      }

      final organizationId =
          await AuthService.getOrganizationId();

      if (organizationId == null) {
        if (!mounted) return;

        setState(() {
          isSaving = false;
        });

        _showError(
          'Aucune organisation active.',
        );

        return;
      }

      final body = <String, dynamic>{
        'employee_code':
            _codeController.text.trim(),

        'first_name':
            _firstNameController.text.trim(),

        'last_name':
            _lastNameController.text.trim(),

        'email':
            _emailController.text.trim(),

        'password':
            _passwordController.text,

        'position':
            _positionController.text.trim(),

        'phone':
            _phoneController.text.trim(),
      };

      if (_selectedDepartmentId != null) {
        body['department_id'] =
            _selectedDepartmentId;
      }

      debugPrint(
        '[EMPLOYEES] POST: ${ApiConfig.employees}',
      );

      debugPrint(
        '[EMPLOYEES] BODY: $body',
      );

      final response =
          await http.post(
        Uri.parse(
          ApiConfig.employees,
        ),
        headers: {
          'Accept':
              'application/json',
          'Content-Type':
              'application/json',
          'Authorization':
              'Bearer $token',
          'X-Organization-Id':
              organizationId.toString(),
        },
        body: jsonEncode(body),
      );

      debugPrint(
        '[EMPLOYEES] POST STATUS: ${response.statusCode}',
      );

      debugPrint(
        '[EMPLOYEES] POST BODY: ${response.body}',
      );

      if (!mounted) return;

      if (response.statusCode == 200 ||
          response.statusCode == 201) {
        final decoded =
            _decodeResponse(
          response.body,
        );

        final temporaryPin =
            _findTemporaryPin(
          decoded,
        );

        Navigator.of(context).pop();

        setState(() {
          isSaving = false;
        });

        await fetchEmployees();

        if (!mounted) return;

        if (temporaryPin != null &&
            temporaryPin.trim().isNotEmpty) {
          await _showTemporaryPinDialog(
            temporaryPin,
          );
        } else {
          _showSuccess(
            'Employé créé avec succès.',
          );
        }

        return;
      }

      setState(() {
        isSaving = false;
      });

      if (response.statusCode == 422) {
        _showError(
          _extractValidationErrors(
            response.body,
          ),
        );

        return;
      }

      if (response.statusCode == 401) {
        _showError(
          'Session expirée. Veuillez vous reconnecter.',
        );

        return;
      }

      if (response.statusCode == 400 ||
          response.statusCode == 403) {
        _showError(
          _extractApiError(
            response.body,
            fallback:
                'Vous n’avez pas accès à cette organisation.',
          ),
        );

        return;
      }

      _showError(
        _extractApiError(
          response.body,
          fallback:
              'Impossible de créer l’employé.',
        ),
      );
    } catch (e) {
      debugPrint(
        '[EMPLOYEES] createEmployee ERROR: $e',
      );

      if (!mounted) return;

      setState(() {
        isSaving = false;
      });

      _showError(
        'Erreur de connexion au serveur.',
      );
    }
  }

  // ===========================================================================
  // MODALE AJOUT
  // ===========================================================================

  void _showAddEmployeeModal() {
    _clearEmployeeForm();

    showDialog<void>(
      context: context,
      barrierDismissible: !isSaving,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (
            context,
            setModalState,
          ) {
            return AlertDialog(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.white,

              title: const Row(
                children: [
                  Icon(
                    Icons.person_add_alt_1_outlined,
                    color: accentBlue,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Ajouter un employé',
                      style: TextStyle(
                        color: textDark,
                        fontSize: 19,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),

              content: SizedBox(
                width: 500,
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize:
                          MainAxisSize.min,
                      children: [
                        _buildFormField(
                          controller:
                              _codeController,
                          label:
                              'Matricule RH',
                          hint:
                              'Ex. EMP-001',
                          icon:
                              Icons.badge_outlined,
                          required: true,
                        ),

                        const SizedBox(height: 14),

                        _buildFormField(
                          controller:
                              _firstNameController,
                          label:
                              'Prénom',
                          hint:
                              'Prénom de l’employé',
                          icon:
                              Icons.person_outline,
                          required: true,
                        ),

                        const SizedBox(height: 14),

                        _buildFormField(
                          controller:
                              _lastNameController,
                          label:
                              'Nom',
                          hint:
                              'Nom de famille',
                          icon:
                              Icons.person_outline,
                          required: true,
                        ),

                        const SizedBox(height: 14),

                        _buildFormField(
                          controller:
                              _emailController,
                          label:
                              'Adresse e-mail',
                          hint:
                              'employe@example.com',
                          icon:
                              Icons.email_outlined,
                          keyboardType:
                              TextInputType.emailAddress,
                          required: true,
                        ),

                        const SizedBox(height: 14),

                        _buildFormField(
                          controller:
                              _passwordController,
                          label:
                              'Mot de passe',
                          hint:
                              'Minimum 8 caractères',
                          icon:
                              Icons.lock_outline,
                          obscureText:
                              true,
                          required:
                              true,
                        ),

                        const SizedBox(height: 14),

                        _buildFormField(
                          controller:
                              _positionController,
                          label:
                              'Poste',
                          hint:
                              'Ex. Comptable',
                          icon:
                              Icons.work_outline,
                        ),

                        const SizedBox(height: 14),

                        _buildDepartmentField(
                          onChanged: (value) {
                            setModalState(() {
                              _selectedDepartmentId =
                                  value;
                            });
                          },
                        ),

                        const SizedBox(height: 14),

                        _buildFormField(
                          controller:
                              _phoneController,
                          label:
                              'Téléphone',
                          hint:
                              'Ex. +225 07 XX XX XX XX',
                          icon:
                              Icons.phone_outlined,
                          keyboardType:
                              TextInputType.phone,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              actionsPadding:
                  const EdgeInsets.fromLTRB(
                20,
                0,
                20,
                20,
              ),

              actions: [
                TextButton(
                  onPressed: isSaving
                      ? null
                      : () {
                          Navigator.of(
                            dialogContext,
                          ).pop();
                        },
                  child: const Text(
                    'Annuler',
                    style: TextStyle(
                      color: textGrey,
                    ),
                  ),
                ),

                ElevatedButton.icon(
                  onPressed: isSaving
                      ? null
                      : () async {
                          setModalState(() {});

                          await _createEmployee();

                          if (mounted) {
                            setModalState(() {});
                          }
                        },
                  icon: isSaving
                      ? const SizedBox(
                          width: 17,
                          height: 17,
                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(
                          Icons.check,
                          size: 18,
                        ),
                  label: Text(
                    isSaving
                        ? 'Création...'
                        : 'Créer l’employé',
                  ),
                  style:
                      ElevatedButton.styleFrom(
                    backgroundColor:
                        accentBlue,
                    foregroundColor:
                        Colors.white,
                    elevation: 0,
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 12,
                    ),
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(6),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ===========================================================================
  // CHAMP DÉPARTEMENT
  // ===========================================================================

  Widget _buildDepartmentField({
    required ValueChanged<int?> onChanged,
  }) {
    if (isLoadingDepartments) {
      return InputDecorator(
        decoration: _inputDecoration(
          label: 'Département',
          icon: Icons.business_outlined,
        ),
        child: const SizedBox(
          height: 22,
          child: Align(
            alignment: Alignment.centerLeft,
            child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: accentBlue,
              ),
            ),
          ),
        ),
      );
    }

    if (departments.isEmpty) {
      return InputDecorator(
        decoration: _inputDecoration(
          label: 'Département',
          icon: Icons.business_outlined,
        ),
        child: const Text(
          'Aucun département disponible',
          style: TextStyle(
            color: textGrey,
            fontSize: 14,
          ),
        ),
      );
    }

    return DropdownButtonFormField<int>(
      value: _selectedDepartmentId,
      isExpanded: true,

      decoration: _inputDecoration(
        label: 'Département',
        icon: Icons.business_outlined,
      ),

      dropdownColor: Colors.white,

      items: departments.map((department) {
        final id =
            _toInt(department['id']);

        final name =
            _stringValue(
          department['name'],
          fallback:
              'Département',
        );

        if (id == null) {
          return null;
        }

        return DropdownMenuItem<int>(
          value: id,
          child: Text(
            name,
            overflow:
                TextOverflow.ellipsis,
          ),
        );
      }).whereType<DropdownMenuItem<int>>().toList(),

      onChanged: isSaving
          ? null
          : onChanged,

      validator: (_) {
        // Le département reste facultatif.
        // Si ton backend le rend obligatoire,
        // remplacer par une validation ici.
        return null;
      },
    );
  }

  // ===========================================================================
  // FORM FIELD
  // ===========================================================================

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    String? hint,
    IconData? icon,
    bool required = false,
    bool obscureText = false,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      enabled: !isSaving,

      style: const TextStyle(
        color: textDark,
        fontSize: 14,
      ),

      validator: (value) {
        final text =
            value?.trim() ?? '';

        if (required && text.isEmpty) {
          return '$label est obligatoire.';
        }

        if (label ==
                'Adresse e-mail' &&
            text.isNotEmpty &&
            !_isValidEmail(text)) {
          return 'Veuillez saisir une adresse e-mail valide.';
        }

        if (label ==
                'Mot de passe' &&
            text.isNotEmpty &&
            text.length < 8) {
          return
              'Le mot de passe doit contenir au moins 8 caractères.';
        }

        return null;
      },

      decoration: _inputDecoration(
        label: required
            ? '$label *'
            : label,
        hint: hint,
        icon: icon,
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    String? hint,
    IconData? icon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,

      prefixIcon: icon == null
          ? null
          : Icon(icon),

      filled: true,
      fillColor:
          const Color(0xFFF8F8F8),

      border:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(7),
        borderSide:
            const BorderSide(
          color: borderColor,
        ),
      ),

      enabledBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(7),
        borderSide:
            const BorderSide(
          color: borderColor,
        ),
      ),

      focusedBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(7),
        borderSide:
            const BorderSide(
          color: accentBlue,
          width: 1.5,
        ),
      ),

      errorBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(7),
        borderSide:
            const BorderSide(
          color: dangerRed,
        ),
      ),

      focusedErrorBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(7),
        borderSide:
            const BorderSide(
          color: dangerRed,
          width: 1.5,
        ),
      ),
    );
  }

  // ===========================================================================
  // PIN TEMPORAIRE
  // ===========================================================================

  Future<void> _showTemporaryPinDialog(
    String pin,
  ) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,

          title: const Row(
            children: [
              Icon(
                Icons.check_circle_outline,
                color: successGreen,
                size: 27,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Employé créé avec succès',
                  style: TextStyle(
                    color: textDark,
                    fontSize: 18,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          content: Column(
            mainAxisSize:
                MainAxisSize.min,
            children: [
              const Text(
                'Un PIN temporaire a été généré pour cet employé.',
                style: TextStyle(
                  color: textGrey,
                  fontSize: 14,
                ),
              ),

              const SizedBox(height: 20),

              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 18,
                ),
                decoration:
                    BoxDecoration(
                  color:
                      const Color(0xFFF3F7FB),
                  borderRadius:
                      BorderRadius.circular(8),
                  border:
                      Border.all(
                    color:
                        const Color(0xFFD6E7F7),
                  ),
                ),
                child: Column(
                  children: [
                    const Text(
                      'PIN TEMPORAIRE',
                      style: TextStyle(
                        color: textGrey,
                        fontSize: 11,
                        fontWeight:
                            FontWeight.w600,
                        letterSpacing: 1,
                      ),
                    ),

                    const SizedBox(height: 8),

                    SelectableText(
                      pin,
                      style:
                          const TextStyle(
                        color:
                            accentBlue,
                        fontSize: 30,
                        fontWeight:
                            FontWeight.bold,
                        letterSpacing: 5,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              const Row(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: warningOrange,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Notez ce PIN maintenant. Il peut ne plus être affiché après la fermeture de cette fenêtre.',
                      style: TextStyle(
                        color: textGrey,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    accentBlue,
                foregroundColor:
                    Colors.white,
                elevation: 0,
              ),
              child: const Text(
                'J’ai noté le PIN',
              ),
            ),
          ],
        );
      },
    );
  }

  // ===========================================================================
  // RESET FORMULAIRE
  // ===========================================================================

  void _clearEmployeeForm() {
    _codeController.clear();
    _firstNameController.clear();
    _lastNameController.clear();
    _positionController.clear();
    _phoneController.clear();
    _emailController.clear();
    _passwordController.clear();

    _selectedDepartmentId = null;

    isSaving = false;
  }

  // ===========================================================================
  // RESTAURER SÉLECTION
  // ===========================================================================

  void _restoreSelectedEmployee() {
    if (employees.isEmpty) {
      if (mounted) {
        setState(() {
          selectedEmployeeId = null;
        });
      }
      return;
    }

    if (selectedEmployeeId != null) {
      final exists = employees.any(
        (employee) =>
            _toInt(employee['id']) ==
            selectedEmployeeId,
      );

      if (exists) {
        return;
      }
    }

    if (mounted) {
      setState(() {
        selectedEmployeeId =
            _toInt(employees.first['id']);
      });
    }
  }

  // ===========================================================================
  // EMPLOYÉ SÉLECTIONNÉ
  // ===========================================================================

  Map<String, dynamic>? get selectedEmployee {
    if (selectedEmployeeId == null) {
      return null;
    }

    for (final employee in employees) {
      if (_toInt(employee['id']) ==
          selectedEmployeeId) {
        return employee;
      }
    }

    return null;
  }

  // ===========================================================================
  // CLICK EMPLOYÉ
  // ===========================================================================

  void _onEmployeeTap(
    int index,
    bool isDesktop,
  ) {
    final visibleEmployees =
        filteredEmployees;

    if (index < 0 ||
        index >= visibleEmployees.length) {
      return;
    }

    final employee =
        visibleEmployees[index];

    final id =
        _toInt(employee['id']);

    if (id == null) {
      return;
    }

    setState(() {
      selectedEmployeeId = id;
    });

    if (!isDesktop) {
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor:
            Colors.transparent,
        builder: (context) {
          return Container(
            height:
                MediaQuery.of(context)
                        .size
                        .height *
                    0.85,

            decoration:
                const BoxDecoration(
              color: Colors.white,
              borderRadius:
                  BorderRadius.vertical(
                top: Radius.circular(18),
              ),
            ),

            child: SafeArea(
              child: Padding(
                padding:
                    const EdgeInsets.all(
                  20,
                ),
                child:
                    _buildEmployeeDetailsContent(
                  showCloseButton: true,
                ),
              ),
            ),
          );
        },
      );
    }
  }

  // ===========================================================================
  // DÉTAILS EMPLOYÉ
  // ===========================================================================

  Widget _buildEmployeeDetailsContent({
    bool showCloseButton = false,
  }) {
    final employee =
        selectedEmployee;

    if (employee == null) {
      return const SizedBox.shrink();
    }

    final firstName =
        _stringValue(
      employee['first_name'],
    );

    final lastName =
        _stringValue(
      employee['last_name'],
    );

    final fullName =
        '$firstName $lastName'.trim();

    final code =
        _stringValue(
      employee['employee_code'],
      fallback: 'Non renseigné',
    );

    final position =
        _stringValue(
      employee['position'],
      fallback: 'Non spécifié',
    );

    final department =
        _departmentName(
      employee,
      fallback: 'Non affecté',
    );

    final email =
        _stringValue(
      employee['email'],
      fallback: 'Non renseigné',
    );

    final phone =
        _stringValue(
      employee['phone'],
      fallback: 'Non renseigné',
    );

    final status =
        _getEmployeeStatus(
      employee,
    );

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        if (showCloseButton)
          Align(
            alignment:
                Alignment.centerRight,
            child: IconButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              icon:
                  const Icon(Icons.close),
              color: textGrey,
            ),
          ),

        Expanded(
          child: SingleChildScrollView(
            physics:
                const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    _buildAvatar(
                      employee,
                      radius: 34,
                    ),

                    const SizedBox(width: 16),

                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            fullName.isEmpty
                                ? 'Employé sans nom'
                                : fullName,
                            style:
                                const TextStyle(
                              color: textDark,
                              fontSize: 22,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow:
                                TextOverflow.ellipsis,
                          ),

                          const SizedBox(height: 6),

                          Text(
                            '$position • $code',
                            style:
                                const TextStyle(
                              color: textGrey,
                              fontSize: 13,
                            ),
                            maxLines: 2,
                            overflow:
                                TextOverflow.ellipsis,
                          ),

                          const SizedBox(height: 10),

                          _buildStatusBadge(
                            status,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 25),

                const Divider(
                  height: 1,
                  color: borderColor,
                ),

                const SizedBox(height: 22),

                const Text(
                  'Informations personnelles',
                  style: TextStyle(
                    color: textDark,
                    fontSize: 16,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 12),

                _buildInfoTile(
                  icon:
                      Icons.badge_outlined,
                  title:
                      'Matricule',
                  value:
                      code,
                ),

                _buildInfoTile(
                  icon:
                      Icons.work_outline,
                  title:
                      'Poste',
                  value:
                      position,
                ),

                _buildInfoTile(
                  icon:
                      Icons.business_outlined,
                  title:
                      'Département',
                  value:
                      department,
                ),

                _buildInfoTile(
                  icon:
                      Icons.email_outlined,
                  title:
                      'E-mail',
                  value:
                      email,
                ),

                _buildInfoTile(
                  icon:
                      Icons.phone_outlined,
                  title:
                      'Téléphone',
                  value:
                      phone,
                ),

                const SizedBox(height: 18),

                const Text(
                  'Pointage',
                  style: TextStyle(
                    color: textDark,
                    fontSize: 16,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 12),

                _buildAttendanceInfo(
                  employee,
                ),

                const SizedBox(height: 22),

                SizedBox(
                  width: double.infinity,
                  child:
                      OutlinedButton.icon(
                    onPressed: () {
                      _showComingSoon(
                        'La modification de l’employé sera connectée à l’API.',
                      );
                    },
                    icon: const Icon(
                      Icons.edit_outlined,
                      size: 17,
                    ),
                    label: const Text(
                      'Modifier l’employé',
                    ),
                    style:
                        OutlinedButton.styleFrom(
                      foregroundColor:
                          accentBlue,
                      side:
                          const BorderSide(
                        color: accentBlue,
                      ),
                      padding:
                          const EdgeInsets.symmetric(
                        vertical: 13,
                      ),
                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(6),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // POINTAGE
  // ===========================================================================

  Widget _buildAttendanceInfo(
    Map<String, dynamic> employee,
  ) {
    final status =
        _getEmployeeStatus(
      employee,
    );

    final checkIn =
        _firstNonEmpty([
      employee['check_in'],
      employee['checkIn'],
      employee['arrival_time'],
      employee['checkin'],
    ]);

    final checkOut =
        _firstNonEmpty([
      employee['check_out'],
      employee['checkOut'],
      employee['departure_time'],
      employee['checkout'],
    ]);

    final attendanceDate =
        _firstNonEmpty([
      employee['attendance_date'],
      employee['date'],
      employee['attendanceDate'],
    ]);

    final message =
        _firstNonEmpty([
      employee['message'],
      employee['attendance_message'],
    ]);

    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(15),
      decoration:
          BoxDecoration(
        color: bgLight,
        borderRadius:
            BorderRadius.circular(8),
        border: Border.all(
          color: borderColor,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(
                Icons.access_time_outlined,
                size: 20,
                color: accentBlue,
              ),

              const SizedBox(width: 12),

              const Expanded(
                child: Text(
                  'Statut actuel',
                  style: TextStyle(
                    color: textGrey,
                    fontSize: 13,
                  ),
                ),
              ),

              _buildStatusBadge(
                status,
              ),
            ],
          ),

          if (attendanceDate != null ||
              checkIn != null ||
              checkOut != null ||
              message != null) ...[
            const SizedBox(height: 15),

            const Divider(
              height: 1,
              color: borderColor,
            ),

            const SizedBox(height: 10),
          ],

          if (attendanceDate != null)
            _buildCompactAttendanceRow(
              Icons.calendar_today_outlined,
              'Date',
              attendanceDate,
            ),

          if (checkIn != null)
            _buildCompactAttendanceRow(
              Icons.login_outlined,
              'Arrivée',
              checkIn,
            ),

          if (checkOut != null)
            _buildCompactAttendanceRow(
              Icons.logout_outlined,
              'Départ',
              checkOut,
            ),

          if (message != null)
            _buildCompactAttendanceRow(
              Icons.info_outline,
              'Information',
              message,
            ),

          if (attendanceDate == null &&
              checkIn == null &&
              checkOut == null &&
              message == null)
            const Padding(
              padding:
                  EdgeInsets.symmetric(
                vertical: 10,
              ),
              child: Text(
                'Aucune information de pointage disponible.',
                style: TextStyle(
                  color: textGrey,
                  fontSize: 13,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCompactAttendanceRow(
    IconData icon,
    String label,
    String value,
  ) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(
        vertical: 5,
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 17,
            color: textGrey,
          ),

          const SizedBox(width: 10),

          SizedBox(
            width: 75,
            child: Text(
              label,
              style:
                  const TextStyle(
                color: textGrey,
                fontSize: 12,
              ),
            ),
          ),

          Expanded(
            child: Text(
              value,
              style:
                  const TextStyle(
                color: textDark,
                fontSize: 13,
                fontWeight:
                    FontWeight.w500,
              ),
              maxLines: 2,
              overflow:
                  TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // INFO TILE
  // ===========================================================================

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return ListTile(
      contentPadding:
          EdgeInsets.zero,
      dense: true,

      leading: Container(
        width: 38,
        height: 38,
        decoration:
            BoxDecoration(
          color: bgLight,
          borderRadius:
              BorderRadius.circular(7),
        ),
        child: Icon(
          icon,
          color: accentBlue,
          size: 19,
        ),
      ),

      title: Text(
        title,
        style:
            const TextStyle(
          color: textGrey,
          fontSize: 11,
        ),
      ),

      subtitle: Padding(
        padding:
            const EdgeInsets.only(
          top: 2,
        ),
        child: Text(
          value,
          maxLines: 2,
          overflow:
              TextOverflow.ellipsis,
          style:
              const TextStyle(
            color: textDark,
            fontSize: 14,
            fontWeight:
                FontWeight.w500,
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // LISTE EMPLOYÉS
  // ===========================================================================

  Widget _buildEmployeesList({
    required bool isDesktop,
  }) {
    final list =
        filteredEmployees;

    if (list.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.separated(
      padding:
          const EdgeInsets.only(
        top: 4,
        bottom: 20,
      ),
      itemCount:
          list.length,
      separatorBuilder:
          (context, index) {
        return const Divider(
          height: 1,
          indent: 82,
          endIndent: 12,
          color: borderColor,
        );
      },
      itemBuilder:
          (context, index) {
        final employee =
            list[index];

        final employeeId =
            _toInt(employee['id']);

        final isSelected =
            employeeId != null &&
            employeeId ==
                selectedEmployeeId;

        return _buildEmployeeListItem(
          employee,
          index,
          isDesktop,
          isSelected,
        );
      },
    );
  }

  Widget _buildEmployeeListItem(
    Map<String, dynamic> employee,
    int index,
    bool isDesktop,
    bool isSelected,
  ) {
    final firstName =
        _stringValue(
      employee['first_name'],
    );

    final lastName =
        _stringValue(
      employee['last_name'],
    );

    final fullName =
        '$firstName $lastName'.trim();

    final position =
        _stringValue(
      employee['position'],
      fallback:
          'Poste non spécifié',
    );

    final code =
        _stringValue(
      employee['employee_code'],
    );

    final department =
        _departmentName(
      employee,
    );

    final status =
        _getEmployeeStatus(
      employee,
    );

    final message =
        _firstNonEmpty([
      employee['message'],
      employee['attendance_message'],
    ]);

    final time =
        _firstNonEmpty([
      employee['time'],
      employee['updated_at'],
      employee['last_attendance'],
    ]);

    return Material(
      color:
          isSelected && isDesktop
              ? hoverColor
              : Colors.transparent,

      child: InkWell(
        onTap: () =>
            _onEmployeeTap(
          index,
          isDesktop,
        ),

        hoverColor:
            hoverColor,

        child: Padding(
          padding:
              const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 11,
          ),

          child: Row(
            children: [
              _buildAvatar(
                employee,
                radius: 24,
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            fullName.isEmpty
                                ? 'Employé sans nom'
                                : fullName,
                            style:
                                const TextStyle(
                              color:
                                  textDark,
                              fontSize:
                                  15,
                              fontWeight:
                                  FontWeight.w600,
                            ),
                            overflow:
                                TextOverflow.ellipsis,
                          ),
                        ),

                        if (time != null)
                          Padding(
                            padding:
                                const EdgeInsets
                                    .only(
                              left: 8,
                            ),
                            child: Text(
                              _formatShortDate(
                                time,
                              ),
                              style:
                                  TextStyle(
                                color:
                                    employee['unread'] ==
                                            true
                                        ? accentBlue
                                        : textGrey,
                                fontSize: 11,
                                fontWeight:
                                    employee['unread'] ==
                                            true
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                              ),
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 3),

                    Text(
                      [
                        position,
                        if (department.isNotEmpty)
                          department,
                        if (code.isNotEmpty)
                          code,
                      ].join(' • '),
                      style:
                          const TextStyle(
                        color: textGrey,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 4),

                    Row(
                      children: [
                        _buildStatusDot(
                          status,
                        ),

                        const SizedBox(width: 6),

                        Text(
                          status,
                          style:
                              const TextStyle(
                            color: textGrey,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),

                    if (message != null) ...[
                      const SizedBox(height: 4),

                      Text(
                        message,
                        style:
                            const TextStyle(
                          color: textGrey,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow:
                            TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // AVATAR
  // ===========================================================================

  Widget _buildAvatar(
    Map<String, dynamic> employee, {
    required double radius,
  }) {
    final avatar =
        employee['avatar'];

    final initials =
        _stringValue(
      employee['initial'],
      fallback: '?',
    );

    final imageUrl =
        avatar?.toString();

    final hasImage =
        imageUrl != null &&
        imageUrl.isNotEmpty &&
        imageUrl != 'null';

    return CircleAvatar(
      radius: radius,

      backgroundColor:
          accentBlue.withValues(
        alpha: 0.12,
      ),

      backgroundImage:
          hasImage
              ? NetworkImage(
                  imageUrl,
                )
              : null,

      onBackgroundImageError:
          hasImage
              ? (_, __) {}
              : null,

      child: !hasImage
          ? Text(
              initials,
              style: TextStyle(
                color: accentBlue,
                fontSize:
                    radius * 0.55,
                fontWeight:
                    FontWeight.bold,
              ),
            )
          : null,
    );
  }

  // ===========================================================================
  // STATUT
  // ===========================================================================

  String _getEmployeeStatus(
    Map<String, dynamic> employee,
  ) {
    final rawStatus =
        employee['status'] ??
        employee['attendance_status'] ??
        employee['presence_status'];

    if (rawStatus == null) {
      return 'Non renseigné';
    }

    final status =
        rawStatus
            .toString()
            .trim()
            .toLowerCase();

    switch (status) {
      case 'present':
      case 'présent':
      case 'present aujourd’hui':
      case 'présent aujourd’hui':
      case 'present aujourd\'hui':
      case 'présent aujourd\'hui':
        return 'Présent';

      case 'absent':
      case 'absence':
        return 'Absent';

      case 'late':
      case 'retard':
      case 'en retard':
        return 'En retard';

      case 'leave':
      case 'congé':
      case 'conge':
        return 'En congé';

      case 'authorized':
      case 'autorisé':
      case 'autorise':
        return 'Autorisé';

      default:
        return rawStatus.toString();
    }
  }

  Widget _buildStatusDot(
    String status,
  ) {
    Color color = textGrey;

    switch (status.toLowerCase()) {
      case 'présent':
      case 'present':
        color = successGreen;
        break;

      case 'absent':
        color = dangerRed;
        break;

      case 'en retard':
        color = warningOrange;
        break;

      case 'en congé':
      case 'congé':
      case 'conge':
      case 'autorisé':
      case 'autorise':
        color = accentBlue;
        break;
    }

    return Container(
      width: 8,
      height: 8,
      decoration:
          BoxDecoration(
        color: color,
        shape:
            BoxShape.circle,
      ),
    );
  }

  Widget _buildStatusBadge(
    String status,
  ) {
    Color foreground = textGrey;
    Color background = bgLight;

    switch (status.toLowerCase()) {
      case 'présent':
      case 'present':
        foreground = successGreen;
        background =
            successGreen.withValues(
          alpha: 0.10,
        );
        break;

      case 'absent':
        foreground = dangerRed;
        background =
            dangerRed.withValues(
          alpha: 0.10,
        );
        break;

      case 'en retard':
        foreground = warningOrange;
        background =
            warningOrange.withValues(
          alpha: 0.10,
        );
        break;

      case 'en congé':
      case 'congé':
      case 'conge':
      case 'autorisé':
      case 'autorise':
        foreground = accentBlue;
        background =
            accentBlue.withValues(
          alpha: 0.10,
        );
        break;
    }

    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration:
          BoxDecoration(
        color: background,
        borderRadius:
            BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: foreground,
          fontSize: 11,
          fontWeight:
              FontWeight.w600,
        ),
      ),
    );
  }

  // ===========================================================================
  // FILTRES
  // ===========================================================================

  Widget _buildFilters() {
    const filters = [
      'Toutes',
      'Présent',
      'Absent',
      'En retard',
    ];

    return SingleChildScrollView(
      scrollDirection:
          Axis.horizontal,
      padding:
          const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 4,
      ),
      child: Row(
        children:
            filters.map((filter) {
          final selected =
              selectedFilter == filter;

          return Padding(
            padding:
                const EdgeInsets.only(
              right: 7,
            ),
            child: ChoiceChip(
              label:
                  Text(filter),
              selected:
                  selected,
              onSelected:
                  (_) {
                setState(() {
                  selectedFilter =
                      filter;
                });
              },
              selectedColor:
                  accentBlue.withValues(
                alpha: 0.12,
              ),
              backgroundColor:
                  Colors.white,
              side:
                  BorderSide(
                color: selected
                    ? accentBlue
                    : borderColor,
              ),
              labelStyle:
                  TextStyle(
                color: selected
                    ? accentBlue
                    : textGrey,
                fontSize: 12,
                fontWeight: selected
                    ? FontWeight.w600
                    : FontWeight.normal,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ===========================================================================
  // RECHERCHE
  // ===========================================================================

  Widget _buildSearchBar() {
    return Padding(
      padding:
          const EdgeInsets.fromLTRB(
        16,
        4,
        16,
        4,
      ),
      child: TextField(
        controller:
            _searchController,
        style:
            const TextStyle(
          color: textDark,
          fontSize: 13,
        ),
        decoration:
            InputDecoration(
          hintText:
              'Rechercher par nom, matricule, poste...',
          hintStyle:
              const TextStyle(
            color: textGrey,
            fontSize: 13,
          ),
          prefixIcon:
              const Icon(
            Icons.search,
            color: textGrey,
            size: 20,
          ),
          suffixIcon:
              searchQuery.isEmpty
                  ? null
                  : IconButton(
                      onPressed: () {
                        _searchController
                            .clear();
                      },
                      icon:
                          const Icon(
                        Icons.close,
                        size: 18,
                        color:
                            textGrey,
                      ),
                    ),
          filled: true,
          fillColor: bgLight,
          border:
              OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(6),
            borderSide:
                const BorderSide(
              color: borderColor,
            ),
          ),
          enabledBorder:
              OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(6),
            borderSide:
                const BorderSide(
              color: borderColor,
            ),
          ),
          focusedBorder:
              OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(6),
            borderSide:
                const BorderSide(
              color: accentBlue,
              width: 1.3,
            ),
          ),
          contentPadding:
              const EdgeInsets.symmetric(
            vertical: 11,
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // ÉTAT VIDE
  // ===========================================================================

  Widget _buildEmptyState() {
    final hasSearch =
        searchQuery.isNotEmpty ||
        selectedFilter != 'Toutes';

    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration:
                  BoxDecoration(
                color: bgLight,
                borderRadius:
                    BorderRadius.circular(
                  32,
                ),
              ),
              child:
                  const Icon(
                Icons.people_outline,
                color: textGrey,
                size: 30,
              ),
            ),

            const SizedBox(height: 15),

            Text(
              hasSearch
                  ? 'Aucun employé ne correspond à votre recherche.'
                  : 'Aucun employé trouvé.',
              textAlign:
                  TextAlign.center,
              style:
                  const TextStyle(
                color: textGrey,
                fontSize: 14,
              ),
            ),

            if (hasSearch) ...[
              const SizedBox(height: 12),

              TextButton(
                onPressed: () {
                  setState(() {
                    selectedFilter =
                        'Toutes';
                  });

                  _searchController.clear();
                },
                child:
                    const Text(
                  'Réinitialiser les filtres',
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // ERREUR
  // ===========================================================================

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration:
                  BoxDecoration(
                color:
                    dangerRed.withValues(
                  alpha: 0.08,
                ),
                shape:
                    BoxShape.circle,
              ),
              child:
                  const Icon(
                Icons.error_outline,
                color: dangerRed,
                size: 32,
              ),
            ),

            const SizedBox(height: 16),

            const Text(
              'Impossible de charger les employés',
              textAlign:
                  TextAlign.center,
              style:
                  TextStyle(
                color: textDark,
                fontSize: 16,
                fontWeight:
                    FontWeight.w600,
              ),
            ),

            const SizedBox(height: 7),

            Text(
              errorMessage ??
                  'Une erreur inconnue est survenue.',
              textAlign:
                  TextAlign.center,
              style:
                  const TextStyle(
                color: textGrey,
                fontSize: 13,
              ),
            ),

            const SizedBox(height: 18),

            ElevatedButton.icon(
              onPressed:
                  fetchEmployees,
              icon:
                  const Icon(
                Icons.refresh,
                size: 18,
              ),
              label:
                  const Text(
                'Réessayer',
              ),
              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    accentBlue,
                foregroundColor:
                    Colors.white,
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // HEADER
  // ===========================================================================

  Widget _buildHeader({
    required bool isDesktop,
  }) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding:
            const EdgeInsets.fromLTRB(
          16,
          10,
          8,
          4,
        ),
        child: Row(
          children: [
            const Expanded(
              child: Text(
                'Employés',
                style:
                    TextStyle(
                  color: textDark,
                  fontSize: 20,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ),

            Container(
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 9,
                vertical: 5,
              ),
              decoration:
                  BoxDecoration(
                color: bgLight,
                borderRadius:
                    BorderRadius.circular(5),
              ),
              child: Text(
                '${employees.length}',
                style:
                    const TextStyle(
                  color: textGrey,
                  fontSize: 12,
                  fontWeight:
                      FontWeight.w600,
                ),
              ),
            ),

            IconButton(
              tooltip: 'Actualiser',
              onPressed:
                  isLoading
                      ? null
                      : fetchEmployees,
              icon:
                  const Icon(
                Icons.refresh_outlined,
                color: textGrey,
              ),
            ),

            IconButton(
              tooltip:
                  'Ajouter un employé',
              onPressed:
                  isSaving
                      ? null
                      : _showAddEmployeeModal,
              icon:
                  const Icon(
                Icons.person_add_outlined,
                color: textGrey,
              ),
            ),

            PopupMenuButton<String>(
              tooltip: 'Options',
              icon:
                  const Icon(
                Icons.more_vert,
                color: textGrey,
              ),
              onSelected:
                  (value) {
                if (value == 'refresh') {
                  fetchEmployees();
                }

                if (value == 'departments') {
                  fetchDepartments();

                  _showSuccess(
                    'Actualisation des départements lancée.',
                  );
                }

                if (value == 'add') {
                  _showAddEmployeeModal();
                }
              },
              itemBuilder:
                  (context) =>
                      const [
                PopupMenuItem(
                  value: 'add',
                  child: Row(
                    children: [
                      Icon(
                        Icons.person_add_outlined,
                        size: 19,
                      ),
                      SizedBox(width: 10),
                      Text(
                        'Ajouter un employé',
                      ),
                    ],
                  ),
                ),

                PopupMenuItem(
                  value: 'refresh',
                  child: Row(
                    children: [
                      Icon(
                        Icons.refresh,
                        size: 19,
                      ),
                      SizedBox(width: 10),
                      Text(
                        'Actualiser les employés',
                      ),
                    ],
                  ),
                ),

                PopupMenuItem(
                  value: 'departments',
                  child: Row(
                    children: [
                      Icon(
                        Icons.business_outlined,
                        size: 19,
                      ),
                      SizedBox(width: 10),
                      Text(
                        'Actualiser les départements',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // BUILD
  // ===========================================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return LayoutBuilder(
      builder:
          (
        context,
        constraints,
      ) {
        final isDesktop =
            constraints.maxWidth > 850;

        if (!isDesktop) {
          return _buildMobileLayout(
            constraints,
          );
        }

        return Row(
          crossAxisAlignment:
              CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 360,
              child:
                  _buildEmployeesPanel(
                isDesktop: true,
              ),
            ),

            Expanded(
              child: Container(
                color: bgLight,
                padding:
                    const EdgeInsets.all(
                  12,
                ),
                child:
                    selectedEmployee == null
                        ? _buildDesktopEmptyDetails()
                        : Card(
                            color:
                                Colors.white,
                            elevation: 0,
                            shape:
                                RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(
                                8,
                              ),
                              side:
                                  const BorderSide(
                                color:
                                    borderColor,
                              ),
                            ),
                            child:
                                Padding(
                              padding:
                                  const EdgeInsets.all(
                                24,
                              ),
                              child:
                                  _buildEmployeeDetailsContent(),
                            ),
                          ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ===========================================================================
  // MOBILE
  // ===========================================================================

  Widget _buildMobileLayout(
    BoxConstraints constraints,
  ) {
    return SizedBox(
      width: constraints.maxWidth,
      child:
          _buildEmployeesPanel(
        isDesktop: false,
      ),
    );
  }

  // ===========================================================================
  // PANEL EMPLOYÉS
  // ===========================================================================

  Widget _buildEmployeesPanel({
    required bool isDesktop,
  }) {
    return Container(
      color: panelLight,
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.stretch,
        children: [
          _buildHeader(
            isDesktop: isDesktop,
          ),

          _buildSearchBar(),

          const SizedBox(height: 4),

          _buildFilters(),

          const SizedBox(height: 5),

          Expanded(
            child: isLoading
                ? const Center(
                    child:
                        CircularProgressIndicator(
                      color: accentBlue,
                    ),
                  )
                : errorMessage != null
                    ? _buildErrorState()
                    : _buildEmployeesList(
                        isDesktop:
                            isDesktop,
                      ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // ÉTAT INITIAL PANNEAU DROIT
  // ===========================================================================

  Widget _buildDesktopEmptyDetails() {
    return Center(
      child: Column(
        mainAxisAlignment:
            MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration:
                const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child:
                const Icon(
              Icons.person_search_outlined,
              size: 35,
              color: textGrey,
            ),
          ),

          const SizedBox(height: 18),

          const Text(
            'Sélectionnez un employé',
            style:
                TextStyle(
              color: textDark,
              fontSize: 16,
              fontWeight:
                  FontWeight.w600,
            ),
          ),

          const SizedBox(height: 6),

          const Padding(
            padding:
                EdgeInsets.symmetric(
              horizontal: 30,
            ),
            child: Text(
              'Sélectionnez un employé dans la liste pour afficher ses informations et son pointage.',
              textAlign:
                  TextAlign.center,
              style:
                  TextStyle(
                color: textGrey,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // DÉPARTEMENT D'UN EMPLOYÉ
  // ===========================================================================

  String _departmentName(
    Map<String, dynamic> employee, {
    String fallback = '',
  }) {
    final direct =
        employee['department_name'];

    if (direct != null &&
        direct.toString().trim().isNotEmpty) {
      return direct.toString().trim();
    }

    final department =
        employee['department'];

    if (department is Map) {
      final name =
          department['name'];

      if (name != null &&
          name.toString().trim().isNotEmpty) {
        return name.toString().trim();
      }
    }

    return fallback;
  }

  // ===========================================================================
  // UTILITAIRES
  // ===========================================================================

  String _stringValue(
    dynamic value, {
    String fallback = '',
  }) {
    if (value == null) {
      return fallback;
    }

    final result =
        value.toString().trim();

    if (result.isEmpty ||
        result == 'null') {
      return fallback;
    }

    return result;
  }

  int? _toInt(
    dynamic value,
  ) {
    if (value == null) {
      return null;
    }

    if (value is int) {
      return value;
    }

    return int.tryParse(
      value.toString(),
    );
  }

  String? _firstNonEmpty(
    List<dynamic> values,
  ) {
    for (final value in values) {
      if (value == null) {
        continue;
      }

      final result =
          value.toString().trim();

      if (result.isNotEmpty &&
          result != 'null') {
        return result;
      }
    }

    return null;
  }

  String _buildInitials(
    String firstName,
    String lastName,
  ) {
    String result = '';

    if (firstName.trim().isNotEmpty) {
      result +=
          firstName.trim()[0];
    }

    if (lastName.trim().isNotEmpty) {
      result +=
          lastName.trim()[0];
    }

    if (result.isEmpty) {
      return '?';
    }

    return result.toUpperCase();
  }

  bool _isValidEmail(
    String email,
  ) {
    return RegExp(
      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
    ).hasMatch(email);
  }

  dynamic _decodeResponse(
    String body,
  ) {
    try {
      return jsonDecode(body);
    } catch (_) {
      return null;
    }
  }

  // ===========================================================================
  // PIN
  // ===========================================================================

  String? _findTemporaryPin(
    dynamic decoded,
  ) {
    if (decoded is! Map) {
      return null;
    }

    final candidates = [
      decoded['temporary_pin'],
      decoded['pin'],
      decoded['temporaryPin'],

      if (decoded['data'] is Map)
        decoded['data']['temporary_pin'],

      if (decoded['data'] is Map)
        decoded['data']['pin'],

      if (decoded['data'] is Map)
        decoded['data']['temporaryPin'],

      if (decoded['employee'] is Map)
        decoded['employee']['temporary_pin'],

      if (decoded['employee'] is Map)
        decoded['employee']['pin'],

      if (decoded['data'] is Map &&
          decoded['data']['employee'] is Map)
        decoded['data']['employee']
            ['temporary_pin'],
    ];

    for (final candidate in candidates) {
      if (candidate != null) {
        final pin =
            candidate.toString().trim();

        if (pin.isNotEmpty) {
          return pin;
        }
      }
    }

    return null;
  }

  // ===========================================================================
  // ERREUR API
  // ===========================================================================

  String _extractApiError(
    String body, {
    required String fallback,
  }) {
    final decoded =
        _decodeResponse(body);

    if (decoded is Map) {
      final message =
          decoded['message'];

      if (message is String &&
          message.trim().isNotEmpty) {
        return message.trim();
      }

      final error =
          decoded['error'];

      if (error is String &&
          error.trim().isNotEmpty) {
        return error.trim();
      }

      final errors =
          decoded['errors'];

      if (errors is Map) {
        final messages =
            <String>[];

        errors.forEach(
          (key, value) {
            if (value is List) {
              for (final item in value) {
                messages.add(
                  item.toString(),
                );
              }
            } else if (value != null) {
              messages.add(
                value.toString(),
              );
            }
          },
        );

        if (messages.isNotEmpty) {
          return messages.join('\n');
        }
      }
    }

    final trimmed =
        body.trim();

    if (trimmed.isNotEmpty &&
        !trimmed.startsWith('<')) {
      return trimmed;
    }

    return fallback;
  }

  // ===========================================================================
  // VALIDATION LARAVEL
  // ===========================================================================

  String _extractValidationErrors(
    String body,
  ) {
    final decoded =
        _decodeResponse(body);

    if (decoded is Map) {
      final errors =
          decoded['errors'];

      if (errors is Map) {
        final messages =
            <String>[];

        errors.forEach(
          (key, value) {
            if (value is List) {
              for (final item in value) {
                messages.add(
                  item.toString(),
                );
              }
            } else if (value != null) {
              messages.add(
                value.toString(),
              );
            }
          },
        );

        if (messages.isNotEmpty) {
          return messages.join('\n');
        }
      }

      final message =
          decoded['message'];

      if (message is String &&
          message.trim().isNotEmpty) {
        return message.trim();
      }
    }

    return
        'Veuillez vérifier les informations saisies.';
  }

  // ===========================================================================
  // DATE / HEURE
  // ===========================================================================

  String _formatShortDate(
    String value,
  ) {
    if (value.isEmpty) {
      return '';
    }

    try {
      final date =
          DateTime.parse(value);

      final hour =
          date.hour
              .toString()
              .padLeft(2, '0');

      final minute =
          date.minute
              .toString()
              .padLeft(2, '0');

      return '$hour:$minute';
    } catch (_) {
      return value;
    }
  }

  // ===========================================================================
  // MESSAGES
  // ===========================================================================

  void _showSuccess(
    String message,
  ) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor:
              successGreen,
          behavior:
              SnackBarBehavior.floating,
        ),
      );
  }

  void _showError(
    String message,
  ) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor:
              dangerRed,
          behavior:
              SnackBarBehavior.floating,
          duration:
              const Duration(
            seconds: 4,
          ),
        ),
      );
  }

  void _showComingSoon(
    String message,
  ) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior:
              SnackBarBehavior.floating,
        ),
      );
  }
}