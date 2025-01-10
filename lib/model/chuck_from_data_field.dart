class ChuckFormDataField {
  const ChuckFormDataField({required this.name, required this.value});

  final String name;
  final String value;

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'value': value,
    };
  }

  factory ChuckFormDataField.fromJson(Map<dynamic, dynamic> json) {
    return ChuckFormDataField(name: json['name'], value: json['value']);
  }
}
