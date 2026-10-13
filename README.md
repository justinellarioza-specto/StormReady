# StormReady

Live through a typhoon in 3 minutes. Your choices decide how the night goes. SwiftUI app playground, fully offline.

## The experience
1. **Storm warning:** a radio alert says a strong typhoon will reach your town tonight.
2. **Pack the go-bag:** 12 items, only 6 slots. Tap or drag to pack.
3. **Secure the home:** find and fix 5 hazards around the house.
4. **The storm hits:** 5 moments play out based on what you packed and fixed.
5. **Morning:** your score and a personal family plan built from what you did and missed.

## How to run
- **iPad:** open `StormReady.swiftpm` in Swift Playgrounds 4.6 or later and tap Run.
- **Mac:** open `StormReady.swiftpm` in Swift Playground or Xcode 26 or later and press Run.

## Built with
- **SwiftUI** for every screen and transition
- **Canvas and TimelineView** for procedural rain, splashes, clouds, wind-blown leaves and a swaying tree
- **AVAudioEngine** to synthesize rain, wind and thunder live from filtered noise
- **Core Haptics** for thunder you can feel (on iPhone)

Everything runs offline. There are no network calls, no third-party packages and no downloaded assets: every visual and sound is generated in code.

## Project layout
- `StormReady.swiftpm/MyApp.swift`: app entry, scene router, theme colors
- `StormReady.swiftpm/Model/`: game state, content (items, hazards, storm events), audio, haptics
- `StormReady.swiftpm/Views/`: one file per scene, shared components and weather effects
