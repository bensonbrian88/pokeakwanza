import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class AppCacheManager {
  static final CacheManager instance = CacheManager(
    Config(
      'stynextImageCache',
      stalePeriod: const Duration(days: 21),
      maxNrOfCacheObjects: 200,
      repo: JsonCacheInfoRepository(databaseName: 'stynextImageCache'),
      fileService: HttpFileService(),
    ),
  );
}

