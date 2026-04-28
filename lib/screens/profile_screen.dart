import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../services/permisions_service.dart';
import '../services/websocket_service.dart';
import '../utils/app_theme.dart';

/// Pantalla de perfil del usuario autenticado.
/// Permite tomar foto con la cámara o elegir desde la galería.
/// Usa [PermissionService] para solicitar permisos antes de acceder.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ImagePicker _picker = ImagePicker();
  File? _profileImage; // Null safety: puede ser null si no hay foto aún

  @override
  Widget build(BuildContext context) {
    final wsService = context.watch<WebSocketService>();
    final permService = context.read<PermissionService>();
    final user = wsService.currentUser;

    return Scaffold(
      backgroundColor: AppTheme.primary,
      appBar: AppBar(
        title: const Text('Mi Perfil'),
        actions: [
          // Botón de cerrar sesión
          IconButton(
            icon: const Icon(Icons.logout, color: AppTheme.textSecondary),
            tooltip: 'Cerrar sesión',
            onPressed: () => _confirmLogout(context, wsService),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 16),

            // ---- Avatar con opciones de foto ----
            _buildAvatar(context, permService),
            const SizedBox(height: 8),
            Text(
              'Toca el ícono para cambiar foto',
              style: const TextStyle(
                  color: AppTheme.textSecondary, fontSize: 12),
            ),

            const SizedBox(height: 32),

            // ---- Info del usuario ----
            _buildInfoCard(user?.username ?? 'Usuario'),

            const SizedBox(height: 24),

            // ---- Sección de permisos (estado visible) ----
            _buildPermissionsCard(context, permService),
          ],
        ),
      ),
    );
  }

  // ---- Avatar ----

  Widget _buildAvatar(BuildContext context, PermissionService permService) {
    return Stack(
      children: [
        CircleAvatar(
          radius: 60,
          backgroundColor: AppTheme.surface,
          backgroundImage:
              _profileImage != null ? FileImage(_profileImage!) : null,
          child: _profileImage == null
              ? const Icon(Icons.person,
                  size: 60, color: AppTheme.textSecondary)
              : null,
        ),
        Positioned(
          right: 0,
          bottom: 0,
          child: GestureDetector(
            onTap: () => _showImageSourceSheet(context, permService),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.accent,
                shape: BoxShape.circle,
                border:
                    Border.all(color: AppTheme.primary, width: 2),
              ),
              child: const Icon(Icons.camera_alt,
                  color: AppTheme.primary, size: 18),
            ),
          ),
        ),
      ],
    );
  }

  // ---- Info card ----

  Widget _buildInfoCard(String username) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.accent.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.person_outline,
                  color: AppTheme.accent, size: 22),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Usuario',
                    style: TextStyle(
                        color: AppTheme.textSecondary, fontSize: 12)),
                Text(
                  username,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ---- Permisos card ----

  Widget _buildPermissionsCard(
      BuildContext context, PermissionService permService) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Estado de Permisos',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 16),
            _buildPermissionRow(
              icon: Icons.camera_alt_outlined,
              label: 'Cámara',
              granted: permService.isCameraGranted,
              onRequest: () async {
                final result = await permService.requestCamera();
                if (context.mounted) {
                  _showSnack(context, result.message,
                      result.granted ? AppTheme.safe : AppTheme.warning);
                  // Si está bloqueada permanentemente, ofrecer ir a ajustes
                  if (!result.granted &&
                      result.message.contains('Ajustes')) {
                    _showOpenSettingsDialog(context, permService);
                  }
                }
              },
            ),
            const Divider(height: 20, color: AppTheme.primary),
            _buildPermissionRow(
              icon: Icons.photo_library_outlined,
              label: 'Galería / Fotos',
              granted: permService.isGalleryGranted,
              onRequest: () async {
                final result = await permService.requestGallery();
                if (context.mounted) {
                  _showSnack(context, result.message,
                      result.granted ? AppTheme.safe : AppTheme.warning);
                  if (!result.granted &&
                      result.message.contains('Ajustes')) {
                    _showOpenSettingsDialog(context, permService);
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionRow({
    required IconData icon,
    required String label,
    required bool granted,
    required VoidCallback onRequest,
  }) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.textSecondary, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(label,
              style: const TextStyle(
                  color: AppTheme.textPrimary, fontSize: 14)),
        ),
        granted
            ? Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.safe.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: AppTheme.safe.withOpacity(0.5)),
                ),
                child: const Text('Concedido',
                    style: TextStyle(
                        color: AppTheme.safe,
                        fontSize: 11,
                        fontWeight: FontWeight.w600)),
              )
            : TextButton(
                onPressed: onRequest,
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.accent,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                ),
                child: const Text('Solicitar',
                    style: TextStyle(fontSize: 12)),
              ),
      ],
    );
  }

  // ----------------------------------------------------------------
  // LÓGICA DE IMÁGENES
  // ----------------------------------------------------------------

  /// Muestra un BottomSheet para elegir entre cámara y galería
  void _showImageSourceSheet(
      BuildContext context, PermissionService permService) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.textSecondary.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Seleccionar foto',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            _buildSheetOption(
              icon: Icons.camera_alt_outlined,
              label: 'Tomar foto',
              color: AppTheme.accent,
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.camera, permService);
              },
            ),
            const SizedBox(height: 12),
            _buildSheetOption(
              icon: Icons.photo_library_outlined,
              label: 'Elegir de la galería',
              color: AppTheme.accent,
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.gallery, permService);
              },
            ),
            if (_profileImage != null) ...[
              const SizedBox(height: 12),
              _buildSheetOption(
                icon: Icons.delete_outline,
                label: 'Eliminar foto',
                color: AppTheme.danger,
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() => _profileImage = null);
                },
              ),
            ],
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildSheetOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 12),
            Text(label,
                style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w500,
                    fontSize: 14)),
          ],
        ),
      ),
    );
  }

  /// Solicita el permiso correspondiente y luego abre cámara o galería
  Future<void> _pickImage(
      ImageSource source, PermissionService permService) async {
    // 1. Solicitar permiso según la fuente
    final PermissionResult result;
    if (source == ImageSource.camera) {
      result = await permService.requestCamera();
    } else {
      result = await permService.requestGallery();
    }

    if (!result.granted) {
      if (mounted) {
        _showSnack(context, result.message, AppTheme.warning);
        if (result.message.contains('Ajustes')) {
          _showOpenSettingsDialog(context, permService);
        }
      }
      return;
    }

    // 2. Abrir cámara o galería
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 80,  // Comprimir un poco la imagen
        maxWidth: 800,
      );

      if (pickedFile != null && mounted) {
        setState(() => _profileImage = File(pickedFile.path));
      }
    } catch (e) {
      if (mounted) {
        _showSnack(context, 'Error al acceder a la imagen: $e',
            AppTheme.danger);
      }
    }
  }

  // ----------------------------------------------------------------
  // HELPERS DE UI
  // ----------------------------------------------------------------

  void _showSnack(BuildContext context, String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showOpenSettingsDialog(
      BuildContext context, PermissionService permService) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Permiso bloqueado',
            style: TextStyle(color: AppTheme.textPrimary)),
        content: const Text(
          'El permiso fue denegado permanentemente. '
          '¿Deseas ir a Ajustes para habilitarlo?',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar',
                style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              permService.openSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accent,
              foregroundColor: AppTheme.primary,
            ),
            child: const Text('Ir a Ajustes'),
          ),
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext context, WebSocketService service) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Cerrar sesión',
            style: TextStyle(color: AppTheme.textPrimary)),
        content: const Text('¿Seguro que deseas salir?',
            style: TextStyle(color: AppTheme.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar',
                style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              service.logout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.danger,
              foregroundColor: Colors.white,
            ),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
  }
}