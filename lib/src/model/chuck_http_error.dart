class ChuckHttpError<T> {
  const new({required this.error, this.stackTrace});

  final T error;
  final StackTrace? stackTrace;
}
