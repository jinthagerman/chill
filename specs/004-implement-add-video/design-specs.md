# Design Specifications: Add Video via URL Modal

**Feature**: 004-implement-add-video  
**Date**: 2025-10-04  
**Reference**: add_video_link_modal.png, video_details_confirmation.png  
**Status**: Complete

---

## Overview

This feature implements a **two-step flow** for adding videos:
1. **Input Modal**: "Save a video" - URL and optional description entry
2. **Confirmation Screen**: "Confirm Video" - Preview with fetched metadata

---

## Step 1: Input Modal ("Save a video")

### Layout Specifications

**Modal Presentation**:
- SwiftUI sheet with `.medium` or `.large` detent
- Rounded corners (system default)
- Drag indicator visible at top center
- Light background (system background color)
- Centered vertically on screen

**Header**:
- Title: **"Save a video"**
- Font: System bold, size ~28pt (title1 or custom)
- Color: Primary text (black in light mode)
- Alignment: Left-aligned with leading padding ~20pt
- Spacing: 20pt from top (below drag indicator)

**URL Input Field**:
- Background: Light gray fill (quaternary system fill or similar)
- Corner radius: 12pt
- Height: ~50-55pt (comfortable touch target)
- Placeholder: "Video URL" (secondary text color)
- Font: System regular, size ~17pt
- Padding: Horizontal 16pt, vertical 16pt
- Keyboard type: URL keyboard
- Auto-capitalization: None
- Auto-correction: Off
- Spacing: 16pt below title

**Description Field (Optional)**:
- Background: Light gray fill (same as URL field)
- Corner radius: 12pt
- Minimum height: ~120pt (multi-line)
- Placeholder: "Description (optional)" (secondary text color)
- Font: System regular, size ~17pt
- Padding: Horizontal 16pt, vertical 16pt
- Max lines: Expandable (but capped at reasonable height)
- Spacing: 12pt below URL field

**Action Buttons**:
- Container: HStack with equal spacing
- Height: ~50-54pt each
- Corner radius: 12pt
- Spacing: 12pt between buttons
- Bottom padding: 20pt from modal bottom (safe area)
- Top spacing: 20pt from description field

**Cancel Button**:
- Background: Light gray (secondary system fill)
- Text: "Cancel" (primary text color)
- Font: System semibold, size ~17pt
- Width: ~48% of modal width

**Save Button**:
- Background: Black (or primary brand color)
- Text: "Save" (white)
- Font: System semibold, size ~17pt
- Width: ~48% of modal width
- State: Disabled (reduced opacity 0.5) when URL field empty

### Behavior

**Auto-focus**:
- URL field focused automatically when modal appears
- Keyboard slides up immediately

**Validation** (Silent):
- Real-time URL validation happens in background
- No visual indicators shown (per design mockup)
- Save button enabled only when URL non-empty (basic validation)

**Submission**:
- Tap "Save" → Show loading indicator
- Overlay with spinner and "Fetching video details..." message
- Transition to confirmation screen on success
- Show error message on failure (keep modal open)

---

## Step 2: Confirmation Screen ("Confirm Video")

### Layout Specifications

**Screen Presentation**:
- Full-screen modal (not sheet)
- White/light background
- X close button in top-left corner
- No back navigation (X button only exit besides confirm)

**Close Button (X)**:
- Position: Top-left, 16-20pt from edges
- Size: 44x44pt touch target
- Icon: X symbol (SF Symbol "xmark")
- Style: Simple black X on transparent background
- Accessibility label: "Close, dismiss without saving"

**Title**:
- Text: **"Confirm Video"**
- Font: System bold, size ~20-22pt (headline or title2)
- Color: Primary text (black)
- Alignment: Centered horizontally
- Position: Top center, ~16-20pt from top edge
- Spacing: 20-24pt below title to video preview

**Video Preview Card**:
- Width: Full width minus 32pt horizontal padding (16pt each side)
- Aspect ratio: 16:9 (standard video aspect)
- Corner radius: 16pt
- Shadow: Subtle elevation (small shadow for depth)
- Spacing: 24pt below title

**Thumbnail**:
- Fill entire preview card area
- Content mode: Aspect fill (crop to fit)
- Background: Dark gray placeholder if image loading

**Play Button Overlay**:
- Position: Centered on thumbnail
- Size: 60x60pt
- Style: White play triangle in semi-transparent dark circle
- Background: Black 40% opacity, circle with 30pt radius
- Icon: SF Symbol "play.fill" or custom triangle
- Note: Non-interactive in MVP (decorative only)

**Platform Badge Overlay**:
- Position: Top-left of thumbnail, 12pt inset from edges
- Background: White or semi-transparent white (80% opacity)
- Text: Platform name ("YouTube", "Facebook", "Twitter")
- Font: System semibold, size ~13-14pt
- Color: Black or brand color
- Padding: 6pt vertical, 10pt horizontal
- Corner radius: 8pt

