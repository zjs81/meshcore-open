import '../helpers/contact_share_message.dart';
import '../utils/contact_qr.dart';

/// Kind of content found when parsing clipboard text for adding a contact.
enum ContactClipboardKind { empty, contact, publicKey, invalid }

/// Result of parsing clipboard text on the Add Contact screen.
class ContactClipboardParseResult {
  final ContactClipboardKind kind;
  final ScannedContact? contact;
  final String? publicKeyHex;

  const ContactClipboardParseResult._(
    this.kind, {
    this.contact,
    this.publicKeyHex,
  });

  const ContactClipboardParseResult.empty()
    : this._(ContactClipboardKind.empty);

  const ContactClipboardParseResult.contact(ScannedContact contact)
    : this._(ContactClipboardKind.contact, contact: contact);

  const ContactClipboardParseResult.publicKey(String publicKeyHex)
    : this._(ContactClipboardKind.publicKey, publicKeyHex: publicKeyHex);

  const ContactClipboardParseResult.invalid()
    : this._(ContactClipboardKind.invalid);
}

/// Parses clipboard text as a `meshcore://` contact URI/advert, an embedded
/// `<PUBKEY:TYPE:NAME>` contact share, or a bare 64-hex-char public key.
ContactClipboardParseResult parseContactClipboard(String? rawText) {
  if (rawText == null) return const ContactClipboardParseResult.empty();
  final trimmed = rawText.trim();
  if (trimmed.isEmpty) return const ContactClipboardParseResult.empty();

  if (trimmed.toLowerCase().startsWith('meshcore://')) {
    final scanned = parseContactQr(trimmed);
    return scanned != null
        ? ContactClipboardParseResult.contact(scanned)
        : const ContactClipboardParseResult.invalid();
  }

  final share = findContactShare(trimmed);
  if (share != null) {
    return ContactClipboardParseResult.contact(share.toScannedContact());
  }

  final normalizedKey = normalizeContactPublicKeyHex(trimmed);
  if (normalizedKey != null) {
    return ContactClipboardParseResult.publicKey(normalizedKey);
  }

  return const ContactClipboardParseResult.invalid();
}
