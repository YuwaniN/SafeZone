# SafeZone

SafeZone is a SwiftUI disaster-alert and emergency-response app for Sri Lanka. It combines live weather risk scoring, saved-location geofencing, nearby emergency services, community incident reports, offline safety guides, local alerts, and biometric app locking in one iPhone app.

The project was built for the NIBM iOS Application Development coursework and follows an MVVM architecture with protocol-oriented services and constructor-based dependency injection.

## Features

### Weather and risk
- Live current weather and 12-hour forecast from OpenWeatherMap.
- On-device risk score (0-100) derived from rainfall, wind, and forecast rainfall.
- Risk levels: Low (`0-29`), Medium (`30-59`), High (`60-100`).
- Cached weather snapshots in Core Data with stale-data fallback.
- Risk-change alerts when a monitored location moves to a higher level.
- Demo weather provider with deterministic prototype values when no API key is configured.

### Locations and geofencing
- Saved locations with monitoring toggles and alert preferences.
- Address search with MapKit.
- Circular geofences with entry notifications.
- Geofence Monitoring screen with permission state, recent entries, and a demo-entry simulator.
- Background location monitoring via Core Location region monitoring.

### Emergency map
- MapKit map with nearby hospitals, police stations, fire stations, and shelters from `MKLocalSearch`.
- Community report pins, saved-location geofence overlays, search, filters, and a selected-service detail panel.
- Compact iPhone layout and regular-width split layout for larger devices.
- Directions and phone-call actions for emergency services.

### Community reports
- Create reports with category, title, details, location, and optional photo.
- Nearby report list with distance, verification state, and upvotes.
- Report detail view with upvote, flag, delete, share, and directions.
- Reports are stored locally in Core Data.

### Safety guide and alerts
- Seven offline safety guides bundled as JSON: flood, landslide, cyclone, tsunami, fire, first aid, and emergency kit.
- Sri Lankan emergency hotlines with tap-to-call.
- Alert centre with unread badge, alert banners, and detail sheets.
- Local notifications for risk changes, geofence entries, and test alerts.

### Profile and security
- Local account registration and sign-in with salted, iterated password hashes.
- Face ID / Touch ID app lock with device-passcode fallback.
- Emergency contact management.
- Notification, weather, risk, and geofence alert preferences.
- Demo account and seeded sample data for evaluation.

## Requirements

- Xcode 26 or later
- iOS 17.0 or later
- XcodeGen 2.46 or later
- An OpenWeatherMap API key (optional; demo weather is used without one)

## Getting started

1. Generate the Xcode project:

   ```sh
   xcodegen generate
   ```

2. Create the local secrets file:

   ```sh
   cp Config/Secrets.example.xcconfig Config/Secrets.xcconfig
   ```

3. Add your OpenWeatherMap key to `Config/Secrets.xcconfig`:

   ```xcconfig
   OPENWEATHER_API_KEY = your_key_here
   ```

4. Open `SafeZone.xcodeproj` and run the `SafeZone` scheme on an iPhone simulator or device.

`Config/Secrets.xcconfig` and `SafeZone.xcodeproj` are generated/local files and are intentionally ignored by Git. `project.yml` is the source of truth for the Xcode project.

### Demo credentials

The app seeds a demo account and sample data on first launch:

```text
Email:    demo@safezone.lk
Password: SafeZone123
```

The demo account includes Home and Work locations, sample community reports, and sample alerts.

### Demo mode

If `OPENWEATHER_API_KEY` is empty or missing, SafeZone automatically uses `DemoWeatherService`, which returns prototype weather values and risk levels. The Home screen shows a `DEMO` badge in this mode.

If a key is present but rejected by OpenWeatherMap, the app shows a clear error and falls back to the last cached snapshot. New OpenWeatherMap keys can take a short time to activate after creation.

## Testing

Run the Swift Testing suite:

```sh
xcodebuild -project SafeZone.xcodeproj \
  -scheme SafeZone \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  test
```

The suite currently contains **20 Swift Testing tests in 4 suites** covering:

- Risk scoring thresholds and boundaries
- Risk-change detection
- Password hashing and validation
- Core Data repositories and demo seeding
- Incident and alert lifecycles
- Guide JSON decoding and fallback content
- Emergency contact/model content
- Distance formatting

