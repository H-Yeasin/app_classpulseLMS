class LanguageModel {
  final String id;
  final String name;
  final String flag;

  const LanguageModel({
    required this.id,
    required this.name,
    required this.flag,
  });
}

const List<LanguageModel> supportedLanguages = [
  LanguageModel(id: "en_us", name: "English (US)", flag: "🇺🇸"),
  LanguageModel(id: "en_uk", name: "English (UK)", flag: "🇬🇧"),
  LanguageModel(id: "fr", name: "French", flag: "🇫🇷"),
  LanguageModel(id: "de", name: "German", flag: "🇩🇪"),
  LanguageModel(id: "zh", name: "Chinese", flag: "🇨🇳"),
  LanguageModel(id: "ja", name: "Japanese", flag: "🇯🇵"),
  LanguageModel(id: "ko", name: "Korean", flag: "🇰🇷"),
  LanguageModel(id: "ru", name: "Russian", flag: "🇷🇺"),
  LanguageModel(id: "it", name: "Italian", flag: "🇮🇹"),
  LanguageModel(id: "es", name: "Spanish", flag: "es"), // Using letters for Spanish if flag emoji is finicky
];
