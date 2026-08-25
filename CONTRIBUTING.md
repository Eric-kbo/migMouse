# Contributing to MigMouse

Thanks for helping make Magic Mouse better.

## Before opening an issue

- Search existing issues first.
- Include your macOS version and Magic Mouse model.
- Describe the gesture, expected result, and actual result.
- For recognition problems, include a screenshot of MigMouse's Diagnostics tab when possible.

Please do not include crash logs or screenshots containing personal information without redacting them first.

## Development

1. Fork and clone the repository.
2. Open `MigMouse.xcodeproj` in Xcode 16 or later.
3. Keep App Sandbox disabled; touch capture depends on `MultitouchSupport.framework`.
4. Add or update tests for gesture-recognition changes.
5. Run the test suite before opening a pull request:

```sh
xcodebuild \
  -project MigMouse.xcodeproj \
  -scheme MigMouse \
  -configuration Debug \
  -destination 'platform=macOS' \
  CODE_SIGNING_ALLOWED=NO \
  test
```

If you add or remove source files, regenerate the Xcode project with `ruby scripts/generate_project.rb`. This requires the `xcodeproj` Ruby gem.

## Pull requests

Keep each pull request focused. Explain user-visible behavior, tradeoffs, and how you tested it. By contributing, you agree that your contribution is licensed under the project's MIT License.
