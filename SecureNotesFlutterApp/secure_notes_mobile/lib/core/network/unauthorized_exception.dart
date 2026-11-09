class UnauthorizedException implements Exception {
  const UnauthorizedException();

  @override
  String toString() {
    return 'Sesija je istekla. Prijavite se ponovo.';
  }
}
