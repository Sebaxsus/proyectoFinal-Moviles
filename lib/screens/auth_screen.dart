import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:gas_monitor/gas_monitor.dart';

/// Pantalla de autenticación con dos modos: Login y Registro.
/// Se muestra cuando [AuthStatus] es [unauthenticated] o [error].
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  // Controlador de pestañas Login / Registro
  late TabController _tabController;

  // Controladores de texto — se limpian en dispose()
  final _loginUserCtrl = TextEditingController();
  final _loginPassCtrl = TextEditingController();
  final _regUserCtrl = TextEditingController();
  final _regPassCtrl = TextEditingController();
  final _regPassConfirmCtrl = TextEditingController();

  // Claves de formulario para validación
  final _loginFormKey = GlobalKey<FormState>();
  final _regFormKey = GlobalKey<FormState>();

  // Ocultar/mostrar contraseñas
  bool _loginPassVisible = false;
  bool _regPassVisible = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _loginUserCtrl.dispose();
    _loginPassCtrl.dispose();
    _regUserCtrl.dispose();
    _regPassCtrl.dispose();
    _regPassConfirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!(_loginFormKey.currentState?.validate() ?? false)) return;
    await context.read<WebSocketService>().login(
          _loginUserCtrl.text.trim(),
          _loginPassCtrl.text,
        );
  }

  Future<void> _handleRegister() async {
    if (!(_regFormKey.currentState?.validate() ?? false)) return;
    await context.read<WebSocketService>().register(
          _regUserCtrl.text.trim(),
          _regPassCtrl.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<WebSocketService>();
    final isLoading = service.authStatus == AuthStatus.loading;

    return Scaffold(
      backgroundColor: AppTheme.primary,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 48),
              _buildLogo(),
              const SizedBox(height: 40),
              _buildTabBar(),
              const SizedBox(height: 24),

              // Error global del servicio
              if (service.authError != null) _buildErrorBanner(service.authError!),

              // Contenido de la pestaña activa
              SizedBox(
                height: 380,
                child: TabBarView(
                  controller: _tabController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildLoginForm(isLoading),
                    _buildRegisterForm(isLoading),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: AppTheme.accent.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppTheme.accent.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: const Icon(Icons.gas_meter_outlined,
              color: AppTheme.accent, size: 36),
        ),
        const SizedBox(height: 16),
        const Text(
          'Gas Monitor',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 26,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Sistema de monitoreo IoT',
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.accent.withOpacity(0.15)),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: AppTheme.accent.withOpacity(0.2),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.accent.withOpacity(0.5)),
        ),
        labelColor: AppTheme.accent,
        unselectedLabelColor: AppTheme.textSecondary,
        labelStyle:
            const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(text: 'Iniciar Sesión'),
          Tab(text: 'Registrarse'),
        ],
      ),
    );
  }

  Widget _buildErrorBanner(String error) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.danger.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.danger.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppTheme.danger, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              error,
              style: const TextStyle(
                  color: AppTheme.danger, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  // ---- FORMULARIO DE LOGIN ----

  Widget _buildLoginForm(bool isLoading) {
    return Form(
      key: _loginFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTextField(
            controller: _loginUserCtrl,
            label: 'Usuario',
            icon: Icons.person_outline,
            validator: _validateUsername,
          ),
          const SizedBox(height: 14),
          _buildTextField(
            controller: _loginPassCtrl,
            label: 'Contraseña',
            icon: Icons.lock_outline,
            isPassword: true,
            isVisible: _loginPassVisible,
            onToggleVisibility: () =>
                setState(() => _loginPassVisible = !_loginPassVisible),
            validator: _validatePassword,
          ),
          const SizedBox(height: 28),
          _buildSubmitButton(
            label: 'Iniciar Sesión',
            isLoading: isLoading,
            onPressed: _handleLogin,
          ),
        ],
      ),
    );
  }

  // ---- FORMULARIO DE REGISTRO ----

  Widget _buildRegisterForm(bool isLoading) {
    return Form(
      key: _regFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTextField(
            controller: _regUserCtrl,
            label: 'Nombre de usuario',
            icon: Icons.person_add_outlined,
            validator: _validateUsername,
          ),
          const SizedBox(height: 14),
          _buildTextField(
            controller: _regPassCtrl,
            label: 'Contraseña',
            icon: Icons.lock_outline,
            isPassword: true,
            isVisible: _regPassVisible,
            onToggleVisibility: () =>
                setState(() => _regPassVisible = !_regPassVisible),
            validator: _validatePassword,
          ),
          const SizedBox(height: 14),
          _buildTextField(
            controller: _regPassConfirmCtrl,
            label: 'Confirmar contraseña',
            icon: Icons.lock_person_outlined,
            isPassword: true,
            isVisible: _regPassVisible,
            onToggleVisibility: () =>
                setState(() => _regPassVisible = !_regPassVisible),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Confirma tu contraseña';
              }
              if (value != _regPassCtrl.text) {
                return 'Las contraseñas no coinciden';
              }
              return null;
            },
          ),
          const SizedBox(height: 28),
          _buildSubmitButton(
            label: 'Crear Cuenta',
            isLoading: isLoading,
            onPressed: _handleRegister,
          ),
        ],
      ),
    );
  }

  // ---- CAMPO DE TEXTO REUTILIZABLE ----

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    bool isVisible = false,
    VoidCallback? onToggleVisibility,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword && !isVisible,
      style: const TextStyle(color: AppTheme.textPrimary),
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppTheme.textSecondary),
        prefixIcon: Icon(icon, color: AppTheme.textSecondary, size: 20),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  isVisible ? Icons.visibility_off : Icons.visibility,
                  color: AppTheme.textSecondary,
                  size: 18,
                ),
                onPressed: onToggleVisibility,
              )
            : null,
        filled: true,
        fillColor: AppTheme.surface,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              BorderSide(color: AppTheme.accent.withOpacity(0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.accent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.danger, width: 1.5),
        ),
        errorStyle: const TextStyle(color: AppTheme.danger, fontSize: 11),
      ),
    );
  }

  // ---- BOTÓN DE ENVÍO ----

  Widget _buildSubmitButton({
    required String label,
    required bool isLoading,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      height: 50,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.accent,
          foregroundColor: AppTheme.primary,
          disabledBackgroundColor: AppTheme.accent.withOpacity(0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: AppTheme.primary,
                  strokeWidth: 2.5,
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
      ),
    );
  }

  // ---- VALIDADORES ----

  String? _validateUsername(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El usuario no puede estar vacío';
    }
    if (value.trim().length < 3) {
      return 'Mínimo 3 caracteres';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'La contraseña no puede estar vacía';
    }
    if (value.length < 6) {
      return 'Mínimo 6 caracteres';
    }
    return null;
  }
}