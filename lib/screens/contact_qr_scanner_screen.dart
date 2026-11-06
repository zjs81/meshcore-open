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

  /// Set after a failed import so the camera does not immediately rescan the
  /// same QR and resend the frame in a loop.
  bool _importFailed = false;

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
          ? const QrScannerProcessingBody()
          : _importFailed
          ? _buildImportFailed(context)
          : QrScannerWidget(
              onScanned: (data) => _handleScannedData(data),
              validator: (data) => parseContactQr(data) != null,
              onValidationFailed: (_) => _showInvalidQrError(),
              instructions: context.l10n.contacts_scanQrInstructions,
              themed: true,
            ),
    );
  }

  Widget _buildImportFailed(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              context.l10n.contacts_contactImportFailed,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => setState(() => _importFailed = false),
              icon: const Icon(Icons.refresh),
              label: Text(context.l10n.common_retry),
            ),
          ],
        ),
      ),
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
      _importFailed = false;
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
      // Keep _isProcessing set: resetting it would restart the camera on a
      // closing route and let a second detection import and pop again.
      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _importFailed = true;
        });
      }
    }
  }

  void _showInvalidQrError() {
    showInvalidQrSnackBar(context, context.l10n.contacts_invalidAdvertFormat);
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
