# Haptic feedback

General settings exposes a Haptic feedback Off/On control, enabled by default,
and a Minimal/Full detail choice.

- Minimal confirms a manually requested provider refresh and its successful
  completion.
- Full additionally responds when the pointer enters and expands the notch,
  first opens a provider tooltip, or moves between provider rings.

The interaction layer emits semantic events and `HapticFeedbackService` maps
them to AppKit's supported alignment, generic, and level-change patterns. It
uses `NSHapticFeedbackManager.defaultPerformer`, which safely does nothing on
hardware without a compatible Force Touch trackpad.

When Reduce Motion is enabled in macOS, Codenotch automatically uses the
Minimal event set even if Full is selected. Turning Haptic feedback off prevents
all events.

Refresh-success feedback is connected only to a ring click. Scheduled polling
does not emit haptics, and a failed or superseded fetch never produces the
success pattern.

## Manual checks

1. Set General → Haptic feedback to On and Haptic detail to Full.
2. Enter the folded notch, move across two provider rings, and confirm the
   opening, initial tooltip, and provider-change cues are distinct but light.
3. Click a provider ring. Confirm the immediate action cue and the success cue
   after the refreshed reading lands.
4. Disconnect the network and click again. Confirm there is no success cue.
5. Select Minimal and confirm hover/open cues stop while manual refresh cues
   remain.
6. Enable Reduce Motion in macOS and confirm the same conservative behavior.
7. Turn Haptic feedback Off and confirm all cues stop.
