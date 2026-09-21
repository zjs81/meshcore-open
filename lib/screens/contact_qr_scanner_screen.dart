import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import '../connector/meshcore_connector.dart';
import '../connector/meshcore_protocol.dart';
import '../helpers/snack_bar_builder.dart';
import '../l10n/l10n.dart';
import '../theme/mesh_theme.dart';
import '../utils/contact_qr.dart';
import '../utils/contact_qr_frame.dart';
import '../widgets/adaptive_app_bar_title.dart';
import '../widgets/qr_scanner_widget.dart';

/// Screen for scanning MeshCore contact QR codes, either with the camera
/// or by picking a photo containing a QR code from the gallery.
class ContactQrScannerScreen extends StatefulWidget {
  const ContactQrScannerScreen({super.key});

  @override
  State<ContactQrScannerScreen> createState() => _ContactQrScannerScreenState();
}

class _ContactQrScannerScreenState extends State<ContactQrScannerScreen> {
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: AdaptiveAppBarTitle(context.l10n.contacts_scanQrCode),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: context.l10n.contacts_qrFromGallery,
            icon: const Icon(Icons.photo_library),
            onPressed: _isProcessing ? null : _pickFromGallery,
          ),
        ],
      ),
      body: _isProcessing
          ? Container(
              color: Theme.of(context).colorScheme.surface,
              child: const Center(child: CircularProgressIndicator()),
            )
          : QrScannerWidget(
              onScanned: (data) => _handleScannedData(data),
              validator: (data) => parseContactQr(data) != null,
              onValidationFailed: (_) => _showInvalidQrError(),
              instructions: context.l10n.contacts_scanQrInstructions,
              overlay: _buildThemedOverlay(context),
            ),
    );
  }

  Widget _buildThemedOverlay(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Dark semi-transparent background with cutout
        ColorFiltered(
          colorFilter: ColorFilter.mode(
            Colors.black.withValues(alpha: 0.5),
            BlendMode.srcOut,
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Container(
                decoration: const BoxDecoration(
                  color: Colors.black,
                  backgroundBlendMode: BlendMode.dstOut,
                ),
              ),
              Center(
                child: Container(
                  height: 250,
                  width: 250,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Corner brackets on top
        const ScannerCornerOverlay(
          scanWindowSize: 250,
          borderColor: MeshPalette.blue,
          borderWidth: 2,
          cornerLength: 24,
        ),
        // Instructions pill below the scan window
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 250 + 24),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.72),
                  borderRadius: BorderRadius.circular(MeshRadii.pill),
                ),
                child: Text(
                  context.l10n.contacts_scanQrInstructions,
                  style: const TextStyle(color: MeshPalette.ink2, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _pickFromGallery() async {
    if (_isProcessing) return;

    // Claim the flag before awaiting the picker, otherwise a camera detection
    // can start a second import while the gallery sheet is open.
    setState(() {
      _isProcessing = true;
    });

    final XFile? image;
    try {
      image = await ImagePicker().pickImage(source: ImageSource.gallery);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
        _showGalleryError();
      }
      return;
    }
    if (!mounted) return;
    if (image == null) {
      setState(() {
        _isProcessing = false;
      });
      return;
    }

    String? rawValue;
    bool decodedAnyBarcode = false;
    final controller = MobileScannerController();
    try {
      final capture = await controller.analyzeImage(image.path);
      for (final barcode in capture?.barcodes ?? const []) {
        final value = barcode.rawValue;
        if (value == null || value.isEmpty) continue;
        decodedAnyBarcode = true;
        if (parseContactQr(value) != null) {
          rawValue = value;
          break;
        }
      }
    } on UnsupportedError {
      rawValue = null;
    } catch (e) {
      rawValue = null;
    } finally {
      controller.dispose();
    }

    if (!mounted) return;

    if (rawValue == null) {
      setState(() {
        _isProcessing = false;
      });
      if (decodedAnyBarcode) {
        _showInvalidQrError();
      } else {
        showDismissibleSnackBar(
          context,
          content: Text(context.l10n.contacts_noQrCodeFound),
          backgroundColor: MeshPalette.warn,
          duration: const Duration(seconds: 2),
        );
      }
      return;
    }

    setState(() {
      _isProcessing = false;
    });
    await _handleScannedData(rawValue);
  }

  Future<void> _handleScannedData(String data) async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    final scanned = parseContactQr(data);
    if (scanned == null) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
        _showInvalidQrError();
      }
      return;
    }

    final connector = Provider.of<MeshCoreConnector>(context, listen: false);
    final publicKey = scanned.publicKey;
    // Saved contacts first (their flags matter), then discovery-only records,
    // which still carry a known name worth preserving.
    final existing = publicKey == null
        ? null
        : connector.allContactsUnfiltered
              .where(
                (contact) => contact.publicKeyHex == pubKeyToHex(publicKey),
              )
              .firstOrNull;
    final frame = buildContactQrFrame(
      scanned,
      existing: existing,
      pathHashByteWidth: connector.pathHashByteWidth,
    );

    try {
      await connector.sendFrame(frame, waitForGenericAck: true);
      await connector.refreshContacts();
      if (!mounted) return;
      showDismissibleSnackBar(
        context,
        content: Text(context.l10n.contacts_contactImported),
      );
      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        showDismissibleSnackBar(
          context,
          content: Text(context.l10n.contacts_contactImportFailed),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  void _showInvalidQrError() {
    showDismissibleSnackBar(
      context,
      content: Text(context.l10n.contacts_invalidAdvertFormat),
      backgroundColor: MeshPalette.warn,
      duration: const Duration(seconds: 2),
    );
  }

  void _showGalleryError() {
    showDismissibleSnackBar(
      context,
      content: Text(context.l10n.contacts_qrGalleryFailed),
      backgroundColor: MeshPalette.warn,
      duration: const Duration(seconds: 2),
    );
  }
}
