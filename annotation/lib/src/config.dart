class GlobalConfig {
  final bool includeFromJson;
  final bool includeToJson;

  const GlobalConfig({
    this.includeFromJson = true,
    this.includeToJson = true,
  });
}

var config = GlobalConfig();
