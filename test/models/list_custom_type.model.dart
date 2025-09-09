import 'package:dataforge_annotation/dataforge_annotation.dart';
import 'package:collection/collection.dart';

part 'list_custom_type.model.data.dart';

@Dataforge()
class ImageListModel with _ImageListModel {
  @override
  final String id;
  @override
  @JsonKey(readValue: ImageListModel._readValue)
  final List<ImageBean> watermarkImages;

  const ImageListModel({
    required this.id,
    required this.watermarkImages,
  });

  // Custom readValue method
  static Object? _readValue(Map<dynamic, dynamic> map, String key) {
    return map[key];
  }

  factory ImageListModel.fromJson(Map<String, dynamic> json) {
    return _ImageListModel.fromJson(json);
  }
}

@Dataforge()
class ImageBean with _ImageBean {
  @override
  final String url;
  @override
  final int width;
  @override
  final int height;

  const ImageBean({
    required this.url,
    required this.width,
    required this.height,
  });

  factory ImageBean.fromJson(Map<String, dynamic> json) {
    return _ImageBean.fromJson(json);
  }
}
