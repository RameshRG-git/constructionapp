# Tenant branding assets

Each tenant's logo lives at `assets/tenants/<tenant_slug>/logo.png`, checked into
git and bundled into the app (not fetched from a URL), so it survives without any
backend configuration.

To add or update a tenant's logo:

1. Place the image at `assets/tenants/<tenant_slug>/logo.png` (square, ideally
   with a transparent background, at least 128x128).
2. Add the path to the `flutter: assets:` list in `pubspec.yaml` if it's a new
   tenant folder.
3. Add an entry to `tenantLogoAssets` in `lib/shared/tenant_branding.dart`
   mapping the tenant slug to that asset path.

A tenant not listed in `tenantLogoAssets` falls back to the `logo_url` stored on
the tenant record (Tenant Admin screen), then to a generic icon.

## kaniskahomes

`logo.png` is generated from `KANISHKA_HOMES_LOGO_PDF.pdf` (kept alongside it for
provenance) via PyMuPDF + Pillow: rasterized, near-white background made
transparent, then cropped to content with a small padding margin.
