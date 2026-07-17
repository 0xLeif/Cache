# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [2.1.3] - 2026-07-17

Release intended for consumers such as **AppState 3.0**, which can replace a revision pin of Cache#30 with `from: "2.1.3"`.

### Fixed

- **WebAssembly / WASI builds** — Guard `@Published` / `ObservableObject` with `#if canImport(Combine)` instead of `#if !os(Linux) && !os(Windows)`, so wasm no longer takes the Combine path ([#30](https://github.com/0xLeif/Cache/pull/30), AppState#149).
- **Linux / WASI collection cast crash** — `Dictionary.get(_:as:)` unwraps the optional value before casting, avoiding `swift_dynamicCastFailure` / `_arrayForceCast` aborts when reading collection-typed values from an `Any` cache ([#30](https://github.com/0xLeif/Cache/pull/30), AppState#151).
- **CI** — macOS and DocC workflows no longer pin Xcode 16 (unavailable on current `macos-latest` images). Use `macos-15` with `latest-stable` Xcode, matching AppState.

### Changed

- Explicitly import Combine when available so `@Published` / `ObservableObject` compile reliably across build configurations.

## [2.1.2] - 2025-09-20

### Added

- DocC plugin dependency and GitHub Pages documentation workflow updates.

[Unreleased]: https://github.com/0xLeif/Cache/compare/2.1.3...HEAD
[2.1.3]: https://github.com/0xLeif/Cache/compare/2.1.2...2.1.3
[2.1.2]: https://github.com/0xLeif/Cache/releases/tag/2.1.2
