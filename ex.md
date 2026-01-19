@dataforge_annotation.Dataforge(includeFromJson: false)
class EchoTrackEvent with _EchoTrackEvent {
  @override
  @dataforge_annotation.JsonKey(name: 'name')
  final String name;

  @override
  @dataforge_annotation.JsonKey(name: 'key')
  final String key;

  @override
  @dataforge_annotation.JsonKey(name: 'routeUrl')
  final String routeUrl;

  @override
  @dataforge_annotation.JsonKey(name: 'isEnableClick')
  final bool isEnableClick;

  @override
  @dataforge_annotation.JsonKey(name: 'isEnableClick')
  final bool isEnableShow;

  @override
  @dataforge_annotation.JsonKey(name: 'immutable')
  final bool immutable;

  @override
  @dataforge_annotation.JsonKey(name: 'sensorEventTypes')
  final List<EchoEventType> sensorEventTypes;

  @override
  @dataforge_annotation.JsonKey(name: 'enableShence')
  final bool enableShence;

  @override
  @dataforge_annotation.JsonKey(name: 'data')
  final Map<String, dynamic> data;

  const EchoTrackEvent({
    this.name = "",
    this.key = "",
    this.routeUrl = "",
    this.immutable = false,
    this.sensorEventTypes = const [EchoEventType.click, EchoEventType.show],
    this.enableShence = true,
    this.isEnableClick = true,
    this.isEnableShow = true,
    this.data = const {},
  });

  factory EchoTrackEvent.fromBuyoutItem(
    KurilTradeBuyout item, {
    required int index,
    required String routeUrl,
  }) {
    return EchoTrackEvent(
      routeUrl: routeUrl,
      data: {
        "index": index,
        "item_id": item.id,
        "related_type": item.relatedType?.id,
        "token_id": item.tokenId,
        "item_name": item.extName,
        "item_type": "sale_order",
        "request_id": item.requestId,
      },
    );
  }

  factory EchoTrackEvent.fromAuctionItem(
    KurilTradeAuction item, {
    required int index,
    required String routeUrl,
  }) {
    return EchoTrackEvent(
      routeUrl: routeUrl,
      data: {
        "index": index,
        "item_id": item.id,
        "related_type": item.relatedType?.id,
        "token_id": item.tokenId,
        "item_name": item.extName,
        "item_type": "auction",
        "request_id": item.requestId,
      },
    );
  }

  factory EchoTrackEvent.fromInnerBuyoutItem(
    KurilTradeBuyout item, {
    String? requestId,
    required int index,
    required String routeUrl,
  }) {
    return EchoTrackEvent(
      name: "product_item",
      routeUrl: routeUrl,
      data: {
        "index": index,
        "item_id": item.id,
        "item_name": item.extName,
        "item_type": "buyout",
        "related_type": item.relatedType?.id,
        "request_id": requestId,
      },
    );
  }

  factory EchoTrackEvent.fromFeed(
    LinjieFeed feed, {
    String? requestId,
    required int index,
    required String routeUrl,
  }) {
    //"index": index,
    //         if (tabName.isNotEmpty) "tab_type": tabName,
    //         "from_scope": "island",
    //         "island_id": "300543",
    //         "entry_type": feed.type.id,
    //         "entry_name": feed.extName,
    //         "entry_id": feed.id,
    //         if (feed.requestId?.isNotEmpty == true)
    //           "algorithm_request_id": feed.requestId,
    //         if (feed.requestId?.isNotEmpty == true) "request_id": feed.requestId,
    return EchoTrackEvent(
      routeUrl: routeUrl,
      data: {
        "index": index,
        "from_scope": "island",
        "island_id": "300543",
        "entry_type": feed.type.id,
        "entry_name": feed.extName,
        "entry_id": feed.id,
        "request_id": feed.requestId,
      },
    );
  }

