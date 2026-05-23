# encore 🎵

a native ios app for tracking concerts — past, present, and upcoming.

built with swiftui + swiftdata.

## features

- search upcoming & past events by artist via bandsintown
- auto-fetches tour posters, venue, city, and date
- setlist lookup powered by setlist.fm
- festival mode with full lineup + multi-day support
- concert stats — top artists, total shows, and more
- home screen countdown widget
- push notifications before upcoming shows

## setup

```bash
# 1. clone
git clone https://github.com/macc14/Encore.git && cd Encore

# 2. add your api keys
cp Encore/Secrets.example.plist Encore/Secrets.plist
# then fill in your keys

# 3. generate xcode project & build
./xcodegen/bin/xcodegen
open Encore.xcodeproj
```

### api keys

| service | required | get one |
|---------|----------|---------|
| bandsintown | yes | [bandsintown.com](https://www.artists.bandsintown.com/bandsintown-api) |
| setlist.fm | yes | [api.setlist.fm](https://api.setlist.fm/docs/1.0/index.html) |
| google custom search | no | [developers.google.com](https://developers.google.com/custom-search/v1/overview) |
| ticketmaster | no | [developer.ticketmaster.com](https://developer.ticketmaster.com/products-and-docs/apis/getting-started/) |

## stack

swiftui · swiftdata · widgetkit · usernotifications

## license

mit — built by [macky](https://github.com/macc14)
