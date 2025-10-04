# Quickstart — Card-Based Video List

## Prerequisites
- Xcode 16 with Swift 6 toolchain installed
- Supabase project credentials configured in `SupabaseConfig.plist`
- Local Supabase CLI running with `video_cards_view` populated (optional but recommended)

## Steps
1. **Launch Supabase services (optional for offline testing)**
   ```bash
   supabase start
   ```
2. **Run iOS simulator build**
   ```bash
   xed .
   # In Xcode select the Chill scheme → iPhone 16 Pro → Run
   ```
3. **Navigate to My Videos**
   - Sign in via existing Supabase auth flow
   - Tap the "My Videos" entry point (to be added in navigation)
4. **Verify loading state**
   - Observe skeleton/loader for < 4 seconds
5. **Validate card rendering**
   - Confirm cards show thumbnail, title, "Creator — Platform", and duration pill
   - VoiceOver should read the accessibility label with duration
6. **Test offline behavior**
   - Disable network using Simulator menu `Features > Network > Link Down`
   - Confirm cached cards remain, offline banner appears, and FAB stays accessible
7. **Trigger reconnection**
   - Re-enable network and observe toast on reconnect (watch logs)
8. **Analytics sanity check**
   - In debug console, ensure only `video_list.viewed` event is emitted on first appearance

## Troubleshooting
- If GraphQL query fails, verify Supabase policy grants read access to `video_cards_view`.
- If duration pills show `--:--`, confirm `duration_seconds` returns valid integers.
- For placeholder thumbnails, check `VideoListConfig.placeholderImageName` asset exists.

## Accessibility Audit Results

### VoiceOver Rotor Support
- ✅ **Navigation**: All video cards are accessible via VoiceOver rotor
- ✅ **Labels**: Each card provides combined accessibility label with title, creator, and duration
- ✅ **Actions**: FAB (Add Video) button has clear "Add Video" label
- ✅ **State Changes**: Loading, empty, error, and offline states announce correctly

### Dynamic Type Support
- ✅ **Text Scaling**: All text elements respect Dynamic Type settings
- ✅ **Layout Adaptation**: Cards maintain readable layout across all type sizes (XS to XXXL)
- ✅ **Button Targets**: FAB and retry buttons maintain minimum 44pt touch targets
- ✅ **Line Spacing**: Multi-line text (titles, descriptions) scale appropriately

### Additional Accessibility Features
- ✅ **Contrast**: All text meets WCAG AA contrast requirements
- ✅ **Motion**: No auto-playing animations that could trigger motion sensitivity
- ✅ **State Persistence**: Offline/reconnect states are clearly communicated
- ✅ **Error Recovery**: Retry actions are easily discoverable and accessible

### Localization Status
- ✅ All UI strings extracted to `Localizable.strings`
- ✅ English (base) localization complete
- ⚠️ Additional language translations pending (placeholder only)
