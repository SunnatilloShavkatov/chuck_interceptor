class ChuckFormDataFile {
  const ChuckFormDataFile({
    this.fileName,
    required this.contentType,
    required this.length,
  });

  final String? fileName;
  final String contentType;
  final int length;

  Map<String, dynamic> toJson() {
    return {
      'length': length,
      'fileName': fileName,
      'contentType': contentType,
    };
  }

  factory ChuckFormDataFile.fromJson(Map<dynamic, dynamic> json) {
    return ChuckFormDataFile(fileName: json['fileName'], contentType: json['contentType'], length: json['length']);
  }
}
