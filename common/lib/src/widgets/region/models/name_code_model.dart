class NameCodeModel {
  NameCodeModel({required this.name, required this.code, this.children});

  factory NameCodeModel.fromJson(Map<String, dynamic> json) {
    return NameCodeModel(
      name: json['name'],
      code: _padRight6(json['code']),
      children: json['children'] != null
          ? (json['children'] as List<dynamic>)
                .map((e) => NameCodeModel.fromJson(e as Map<String, dynamic>))
                .toList()
          : null,
    );
  }

  final String name;
  final String code;
  final List<NameCodeModel>? children;

  Map<String, Object?> toJson() => {
    'name': name,
    'code': code,
    'children': children?.map((e) => e.toJson()).toList(),
  };
}

class AdministrativeRegionData {
  AdministrativeRegionData({required this.data});

  factory AdministrativeRegionData.fromJson(Map<String, dynamic> json) {
    final Map<String, List<NameCodeModel>> result = {};
    json.forEach((key, value) {
      result[key] = (value as List<dynamic>)
          .map((e) => NameCodeModel.fromJson(e as Map<String, dynamic>))
          .toList();
    });
    return AdministrativeRegionData(data: result);
  }
  final Map<String, List<NameCodeModel>> data;

  Map<String, dynamic> toJson() {
    return data.map((key, value) => MapEntry(key, value.map((e) => e.toJson()).toList()));
  }
}

String _padRight6(String code) => code.padRight(6, '0');