  factory EchoTrackEvent.fromBuyout(
    KurilTradeBuyout item, {
    String? requestId,
    int? index,
    required String routeUrl,
  }) {
    return EchoTrackEvent(
      routeUrl: routeUrl,
      data: {
        "index": index,
        "item_id": item.id,
        "item_name": item.extName,
        "related_type": item.relatedType?.id,
        "item_type": "sale_order",
        "request_id": requestId,
      },
    );
  }

  factory EchoTrackEvent.fromInnerAuctionItem(
    KurilTradeAuction item, {
    required int index,
    String? requestId,
    required String routeUrl,
  }) {
    return EchoTrackEvent.fromAuction(
      item,
      routeUrl: routeUrl,
      index: index,
      requestId: requestId,
    ).copyWith(name: "product_item");
  }

  factory EchoTrackEvent.fromAuction(
    KurilTradeAuction item, {
    int? index,
    String? requestId,
    required String routeUrl,
  }) {
    return EchoTrackEvent(
      routeUrl: routeUrl,
      data: {
        "index": index,
        "item_id": item.id,
        "item_type": "auction",
        "related_type": item.relatedType?.id,
        "item_name": item.extName,
        "request_id": requestId,
      },
    );
  }

  factory EchoTrackEvent.fromInnerPostItem(
    KurilPost post, {
    required int index,
    String? requestId,
    required String routeUrl,
  }) {
    return EchoTrackEvent(
      name: "post_item",
      routeUrl: routeUrl,
      data: {"index": index, "item_id": post.id, "request_id": requestId},
    );
  }

  // Map<String, dynamic> get dataMap => {
  //         "index": index,
  //         if (tabName.isNotEmpty) "tab_name": tabName,
  //         "token_id": token.id,
  //         "item_id": token.tradeId.isNotEmpty ? token.tradeId : token.id,
  //         if (itemType.isNotEmpty) "item_type": itemType,
  //         "item_name": token.name,
  //         if (token.requestId?.isNotEmpty == true)
  //           "algorithm_request_id": token.requestId,
  //         if (token.requestId?.isNotEmpty == true) "request_id": token.requestId,
  //       };
  factory EchoTrackEvent.fromTokenItem(
    TokenBean token, {
    required int index,
    required String routeUrl,
  }) {
    return EchoTrackEvent(
      routeUrl: routeUrl,
      data: {
        "index": index,
        "token_id": token.id,
        "item_id": token.tradeId.ifEmpty(token.id),
        "item_type": token.tradeInfo?.type.trackName,
        "item_name": token.name,
        "oc_id": token.charactersBelongs.firstOrNull?.id,
        "request_id": token.requestId,
      },
    );
  }

  factory EchoTrackEvent.fromInnerTokenItem(
    TokenBean token, {
    required int index,
    String? requestId,
    required String routeUrl,
  }) {
    return EchoTrackEvent(
      name: "token_item",
      routeUrl: routeUrl,
      data: {
        "item_id": token.id,
        "index": index,
        "item_name": token.name,
        "oc_id": token.charactersBelongs.firstOrNull?.id,
        "request_id": requestId,
      },
    );
  }
}











// Generated by data class generator
// DO NOT MODIFY BY HAND

part of 'sensor.dart';

