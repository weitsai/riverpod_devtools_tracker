## 1.0.2

**Release Date**: 2026-01-07

### Code Quality Improvements

* **Refactored LocaleNotifier to follow Riverpod best practices**
  - Removed `currentLanguage` public getter from LocaleNotifier
  - All public API now exposed through `state` property only
  - Fixed `avoid_public_notifier_properties` lint warning
  - Locale to Language conversion moved to usage sites

## 1.0.1

**Release Date**: 2026-01-07

### Documentation Improvements

* **Enhanced README with visual guides**
  - Added DevTools extension screenshots for better understanding
  - Renamed image files to English for better accessibility
  - Added visual guides for DevTools setup and configuration
  - Added Provider filtering screenshots and documentation

* **Removed development-only content**
  - Removed Build Status badge (GitHub Actions workflow removed)
  - Removed "Building the Extension" section (scripts not published in package)
  - Cleaned up documentation to focus on end-user experience

## 1.0.0

**Release Date**: 2026-01-07

### Package Optimizations

* **Optimized package content** (compressed size: ~12 MB)
  - Added comprehensive `.pubignore` to exclude development files
  - Package includes pre-built DevTools extension for Flutter DevTools integration
  - Optimized published content for end users only
  - Note: Size is primarily from DevTools extension's web resources (required for functionality)

* **Updated to latest development tools**
  - Upgraded `flutter_lints` to ^6.0.0 (main package and example app)
  - Fixed lint warnings for latest Dart standards
  - Maintained zero static analysis warnings

* **Continuous Integration & Deployment**
  - GitHub Actions CI/CD workflow for automated testing
  - Automatic format checking, static analysis, and test execution
  - Build status badge for transparency
  - Coverage reporting to Codecov

### Features

* **RiverpodDevToolsObserver** - Automatic provider lifecycle tracking
  - Monitors all provider events (add, update, dispose, error)
  - Captures stack traces to identify state change origins
  - Smart async provider support with stack trace caching

* **StackTraceParser** - Intelligent call stack analysis
  - Detailed call stack parsing and location detection
  - Filters framework code to show only user code
  - Configurable depth and pattern matching

* **TrackerConfig** - Flexible configuration system
  - Quick setup with `TrackerConfig.forPackage()`
  - Advanced customization options
  - Production-ready performance controls
  - Comprehensive inline documentation

* **DevTools Extension** - Beautiful debugging interface
  - GitHub-style dark theme UI
  - Real-time state change monitoring
  - Interactive provider list with filtering
  - Detailed call chain visualization
  - Multi-language support (English, 繁體中文)

* **Console Output** - Development-friendly logging
  - Pretty formatted output with emojis and boxes
  - Simple one-line format option
  - Configurable verbosity

* **Performance Optimizations**
  - Memory leak prevention with automatic stack cache cleanup
  - Configurable cache size limits (default: 100 entries)
  - Automatic expiration of old stack traces (default: 60 seconds)
  - Efficient filtering and serialization

* **Quality Assurance**
  - Comprehensive test coverage (46 tests: 29 main package + 17 DevTools extension)
  - Zero flutter analyze warnings
  - Zero pub publish warnings
  - Production-ready code quality
  - Automated CI/CD testing on every commit

### Compatibility

* Flutter SDK >= 3.27.0
* Dart SDK >= 3.7.0
* flutter_riverpod >= 3.1.0

### Documentation

* Complete README with usage examples
* Troubleshooting guide
* Best practices for production use
* Performance optimization tips
* Contributing guidelines (CONTRIBUTING.md)
