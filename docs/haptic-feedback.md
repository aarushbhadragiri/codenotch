# Haptic feedback

General settings exposes a Haptic feedback Off/On control, enabled by default,
and a Minimal/Full detail choice.

- Minimal confirms deliberate actions: opening Settings, toggling a provider,
  and manually requesting a refresh.
- Full additionally responds when the pointer enters the notch, moves between
  provider rings, or option-drags the notch along the screen edge.

The interaction layer emits semantic events and `HapticFeedbackService` maps
them to AppKit's supported alignment, generic, and level-change patterns. It
uses `NSHapticFeedbackManager.defaultPerformer`, which safely does nothing on
hardware without a compatible Force Touch trackpad.

When Reduce Motion is enabled in macOS, Codenotch automatically uses the
Minimal event set even if Full is selected. Turning Haptic feedback off prevents
all events.

Refresh-success feedback is connected only to a ring click. It begins 0.15
seconds after the refresh animation ends: one medium click through 50%, two
above 50% and below 75%, three from 75% through 99%, and three strong clicks at
100% or higher. Scheduled polling does not emit haptics, and a failed or
superseded fetch never produces the success pattern.

Option-dragging starts with a medium click, then produces throttled bumps while
the notch moves. Faster movement selects the strongest AppKit pattern. The
service also defines a light slider-boundary event; upstream 1.6.0 does not yet
contain the custom blur-strength slider that will invoke it.

## Manual checks

1. Set General → Haptic feedback to On and Haptic detail to Full.
2. Enter the folded notch and move across two provider rings.
3. Click provider rings at different usage levels and confirm the tiered cue
   after the refreshed reading lands.
4. Disconnect the network and click again. Confirm there is no success cue.
5. Option-drag the notch slowly and quickly; confirm the initial medium click
   and the stronger, denser bumps at speed.
6. Select Minimal and confirm hover/drag cues stop while deliberate cues remain.
7. Enable Reduce Motion in macOS and confirm the same conservative behavior.
8. Turn Haptic feedback Off and confirm all cues stop.
