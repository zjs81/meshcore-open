import 'package:meshcore_open/storage/channel_region_store.dart';
import 'package:meshcore_open/storage/channel_store.dart';

import 'prefs_manager.dart';

typedef Region = String;

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
    final channelStore = ChannelStore();
    final channelRegionStore = ChannelRegionStore();
    channelStore.setPublicKeyHex = publicKeyHex;
    channelRegionStore.setPublicKeyHex = publicKeyHex;

    for (var channel in await channelStore.loadChannels()) {
      var channelRegion = await channelRegionStore.loadRegion(channel.index);
      if (channelRegion == region) {
        await channelRegionStore.saveRegion(channel.index, '');
      }
    }
    regions.remove(region);
    saveRegions(regions);
  }
}
