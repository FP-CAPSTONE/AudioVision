class DummyApi {
  static Map<String, String> registeredUsers = {};

  static void registerUser(String name, String email, String password) {
    registeredUsers[email] = password;
  }

  static bool loginUser(String email, String password) {
    return registeredUsers[email] == password;
  }
}
