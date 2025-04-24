class ChuckHttpError<T> {
  const ChuckHttpError({required this.error, this.stackTrace});

  final T error;
  final StackTrace? stackTrace;
}
