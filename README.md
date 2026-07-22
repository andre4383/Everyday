# Everyday

A minimalist habit tracker for iOS.

<p align="center">
  <img src="screenshots/hello.png" width="240" />
  <img src="screenshots/detail.png" width="240" />
  <img src="screenshots/new-habit.png" width="240" />
</p>

## About

Everyday is the iOS client of a small full-stack side project. It lets you keep track of daily habits, mark them as done, and watch your streaks grow. The design leans on plenty of whitespace, a serif display face, and a curated warm palette so the app stays out of the way of the thing it's tracking.

## Requirements

- iOS 17+
- Xcode 16+
- A running instance of the [Everyday backend](https://github.com/andre4383/HabitTracker-API) (NestJS + Prisma + Postgres).

## Getting started

1. Clone this repo.
2. Open `HabitTracker-IOS.xcodeproj` in Xcode.
3. Start the backend locally (see backend README).
4. Run the app on the iOS simulator (`Cmd+R`).

The app is preconfigured to talk to `http://localhost:3000`. To point it to a deployed backend, update `baseURL` in `Services/APIClient.swift`.

## Features

- Email/password authentication (JWT).
- Create, edit and delete habits with a custom accent color.
- Mark habits as done for the day.
- Contribution grid, current streak and longest streak per habit.
- Today progress card on the home screen.

## Stack

- SwiftUI (`@Observable`, `NavigationStack`, sheets with detents).
- `URLSession` + `async/await`.
- Keychain for JWT storage.
- No third-party dependencies.

## Structure

```
HabitTracker-IOS/
├── Models/          Codable structs matching the API
├── Services/        APIClient, AuthService, HabitsService, Keychain
├── Views/           SwiftUI screens and reusable components
├── Theme.swift      Colors, fonts and design tokens
└── ContentView.swift, HabitTracker_IOSApp.swift
```

## Design notes

- Off-white background (`#FAFAF7`) with near-black text (`#0A0A0A`).
- Serif display face for headings, SF Pro for body.
- Each habit picks an accent color from a curated palette.
- Detail view opens as a large sheet with drag handle.

## Backend

Source: [HabitTracker-API](https://github.com/andre4383/HabitTracker-API).

The API exposes `/auth/*` and `/habits/*` endpoints, protected by JWT. See its README for setup and endpoint documentation.

## License

Personal project. Not published.
