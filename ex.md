  abstract final DateTime date;

  DoujinLatestRank({required this.date, this.list = const []});


    date:
          (SafeCasteUtil.readRequiredValue<DateTime>(json, 'date') ??
          DateTime.fromMillisecondsSinceEpoch(0)),





 (SafeCasteUtil.readObjectList(
            SafeCasteUtil.safeCast<List<dynamic>>(json['list']),
            KurilTag.fromJson,
          ) ??
          (const [])),       