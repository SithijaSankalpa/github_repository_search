sealed class ApiException implements Exception {
  final String message;
  ApiException (this.message);

  @override
  String toString() => message;
  }

  class UnauthorizedException extends ApiException{
    UnauthorizedException() : super('Invalid or expired token. Please re-enter your token');
  }
class RateLimitException extends ApiException{
  RateLimitException() : super('Rate limit exceeded. Please wait a moment and try again');
}
class NetworkException extends ApiException{
  NetworkException() : super('Network error. Check your connection and try again');
}
class InvalidQueryException extends ApiException{
  InvalidQueryException() : super('Invalid search query');
}
class UnknownApiException extends ApiException{
  UnknownApiException(String message) : super(message);
}
