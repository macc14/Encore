# 🎵 Encore

A native iOS app for tracking your concert history, upcoming shows, and live music stats — built with SwiftUI and SwiftData.

![iOS 17+](https://img.shields.io/badge/iOS-17%2B-blue) ![Swift 5](https://img.shields.io/badge/Swift-5-orange) ![License](https://img.shields.io/badge/license-MIT-green)

## Features

- **Concert Tracking** — Log upcoming and past concerts with artist, venue, city, and date info
- **Auto-Search** — Search for events via Bandsintown and Ticketmaster APIs to autofill concert details
- **Setlist Lookup** — Automatically fetches potential setlists from Setlist.fm for each show
- **Tour Poster Images** — Auto-fetches artist/tour images when adding a concert
- **Festival Support** — Toggle festival mode for multi-day events with full lineup tracking
- **Concert Stats** — View your top artists, total shows attended, and other listening stats
- **Home Screen Widget** — Countdown widget showing days until your next concert
- **Notifications** — Get reminded before upcoming shows

## Screenshots

*Coming soon*

## Setup

### Prerequisites
- Xcode 16+
- iOS 17+ device or simulator
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) (included in repo)

### API Keys
This app uses several music APIs. You'll need to create a `Secrets.plist` file with your own keys:

1. Copy the template:
   ```bash
   cp Encore/Secrets.example.plist Encore/Secrets.plist
   ```

2. Fill in your API keys in `Encore/Secrets.plist`:
   - **Bandsintown** — [Get an App ID](https://www.artists.bandsintown.com/bandsintown-api)
   - **Setlist.fm** — [Get an API key](https://api.setlist.fm/docs/1.0/index.html)
   - **Google Custom Search** — [Get an API key](https://developers.google.com/custom-search/v1/overview) *(optional)*
   - **Ticketmaster** — [Get an API key](https://developer.ticketmaster.com/products-and-docs/apis/getting-started/) *(optional)*

### Build
```bash
# Generate Xcode project
./xcodegen/bin/xcodegen

# Open in Xcode
open Encore.xcodeproj

# Or build from command line
xcodebuild -project Encore.xcodeproj -scheme Encore -sdk iphoneos build
```

## Tech Stack

- **SwiftUI** — Declarative UI framework
- **SwiftData** — Persistent storage for concert data
- **WidgetKit** — Home screen countdown widget
- **UserNotifications** — Concert reminder notifications

## Project Structure

```
Encore/
├── Models/          # SwiftData models (Concert)
├── Services/        # API integrations (Bandsintown, Setlist.fm, etc.)
├── Views/           # SwiftUI views
└── Assets.xcassets/ # App icons and assets

EncoreWidget/        # WidgetKit extension
```

## License

MIT License — see [LICENSE](LICENSE) for details.

## Author

Built by [macky](https://github.com/macc14)
