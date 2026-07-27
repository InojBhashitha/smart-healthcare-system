class ApiConstants {
  ApiConstants._();

  /// Change this to your computer's IP address.
  ///
  /// For Android emulators, use 10.0.2.2 if you run the backend from the host machine.
  static const String host = "192.168.20.164";

  static const int port = 8080;

  static const String baseUrl = "http://$host:$port";

  static const String login = "/api/auth/login";

  static const String register = "/api/auth/register";

  static const String uploadPrescription =
    "/api/prescriptions/upload";

  static const String prescriptions = "/api/prescriptions";
}