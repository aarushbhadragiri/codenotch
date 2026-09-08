# Hover notch blur

Appearance → Show on hover exposes a Blur Off/On selector. Blur defaults to
On and the choice persists across launches and visibility-mode changes.
It fades in when the notch expands and fades out when it folds. Always show
does not apply the effect. macOS Reduce Transparency suppresses it.

The implementation uses public NSVisualEffectView behind-window sampling,
masked by a feathered copy of the notch silhouette on all four screen edges.
The feather blends a fixed native blur progressively into the desktop; it
does not use private variable-radius filters or screen recording.
The tooltip is a separate foreground sibling: neither its contents nor its
outline contribute to the blur mask. The effect does not receive mouse events.

## Manual verification

- Put patterned wallpaper or a text window behind the notch, hover to expand,
  and check that the backdrop softens near the notch and fades outward.
- Hover each provider: the detail card and pointer must stay sharp and must
  not produce a halo of their own.
- Toggle Blur Off/On while expanded, then restart to verify persistence.
- Select Always show: the blur and its setting must disappear. Returning to
  Show on hover restores the saved choice.
- Check all four edges, folded/expanded transitions, and Reduce Transparency.
