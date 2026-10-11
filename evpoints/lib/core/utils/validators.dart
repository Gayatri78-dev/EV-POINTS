class Validators {
  Validators._();

  static String? requiredField(String? value, [String? label]) {
    if (value == null || value.trim().isEmpty) {
      return label != null ? '$label is required.' : 'This field is required.';
    }
    return null;
  }

  static String? email(String? value) {
    final req = requiredField(value, 'Email');
    if (req != null) return req;
    final regex = RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!regex.hasMatch(value!.trim())) return 'Enter a valid email address.';
    return null;
  }

  static String? password(String? value) {
    final req = requiredField(value, 'Password');
    if (req != null) return req;
    if (value!.length < 6) return 'Password must be at least 6 characters.';
    return null;
  }

  static String? confirmPassword(String? value, String password) {
    final req = requiredField(value, 'Confirm Password');
    if (req != null) return req;
    if (value != password) return 'Passwords do not match.';
    return null;
  }

  static String? fullName(String? value) {
    final req = requiredField(value, 'Full name');
    if (req != null) return req;
    if (value!.trim().length < 2) return 'Name must be at least 2 characters.';
    return null;
  }
}
