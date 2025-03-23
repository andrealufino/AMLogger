# AMLogger

Welcome to the comprehensive documentation for `AMLogger`, a standalone Swift package for powerful, structured, and privacy-aware logging. This documentation covers every aspect of the `API`, describes the various `logging` methods in detail, and explains how to integrate `AMLogger` into your project.

---

## Overview

`AMLogger` is designed to provide:
- **Structured Logging:** Utilizing modern Swift string interpolation for type-safe `logging`.
- **Privacy Controls:** Three levels of `logging` privacy (`public`, `private`, and `hashed`) to protect sensitive information.
- **Pulse Integration:** Built-in support for the [Pulse library](https://github.com/kean/pulse) to capture and store logs for diagnostics.
- **Platform Agnostic UI:** Offers both `SwiftUI` views and `UIKit` view controllers to present logs in your app.

`AMLogger` is now a fully independent Swift package, making it easy to add to any project via `Swift Package Manager`.

---

## Getting Started

### Installation

Add `AMLogger` to your project using `Swift Package Manager` by including the following in your `Package.swift`:

```swift
.package(url: "https://github.com/yourusername/AMLogger.git", from: "1.0.0")
```

Then, include `"AMLogger"` as a dependency for your target. In your source files, import the package as:

```swift
import AMLogger
```

### Basic Setup & Usage

To instantiate a `logger`:

```swift
let logger = AMLogger(subsystem: "com.yourcompany.yourapp", label: .generic)
```

Log an informational message:

```swift
logger.info("Application started successfully.")
```

Log with additional metadata and privacy options:

```swift
logger.debug("User login attempt by:", metadata: ["username": ("user@example.com", privacy: .private)])
```

The `logger` uses the system’s `OSLog` and also forwards logs to the `Pulse` library for historical storage.

---

## API Reference

### `AMLogger`

The core of the `logging` framework, `AMLogger`, provides methods for various log levels.

#### Initialization

Initialize the `logger` using the following Swift method:

```swift
let logger = AMLogger(subsystem: "com.example.app", label: .generic)
```

- Parameters:
  - `subsystem`: A `String` representing the subsystem, typically the bundle identifier.
  - `label`: A value of type `AMLogger.Label` that categorizes the log (e.g., `.generic`, `.network`).

The initializer should be defined as follows:

```swift
public init(subsystem: String, label: AMLogger.Label) {
 // Configure the logger (e.g., set up OSLog, Pulse, etc.)
}
```

#### Logging Methods

Each `logging` method accepts a message, optional context, metadata, and default values for `file`, `function`, and `line`. These are used to generate a structured log message:

- `info(_ message: Message, context: Any? = nil, label: AMLogger.Label? = nil, metadata: [String: Any]? = nil, file: String, function: String, line: Int)`  
  For informational and general-purpose logs.

- `debug(_ message: Message, context: Any? = nil, metadata: [String: Any]? = nil, file: String, function: String, line: Int)`  
  Intended for logging debug-level details during development.

- `warning(_ message: Message, context: Any? = nil, label: AMLogger.Label? = nil, metadata: [String: Any]? = nil, file: String, function: String, line: Int)`  
  Use for non-fatal errors that require attention.

- `error(_ message: Message, context: Any? = nil, label: AMLogger.Label? = nil, metadata: [String: Any]? = nil, file: String, function: String, line: Int)`  
  For errors that indicate a failure in a specific functionality.

- `critical(_ message: Message, context: Any? = nil, metadata: [String: Any]? = nil, file: String, function: String, line: Int)`  
  For capturing system-level or process-critical issues.

These methods internally use `OSLog` for real-time logging and `Pulse` to archive log history.

### `Message`

`Message` is a type-safe structure for defining a log message. It leverages Swift’s string interpolation:

- **Initialization:**  
  Can be created directly from a string literal.  
  Supports custom interpolations to designate the privacy level for dynamic values.

- **Custom Interpolation:**  
  Values interpolated in the message can be annotated to be either `public`, `private` (replaced with a secure string), or `hashed`.  
  Example:

```swift
logger.info("User ID: \(user.id, privacy: .hashed)")
```

### `Privacy`

Privacy controls help protect sensitive data in logs:

- `public`: Logs the actual value.
- `private`: Replaces sensitive values with a placeholder (e.g., "🔒").
- `hashed`: Transforms the value using SHA256 hashing to allow correlation without disclosing actual data.

### `Label`

A lightweight type used to categorize logs. `AMLogger` predefines several common labels, such as:
- `.generic`
- `.network`
- `.ui`
- `.database`
- ...and more.

Users can extend these labels by defining new ones if needed.

---

## Advanced Topics

### Customizing the Logger

`AMLogger`’s design allows you to extend and modify its behavior:
- **Custom Labels:** Extend the default set of `labels` to match your app’s domains.
- **Metadata Enrichment:** Attach custom `metadata` to log messages for advanced diagnostics.
- **Log Routing:** The framework is built on top of `OSLog` and `Pulse`, and you can adjust log storage behavior if required.

### SwiftUI & UIKit Integration

`AMLogger` provides seamless integration with both `SwiftUI` and `UIKit`:
- **SwiftUI View:** Use `consoleView` to embed a log viewer in your `SwiftUI` hierarchy.

```swift
@MainActor
static var consoleView: some View {
    NavigationView {
        ConsoleView()
    }
}
```

- **UIKit Controllers:** For `UIKit` apps, use `consoleViewController` or `consoleViewEmbeddedInNavigationViewController` to present logs in a view controller.

### Pulse Integration

By integrating with the [Pulse library](https://github.com/kean/pulse), `AMLogger` not only logs in real time but also:
- Saves historical log data for post-mortem debugging.
- Provides a `UI` interface to sift through past log entries.

---

## Evolving Features

`AMLogger` is continuously evolving to meet modern development needs. We are committed to:
- Regularly adding new features.
- Optimizing performance and reliability.
- Enhancing the logging privacy mechanisms.
- Staying updated with the latest Swift advancements.

---

## Contributing

Contributions to `AMLogger` are welcome. Whether you’re fixing bugs, adding new features, or improving documentation:
- Please check the [CONTRIBUTING](CONTRIBUTING.md) guide.
- Submit issues or pull requests on GitHub.
- Engage with the community to help evolve the project.

---

## Acknowledgements

Heartfelt thanks to the creators of the [Pulse library](https://github.com/kean/pulse) for the framework that inspired and powers our logging enhancements.

---

For further details, deeper `API` insights, and usage examples, explore the individual sections and pages linked herein. Enjoy using `AMLogger` and happy coding!
