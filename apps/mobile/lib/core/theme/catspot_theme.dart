import 'package:flutter/material.dart';

import 'catspot_tokens.dart';

/// Convenience helper for accessing Catspot design tokens from a [BuildContext].
class CatspotTheme {
  CatspotTheme._();

  /// Returns the aggregate [CatspotTokens] extension from the current theme.
  static CatspotTokens of(BuildContext context) {
    return Theme.of(context).extension<CatspotTokens>()!;
  }
}
