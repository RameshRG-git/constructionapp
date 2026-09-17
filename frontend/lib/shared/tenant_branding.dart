/// Per-tenant branding assets bundled with the app (checked into git under
/// assets/tenants/<slug>/logo.png), keyed by tenant slug. A tenant not listed
/// here falls back to the `logo_url` returned by the backend, then to a
/// generic icon. To add a new tenant's logo: drop the file at
/// assets/tenants/<slug>/logo.png, add it to pubspec.yaml's flutter->assets
/// list, and add an entry below.
const Map<String, String> tenantLogoAssets = {
  'kaniskahomes': 'assets/tenants/kaniskahomes/logo.png',
};

String? resolveTenantLogoAsset(String? tenantSlug) {
  if (tenantSlug == null || tenantSlug.isEmpty) {
    return null;
  }
  return tenantLogoAssets[tenantSlug.trim().toLowerCase()];
}
