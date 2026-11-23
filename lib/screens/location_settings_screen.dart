import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../connector/meshcore_connector.dart';
import '../helpers/guessed_location_estimator.dart';
import '../helpers/snack_bar_builder.dart';
import '../l10n/l10n.dart';
import '../services/app_settings_service.dart';
import '../widgets/mesh_nav_tile.dart';
import '../widgets/mesh_ui.dart';
import '../widgets/unsaved_changes_guard.dart';
import 'location_picker_screen.dart';

/// Form values compared to detect unsaved edits.
typedef _LocationForm = ({
  String latitude,
  String longitude,
  String interval,
  bool gpsEnabled,
});

/// Advertised location and, with GPS hardware, GPS settings. Sent on Save.
class LocationSettingsScreen extends StatefulWidget {
  const LocationSettingsScreen({super.key});

  @override
  State<LocationSettingsScreen> createState() => _LocationSettingsScreenState();
}

class _LocationSettingsScreenState extends State<LocationSettingsScreen> {
  final _latController = TextEditingController();
  final _lonController = TextEditingController();
  final _intervalController = TextEditingController();
  late final bool _hasGps;
  bool _gpsEnabled = false;
  double? _deviceLatitude;
  double? _deviceLongitude;
  late _LocationForm _savedForm;
  String? _latError;
  String? _lonError;
  String? _intervalError;

  @override
  void initState() {
    super.initState();
    final connector = context.read<MeshCoreConnector>();
    final settingsService = context.read<AppSettingsService>();
    // Null until the device answers.
    final customVars = connector.currentCustomVars ?? {};
    _hasGps = customVars.containsKey('gps');
    _gpsEnabled = customVars['gps'] == '1';
    _deviceLatitude = connector.selfLatitude;
    _deviceLongitude = connector.selfLongitude;
    if (_hasLocation) {
      _latController.text = _deviceLatitude!.toStringAsFixed(6);
      _lonController.text = _deviceLongitude!.toStringAsFixed(6);
    }
    _intervalController.text = settingsService
        .resolvedGpsIntervalSeconds(customVars)
        .toString();
    _savedForm = _currentForm();
  }

  @override
  void dispose() {
    _latController.dispose();
    _lonController.dispose();
    _intervalController.dispose();
    super.dispose();
  }

  /// Firmware stores "no location" as 0,0 (the default for a fresh node), so
  /// that pair is shown as empty fields rather than a real coordinate.
  bool get _hasLocation {
    final lat = _deviceLatitude;
    final lon = _deviceLongitude;
    return lat != null && lon != null && !(lat == 0 && lon == 0);
  }

  _LocationForm _currentForm() => (
    latitude: _latController.text.trim(),
    longitude: _lonController.text.trim(),
    interval: _hasGps ? _intervalController.text.trim() : '',
    gpsEnabled: _hasGps && _gpsEnabled,
  );

  /// Valid field coordinates, else the radio's location.
  LatLng? get _pickerStart {
    final lat = double.tryParse(_latController.text.trim());
    final lon = double.tryParse(_lonController.text.trim());
    if (lat != null && lon != null && isPlausibleLocation(lat, lon)) {
      return LatLng(lat, lon);
    }
    return _hasLocation ? LatLng(_deviceLatitude!, _deviceLongitude!) : null;
  }