**Video Title Overlay**:
- Position: Bottom-left of thumbnail, 12-16pt inset from edges
- Background: Linear gradient from transparent (top) to black (bottom)
- Text: Video title (1-2 lines, truncated if too long)
- Font: System semibold, size ~16-18pt
- Color: White
- Padding: 12pt horizontal, 16pt bottom
- Max lines: 2 with ellipsis

**Duration Badge Overlay**:
- Position: Below title overlay, bottom-left, 12-16pt inset
- Background: Black 60% opacity
- Text: Duration (e.g., "15:30")
- Font: System semibold, size ~13-14pt
- Color: White
- Padding: 4pt vertical, 8pt horizontal
- Corner radius: 6pt

**Metadata Section**:
- Spacing: 24pt below preview card
- Background: White (or very light gray card if preferred)
- Padding: 16pt horizontal

**Metadata Rows** (Title, Source, Length):
- Layout: HStack with label on left, value on right
- Height: ~44-50pt each
- Spacing: 0pt between rows (flush)
- Divider: 1pt light gray line between rows (optional, per design)

**Row Label**:
- Text: "Title", "Source", "Length"
- Font: System regular, size ~15pt
- Color: Secondary text (gray)
- Alignment: Leading

**Row Value**:
- Text: Actual value (video title, platform name, duration)
- Font: System regular or medium, size ~15pt
- Color: Primary text (black)
- Alignment: Trailing
- Max lines: 1 for Source and Length, 2 for Title with ellipsis

**Action Buttons Section**:
- Position: Bottom of screen, pinned to safe area
- Padding: 16pt horizontal, 20pt bottom
- Spacing: 12pt between buttons

**Confirm and Save Button**:
- Width: Full width (minus horizontal padding)
- Height: ~54pt
- Background: Black (or primary brand color)
- Text: "Confirm and Save" (white)
- Font: System semibold, size ~17pt
- Corner radius: 12pt
- Spacing: Directly above "Edit Details" button

**Edit Details Button**:
- Width: Full width (minus horizontal padding)
- Height: ~54pt
- Background: Light gray (secondary system fill)
- Text: "Edit Details" (primary text color)
- Font: System regular or medium, size ~17pt
- Corner radius: 12pt
- Spacing: 12pt below "Confirm and Save"
- Behavior: Returns to input modal with pre-filled data (stretch goal)

---

## Color Palette

**From Mockups**:
- Primary CTA: Black (`#000000` or `.primary`)
- Secondary CTA: Light gray (`#E5E5E5` or `.systemGray5`)
- Input background: Light gray (`#F0F0F0` or `.systemGray6` / `.quaternarySystemFill`)
- Text primary: Black (`#000000` or `.primary`)
- Text secondary: Gray (`#8E8E93` or `.secondaryLabel`)
- Overlay dark: Black 40-60% opacity for thumbnail overlays

**Design System Integration**:
- Use Chill design tokens from `Assets.xcassets` where available
- Fall back to system colors for consistency with iOS design language
- Match existing VideoListView card styling for cohesion

---

## Typography Scale

**Primary Hierarchy**:
- Modal Title ("Save a video"): ~28pt bold
- Screen Title ("Confirm Video"): ~20-22pt bold
- Video Title Overlay: ~16-18pt semibold
- Button Text: ~17pt semibold
- Input Field Text: ~17pt regular
- Metadata Labels/Values: ~15pt regular/medium
- Platform Badge: ~13-14pt semibold
- Duration Badge: ~13-14pt semibold

**Dynamic Type Support**:
- All text must scale with user's accessibility settings
- Maintain hierarchy with relative scaling
- Test at smallest and largest accessibility sizes

---

## Spacing System

**Consistent Spacing Values**:
- Screen edge padding: 16-20pt
- Between major sections: 20-24pt
- Between related elements: 12-16pt
- Internal padding (buttons, fields): 16pt horizontal, 12-16pt vertical
- Button corner radius: 12pt
- Card corner radius: 16pt (preview), 12pt (fields)

---

## Animations & Transitions

**Input Modal**:
- Presentation: Slide up from bottom (0.3s ease-out)
- Dismissal: Slide down (0.3s ease-in)
- Keyboard: Standard iOS keyboard animation

**Loading State**:
- Spinner: Center of modal, system default style
- Overlay: 40% white/black overlay with blur (optional)
- Status text: Below spinner, fades in after 3s

**Confirmation Screen**:
- Presentation: Slide up from bottom or fade in (0.3s)
- Dismissal: Slide down on X tap or fade out
- Image loading: Fade in thumbnail when loaded (0.2s)

**Reduced Motion**:
- All slide animations become fade in/out
- Spinner becomes pulsing opacity (no rotation)

---

## Accessibility

