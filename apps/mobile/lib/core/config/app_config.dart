enum DataSourceMode {
  /// Local mocks only. Default for demo and widget tests.
  mock,

  /// Real API only. Errors surface to the UI.
  api,

  /// Try API first, fall back to mocks when the backend is unavailable.
  apiWithMockFallback,
}

class AppConfig {
  const AppConfig({
    this.mode = DataSourceMode.mock,
    this.apiBaseUrl = 'http://localhost:8080',
    this.devUserId = 'dev-user-1',
  });

  final DataSourceMode mode;
  final String apiBaseUrl;
  final String devUserId;

  factory AppConfig.fromEnvironment() {
    const modeName = String.fromEnvironment(
      'DATA_SOURCE_MODE',
      defaultValue: 'mock',
    );
    const apiBaseUrl = String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'http://localhost:8080',
    );
    const devUserId = String.fromEnvironment(
      'DEV_USER_ID',
      defaultValue: 'dev-user-1',
    );

    return AppConfig(
      mode: _parseMode(modeName),
      apiBaseUrl: apiBaseUrl,
      devUserId: devUserId,
    );
  }

  static DataSourceMode _parseMode(String value) {
    return switch (value) {
      'api' => DataSourceMode.api,
      'apiWithMockFallback' => DataSourceMode.apiWithMockFallback,
      _ => DataSourceMode.mock,
    };
  }
}