  Future<void> _pickOnMap() async {
    final picked = await Navigator.push<LatLng>(
      context,
      MaterialPageRoute(
        builder: (_) => LocationPickerScreen(initial: _pickerStart),
      ),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _latController.text = picked.latitude.toStringAsFixed(6);
      _lonController.text = picked.longitude.toStringAsFixed(6);
      _latError = null;
      _lonError = null;
    });
  }

  /// Validates all fields, then sends GPS (if changed), interval and location.
  Future<bool> _save() async {
    final l10n = context.l10n;
    // Validate first so a typo doesn't leave half the changes applied.
    int? interval;
    String? intervalError;
    if (_hasGps) {
      final intervalText = _intervalController.text.trim();
      if (intervalText.isNotEmpty) {
        interval = int.tryParse(intervalText);
        if (interval == null || interval < 60 || interval >= 86400) {
          intervalError = l10n.settings_locationIntervalInvalid;
        }
      }
    }

    final latText = _latController.text.trim();
    final lonText = _lonController.text.trim();
    double? lat;
    double? lon;
    String? latError;
    String? lonError;
    var clearsLocation = false;
    if (latText.isEmpty && lonText.isEmpty) {
      // Clearing both fields removes the location. Companion firmware has no
      // dedicated "clear" command: CMD_SET_ADVERT_LATLON with 0,0 restores
      // the factory default, which firmware and this app treat as unset.
      if (_hasLocation) {
        lat = 0;
        lon = 0;
        clearsLocation = true;
      }
    } else {
      // One empty field keeps the device's current value for that axis.
      lat = latText.isNotEmpty
          ? double.tryParse(latText)
          : (_hasLocation ? _deviceLatitude : null);
      lon = lonText.isNotEmpty
          ? double.tryParse(lonText)
          : (_hasLocation ? _deviceLongitude : null);
      if (lat == null) {
        latError = latText.isEmpty
            ? l10n.settings_locationBothRequired
            : l10n.settings_locationInvalid;
      } else if (lat < -90 || lat > 90) {
        latError = l10n.settings_locationInvalid;
      }
      if (lon == null) {
        lonError = lonText.isEmpty
            ? l10n.settings_locationBothRequired
            : l10n.settings_locationInvalid;
      } else if (lon < -180 || lon > 180) {
        lonError = l10n.settings_locationInvalid;
      }
    }

    if (intervalError != null || latError != null || lonError != null) {
      setState(() {
        _intervalError = intervalError;
        _latError = latError;
        _lonError = lonError;
      });
      return false;
    }

    // An empty interval leaves the stored one; show it again.
    if (_hasGps && _intervalController.text.trim().isEmpty) {
      _intervalController.text = _savedForm.interval;
    }
    final gpsChanged = _hasGps && _gpsEnabled != _savedForm.gpsEnabled;
    if (!gpsChanged && interval == null && (lat == null || lon == null)) {
      // Nothing to send, like the old dialog.
      setState(() => _savedForm = _currentForm());
      return true;
    }

    final connector = context.read<MeshCoreConnector>();
    final settingsService = context.read<AppSettingsService>();
    if (gpsChanged) {
      await connector.setCustomVar(_gpsEnabled ? "gps:1" : "gps:0");
    }
    if (interval != null) {
      await settingsService.setGpsIntervalSeconds(
        interval,
        writeToDevice: (value) => connector.setCustomVar("gps_interval:$value"),
      );
    }
    if (lat != null && lon != null) {
      await connector.setNodeLocation(lat: lat, lon: lon);
    }
    await connector.refreshDeviceInfo();
    if (!mounted) return true;
    setState(() {
      if (lat != null && lon != null) {
        _deviceLatitude = lat;
        _deviceLongitude = lon;
      }
      _savedForm = _currentForm();
    });
    showDismissibleSnackBar(
      context,
      content: Text(
        clearsLocation
            ? l10n.settings_locationCleared
            : l10n.settings_locationUpdated,
      ),
    );
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    const coordinateKeyboard = TextInputType.numberWithOptions(
      decimal: true,
      signed: true,
    );
    return SaveToRadioPage(
      title: l10n.settings_location,
      hasChanges: _currentForm() != _savedForm,
      onSave: _save,
      children: [
        SectionHeader(
          l10n.location_coordinates,
          description: l10n.location_coordinatesDescription,
        ),
        MeshCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    TextField(
                      controller: _latController,
                      onTapOutside: (_) => FocusScope.of(context).unfocus(),
                      onChanged: (_) => setState(() => _latError = null),
                      decoration: InputDecoration(
                        labelText: l10n.settings_latitude,
                        errorText: _latError,
                        errorMaxLines: 2,
                      ),
                      keyboardType: coordinateKeyboard,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _lonController,
                      onTapOutside: (_) => FocusScope.of(context).unfocus(),
                      onChanged: (_) => setState(() => _lonError = null),
                      decoration: InputDecoration(
                        labelText: l10n.settings_longitude,
                        helperText: l10n.settings_locationClearHelper,
                        helperMaxLines: 2,
                        errorText: _lonError,
                        errorMaxLines: 2,
                      ),
                      keyboardType: coordinateKeyboard,
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, indent: 16),
              MeshNavTile(
                icon: Icons.map_outlined,
                title: l10n.location_pickOnMap,
                onTap: _pickOnMap,
              ),
            ],
          ),
        ),
        if (_hasGps) ...[
          SectionHeader(l10n.telemetry_gpsLabel),
          MeshCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                SwitchListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  secondary: const Icon(Icons.gps_fixed, size: 24),
                  title: Text(l10n.settings_locationGPSEnable),
                  subtitle: Text(l10n.settings_locationGPSEnableSubtitle),
                  value: _gpsEnabled,
                  // Sent on Save.
                  onChanged: (value) => setState(() => _gpsEnabled = value),
                ),
                const Divider(height: 1, indent: 16),
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: TextField(
                    controller: _intervalController,
                    onTapOutside: (_) => FocusScope.of(context).unfocus(),
                    onChanged: (_) => setState(() => _intervalError = null),
                    decoration: InputDecoration(
                      labelText: l10n.settings_locationIntervalSec,
                      helperText: l10n.settings_locationIntervalHelper,
                      errorText: _intervalError,
                      errorMaxLines: 2,
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: false,
                      signed: false,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
