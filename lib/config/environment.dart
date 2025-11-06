class Environment {
  // Read from --dart-define variables (passed at build time)
  // Fallback to empty string if not provided (will cause errors, forcing proper configuration)
  static const String appwriteProjectId = String.fromEnvironment(
    'APPWRITE_PROJECT_ID',
    defaultValue: '',
  );

  static const String appwriteProjectName = String.fromEnvironment(
    'APPWRITE_PROJECT_NAME',
    defaultValue: 'ollie',
  );

  static const String appwritePublicEndpoint = String.fromEnvironment(
    'APPWRITE_ENDPOINT',
    defaultValue: '',
  );

  static const String appwriteDatabaseId = String.fromEnvironment(
    'APPWRITE_DATABASE_ID',
    defaultValue: '',
  );

  // App URL for password reset redirects
  static const String appUrl = String.fromEnvironment(
    'APP_URL',
    defaultValue: 'http://localhost:8080',
  );

  // Validation helper
  static bool get isConfigured {
    return appwriteProjectId.isNotEmpty &&
        appwritePublicEndpoint.isNotEmpty &&
        appwriteDatabaseId.isNotEmpty;
  }
}
