import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';

/// L'annuaire hors ligne du kiosk doit calculer EXACTEMENT les mêmes
/// empreintes que le backend PHP, sinon aucun PIN/QR ne serait reconnu.
///
/// Valeurs de référence produites par PHP :
///   hash_hmac('sha256', '111111', 'pepper-secret-é')
///   hash('sha256', 'token-QR-123')
void main() {
  test('empreinte PIN : HMAC-SHA256 identique à PHP (secret accentué compris)', () {
    final lookup = Hmac(sha256, utf8.encode('pepper-secret-é'))
        .convert(utf8.encode('111111'))
        .toString();

    expect(
      lookup,
      'f859f6dc704ca6e22da61f7652e2d0e6678df2e9a11105182c9e40c4cd2bc2f6',
    );
  });

  test('empreinte QR : SHA-256 identique à PHP', () {
    expect(
      sha256.convert(utf8.encode('token-QR-123')).toString(),
      'd2d654c711c73d99ac212c5096f4a409a9ac77a55204b85fe7cbbcb8114d6a69',
    );
  });
}