mixin _EchoTrackEvent {
  abstract final String name;
  abstract final String key;
  abstract final String routeUrl;
  abstract final bool isEnableClick;
  abstract final bool isEnableShow;
  abstract final bool immutable;
  abstract final List<EchoEventType> sensorEventTypes;
  abstract final bool enableShence;
  abstract final Map<String, dynamic> data;
  _EchoTrackEventCopyWith<EchoTrackEvent> get copyWith =>
      _EchoTrackEventCopyWith<EchoTrackEvent>._(this);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! EchoTrackEvent) return false;

    if (name != other.name) {
      return false;
    }
    if (key != other.key) {
      return false;
    }
    if (routeUrl != other.routeUrl) {
      return false;
    }
    if (isEnableClick != other.isEnableClick) {
      return false;
    }
    if (isEnableShow != other.isEnableShow) {
      return false;
    }
    if (immutable != other.immutable) {
      return false;
    }
    if (!const DeepCollectionEquality().equals(
      sensorEventTypes,
      other.sensorEventTypes,
    )) {
      return false;
    }
    if (enableShence != other.enableShence) {
      return false;
    }
    if (!const DeepCollectionEquality().equals(data, other.data)) {
      return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAll([
    name,
    key,
    routeUrl,
    isEnableClick,
    isEnableShow,
    immutable,
    const DeepCollectionEquality().hash(sensorEventTypes),
    enableShence,
    const DeepCollectionEquality().hash(data),
  ]);

  @override
  String toString() =>
      'EchoTrackEvent(name: $name, key: $key, routeUrl: $routeUrl, isEnableClick: $isEnableClick, isEnableShow: $isEnableShow, immutable: $immutable, sensorEventTypes: $sensorEventTypes, enableShence: $enableShence, data: $data)';

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'key': key,
      'routeUrl': routeUrl,
      'isEnableClick': isEnableClick,
      'isEnableClick': isEnableShow,
      'immutable': immutable,
      'sensorEventTypes': sensorEventTypes,
      'enableShence': enableShence,
      'data': data,
    };
  }
}

class _EchoTrackEventCopyWith<R> {
  final _EchoTrackEvent _instance;
  final R Function(EchoTrackEvent)? _then;
  _EchoTrackEventCopyWith._(this._instance, [this._then]);

  R call({
    Object? name = dataforge_annotation.dataforgeUndefined,
    Object? key = dataforge_annotation.dataforgeUndefined,
    Object? routeUrl = dataforge_annotation.dataforgeUndefined,
    Object? isEnableClick = dataforge_annotation.dataforgeUndefined,
    Object? isEnableShow = dataforge_annotation.dataforgeUndefined,
    Object? immutable = dataforge_annotation.dataforgeUndefined,
    Object? sensorEventTypes = dataforge_annotation.dataforgeUndefined,
    Object? enableShence = dataforge_annotation.dataforgeUndefined,
    Object? data = dataforge_annotation.dataforgeUndefined,
  }) {
    final res = EchoTrackEvent(
      name: (name == dataforge_annotation.dataforgeUndefined
          ? _instance.name
          : name as String),
      key: (key == dataforge_annotation.dataforgeUndefined
          ? _instance.key
          : key as String),
      routeUrl: (routeUrl == dataforge_annotation.dataforgeUndefined
          ? _instance.routeUrl
          : routeUrl as String),
      isEnableClick: (isEnableClick == dataforge_annotation.dataforgeUndefined
          ? _instance.isEnableClick
          : isEnableClick as bool),
      isEnableShow: (isEnableShow == dataforge_annotation.dataforgeUndefined
          ? _instance.isEnableShow
          : isEnableShow as bool),
      immutable: (immutable == dataforge_annotation.dataforgeUndefined
          ? _instance.immutable
          : immutable as bool),
      sensorEventTypes:
          (sensorEventTypes == dataforge_annotation.dataforgeUndefined
          ? _instance.sensorEventTypes
          : (sensorEventTypes as List).cast<EchoEventType>()),
      enableShence: (enableShence == dataforge_annotation.dataforgeUndefined
          ? _instance.enableShence
          : enableShence as bool),
      data: (data == dataforge_annotation.dataforgeUndefined
          ? _instance.data
          : (data as Map).cast<String, dynamic>()),
    );
    return (_then != null ? _then(res) : res as R);
  }

  R name(String value) {
    final res = EchoTrackEvent(
      name: value,
      key: _instance.key,
      routeUrl: _instance.routeUrl,
      isEnableClick: _instance.isEnableClick,
      isEnableShow: _instance.isEnableShow,
      immutable: _instance.immutable,
      sensorEventTypes: _instance.sensorEventTypes,
      enableShence: _instance.enableShence,
      data: _instance.data,
    );
    return (_then != null ? _then(res) : res as R);
  }

