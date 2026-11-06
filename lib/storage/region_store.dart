import 'package:meshcore_open/storage/channel_region_store.dart';

import 'prefs_manager.dart';

typedef Region = String;

/// Stored region assignment meaning "explicitly no region": floods go out
/// unscoped even when an app or radio default region exists. '!' cannot occur
/// in a region name, so it never collides with a real region.
const Region kUnscopedRegion = '!unscoped';

class RegionStore {
  static const String key = 'regions';
  String publicKeyHex = '';
  set setPublicKeyHex(String value) =>
      publicKeyHex = value.length >= 10 ? value.substring(0, 10) : '';

  List<Region> loadRegions() {
    final prefs = PrefsManager.instance;
    List<Region>? region = prefs.getStringList(key);
    return region ?? [];
  }

  void saveRegions(List<Region> regions) {
    final prefs = PrefsManager.instance;

    var distinctRegions = [
      ...{...regions},
    ];

    distinctRegions.sort();
    prefs.setStringList(key, distinctRegions);
  }

  void addRegion(Region region) {
    final regions = loadRegions();
    regions.add(region);
    saveRegions(regions);
  }

  Future<void> removeRegion(Region region) async {
    final regions = loadRegions();
    await ChannelRegionStore.clearRegionEverywhere(region);
    regions.remove(region);
    saveRegions(regions);
  }
}
