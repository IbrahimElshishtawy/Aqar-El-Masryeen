import 'package:aqarelmasryeen/app/providers.dart';
import 'package:aqarelmasryeen/shared/models/property_models.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PropertyFilesRepository {
  PropertyFilesRepository(this._storage);

  final FirebaseStorage _storage;

  Future<List<PropertyStorageFile>> listFiles(String propertyId) async {
    final result = await _storage.ref('properties/$propertyId/files').listAll();
    final files = <PropertyStorageFile>[];

    for (final ref in result.items) {
      final metadata = await ref.getMetadata();
      final url = await ref.getDownloadURL();
      files.add(
        PropertyStorageFile(
          name: metadata.name,
          fullPath: ref.fullPath,
          downloadUrl: url,
          sizeBytes: metadata.size ?? 0,
          updatedAt: metadata.updated,
          contentType: metadata.contentType,
        ),
      );
    }

    files.sort((a, b) {
      final left = a.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final right = b.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return right.compareTo(left);
    });

    return files;
  }
}

final propertyFilesRepositoryProvider = Provider<PropertyFilesRepository>((
  ref,
) {
  return PropertyFilesRepository(ref.watch(firebaseStorageProvider));
});