  R key(String value) {
    final res = EchoTrackEvent(
      name: _instance.name,
      key: value,
      routeUrl: _instance.routeUrl,
      isEnableClick: _instance.isEnableClick,
      isEnableShow: _instance.isEnableShow,
      immutable: _instance.immutable,
      sensorEventTypes: _instance.sensorEventTypes,
      enableShence: _instance.enableShence,
      data: _instance.data,
    );
    return (_then != null ? _then(res) : res as R);
  }

  R routeUrl(String value) {
    final res = EchoTrackEvent(
      name: _instance.name,
      key: _instance.key,
      routeUrl: value,
      isEnableClick: _instance.isEnableClick,
      isEnableShow: _instance.isEnableShow,
      immutable: _instance.immutable,
      sensorEventTypes: _instance.sensorEventTypes,
      enableShence: _instance.enableShence,
      data: _instance.data,
    );
    return (_then != null ? _then(res) : res as R);
  }

  R isEnableClick(bool value) {
    final res = EchoTrackEvent(
      name: _instance.name,
      key: _instance.key,
      routeUrl: _instance.routeUrl,
      isEnableClick: value,
      isEnableShow: _instance.isEnableShow,
      immutable: _instance.immutable,
      sensorEventTypes: _instance.sensorEventTypes,
      enableShence: _instance.enableShence,
      data: _instance.data,
    );
    return (_then != null ? _then(res) : res as R);
  }

  R isEnableShow(bool value) {
    final res = EchoTrackEvent(
      name: _instance.name,
      key: _instance.key,
      routeUrl: _instance.routeUrl,
      isEnableClick: _instance.isEnableClick,
      isEnableShow: value,
      immutable: _instance.immutable,
      sensorEventTypes: _instance.sensorEventTypes,
      enableShence: _instance.enableShence,
      data: _instance.data,
    );
    return (_then != null ? _then(res) : res as R);
  }

  R immutable(bool value) {
    final res = EchoTrackEvent(
      name: _instance.name,
      key: _instance.key,
      routeUrl: _instance.routeUrl,
      isEnableClick: _instance.isEnableClick,
      isEnableShow: _instance.isEnableShow,
      immutable: value,
      sensorEventTypes: _instance.sensorEventTypes,
      enableShence: _instance.enableShence,
      data: _instance.data,
    );
    return (_then != null ? _then(res) : res as R);
  }

  R sensorEventTypes(List<EchoEventType> value) {
    final res = EchoTrackEvent(
      name: _instance.name,
      key: _instance.key,
      routeUrl: _instance.routeUrl,
      isEnableClick: _instance.isEnableClick,
      isEnableShow: _instance.isEnableShow,
      immutable: _instance.immutable,
      sensorEventTypes: value,
      enableShence: _instance.enableShence,
      data: _instance.data,
    );
    return (_then != null ? _then(res) : res as R);
  }

  R enableShence(bool value) {
    final res = EchoTrackEvent(
      name: _instance.name,
      key: _instance.key,
      routeUrl: _instance.routeUrl,
      isEnableClick: _instance.isEnableClick,
      isEnableShow: _instance.isEnableShow,
      immutable: _instance.immutable,
      sensorEventTypes: _instance.sensorEventTypes,
      enableShence: value,
      data: _instance.data,
    );
    return (_then != null ? _then(res) : res as R);
  }

  R data(Map<String, dynamic> value) {
    final res = EchoTrackEvent(
      name: _instance.name,
      key: _instance.key,
      routeUrl: _instance.routeUrl,
      isEnableClick: _instance.isEnableClick,
      isEnableShow: _instance.isEnableShow,
      immutable: _instance.immutable,
      sensorEventTypes: _instance.sensorEventTypes,
      enableShence: _instance.enableShence,
      data: value,
    );
    return (_then != null ? _then(res) : res as R);
  }
}