The test log may show non-fatal Core Data warnings about multiple `NSEntityDescription` instances. These occur because the app host and in-memory test containers load the same managed-object model; all tests pass.

## Architecture

```text
SafeZone/
  App/              App entry point, app state, tab shell, lock screen, DI container
  Core/
    Config/         App configuration and persisted settings
    Design/         Theme, reusable components, formatters
    Models/         Domain models and value types
    Persistence/    Core Data controller, entities, repositories, demo seeding
    Services/       Weather, auth, biometrics, location, geofencing, alerts, guide, network
    Utilities/      Image processing and password hashing
  Features/         Feature folders with views and view models
    Alerts/
    Auth/
    Guide/
    Home/
    Locations/
    Map/
    Onboarding/
    Profile/
    Reports/
  Resources/        Asset catalogue and offline guide JSON
SafeZoneTests/      Swift Testing suites
Config/             Info.plist and xcconfig secrets
firebase/           Reserved for optional backend functions/rules
```

Key architectural choices:

- **MVVM** keeps view state and business logic in view models.
- **Protocol-oriented services** allow live/demo providers and repository abstractions.
- **Constructor injection** through `AppContainer` makes dependencies explicit and testable.
- **Core Data repositories** isolate persistence from feature code.
- **Feature-first folder structure** keeps related views, view models, and models together.

## Data model

Core Data entities:

- `UserAccountEntity` - local account, password hash, emergency contact
- `SavedLocationEntity` - saved places, radius, monitoring and alert preferences
- `IncidentReportEntity` - community reports, category, location, photo, votes
- `RiskSnapshotEntity` - cached weather and risk assessments
- `AlertRecordEntity` - alert history and read state

## External API and backend decision

The mandatory external API integration is **OpenWeatherMap**, used for current conditions and forecast data that directly drives the app's risk score. No additional backend is required for the current feature set.

**Firebase is not a requirement for this project.** The assessment requires at least one genuine external API or backend service, and OpenWeatherMap satisfies that requirement. Firebase is only one example. The current app also satisfies the MVP platform-feature requirement through Core Data and Face ID/Touch ID (and additionally implements local notifications), plus the advanced MapKit/Core Location geofencing feature.

Firebase/FCM is intentionally left as a future enhancement. It would add cross-device sync for community reports and remote push notifications. If that work is resumed, a `GoogleService-Info.plist` and Firebase SPM packages would be required.

Free alternatives if cloud sync or remote push is added later:

- **CloudKit** - native Apple sync, free with an Apple Developer account
- **Supabase** - free tier for Postgres, auth, and storage
- **OneSignal** - free tier for remote push notifications
- **Cloudflare Workers / Vercel Functions** - free serverless endpoints
- **APNs directly** - free push delivery with an Apple Developer account, but requires your own server

For the current submission, the app is fully functional offline and locally without any backend.

## Accessibility

- Dynamic Type scaling is implemented globally through `Font.szScaled`, which uses `UIFontMetrics` and caps scaling to protect dense layouts.
- The Home, Guide, Profile, and Map screens were checked at the largest standard Dynamic Type size.
- Map pins, call buttons, search controls, and primary actions include accessibility labels.
- Semantic system colours are used for text and backgrounds.
- Layouts scroll and reflow rather than clipping fixed content where possible.
- Reduce Motion and full VoiceOver audits remain recommended before submission.

## Known limitations

- Firebase/FCM and cloud sync are not implemented; reports and accounts are local to the device.
- Community reports are not moderated or synced between devices.
- Face ID cannot be fully verified on a simulator without enrolled biometrics.
- Remote push notifications are not configured; notifications are local.
- OpenWeatherMap free-tier rate limits apply.
- iPad adaptive layout exists, but iPhone 17 Pro is the primary QA target.
- The test suite covers core logic; UI tests are not included.
- The final report, narrated screen recording, and viva preparation are separate submission artifacts.

## Attribution

Weather data is provided by [OpenWeatherMap](https://openweathermap.org/). SafeZone risk scores are indicative weather assessments, not official flood predictions or evacuation warnings. Always follow guidance from Sri Lanka's Disaster Management Centre and local authorities.
