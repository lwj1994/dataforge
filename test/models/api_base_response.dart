import 'package:dataforge_annotation/dataforge_annotation.dart';

import 'utils.dart';

part 'api_base_response.data.dart';

@Dataforge()
class EchoApiResponse<T> with _EchoApiResponse {
  // int or string ??
  @override
  @JsonKey(name: 'code')
  final String code;

  @override
  @JsonKey(
    name: 'message',
  )
  final String message;

  @override
  @JsonKey(name: "data", fromJson: jsonToObject)
  final T? data;

  const EchoApiResponse({
    this.code = "",
    this.message = "",
    this.data,
  });

  factory EchoApiResponse.fromJson(Map<String, dynamic> json) {
    return _EchoApiResponse.fromJson(json);
  }
}
