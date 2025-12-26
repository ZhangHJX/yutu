import 'dart:convert';

import 'package:common/common.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'models/name_code_model.dart';

/// 省市区三级联动的选择器组件
class CTriLevelRegionWidget extends HookWidget {
  CTriLevelRegionWidget({required this.codes, super.key, this.tag, this.onConfirm, this.onCancel});

  final String? tag;
  final List<String> codes;
  final Function(Map<String, String> regionMap)? onConfirm;
  final VoidCallback? onCancel;

  final Map<String, String> codeName = {};
  final Map<String, List<Map<String, dynamic>>> codeChildren = {};

  @override
  Widget build(BuildContext context) {
    final scrollController = useScrollController();
    final regionData = useState<AdministrativeRegionData?>(null);
    final provinceList = useState<List<NameCodeModel>>([]);
    final currentList = useState<List<NameCodeModel>>([]);

    final selectedCodes = useState<List<String>>(codes);

    /// 是否是在选完之后重新选取的索引
    final reselectIdx = useState<int>(-1);

    final loadRegionJson = useCallback(() async {
      final jsonStr = await rootBundle.loadString('assets/jsons/region.json');
      final data = json.decode(jsonStr);
      provinceList.value = JsonHelper.fromMapList(data, NameCodeModel.fromJson);

      buildLookupAndChildren(codeName, codeChildren, data);
      regionData.value = JsonHelper.fromMap(codeChildren, AdministrativeRegionData.fromJson);
    }, []);

    final getCurrentRegionList = useCallback((int index) {
      if (index <= 0) {
        currentList.value = provinceList.value;
      } else {
        currentList.value = regionData.value?.data[selectedCodes.value[index - 1]] ?? [];
      }
    }, [regionData.value]);

    /// 点击选中之后展示的地址, 如 广东省 深圳市 南山区
    final onClickShowedRegion = useCallback((int index) {
      getCurrentRegionList(index);
      reselectIdx.value = index;
    }, [getCurrentRegionList]);

    final buildShowedRegion = useCallback((String code, int index, bool isTip) {
      final len = selectedCodes.value.length;
      return GestureDetector(
        onTap: () => onClickShowedRegion(index),
        child: Column(
          children: [
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 98.w),
              child: CText(codeName[code] ?? (isTip ? '请选择' : ''), maxLines: 1),
            ),
            if (reselectIdx.value == index ||
                (reselectIdx.value == -1 && (isTip || (len == 3 && index == 2))))
              Container(
                margin: .symmetric(vertical: 5.w),
                width: 20.w,
                height: 3.w,
                decoration: BoxDecoration(
                  gradient: defaultGradient,
                  borderRadius: .circular(1.5.w),
                ),
              ),
          ],
        ),
      );
    }, [selectedCodes.value, reselectIdx.value, codeName, onClickShowedRegion]);

    /// 点击列表里的地址
    final onClickRegionItem = useCallback((String code) {
      if (reselectIdx.value != -1) {
        selectedCodes.value.removeRange(reselectIdx.value, selectedCodes.value.length);
        reselectIdx.value = -1;
      }

      if (selectedCodes.value.length == 3) {
        selectedCodes.value.removeLast();
        selectedCodes.value.add(code);
      } else {
        selectedCodes.value.add(code);
      }

      if (selectedCodes.value.length < 3) {
        // 选择了省份或市，继续显示下一级列表
        currentList.value = regionData.value?.data[code] ?? [];
        scrollController.animateTo(0, duration: 200.ms, curve: Curves.easeInOut);
      } else {
        currentList.value = [];

        onConfirm?.call({
          'province': selectedCodes.value[0],
          'city': selectedCodes.value[1],
          'area': selectedCodes.value[2],
          'provinceName': codeName[selectedCodes.value[0]] ?? '',
          'cityName': codeName[selectedCodes.value[1]] ?? '',
          'areaName': codeName[selectedCodes.value[2]] ?? '',
        });

        // 关闭选择器
        SmartDialog.dismiss(tag: tag);
      }
    }, [selectedCodes.value, reselectIdx.value, regionData.value, codeName, tag, onConfirm]);

    final onClosePressed = useCallback(() {
      onCancel?.call();
      SmartDialog.dismiss(tag: tag);
    }, [tag, onCancel]);

    useEffect(() {
      loadRegionJson().then((_) {
        getCurrentRegionList(selectedCodes.value.length - 1);
      });
      return null;
    }, [loadRegionJson]);

    return Container(
      padding: .only(top: 6.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: .vertical(top: Radius.circular(14.w)),
      ),
      height: Get.height * .84,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: .spaceBetween,
            children: [
              _buildCloseButton(),
              Text(
                '请选择所在地区',
                style: text333333(fontSize: 18.w, height: 24 / 18, fontWeight: .w500),
              ),
              _buildCloseButton(onClosePressed),
            ],
          ),
          SizedBox(height: 13.w),
          DefaultTextStyle(
            style: text333333(fontSize: 16.w, height: 22 / 16),
            child: Padding(
              padding: .symmetric(horizontal: 16.w),
              child: Row(
                crossAxisAlignment: .start,
                spacing: 24.w,
                children: [
                  ...selectedCodes.value.asMap().entries.map(
                    (e) => buildShowedRegion(e.value, e.key, false),
                  ),
                  if (selectedCodes.value.length < 3) buildShowedRegion('', 0, true),
                ],
              ),
            ),
          ),
          Container(height: hairline, width: .infinity, color: '#FFEAEAEA'.color),
          Expanded(
            child: CHandler(() {
              final list = currentList.value;
              return ListView.builder(
                controller: scrollController,
                padding: getSafePadding(
                  context,
                  minimum: .only(left: 12.w, bottom: 16.w),
                ),
                itemCount: list.length,
                itemBuilder: (context, index) {
                  final model = list[index];
                  return DefaultTextStyle(
                    style: text333333(fontSize: 16.w, height: 1.1),
                    child: CGestureContainer(
                      onTap: () => onClickRegionItem(model.code),
                      margin: .only(top: 22.w, bottom: 8.w),
                      child:
                          (selectedCodes.value.isNotEmpty &&
                              (reselectIdx.value > 0 &&
                                      model.code == selectedCodes.value[reselectIdx.value] ||
                                  model.code == selectedCodes.value.last))
                          ? CGradientText(model.name, style: .new(fontWeight: .w500))
                          : CText(model.name),
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  String padRight6(String code) => code.padRight(6, '0');

  void buildLookupAndChildren(
    Map<String, String> nameMap,
    Map<String, List<Map<String, dynamic>>> childrenMap,
    List<dynamic> list,
  ) {
    for (final item in list) {
      final rawCode = item['code'] as String?;
      final name = item['name'] as String?;
      if (rawCode == null || name == null) {
        continue;
      }

      final code = padRight6(rawCode);
      nameMap[code] = name;

      final rawChildren = item['children'];
      if (rawChildren is List) {
        final normalizedChildren = rawChildren.map((child) {
          final cCode = child['code'] as String?;
          if (cCode != null) {
            child['code'] = padRight6(cCode);
          }
          return child;
        }).toList();

        childrenMap[code] = normalizedChildren.cast<Map<String, dynamic>>();
        buildLookupAndChildren(nameMap, childrenMap, normalizedChildren);
      }
    }
  }

  Widget _buildCloseButton([VoidCallback? onPressed]) => Opacity(
    opacity: onPressed == null ? 0 : 1,
    child: CButton(
      icon: Image.asset('assets/images/common/ic_close_circle.png'),
      padding: .all(10.w),
      onPressed: onPressed,
    ),
  );
}
