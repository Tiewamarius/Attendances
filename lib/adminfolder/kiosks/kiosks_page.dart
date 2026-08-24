import 'package:flutter/material.dart';

import 'package:attendance/controllers/admins/kiosk_controller.dart';
import 'package:attendance/models/admins/kiosk_model..dart';

class KioskPage extends StatefulWidget {
  const KioskPage({super.key});

  @override
  State<KioskPage> createState() => _KioskPageState();
}

class _KioskPageState extends State<KioskPage> {
  late final KioskController controller;

  @override
  void initState() {
    super.initState();

    controller = KioskController();

    controller.loadKiosks();
  }

  @override
  void dispose() {
    controller.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),

      appBar: AppBar(
        title: const Text('Kiosks de pointage'),

        actions: [
          IconButton(
            onPressed: controller.loading
                ? null
                : controller.loadKiosks,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),

      body: ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          if (controller.loading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (controller.error != null) {
            return _buildError();
          }

          if (controller.kiosks.isEmpty) {
            return _buildEmpty();
          }

          return RefreshIndicator(
            onRefresh: controller.loadKiosks,
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: controller.kiosks.length,
              itemBuilder: (context, index) {
                final kiosk = controller.kiosks[index];

                return _buildKioskCard(kiosk);
              },
            ),
          );
        },
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateDialog,
        icon: const Icon(Icons.add),
        label: const Text('Ajouter'),
      ),
    );
  }

  // ============================================================
  // CARD
  // ============================================================

  Widget _buildKioskCard(KioskModel kiosk) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: kiosk.active
              ? Colors.green.shade100
              : Colors.red.shade100,
          child: Icon(
            Icons.point_of_sale,
            color: kiosk.active
                ? Colors.green
                : Colors.red,
          ),
        ),

        title: Text(
          kiosk.name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),

        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Text('Code : ${kiosk.code}'),

            if (kiosk.location != null)
              Text('Lieu : ${kiosk.location}'),

            Text('Mode : ${kiosk.method}'),

            if (kiosk.ipAddress != null)
              Text('IP : ${kiosk.ipAddress}'),

            const SizedBox(height: 5),

            Text(
              kiosk.active ? 'Actif' : 'Inactif',
              style: TextStyle(
                color: kiosk.active
                    ? Colors.green
                    : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),

        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'toggle':
                _toggleKiosk(kiosk);

                break;

              case 'delete':
                _deleteKiosk(kiosk);

                break;
            }
          },

          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'toggle',
              child: Row(
                children: [
                  Icon(
                    kiosk.active
                        ? Icons.block
                        : Icons.check_circle,
                    color: kiosk.active
                        ? Colors.orange
                        : Colors.green,
                  ),

                  const SizedBox(width: 10),

                  Text(
                    kiosk.active
                        ? 'Désactiver'
                        : 'Activer',
                  ),
                ],
              ),
            ),

            const PopupMenuDivider(),

            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(
                    Icons.delete,
                    color: Colors.red,
                  ),

                  SizedBox(width: 10),

                  Text('Supprimer'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // TOGGLE
  // ============================================================

  Future<void> _toggleKiosk(KioskModel kiosk) async {
    final success = await controller.toggleKiosk(kiosk.id);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'État du kiosk modifié'
              : controller.error ?? 'Erreur',
        ),
        backgroundColor:
            success ? Colors.green : Colors.red,
      ),
    );
  }

  // ============================================================
  // DELETE
  // ============================================================

  Future<void> _deleteKiosk(KioskModel kiosk) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Supprimer le kiosk ?'),

          content: Text(
            'Voulez-vous supprimer "${kiosk.name}" ?',
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Annuler'),
            ),

            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Supprimer'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    final success = await controller.deleteKiosk(
      kiosk.id,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Kiosk supprimé'
              : controller.error ?? 'Erreur',
        ),
        backgroundColor:
            success ? Colors.green : Colors.red,
      ),
    );
  }

  // ============================================================
  // CREATE DIALOG
  // ============================================================

  void _showCreateDialog() {
    final nameController = TextEditingController();
    final codeController = TextEditingController();
    final locationController = TextEditingController();
    final ipController = TextEditingController();

    String method = 'KIOSK_QR';
    bool active = true;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Ajouter un kiosk'),

              content: SizedBox(
                width: 500,

                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: nameController,
                        decoration:
                            const InputDecoration(
                          labelText: 'Nom',
                          border: OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(height: 15),

                      TextField(
                        controller: codeController,
                        decoration:
                            const InputDecoration(
                          labelText: 'Code',
                          border: OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(height: 15),

                      TextField(
                        controller: locationController,
                        decoration:
                            const InputDecoration(
                          labelText: 'Emplacement',
                          border: OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(height: 15),

                      DropdownButtonFormField<String>(
                        initialValue: method,

                        decoration:
                            const InputDecoration(
                          labelText: 'Mode',
                          border: OutlineInputBorder(),
                        ),

                        items: const [
                          DropdownMenuItem(
                            value: 'KIOSK_QR',
                            child: Text(
                              'QR Code + PIN',
                            ),
                          ),

                          DropdownMenuItem(
                            value: 'qr',
                            child: Text(
                              'QR Code uniquement',
                            ),
                          ),

                          DropdownMenuItem(
                            value: 'KIOSK_PIN',
                            child: Text(
                              'PIN uniquement',
                            ),
                          ),
                        ],

                        onChanged: (value) {
                          setDialogState(() {
                            method = value ?? 'KIOSK_QR';
                          });
                        },
                      ),

                      const SizedBox(height: 15),

                      TextField(
                        controller: ipController,
                        decoration:
                            const InputDecoration(
                          labelText:
                              'Adresse IP (optionnel)',
                          border: OutlineInputBorder(),
                        ),
                      ),

                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,

                        title: const Text(
                          'Kiosk actif',
                        ),

                        value: active,

                        onChanged: (value) {
                          setDialogState(() {
                            active = value;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),

              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Annuler'),
                ),

                ElevatedButton(
                  onPressed: () async {
                    if (nameController.text
                        .trim()
                        .isEmpty) {
                      return;
                    }

                    if (codeController.text
                        .trim()
                        .isEmpty) {
                      return;
                    }

                    final success =
                        await controller.createKiosk(
                      name:
                          nameController.text.trim(),


                      location:
                          locationController.text
                              .trim(),

                      method: method,

                      ipAddress:
                          ipController.text
                              .trim()
                              .isEmpty
                          ? null
                          : ipController.text
                              .trim(),

                      active: active,
                    );

                    if (!mounted) return;

                    if (success) {
                      Navigator.pop(dialogContext);

                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Kiosk créé avec succès',
                          ),
                          backgroundColor:
                              Colors.green,
                        ),
                      );
                    }
                  },

                  child: const Text('Créer'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ============================================================
  // EMPTY
  // ============================================================

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment:
            MainAxisAlignment.center,

        children: [
          Icon(
            Icons.point_of_sale_outlined,
            size: 70,
            color: Colors.grey.shade400,
          ),

          const SizedBox(height: 15),

          const Text(
            'Aucun kiosk',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          const Text(
            'Aucun appareil de pointage configuré.',
            style: TextStyle(
              color: Colors.grey,
            ),
          ),

          const SizedBox(height: 20),

          ElevatedButton.icon(
            onPressed: _showCreateDialog,
            icon: const Icon(Icons.add),
            label: const Text('Ajouter un kiosk'),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ERROR
  // ============================================================

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment:
            MainAxisAlignment.center,

        children: [
          const Icon(
            Icons.error_outline,
            size: 60,
            color: Colors.red,
          ),

          const SizedBox(height: 15),

          Text(
            controller.error ??
                'Une erreur est survenue.',
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 20),

          ElevatedButton.icon(
            onPressed: controller.loadKiosks,
            icon: const Icon(Icons.refresh),
            label: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }
}