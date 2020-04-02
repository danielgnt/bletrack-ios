# bletrack-ios
iOS Prototype of "Tracing Contacts to Control the COVID-19 Pandemic" ( https://arxiv.org/abs/2004.00517 )

This app sends a beacon with a specified service uuid and upon connection from another device ( this does not require pairing and therefore no user interaction) it will share its unique user id. **It is important to note that iOS apps can only send a beacon while in foreground mode.** Furthermore the app also monitors for other beacons transmitting the specified service uuid. When a foreign beacon is found the app will connect with that device and query its unique id. After receiving this id it is added to a list.
**The app works Android <--> iOS but not iOS <--> iOS**

### Import project ( You will need XCode )
1. Clone git repository or download it manually
2. Double click BLETrack.xcodeproj or open it from XCode
