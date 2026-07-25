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
    this.mode = DataSourceMode.api,
    this.apiBaseUrl = 'https://creative.gde-kofe.ru',
    this.devUserId = '00000000-0000-0000-0000-000000000001',
  });

  final DataSourceMode mode;
  final String apiBaseUrl;
  final String devUserId;

  factory AppConfig.fromEnvironment() {
    const modeName = String.fromEnvironment(
      'DATA_SOURCE_MODE',
      defaultValue: 'api',
    );
    const apiBaseUrl = String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'https://creative.gde-kofe.ru',
    );
    const devUserId = String.fromEnvironment(
      'DEV_USER_ID',
      defaultValue: '00000000-0000-0000-0000-000000000001',
    );

    return AppConfig(
      mode: _parseMode(modeName),
      apiBaseUrl: apiBaseUrl,
      devUserId: devUserId,
    );
  }

  static DataSourceMode _parseMode(String value) {
    return switch (value) {
      'mock' => DataSourceMode.mock,
      'api' => DataSourceMode.api,
      'apiWithMockFallback' => DataSourceMode.apiWithMockFallback,
      _ => DataSourceMode.api,
    };
  }
}
