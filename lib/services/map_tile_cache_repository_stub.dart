import 'package:flutter_cache_manager/flutter_cache_manager.dart';

CacheInfoRepository createMapTileCacheRepository(String cacheKey) =>
    NonStoringObjectProvider();
