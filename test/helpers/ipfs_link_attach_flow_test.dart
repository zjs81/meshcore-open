import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_open/helpers/ipfs_link_attach_flow.dart';
import 'package:meshcore_open/helpers/ipfs_upload_helper.dart';
import 'package:meshcore_open/l10n/app_localizations.dart';

void main() {
  const url = 'ipfs://cid';
  String identity(String text) => text;

  group('composeIpfsLinkDraft', () {
    test('puts the link before an empty draft with a trailing space', () {
      expect(composeIpfsLinkDraft(messageUrl: url, existingText: ''), '$url ');
    });

    test('keeps the whole draft after the link', () {
      final draft = 'x' * 500;
      expect(
        composeIpfsLinkDraft(messageUrl: url, existingText: draft),
        '$url\n$draft',
      );
    });
  });

  group('ipfsLinkDraftFits', () {
    test('accepts a draft at the limit and rejects one byte over', () {
      expect(
        ipfsLinkDraftFits('$url\nhi', maxBytes: 13, encodeOutbound: identity),
        isTrue,
      );
      expect(
        ipfsLinkDraftFits('$url\nhi', maxBytes: 12, encodeOutbound: identity),
        isFalse,
      );
    });

    test('measures the encoded form, including a reply prefix', () {
      String withReply(String text) => '@[Alice] $text';
      expect(
        ipfsLinkDraftFits('$url\nhi', maxBytes: 13, encodeOutbound: withReply),
        isFalse,
      );
      expect(
        ipfsLinkDraftFits('$url\nhi', maxBytes: 22, encodeOutbound: withReply),
        isTrue,
      );
    });

    test('ignores the trailing space the send path trims', () {
      expect(
        ipfsLinkDraftFits(
          '$url ',
          maxBytes: url.length,
          encodeOutbound: identity,
        ),
        isTrue,
      );
    });
  });

  group('IpfsUploadHelper.linkForCid', () {
    test('uses ipfs:// without a gateway', () {
      expect(
        IpfsUploadHelper.linkForCid(uploadGateway: '', cid: 'abc'),
        'ipfs://abc',
      );
    });

    test('sample CID is CIDv1 base32 length', () {
      expect(IpfsUploadHelper.sampleCid.length, 59);
    });
  });

  group('ipfsUploadErrorText', () {
    final l10n = lookupAppLocalizations(const Locale('en'));

    test('gives every config reason its own localized message', () {
      final texts = {
        for (final reason in IpfsUploadConfigError.values)
          reason: ipfsUploadErrorText(l10n, IpfsUploadConfigException(reason)),
      };
      expect(
        texts[IpfsUploadConfigError.emptyEndpoint],
        l10n.chat_ipfsUploadNotConfigured,
      );
      expect(
        texts[IpfsUploadConfigError.kuboPathInvalid],
        l10n.chat_ipfsKuboPathInvalid,
      );
      expect(texts.values.toSet(), hasLength(texts.length));
    });

    test('wraps other errors in the generic message without the prefix', () {
      expect(
        ipfsUploadErrorText(l10n, Exception('IPFS upload failed (500): x')),
        l10n.chat_ipfsUploadFailed('IPFS upload failed (500): x'),
      );
    });
  });
}
