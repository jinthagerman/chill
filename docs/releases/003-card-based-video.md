# Release Notes: Card-Based Video List (003)

**Release Date**: TBD  
**Feature Branch**: `003-card-based-video`  
**Spec**: `/specs/003-card-based-video/spec.md`

## Overview

This release introduces the "My Videos" feature - a vertically scrolling list of rich video cards sourced from a curated Supabase GraphQL view. The experience includes offline browsing, localized UI, reconnection detection, and privacy-preserving analytics.

## What's New

### User-Facing Features
- **My Videos Screen**: New authenticated landing page displaying saved video cards
- **Rich Card UI**: Each card shows thumbnail, title, creator, platform, and duration
- **Offline Support**: Cached cards remain browsable when network is unavailable
- **Connection Status**: Visual indicators for offline state and reconnection
- **Accessibility**: Full VoiceOver support with Dynamic Type scaling
- **Localized Strings**: All UI text supports internationalization

### Technical Features
- **SwiftData Cache**: Local persistence for offline-first video browsing
- **GraphQL Integration**: Real-time subscription to Supabase `video_cards_view`
- **MVVM Architecture**: Clean separation with `VideoListViewModel` and `VideoCardsService`
- **Automated Purging**: Stale cache entries removed after 90 days
- **Privacy-First Analytics**: Single anonymized page-view event only

## Rollout Plan

### Pre-Deployment Checklist
- [ ] Run Supabase migration `20251004200000_create_video_cards_view.sql`
- [ ] Verify `video_cards_view` returns data for test accounts
- [ ] Confirm RLS policies enforce user-scoped access
- [ ] Test offline behavior on real device with network toggle
- [ ] Validate VoiceOver navigation on iOS 18.0+
- [ ] Check Dynamic Type at XXXL size
- [ ] Verify analytics events appear in logs (no PII)

### Staged Rollout

#### Stage 1: Internal Testing (Days 1-3)
- Deploy to internal TestFlight group
- Monitor crash reports and network errors
- Validate subscription reconnection behavior
- Confirm cache purging works as expected

#### Stage 2: Beta Release (Days 4-7)
- Roll out to beta TestFlight group (100 users)
- Monitor page-view analytics volume
- Track cache performance metrics
- Gather user feedback on card UI

#### Stage 3: Full Release (Day 8+)
- Submit to App Store for review
- Release to production when approved
- Monitor Supabase query performance
- Watch for subscription connection issues

### Monitoring Checklist

During rollout, monitor:
- ✅ `video_list.viewed` analytics event rate
- ✅ Supabase query latency for `video_cards_view`
- ✅ Realtime subscription connection failures
- ✅ SwiftData cache size growth
- ✅ Crash reports related to `VideoList` module
- ✅ User-reported network transition issues

## Rollback Plan

If critical issues arise, execute the following rollback steps:

### Option 1: Quick Disable (No Deployment)
1. Update remote feature flag to hide "My Videos" entry point
2. Users fall back to existing saved links view
3. No data loss - cache persists for future re-enable

**Downside**: Requires remote config infrastructure (not yet implemented)

### Option 2: Hot Fix Deployment (Preferred)
1. Update `AuthCoordinator` to route to `.savedLinks` instead of `.videoList`
2. Submit hot fix build to App Store (expedited review if needed)
3. Deploy within 24-48 hours

**Code Change**:
```swift
// In AuthCoordinator.swift, line 38 and 46
self?.route = .savedLinks  // instead of .videoList
```

### Option 3: Supabase Access Revocation (Emergency)
1. Revoke SELECT policy on `public.video_cards_view`
2. Users see error state with retry option
3. Cache remains functional for offline browsing

**SQL Command**:
```sql
DROP POLICY IF EXISTS "Users can view video cards" ON public.video_cards_view;
```

### Option 4: Full Rollback (Last Resort)
1. Revert branch to previous release commit
2. Remove `VideoList` module from Xcode project
3. Redeploy previous stable version

**Note**: This loses all video list work and should only be used for catastrophic issues.

## Support Playbook

### Common Issues

#### Issue: "Couldn't load videos" error on launch
**Symptoms**: Error screen appears immediately, no cached cards  
**Likely Cause**: Supabase connection failure or missing view permissions  
**Resolution**:
1. Check user's network connectivity
2. Verify `video_cards_view` exists and RLS allows access
3. Confirm user is authenticated (valid session)
4. Check Supabase service status

#### Issue: Cards not updating after reconnection
**Symptoms**: Offline banner persists, toast doesn't appear  
**Likely Cause**: Realtime subscription not reconnecting  
**Resolution**:
1. Force-quit app and relaunch
2. Check Supabase realtime connection status
3. Review logs for subscription error messages
4. Verify user's auth token is valid

#### Issue: Stale cards showing old content
**Symptoms**: Cards display outdated information  
**Likely Cause**: Cache purging not running or subscription missed updates  
**Resolution**:
1. Pull-to-refresh to force sync (future enhancement)
2. Clear app data and re-login
3. Check cache timestamp in logs
4. Verify subscription is active

#### Issue: App consuming too much storage
**Symptoms**: iOS reports high app storage usage  
**Likely Cause**: Cache not purging stale entries  
**Resolution**:
1. Check `VideoListConfig.cachePurgeDays` setting (default: 90)
2. Manually trigger `VideoCardCacheManager.purgeStaleEntries()`
3. Review cache statistics with `statistics()` method
4. Consider lowering purge threshold for future releases

### Debug Commands

Access via Xcode console:
```swift
// Check cache statistics
let stats = try await cacheManager.statistics()
print(stats.description)

// Manually purge stale entries
let purgedCount = try await cacheManager.purgeStaleEntries(olderThanDays: 30)

// Clear entire cache (caution)
try await cacheManager.clearAll()
```

### Escalation Path
1. **Level 1**: Check known issues above, gather logs
2. **Level 2**: Review Supabase dashboard for query errors
3. **Level 3**: Consult `specs/003-card-based-video/` documentation
4. **Level 4**: Contact engineering team with reproduction steps

## Performance Metrics

### Success Criteria
- First card batch loads in ≤4 seconds on LTE
- Offline cache hit rate >80% for returning users
- Subscription reconnection time <2 seconds
- Zero PII in analytics events
- Crash-free rate >99.5%

### Monitoring Dashboard
- **Analytics**: Track `video_list.viewed` event volume
- **Logs**: Filter for `VideoList` and `VideoCardCache` categories
- **Supabase**: Monitor `video_cards_view` query latency
- **Crashes**: Watch for `VideoList` module in stack traces

## Known Limitations

1. **No Pull-to-Refresh**: Users cannot manually trigger sync (future enhancement)
2. **Dormant FAB**: Add video button has no functionality yet
3. **Single Language**: Only English localization complete
4. **No Search/Filter**: Users cannot filter or search their video list
5. **Fixed Sort Order**: Always sorts by `updated_at desc`

## Future Enhancements

- Manual refresh gesture (pull-to-refresh)
- Video upload/add functionality (FAB action)
- Search and filter capabilities
- Custom sort options (date added, title, duration)
- Additional language translations
- Batch operations (multi-select delete)
- Share video card to other apps

---

**Release Owner**: Engineering Team  
**Support Contact**: support@bitcrank.com  
**Documentation**: `/specs/003-card-based-video/`
