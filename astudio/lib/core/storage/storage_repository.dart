import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final storageRepositoryProvider = Provider<StorageRepository>((ref) {
  final client = Supabase.instance.client;
  return StorageRepository(client);
});

class StorageRepository {
  StorageRepository(this._client);

  final SupabaseClient _client;

  Future<String> uploadPortfolioAsset({
    required String profileId,
    required PlatformFile file,
  }) async {
    final bytes = await _resolveBytes(file);
    final extension = file.extension ?? 'bin';
    final path =
        'portfolio/$profileId/${DateTime.now().millisecondsSinceEpoch}.$extension';
    await _client.storage
        .from('portfolio')
        .uploadBinary(path, bytes, fileOptions: const FileOptions(upsert: true));
    return _client.storage.from('portfolio').getPublicUrl(path);
  }

  Future<String> uploadProfileImage({
    required String profileId,
    required PlatformFile file,
    required String folder,
  }) async {
    final bytes = await _resolveBytes(file);
    final extension = file.extension ?? 'jpg';
    final path =
        '$folder/$profileId/${DateTime.now().millisecondsSinceEpoch}.$extension';
    await _client.storage
        .from('profile-assets')
        .uploadBinary(path, bytes, fileOptions: const FileOptions(upsert: true));
    return _client.storage.from('profile-assets').getPublicUrl(path);
  }

  Future<Uint8List> _resolveBytes(PlatformFile file) async {
    if (file.bytes != null) {
      return file.bytes!;
    }
    if (file.path != null && !kIsWeb) {
      return File(file.path!).readAsBytes();
    }
    throw Exception('Unable to read file bytes');
  }
}

