class PropertyStorageFile {
  const PropertyStorageFile({
    required this.name,
    required this.fullPath,
    required this.downloadUrl,
    required this.sizeBytes,
    required this.updatedAt,
    required this.contentType,
  });

  final String name;
  final String fullPath;
  final String downloadUrl;
  final int sizeBytes;
  final DateTime? updatedAt;
  final String? contentType;
}
