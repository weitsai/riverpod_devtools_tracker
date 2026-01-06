# Changelog

## 1.0.0

**Release Date**: 2026-01-07

### Features

* Initial release of DevTools extension
* Real-time monitoring of Riverpod provider state changes
* Interactive provider list with filtering capabilities
* Detailed call chain visualization with file locations
* GitHub-style dark theme UI
* Performance optimizations with intelligent filter caching
* Multi-language support (English, 繁體中文)
* Auto-discovery by Flutter DevTools

### UI Components

* Provider list panel with search and multi-select
* State detail panel with before/after value comparison
* Filter controls for change types (add, update, dispose, error)
* Auto-computed updates toggle
* History mode (all history vs latest only)

### Performance

* Filter result caching for optimal UI responsiveness
* Efficient state management with cache invalidation
* Limited history size (500 entries) to prevent memory issues
* Smooth scrolling and interaction even with large datasets

### Internationalization

* English (en) - Complete translations
* Traditional Chinese (zh-TW) - Complete translations
* Extensible localization system for future languages
