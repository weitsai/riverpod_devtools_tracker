# Contributing to Riverpod DevTools Tracker

Thank you for your interest in contributing to Riverpod DevTools Tracker! This document provides guidelines and instructions for contributing.

## Getting Started

### Prerequisites

- Flutter SDK >= 3.27.0
- Dart SDK >= 3.7.0
- FVM (recommended for Flutter version management)

### Setup

1. Fork the repository
2. Clone your fork:
   ```bash
   git clone https://github.com/YOUR_USERNAME/riverpod_devtools_tracker.git
   cd riverpod_devtools_tracker
   ```
3. Install dependencies:
   ```bash
   flutter pub get
   cd devtools_extension && flutter pub get && cd ..
   ```
4. Run tests to ensure everything is working:
   ```bash
   flutter test
   cd devtools_extension && flutter test && cd ..
   ```

## Development Workflow

### Code Style

- Follow the [Dart Style Guide](https://dart.dev/guides/language/effective-dart/style)
- Run `flutter analyze` before committing to ensure no issues
- Use meaningful variable and function names
- Add comments for complex logic

### Running Tests

```bash
# Run main package tests
flutter test

# Run DevTools extension tests
cd devtools_extension && flutter test
```

### Building the DevTools Extension

```bash
./scripts/build_extension.sh
```

## Submitting Changes

### Pull Request Process

1. Create a new branch for your feature or fix:
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. Make your changes and commit with clear messages:
   ```bash
   git commit -m "feat: add new feature description"
   ```

3. Push to your fork:
   ```bash
   git push origin feature/your-feature-name
   ```

4. Open a Pull Request against the `main` branch

### Commit Message Convention

We follow [Conventional Commits](https://www.conventionalcommits.org/):

- `feat:` - New features
- `fix:` - Bug fixes
- `docs:` - Documentation changes
- `test:` - Adding or updating tests
- `chore:` - Maintenance tasks
- `refactor:` - Code refactoring

Examples:
```
feat: add provider filtering by type
fix: resolve stack trace parsing for async providers
docs: update README with new configuration options
test: add unit tests for TrackerConfig
```

## Reporting Issues

When reporting issues, please include:

1. A clear description of the problem
2. Steps to reproduce the issue
3. Expected behavior vs actual behavior
4. Flutter/Dart version (`flutter --version`)
5. Package version
6. Relevant code snippets or error messages

## Feature Requests

Feature requests are welcome! Please:

1. Check if the feature has already been requested
2. Provide a clear use case
3. Describe the expected behavior

## Code of Conduct

- Be respectful and inclusive
- Provide constructive feedback
- Help others learn and grow

## Questions?

If you have questions, feel free to:

- Open an issue with the `question` label
- Start a discussion in the GitHub Discussions tab

Thank you for contributing!
