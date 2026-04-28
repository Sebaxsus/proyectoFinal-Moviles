// Posibles estados del flujo de Auth
enum AuthStatus {
  unauthenticated,  /// El usuario no ha iniciado sesión
  loading,          /// Se está procesando login o registro
  authenticated,    /// El usuario está autenticado correctamente
  error,            /// Hubo un error en el proceso
}