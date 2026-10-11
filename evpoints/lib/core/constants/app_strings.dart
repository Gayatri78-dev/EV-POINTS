class AppStrings {
  AppStrings._();

  static const String appName = 'EV Charge Finder';
  static const String tagline = 'Find. Charge. Drive.';

  // Auth
  static const String login = 'Login';
  static const String register = 'Register';
  static const String logout = 'Logout';
  static const String email = 'Email';
  static const String password = 'Password';
  static const String confirmPassword = 'Confirm Password';
  static const String fullName = 'Full Name';
  static const String noAccount = "Don't have an account? Register";
  static const String haveAccount = 'Already have an account? Login';
  static const String loginSuccess = 'Login successful!';
  static const String registerSuccess = 'Registration successful! Please login.';
  static const String logoutSuccess = 'Logged out successfully.';

  // Map
  static const String searchHint = 'Search charging stations...';
  static const String filterAll = 'All';
  static const String filterAC = 'AC';
  static const String filterDC = 'DC';
  static const String filterFast = 'Fast Charge';
  static const String centreOnMe = 'Centre on Me';

  // Spots
  static const String viewDetails = 'View Details';
  static const String navigate = 'Navigate';
  static const String available = 'Available';
  static const String unavailable = 'Unavailable';
  static const String noSpots = 'No charging stations found.';

  // Profile
  static const String editProfile = 'Edit Profile';
  static const String changePassword = 'Change Password';
  static const String savedSpots = 'Saved Spots';
  static const String save = 'Save';
  static const String cancel = 'Cancel';

  // Errors
  static const String genericError = 'Something went wrong. Please try again.';
  static const String networkError = 'Network error. Check your connection.';
  static const String sessionExpired = 'Session expired. Please login again.';
  static const String locationPermissionDenied = 'Location permission denied.';

  // Validation
  static const String fieldRequired = 'This field is required.';
  static const String invalidEmail = 'Enter a valid email address.';
  static const String passwordTooShort = 'Password must be at least 6 characters.';
  static const String passwordMismatch = 'Passwords do not match.';

  // Navigation tabs
  static const String tabMap = 'Map';
  static const String tabSpots = 'Spots';
  static const String tabProfile = 'Profile';
}
