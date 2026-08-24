class AuthFailure implements Exception {
  const AuthFailure(this.message, {this.cancelled = false});

  final String message;
  final bool cancelled;

  factory AuthFailure.cancelled() => const AuthFailure('Cancelled', cancelled: true);

  @override
  String toString() => message;
}
