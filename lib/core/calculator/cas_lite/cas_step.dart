class CasStep {
  const CasStep({required this.title, this.detail});

  final String title;
  final String? detail;

  String get display {
    final suffix = detail?.trim();
    if (suffix == null || suffix.isEmpty) {
      return title;
    }
    return '$title: $suffix';
  }
}
