# QA Assets: Card-Based Video List (003)

This directory contains all QA-related documentation and test assets for the card-based video list feature.

## Contents

### Documentation
- **test-plan.md** - Comprehensive test scenarios with acceptance criteria
- **README.md** - This file, overview of QA assets

### Screenshots
Screenshots demonstrating key UI states and flows are stored in `screenshots/`:

1. `01-loading-state.png` - Initial loading spinner
2. `02-loaded-cards.png` - Cards displayed successfully  
3. `03-empty-state.png` - No videos message
4. `04-error-state.png` - Connection error with retry button
5. `05-offline-banner.png` - Offline mode with cached cards
6. `06-reconnect-toast.png` - Back online notification
7. `07-dynamic-type-xl.png` - Large text size view
8. `08-voiceover-labels.png` - VoiceOver inspector showing labels
9. `09-placeholder-thumbnail.png` - Card with fallback image
10. `10-duration-formats.png` - Various duration pill examples

**Note**: Screenshots are placeholders until actual QA execution. They should be captured during manual testing on real iOS devices.

## Quick Start for QA

### 1. Environment Setup
```bash
# Clone repository
git clone <repo-url>
cd Chill

# Checkout feature branch
git checkout 003-card-based-video

# Open in Xcode
xed .
```

### 2. Run Supabase Migrations
```bash
# Start local Supabase (optional for local testing)
supabase start

# Apply migrations
supabase db reset
```

### 3. Configure Test Data
- Ensure `SupabaseConfig.plist` has valid credentials
- Populate test videos in `public.videos` table
- Create test accounts with various data scenarios (empty, few videos, many videos)

### 4. Execute Test Plan
Follow scenarios in `test-plan.md` step by step, checking off completed tests.

### 5. Capture Screenshots
Use iOS Simulator or device to capture required screenshots and save to `screenshots/` directory.

### 6. Sign Off
Complete the sign-off section in `test-plan.md` with findings and recommendations.

## Testing Checklist

- [ ] All 15 test scenarios executed
- [ ] Regression tests passed
- [ ] Screenshots captured (10 images minimum)
- [ ] Accessibility audit completed (VoiceOver + Dynamic Type)
- [ ] Performance metrics validated (4s load time on LTE)
- [ ] Privacy audit passed (no PII in logs)
- [ ] Test plan signed off by QA, Engineering, and Product

## Known Test Limitations

- **Network Simulation**: iOS Simulator network toggle doesn't perfectly simulate real-world conditions. Consider using Link Conditioner or physical device testing.
- **Real-time Testing**: Requires multiple devices or web interface to test subscription updates.
- **Analytics Verification**: Requires production analytics setup or mock implementation for full validation.

## Support

For questions about QA process or test plan, contact:
- **QA Lead**: TBD
- **Engineering Contact**: See `/docs/releases/003-card-based-video.md`
- **Spec Reference**: `/specs/003-card-based-video/`

## Change Log

| Date | Tester | Changes |
|------|--------|---------|
| 2025-10-04 | System | Initial QA documentation created |
| TBD | TBD | First test execution |
