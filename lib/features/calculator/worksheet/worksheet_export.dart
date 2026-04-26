/// Export payload produced by worksheet and graph exporters.
class WorksheetExportResult {
  const WorksheetExportResult({
    required this.fileName,
    required this.mimeType,
    required this.contentText,
    required this.extension,
    required this.createdAt,
    this.warning,
  });

  final String fileName;
  final String mimeType;
  final String contentText;
  final String extension;
  final DateTime createdAt;
  final String? warning;
}
