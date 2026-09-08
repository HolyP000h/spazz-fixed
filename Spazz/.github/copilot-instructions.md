Copilot Instructions for Spazz (spazz-fixed)
Project Context
Repository Type: React Native / Expo application (spazz-fixed).

Core Concept: Spazz is a proximity-based social and dating scavenger hunt app. Rather than showing traditional map pins or profile stacks, Spazz matches users dynamically along active walking routes using haptics, radial screen flashes, and visual element effects to turn real-world encounters into an interactive hunt.

Development Strategy: Prefer small, focused changes that fit the existing screen/service structure. Keep UI updates simple, performant, and consistent with current app styling.

Gameplay & Domain Mechanics
1. First-Person Map Viewport
User-Centric Position: Map lives on the main screen in a first-person perspective, with the user's location anchored near the bottom-third of the screen.

Privacy & Occlusion: NEVER render other users, target destination pins, or pathfinding route lines on the client map interface. The map provides spatial context only.

2. Header UI Controls
"Start Spazz" Button (Top Center): Instantly initiates active signal broadcasting.

Search Icon (Top Left): Opens route input modal where users enter an approximate walking path to trigger route-intersection matching filtered by demographic preferences (age, sex, etc.).

3. Route Intersection & "Spazzing Out" Phase
Backend Matching: Route intersection engine calculates convergence between active broadcasts and planned walking paths.

Spazz Trigger: When two routes intersect, both phones trigger an intense "Spazz Out" state:

Rapid, high-frequency haptic vibration patterns.

Full-screen radial flash effects and element overlays (e.g., lightning, fire) emanating from the radar.

A modal popup: "Nearby Encounter! Accept?".

Signal Lock: Accepting locks the radar onto that specific target signal, filtering out extraneous background signals to isolate the hunt.

4. Radar & Scavenging Hunt Engine
Radar Position: Anchored directly under/around the user position marker.

Hot/Cold Mechanics: Emits center-outward radial flashes and dynamic haptic rates that scale in speed/frequency based on physical distance to the locked target.

Peak Intensity Overlays: At maximum proximity, particle/overlay effects (fire, lightning bolts) shoot across the viewport screen.

5. Encounter Resolution & Progression
Successful Encounter State: Reaching the target triggers the "Successful Encounter!" completion state.

Unlocks & Rewards:

Updates user profile stats, streaks, and badges.

Unlocks Add Friend option, 1-on-1 Direct Chat, Co-op Games, and "Love Notes".

6. AI Dating Coach Subsystem
Fallback System: Activates when users experience low match rates or prolonged idle periods.

Behavior: Delivers motivational nudges, grooming/lifestyle tips, dating advice, and encourages physical walking activity to increase route intersection opportunities.

Working Conventions
Minimal Diffs: Prefer editing existing files before creating new ones.

Naming Aligned: Keep component and screen names aligned with conventions in src/screens/.

Logic Separation: Keep shared business and domain behavior in src/services/ (e.g., location tracking, haptic generators, proximity engines).

Preserve Flow: Preserve existing navigation and state flow unless explicitly instructed to restructure.

Expo / React Native Guidance
Performance: Ensure high-framerate overlay animations (Canvas/Skia) and haptic triggers run efficiently without choking location-tracking threads.

Dependencies: Keep imports tidy and avoid unnecessary third-party packages.

Direct Patterns: Prefer straightforward React Native patterns over over-engineered abstractions.

Typical Project Structure
App.js: Main application entry point.

src/screens/: Screen components (Map, Route Selection, Chat, Stats).

src/services/: Shared business logic, location/radar state machines, haptics, and API services.

Security & State Integrity
Server-Side Proximity: Raw coordinates of other users MUST remain obscured server-side. Only transmit calculated proximity intensities or relative distance metrics to the client.

State Machine: Enforce explicit state transitions for encounter handling: IDLE ➔ BROADCASTING ➔ INTERSECT_FOUND ➔ SIGNAL_LOCKED ➔ ENCOUNTER_SUCCESS.