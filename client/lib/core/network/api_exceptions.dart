class ApiException implements Exception {
  const ApiException({
    required this.code,
    required this.message,
    this.statusCode,
    this.details = const {},
  });

  final String code;
  final String message;
  final int? statusCode;
  final Map<String, dynamic> details;

  @override
  String toString() => 'ApiException($code): $message';
}

class ValidationException extends ApiException {
  const ValidationException({
    required super.message,
    required super.details,
    super.statusCode = 422,
  }) : super(code: 'validation_failed');

  List<String> get fieldErrors {
    final fields = details['fields'] is Map
        ? details['fields'] as Map
        : (details.isNotEmpty ? details : null);
    if (fields != null) {
      final list = <String>[];
      for (final entry in fields.entries) {
        if (entry.value is List) {
          list.addAll((entry.value as List).map((e) => e.toString()));
        } else if (entry.value is String) {
          list.add(entry.value as String);
        }
      }
      return list;
    }
    return [message];
  }

  @override
  String toString() {
    final errors = fieldErrors;
    if (errors.isNotEmpty && errors.first != message) {
      return errors.join(' ');
    }
    return message;
  }
}

class UnauthenticatedException extends ApiException {
  const UnauthenticatedException([String message = 'Please log in again.'])
    : super(code: 'unauthenticated', message: message, statusCode: 401);
}

class NetworkException extends ApiException {
  const NetworkException([
    String message =
        'Unable to connect to server. Check your network connection.',
  ]) : super(code: 'network_error', message: message);
}
