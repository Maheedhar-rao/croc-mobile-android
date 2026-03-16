class Env {
  static const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://lxqsswgqugwszhovfsxw.supabase.co',
  );
  static const supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imx4cXNzd2dxdWd3c3pob3Zmc3h3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjA0MjkxMjYsImV4cCI6MjA3NjAwNTEyNn0.8Xa1b3IszvMoBQvHNYE0l2uV4MUaVG8kS6CFsiCX5bI',
  );
  static const oneSignalAppId = String.fromEnvironment(
    'ONESIGNAL_APP_ID',
    defaultValue: '21f6ef3b-c038-4407-975a-b66f6b7158e8',
  );
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://paradise.croccrm.com',
  );
}
