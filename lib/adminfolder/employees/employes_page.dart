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

  bool isLoading = true;
  bool isSaving = false;
  bool isDeleting = false;

  String? errorMessage;

  String selectedFilter = 'Toutes';
  int? selectedIndex;

  String searchQuery = '';

  // ===========================================================================
  // CONTRÔLEURS
  // ===========================================================================

  final TextEditingController _searchController = TextEditingController();

  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _positionController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // ===========================================================================
  // INITIALISATION
  // ===========================================================================

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    fetchEmployees();
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
        final status = _getEmployeeStatus(employee);
        return status.toLowerCase() == selectedFilter.toLowerCase();
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

        final fullName = '$firstName $lastName';

        return firstName.contains(searchQuery) ||
            lastName.contains(searchQuery) ||
            fullName.contains(searchQuery) ||
            code.contains(searchQuery) ||
            email.contains(searchQuery) ||
            phone.contains(searchQuery) ||
            position.contains(searchQuery);
      });
    }

    return result.toList();
  }

  // ===========================================================================
  // API - RÉCUPÉRER LES EMPLOYÉS
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
          errorMessage = 'Session expirée. Veuillez vous reconnecter.';
        });

        return;
      }

      final response = await http.get(
        Uri.parse(ApiConfig.employees),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        final List<dynamic> fetchedList = _extractList(decoded);

        final List<Map<String, dynamic>> normalizedEmployees =
            fetchedList
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

        if (selectedIndex != null &&
            selectedIndex! >= employees.length) {
          setState(() {
            selectedIndex = employees.isEmpty ? null : 0;
          });
        }
      } else if (response.statusCode == 401) {
        setState(() {
          isLoading = false;
          errorMessage =
              'Votre session a expiré. Veuillez vous reconnecter.';
        });
      } else {
        setState(() {
          isLoading = false;
          errorMessage = _extractApiError(
            response.body,
            fallback:
                'Impossible de récupérer la liste des employés.',
          );
        });
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage =
            'Impossible de contacter le serveur. Vérifiez votre connexion.';
      });
    }
  }

  // ===========================================================================
  // NORMALISATION EMPLOYÉ
  // ===========================================================================

  Map<String, dynamic> _normalizeEmployee(
    Map<String, dynamic> employee,
  ) {
    final firstName = _stringValue(employee['first_name']);
    final lastName = _stringValue(employee['last_name']);

    final avatar = employee['avatar'] ??
        employee['photo'] ??
        employee['profile_photo'] ??
        employee['avatar_url'];

    final status = employee['status'] ??
        employee['attendance_status'] ??
        employee['presence_status'];

    return {
      ...employee,

      'employee_code': _stringValue(employee['employee_code']),
      'first_name': firstName,
      'last_name': lastName,
      'email': _stringValue(employee['email']),
      'phone': _stringValue(employee['phone']),
      'position': _stringValue(
        employee['position'],
        fallback: 'Non spécifié',
      ),

      'avatar': avatar,

      'initial': _buildInitials(
        firstName,
        lastName,
      ),

      // On conserve les valeurs API si elles existent.
      'status': status,

      'message': employee['message'],
      'time': employee['time'],
      'unread': employee['unread'] == true,
    };
  }

  // ===========================================================================
  // EXTRACTION DE LA LISTE JSON
  // ===========================================================================

  List<dynamic> _extractList(dynamic decoded) {
    if (decoded is List) {
      return decoded;
    }

    if (decoded is Map<String, dynamic>) {
      final data = decoded['data'];

      if (data is List) {
        return data;
      }

      if (data is Map<String, dynamic>) {
        final nestedData = data['data'];

        if (nestedData is List) {
          return nestedData;
        }

        if (data['employees'] is List) {
          return data['employees'] as List;
        }
      }

      if (decoded['employees'] is List) {
        return decoded['employees'] as List;
      }
    }

    return [];
  }

  // ===========================================================================
  // API - AJOUTER UN EMPLOYÉ
  // ===========================================================================

  Future<void> _createEmployee() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (isSaving) return;

    setState(() {
      isSaving = true;
    });

    try {
      final token = await AuthService.getToken();

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

      final body = {
        'employee_code': _codeController.text.trim(),
        'first_name': _firstNameController.text.trim(),
        'last_name': _lastNameController.text.trim(),
        'email': _emailController.text.trim(),
        'password': _passwordController.text,
        'position': _positionController.text.trim(),
        'phone': _phoneController.text.trim(),
      };

      final response = await http.post(
        Uri.parse(ApiConfig.employees),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      if (!mounted) return;

      if (response.statusCode == 200 ||
          response.statusCode == 201) {
        final responseData = _decodeResponse(response.body);

        final temporaryPin =
            _findTemporaryPin(responseData);

        Navigator.of(context).pop();

        await fetchEmployees();

        if (!mounted) return;

        setState(() {
          isSaving = false;
        });

        if (temporaryPin != null &&
            temporaryPin.toString().isNotEmpty) {
          await _showTemporaryPinDialog(
            temporaryPin.toString(),
          );
        } else {
          _showSuccess(
            'Employé créé avec succès.',
          );
        }
      } else if (response.statusCode == 422) {
        setState(() {
          isSaving = false;
        });

        _showError(
          _extractValidationErrors(response.body),
        );
      } else if (response.statusCode == 401) {
        setState(() {
          isSaving = false;
        });

        _showError(
          'Session expirée. Veuillez vous reconnecter.',
        );
      } else {
        setState(() {
          isSaving = false;
        });

        _showError(
          _extractApiError(
            response.body,
            fallback: 'Impossible de créer l’employé.',
          ),
        );
      }
    } catch (e) {
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
  // MODAL AJOUT
  // ===========================================================================

  void _showAddEmployeeModal() {
    _clearEmployeeForm();

    showDialog(
      context: context,
      barrierDismissible: !isSaving,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
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
                  Text(
                    'Ajouter un employé',
                    style: TextStyle(
                      color: textDark,
                      fontSize: 19,
                      fontWeight: FontWeight.w600,
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
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildFormField(
                          controller: _codeController,
                          label: 'Matricule RH',
                          hint: 'Ex. EMP-001',
                          icon: Icons.badge_outlined,
                          required: true,
                        ),
                        const SizedBox(height: 14),

                        _buildFormField(
                          controller: _firstNameController,
                          label: 'Prénom',
                          hint: 'Prénom de l’employé',
                          icon: Icons.person_outline,
                          required: true,
                        ),
                        const SizedBox(height: 14),

                        _buildFormField(
                          controller: _lastNameController,
                          label: 'Nom',
                          hint: 'Nom de famille',
                          icon: Icons.person_outline,
                          required: true,
                        ),
                        const SizedBox(height: 14),

                        _buildFormField(
                          controller: _emailController,
                          label: 'Adresse e-mail',
                          hint: 'employe@example.com',
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          required: true,
                        ),
                        const SizedBox(height: 14),

                        _buildFormField(
                          controller: _passwordController,
                          label: 'Mot de passe',
                          hint: 'Minimum 8 caractères',
                          icon: Icons.lock_outline,
                          obscureText: true,
                          required: true,
                        ),
                        const SizedBox(height: 14),

                        _buildFormField(
                          controller: _positionController,
                          label: 'Poste',
                          hint: 'Ex. Comptable',
                          icon: Icons.work_outline,
                        ),
                        const SizedBox(height: 14),

                        _buildFormField(
                          controller: _phoneController,
                          label: 'Téléphone',
                          hint: 'Ex. +225 07 XX XX XX XX',
                          icon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actionsPadding: const EdgeInsets.fromLTRB(
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
                          Navigator.of(dialogContext).pop();
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
                          child: CircularProgressIndicator(
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
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentBlue,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
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
  // CHAMP FORMULAIRE
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
        final text = value?.trim() ?? '';

        if (required && text.isEmpty) {
          return '$label est obligatoire.';
        }

        if (label == 'Adresse e-mail' &&
            text.isNotEmpty &&
            !_isValidEmail(text)) {
          return 'Veuillez saisir une adresse e-mail valide.';
        }

        if (label == 'Mot de passe' &&
            text.isNotEmpty &&
            text.length < 8) {
          return 'Le mot de passe doit contenir au moins 8 caractères.';
        }

        return null;
      },
      decoration: InputDecoration(
        labelText: required ? '$label *' : label,
        hintText: hint,
        prefixIcon: icon == null ? null : Icon(icon),
        filled: true,
        fillColor: const Color(0xFFF8F8F8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(7),
          borderSide: const BorderSide(
            color: borderColor,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(7),
          borderSide: const BorderSide(
            color: borderColor,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(7),
          borderSide: const BorderSide(
            color: accentBlue,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(7),
          borderSide: const BorderSide(
            color: dangerRed,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(7),
          borderSide: const BorderSide(
            color: dangerRed,
            width: 1.5,
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // DIALOG PIN TEMPORAIRE
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
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 18,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F7FB),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFFD6E7F7),
                  ),
                ),
                child: Column(
                  children: [
                    const Text(
                      'PIN TEMPORAIRE',
                      style: TextStyle(
                        color: textGrey,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SelectableText(
                      pin,
                      style: const TextStyle(
                        color: accentBlue,
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
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
              style: ElevatedButton.styleFrom(
                backgroundColor: accentBlue,
                foregroundColor: Colors.white,
                elevation: 0,
              ),
              child: const Text('J’ai noté le PIN'),
            ),
          ],
        );
      },
    );
  }

  // ===========================================================================
  // FORMULAIRE
  // ===========================================================================

  void _clearEmployeeForm() {
    _codeController.clear();
    _firstNameController.clear();
    _lastNameController.clear();
    _positionController.clear();
    _phoneController.clear();
    _emailController.clear();
    _passwordController.clear();

    isSaving = false;
  }

  // ===========================================================================
  // SÉLECTION EMPLOYÉ
  // ===========================================================================

  void _onEmployeeTap(
    int index,
    bool isDesktop,
  ) {
    final visibleEmployees = filteredEmployees;

    if (index < 0 || index >= visibleEmployees.length) {
      return;
    }

    final selectedEmployee = visibleEmployees[index];

    final realIndex = employees.indexOf(selectedEmployee);

    if (!mounted) return;

    setState(() {
      selectedIndex = realIndex >= 0 ? realIndex : null;
    });

    if (!isDesktop) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.82,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(18),
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: _buildEmployeeDetailsContent(
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
    if (selectedIndex == null ||
        selectedIndex! < 0 ||
        selectedIndex! >= employees.length) {
      return const SizedBox.shrink();
    }

    final employee = employees[selectedIndex!];

    final firstName = _stringValue(employee['first_name']);
    final lastName = _stringValue(employee['last_name']);

    final fullName = '$firstName $lastName'.trim();

    final code = _stringValue(
      employee['employee_code'],
      fallback: 'Non renseigné',
    );

    final position = _stringValue(
      employee['position'],
      fallback: 'Non spécifié',
    );

    final email = _stringValue(
      employee['email'],
      fallback: 'Non renseigné',
    );

    final phone = _stringValue(
      employee['phone'],
      fallback: 'Non renseigné',
    );

    final status = _getEmployeeStatus(employee);

    final avatar = employee['avatar'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showCloseButton)
          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              icon: const Icon(Icons.close),
              color: textGrey,
            ),
          ),

        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAvatar(
              employee,
              radius: 34,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fullName.isEmpty
                        ? 'Employé sans nom'
                        : fullName,
                    style: const TextStyle(
                      color: textDark,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$position • $code',
                    style: const TextStyle(
                      color: textGrey,
                      fontSize: 13,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),
                  _buildStatusBadge(status),
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
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 12),

        _buildInfoTile(
          icon: Icons.badge_outlined,
          title: 'Matricule',
          value: code,
        ),

        _buildInfoTile(
          icon: Icons.work_outline,
          title: 'Poste',
          value: position,
        ),

        _buildInfoTile(
          icon: Icons.email_outlined,
          title: 'E-mail',
          value: email,
        ),

        _buildInfoTile(
          icon: Icons.phone_outlined,
          title: 'Téléphone',
          value: phone,
        ),

        const SizedBox(height: 18),

        const Text(
          'Pointage',
          style: TextStyle(
            color: textDark,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 12),

        _buildAttendanceInfo(employee),

        const Spacer(),

        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              _showComingSoon(
                'La modification de l’employé sera connectée à l’API.',
              );
            },
            icon: const Icon(
              Icons.edit_outlined,
              size: 17,
            ),
            label: const Text('Modifier l’employé'),
            style: OutlinedButton.styleFrom(
              foregroundColor: accentBlue,
              side: const BorderSide(
                color: accentBlue,
              ),
              padding: const EdgeInsets.symmetric(
                vertical: 13,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // INFORMATIONS POINTAGE
  // ===========================================================================

  Widget _buildAttendanceInfo(
    Map<String, dynamic> employee,
  ) {
    final status = _getEmployeeStatus(employee);

    final checkIn = _firstNonEmpty([
      employee['check_in'],
      employee['checkIn'],
      employee['arrival_time'],
      employee['checkin'],
    ]);

    final checkOut = _firstNonEmpty([
      employee['check_out'],
      employee['checkOut'],
      employee['departure_time'],
      employee['checkout'],
    ]);

    final attendanceDate = _firstNonEmpty([
      employee['attendance_date'],
      employee['date'],
      employee['attendanceDate'],
    ]);

    final message = _firstNonEmpty([
      employee['message'],
      employee['attendance_message'],
    ]);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: bgLight,
        borderRadius: BorderRadius.circular(8),
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
              _buildStatusBadge(status),
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
              padding: EdgeInsets.symmetric(
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
      padding: const EdgeInsets.symmetric(
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
              style: const TextStyle(
                color: textGrey,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: textDark,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // TILE INFORMATION
  // ===========================================================================

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: bgLight,
          borderRadius: BorderRadius.circular(7),
        ),
        child: Icon(
          icon,
          color: accentBlue,
          size: 19,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: textGrey,
          fontSize: 11,
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Text(
          value,
          style: const TextStyle(
            color: textDark,
            fontSize: 14,
            fontWeight: FontWeight.w500,
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
    final list = filteredEmployees;

    if (list.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.separated(
      padding: const EdgeInsets.only(
        top: 4,
        bottom: 20,
      ),
      itemCount: list.length,
      separatorBuilder: (context, index) {
        return const Divider(
          height: 1,
          indent: 82,
          endIndent: 12,
          color: borderColor,
        );
      },
      itemBuilder: (context, index) {
        final employee = list[index];

        final realIndex = employees.indexOf(employee);

        final isSelected =
            realIndex >= 0 &&
            selectedIndex == realIndex;

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
    final firstName = _stringValue(
      employee['first_name'],
    );

    final lastName = _stringValue(
      employee['last_name'],
    );

    final fullName = '$firstName $lastName'.trim();

    final position = _stringValue(
      employee['position'],
      fallback: 'Poste non spécifié',
    );

    final code = _stringValue(
      employee['employee_code'],
    );

    final status = _getEmployeeStatus(employee);

    final message = _firstNonEmpty([
      employee['message'],
      employee['attendance_message'],
    ]);

    final time = _firstNonEmpty([
      employee['time'],
      employee['updated_at'],
      employee['last_attendance'],
    ]);

    return Material(
      color: isSelected && isDesktop
          ? hoverColor
          : Colors.transparent,
      child: InkWell(
        onTap: () => _onEmployeeTap(
          index,
          isDesktop,
        ),
        hoverColor: hoverColor,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 11,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
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
                            style: const TextStyle(
                              color: textDark,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow:
                                TextOverflow.ellipsis,
                          ),
                        ),
                        if (time != null)
                          Padding(
                            padding:
                                const EdgeInsets.only(
                              left: 8,
                            ),
                            child: Text(
                              _formatShortDate(time),
                              style: TextStyle(
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

                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '$position${code.isNotEmpty ? ' • $code' : ''}',
                            style: const TextStyle(
                              color: textGrey,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow:
                                TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _buildStatusDot(status),
                      ],
                    ),

                    if (message != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        message,
                        style: const TextStyle(
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
    final avatar = employee['avatar'];

    final initials = _stringValue(
      employee['initial'],
      fallback: '?',
    );

    final imageUrl = avatar?.toString();

    return CircleAvatar(
      radius: radius,
      backgroundColor: accentBlue.withValues(
        alpha: 0.12,
      ),
      backgroundImage:
          imageUrl != null && imageUrl.isNotEmpty
              ? NetworkImage(imageUrl)
              : null,
      onBackgroundImageError:
          imageUrl != null && imageUrl.isNotEmpty
              ? (_, __) {}
              : null,
      child: imageUrl == null || imageUrl.isEmpty
          ? Text(
              initials,
              style: TextStyle(
                color: accentBlue,
                fontSize: radius * 0.55,
                fontWeight: FontWeight.bold,
              ),
            )
          : null,
    );
  }

  // ===========================================================================
  // STATUS
  // ===========================================================================

  String _getEmployeeStatus(
    Map<String, dynamic> employee,
  ) {
    final rawStatus = employee['status'] ??
        employee['attendance_status'] ??
        employee['presence_status'];

    if (rawStatus == null) {
      return 'Non renseigné';
    }

    final status = rawStatus
        .toString()
        .trim()
        .toLowerCase();

    switch (status) {
      case 'present':
      case 'présent':
      case 'present aujourd’hui':
      case 'present aujourd’hui':
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
        color = accentBlue;
        break;
    }

    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
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
            successGreen.withValues(alpha: 0.10);
        break;

      case 'absent':
        foreground = dangerRed;
        background =
            dangerRed.withValues(alpha: 0.10);
        break;

      case 'en retard':
        foreground = warningOrange;
        background =
            warningOrange.withValues(alpha: 0.10);
        break;

      case 'en congé':
      case 'congé':
        foreground = accentBlue;
        background =
            accentBlue.withValues(alpha: 0.10);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: foreground,
          fontSize: 11,
          fontWeight: FontWeight.w600,
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
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 4,
      ),
      child: Row(
        children: filters.map((filter) {
          final selected =
              selectedFilter == filter;

          return Padding(
            padding: const EdgeInsets.only(
              right: 7,
            ),
            child: ChoiceChip(
              label: Text(filter),
              selected: selected,
              onSelected: (_) {
                setState(() {
                  selectedFilter = filter;
                });
              },
              selectedColor:
                  accentBlue.withValues(alpha: 0.12),
              backgroundColor: Colors.white,
              side: BorderSide(
                color: selected
                    ? accentBlue
                    : borderColor,
              ),
              labelStyle: TextStyle(
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
      padding: const EdgeInsets.fromLTRB(
        16,
        4,
        16,
        4,
      ),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(
          color: textDark,
          fontSize: 13,
        ),
        decoration: InputDecoration(
          hintText:
              'Rechercher par nom, matricule, poste...',
          hintStyle: const TextStyle(
            color: textGrey,
            fontSize: 13,
          ),
          prefixIcon: const Icon(
            Icons.search,
            color: textGrey,
            size: 20,
          ),
          suffixIcon: searchQuery.isEmpty
              ? null
              : IconButton(
                  onPressed: () {
                    _searchController.clear();
                  },
                  icon: const Icon(
                    Icons.close,
                    size: 18,
                    color: textGrey,
                  ),
                ),
          filled: true,
          fillColor: bgLight,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(
              color: borderColor,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(
              color: borderColor,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(
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
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: bgLight,
                borderRadius:
                    BorderRadius.circular(32),
              ),
              child: const Icon(
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
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: textGrey,
                fontSize: 14,
              ),
            ),
            if (hasSearch) ...[
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  setState(() {
                    selectedFilter = 'Toutes';
                    _searchController.clear();
                  });
                },
                child: const Text(
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
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: dangerRed.withValues(
                  alpha: 0.08,
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline,
                color: dangerRed,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Impossible de charger les employés',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: textDark,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              errorMessage ??
                  'Une erreur inconnue est survenue.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: textGrey,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: fetchEmployees,
              icon: const Icon(
                Icons.refresh,
                size: 18,
              ),
              label: const Text('Réessayer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: accentBlue,
                foregroundColor: Colors.white,
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
        padding: const EdgeInsets.fromLTRB(
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
                style: TextStyle(
                  color: textDark,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 9,
                vertical: 5,
              ),
              decoration: BoxDecoration(
                color: bgLight,
                borderRadius:
                    BorderRadius.circular(5),
              ),
              child: Text(
                '${employees.length}',
                style: const TextStyle(
                  color: textGrey,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            const SizedBox(width: 4),

            IconButton(
              tooltip: 'Actualiser',
              onPressed:
                  isLoading ? null : fetchEmployees,
              icon: const Icon(
                Icons.refresh_outlined,
                color: textGrey,
              ),
            ),

            IconButton(
              tooltip: 'Ajouter un employé',
              onPressed:
                  isSaving ? null : _showAddEmployeeModal,
              icon: const Icon(
                Icons.person_add_outlined,
                color: textGrey,
              ),
            ),

            PopupMenuButton<String>(
              tooltip: 'Options',
              icon: const Icon(
                Icons.more_vert,
                color: textGrey,
              ),
              onSelected: (value) {
                if (value == 'refresh') {
                  fetchEmployees();
                }

                if (value == 'add') {
                  _showAddEmployeeModal();
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: 'add',
                  child: Row(
                    children: [
                      Icon(
                        Icons.person_add_outlined,
                        size: 19,
                      ),
                      SizedBox(width: 10),
                      Text('Ajouter un employé'),
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
                      Text('Actualiser'),
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
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isDesktop =
            constraints.maxWidth > 850;

        return Row(
          children: [
            // ===============================================================
            // COLONNE GAUCHE
            // ===============================================================

            Container(
              width: isDesktop
                  ? 360
                  : constraints.maxWidth,
              decoration: BoxDecoration(
                color: panelLight,
                border: isDesktop
                    ? const Border(
                        right: BorderSide(
                          color: borderColor,
                          width: 1,
                        ),
                      )
                    : null,
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
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
                                isDesktop: isDesktop,
                              ),
                  ),
                ],
              ),
            ),

            // ===============================================================
            // PANNEAU DROIT DESKTOP
            // ===============================================================

            if (isDesktop)
              Expanded(
                child: Container(
                  color: bgLight,
                  padding: const EdgeInsets.all(12),
                  child: selectedIndex == null
                      ? _buildDesktopEmptyDetails()
                      : Card(
                          color: Colors.white,
                          elevation: 0,
                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(8),
                            side: const BorderSide(
                              color: borderColor,
                            ),
                          ),
                          child: Padding(
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
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius:
                  BorderRadius.circular(36),
            ),
            child: const Icon(
              Icons.person_search_outlined,
              size: 35,
              color: textGrey,
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Sélectionnez un employé',
            style: TextStyle(
              color: textDark,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Sélectionnez un employé dans la liste pour afficher ses informations et son pointage.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: textGrey,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
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

    final stringValue = value.toString().trim();

    if (stringValue.isEmpty ||
        stringValue == 'null') {
      return fallback;
    }

    return stringValue;
  }

  String? _firstNonEmpty(
    List<dynamic> values,
  ) {
    for (final value in values) {
      if (value == null) continue;

      final stringValue =
          value.toString().trim();

      if (stringValue.isNotEmpty &&
          stringValue != 'null') {
        return stringValue;
      }
    }

    return null;
  }

  String _buildInitials(
    String firstName,
    String lastName,
  ) {
    final first = firstName.trim();
    final last = lastName.trim();

    String result = '';

    if (first.isNotEmpty) {
      result += first[0];
    }

    if (last.isNotEmpty) {
      result += last[0];
    }

    if (result.isEmpty) {
      return '?';
    }

    return result.toUpperCase();
  }

  bool _isValidEmail(String email) {
    return RegExp(
      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
    ).hasMatch(email);
  }

  dynamic _decodeResponse(String body) {
    try {
      return jsonDecode(body);
    } catch (_) {
      return null;
    }
  }

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
      decoded['data'] is Map
          ? decoded['data']['temporary_pin']
          : null,
      decoded['data'] is Map
          ? decoded['data']['pin']
          : null,
      decoded['data'] is Map
          ? decoded['data']['temporaryPin']
          : null,
      decoded['employee'] is Map
          ? decoded['employee']['temporary_pin']
          : null,
    ];

    for (final candidate in candidates) {
      if (candidate != null &&
          candidate.toString().trim().isNotEmpty) {
        return candidate.toString();
      }
    }

    return null;
  }

  String _extractApiError(
    String body, {
    required String fallback,
  }) {
    final decoded = _decodeResponse(body);

    if (decoded is Map) {
      final message = decoded['message'];

      if (message is String &&
          message.trim().isNotEmpty) {
        return message.trim();
      }

      final error = decoded['error'];

      if (error is String &&
          error.trim().isNotEmpty) {
        return error.trim();
      }
    }

    if (body.trim().isNotEmpty &&
        !body.trim().startsWith('<')) {
      return body.trim();
    }

    return fallback;
  }

  String _extractValidationErrors(
    String body,
  ) {
    final decoded = _decodeResponse(body);

    if (decoded is Map) {
      final errors = decoded['errors'];

      if (errors is Map) {
        final messages = <String>[];

        errors.forEach((key, value) {
          if (value is List) {
            for (final item in value) {
              messages.add(item.toString());
            }
          } else if (value != null) {
            messages.add(value.toString());
          }
        });

        if (messages.isNotEmpty) {
          return messages.join('\n');
        }
      }

      final message = decoded['message'];

      if (message is String &&
          message.trim().isNotEmpty) {
        return message.trim();
      }
    }

    return 'Veuillez vérifier les informations saisies.';
  }

  String _formatShortDate(
    String value,
  ) {
    if (value.isEmpty) {
      return '';
    }

    try {
      final date = DateTime.parse(value);

      final hour = date.hour
          .toString()
          .padLeft(2, '0');

      final minute = date.minute
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
          backgroundColor: successGreen,
          behavior: SnackBarBehavior.floating,
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
          backgroundColor: dangerRed,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(
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
          behavior: SnackBarBehavior.floating,
        ),
      );
  }
}