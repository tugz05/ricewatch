import '../config/openai_secrets.dart' as secrets;

/// OpenAI API key. Priority: [apiKeyOverride] > [openai_secrets.dart] > --dart-define.
const String _envKey = String.fromEnvironment(
  'OPENAI_API_KEY',
  defaultValue: '',
);

/// Override at runtime if needed (e.g. from settings). Prefer editing openai_secrets.dart for local use.
String? apiKeyOverride;

/// Resolved API key: override > file > env.
String get openAiApiKey =>
    apiKeyOverride ??
    (secrets.openAiApiKeyFromFile.isNotEmpty
        ? secrets.openAiApiKeyFromFile
        : _envKey);

bool get hasOpenAiKey => openAiApiKey.isNotEmpty;

/// OpenAI model for chat. Set in lib/core/config/openai_secrets.dart.
String get openAiModel => secrets.openAiModelFromFile;
