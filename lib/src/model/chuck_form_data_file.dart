class ChuckFormDataFile {
  const new(this.fileName, this.contentType, this.length);

  final int length;
  final String? fileName;
  final String contentType;
}
