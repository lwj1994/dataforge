


  final List<ImageBean> watermarkImages;




   watermarkImages:
          (((dataforge_annotation.SafeCasteUtil.safeCast<List<ImageBean>>(
                TokenBean._readValue(json, 'watermarkImages'),
              )
              ?.map((e) => (ImageBean.fromJson(e as Map<String, dynamic>)))
              .toList())) ??
          (const [])),




    