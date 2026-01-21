





abstract final AsyncResult<double> uploadState;




 R call({
    Object? uploadState = dataforgeUndefined,
    Object? watermarkMode = dataforgeUndefined,
    Object? enableWatermarkModes = dataforgeUndefined,
    Object? images = dataforgeUndefined,
    Object? sourceType = dataforgeUndefined,
    Object? token = dataforgeUndefined,
    Object? island = dataforgeUndefined,
    Object? shouldHideSourceComponent = dataforgeUndefined,
  }) {
    final res = TokenCreateSinglePageState(
      uploadState: (uploadState == dataforgeUndefined
          ? _instance.uploadState
          : uploadState as AsyncResult<double>),
