/// Storage scopes (first 10 hex chars of a radio's public key) that must
/// never adopt data from the legacy unscoped keys.
///
/// The per-radio stores move a legacy key into the first scope that loads it
/// and then delete the legacy key. A scope listed here, such as the simulated
/// review-mode radio, leaves legacy data for the next real radio.
final Set<String> scopesWithoutLegacyMigration = {};

bool canMigrateLegacyKeys(String scopeHex) =>
    !scopesWithoutLegacyMigration.contains(scopeHex);
