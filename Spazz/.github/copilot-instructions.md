# Copilot instructions for Spazz

## Project context
- This repository is a React Native / Expo app.
- Prefer small, focused changes that fit the existing screen/service structure.
- Keep UI updates simple and consistent with the current app style.

## Working conventions
- Prefer editing existing files before creating new ones.
- Keep component and screen names aligned with the current conventions in src/screens.
- Use clear, descriptive names for new helpers and services.
- Preserve existing navigation and state flow unless the task explicitly requires a structural change.

## Expo / React Native guidance
- When changing app behavior, consider both UI and underlying logic in the relevant screen or service.
- Keep imports tidy and avoid introducing unnecessary dependencies.
- Prefer straightforward React Native patterns over over-engineered abstractions.

## Code quality expectations
- Make changes that are easy to review and easy to reason about.
- Avoid unrelated refactors.
- If a change affects behavior, briefly explain the expected user impact.

## Typical project structure
- App.js is the app entry point.
- Screens live under src/screens/.
- Shared logic or domain behavior should live under src/services/ when appropriate.

## When proposing changes
- Prefer minimal diffs that solve the stated problem.
- If a feature spans multiple areas, call out the affected files and the reasoning.
- If a task is ambiguous, ask clarifying questions before making broad changes.
