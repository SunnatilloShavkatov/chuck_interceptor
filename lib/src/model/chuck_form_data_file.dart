class ChuckFormDataFile {
  const ChuckFormDataFile(this.fileName, this.contentType, this.length);

  final int length;
  final String? fileName;
  final String contentType;
}