**Input Modal**:
- Title: Accessibility label "Save a video modal"
- URL field: Hint "Enter video URL from Facebook or Twitter"
- Description field: Hint "Optional description for this video"
- Save button (disabled): "Save button, disabled. Enter URL to enable"
- Save button (enabled): "Save button. Fetch video details"

**Confirmation Screen**:
- Screen: Accessibility label "Confirm video details"
- Close button: "Close, dismiss without saving"
- Preview card: "Video preview, {title}, {duration}, {platform}"
- Metadata rows: "{label}, {value}" (e.g., "Title, The Ultimate Guide to Productivity")
- Confirm button: "Confirm and save video to library"
- Edit button: "Edit video details"

**VoiceOver Navigation Order**:
1. Modal/Screen title
2. Close button (if confirmation screen)
3. Input fields (if input modal)
4. Preview card (if confirmation)
5. Metadata rows (if confirmation)
6. Action buttons (bottom-up: secondary then primary)

---

## Error States

**Input Modal Errors**:
- Invalid URL: Show red border on field, message below: "Please enter a valid video URL"
- Unsupported platform: "Only Facebook and Twitter videos are supported"
- Network error: "Unable to fetch video details. Check your connection and try again."
- Duplicate warning: Yellow/orange border, message: "⚠️ Already in your library"

**Error Message Styling**:
- Font: System regular, size ~14pt
- Color: Red (`.systemRed`) for errors, orange for warnings
- Position: 8pt below affected field
- Padding: 4pt vertical
- Animation: Fade in (0.2s)

**Confirmation Screen Errors**:
- If metadata incomplete: Show placeholder values ("Unknown", "N/A")
- If thumbnail fails: Show gray placeholder with platform icon
- If "Edit Details" pressed: Return to input modal (stretch goal for MVP)

---

## Loading States

**Input Modal Loading**:
- Overlay entire modal with semi-transparent white/black
- Center spinner (system default, medium size)
- Text below spinner: "Fetching video details..."
- After 3 seconds: "This is taking longer than usual..."
- Disable all interactions during loading

**Confirmation Screen Loading**:
- Thumbnail: Gray placeholder with subtle pulse animation
- Metadata values: Gray placeholder lines (shimmer optional)
- Buttons disabled until fully loaded

---

## Edge Cases & Adaptations

**Small Screens (iPhone SE, iPhone Mini)**:
- Reduce modal padding to 12pt
- Reduce font sizes by 1-2pt
- Ensure buttons remain above keyboard on input modal
- Scroll confirmation screen if metadata rows overflow

**Large Screens (iPhone Pro Max, iPad)**:
- Max width for input modal: 500pt (centered)
- Confirmation screen: Maintain reasonable content width
- Increased spacing for better visual balance

**Dark Mode**:
- Invert background: Dark gray/black
- Invert text: White primary, gray secondary
- Buttons: White text on dark background / Light gray secondary
- Overlays: Adjust opacity for visibility
- Thumbnail overlays: Maintain readability (text contrast)

**Landscape Orientation**:
- Input modal: Adapt to wider aspect, side-by-side fields (optional)
- Confirmation: Thumbnail maintains 16:9, metadata beside preview (optional)
- Or: Force portrait orientation for simplicity in MVP

---

## Implementation Notes

**View Structure**:
```
AddVideoCoordinator
├── AddVideoInputView (Step 1)
│   ├── Header ("Save a video")
│   ├── URLTextField
│   ├── DescriptionTextEditor
│   └── ActionButtons (Cancel, Save)
└── AddVideoConfirmationView (Step 2)
    ├── NavigationBar (X button, title)
    ├── VideoPreviewCard
    │   ├── ThumbnailImage
    │   ├── PlayButtonOverlay
    │   ├── PlatformBadge
    │   ├── TitleOverlay
    │   └── DurationBadge
    ├── MetadataSection
    │   ├── MetadataRow (Title)
    │   ├── MetadataRow (Source)
    │   └── MetadataRow (Length)
    └── ActionButtons (Confirm and Save, Edit Details)
```

**Assets Needed**:
- Play button icon (SF Symbol "play.fill" or custom)
- Close X icon (SF Symbol "xmark")
- Placeholder thumbnail (gray with platform icon or logo)
- Loading spinner (system default)

**Design System References**:
- Match existing VideoListView card styling
- Use Chill/Support/DesignSystem/DesignTokens.swift for colors
- Follow spacing conventions from existing modals in app

---

## Future Enhancements (Post-MVP)

- **Edit Details**: Make "Edit Details" functional to return to input modal with pre-filled data
- **Custom Description**: Allow editing description on confirmation screen
- **Thumbnail Preview**: Show thumbnail in input modal after validation (before confirmation)
- **Multiple URLs**: Support batch input (paste multiple URLs separated by newlines)
- **Shareable**: Add share sheet to share video link from confirmation screen
- **Tags/Categories**: Add tag selection on confirmation screen

---

**Status**: Design specifications complete. Ready for implementation in SwiftUI.
