![logo](AMLogger_s.png "Logo")

# AMLogger Documentation

## Overview
AMLogger is a lightweight and powerful logging framework built atop Pulse and OSLog. It provides structured logging with modern Swift string interpolation and advanced privacy options. Whether you're developing for iOS, macOS, or other Apple platforms, AMLogger helps you manage your logs in a clear, secure, and scalable way.

## Features
- **Structured Logging:** Leverages modern Swift string interpolation and generics for type-safe logging.
- **Privacy Controls:** Supports public, private, and hashed log outputs to protect sensitive data.
- **Pulse Integration:** Stores log history using Pulse, making debugging easier and more informative.
- **SwiftUI & UIKit Support:** Comes with built-in views and view controllers for displaying logs.
- **Easy Integration:** Delivered as Swift Package, so you can integrate it seamlessly into your project.

## Requirements
- Swift 6
- Xcode 15 or later
- Platforms supporting Pulse and OSLog (iOS, macOS, etc.)

## Installation
Add AMLogger as a dependency via Swift Package Manager. Once added, import AMLogger in your source files where logging is needed.

## Usage
To create and use a logger:

```swift
// Create an instance of AMLogger with a subsystem and a label.
let logger = AMLogger(subsystem: "com.yourcompany.yourapp", label: .generic)

// Log an informational message
logger.info("Application started successfully.")

// Log an error message with metadata
logger.error("Unable to load configuration", metadata: ["filename": "config.json"])

// Log a debug message using privacy options
logger.debug("User login attempt: ", metadata: ["username": ("user@example.com", privacy: .private)])
```

## Documentation
See [Documentation](Documentation.md "Documentation") for more details about the library.

## Customization
AMLogger allows you to extend its labels, adjust privacy levels, and even override how logs are handled. Whether you need a custom log format or additional metadata, the API is flexible enough to meet your needs.

## SwiftUI and UIKit Integration
For SwiftUI applications, AMLogger offers convenient views:
- `consoleView`: A SwiftUI view presenting your logs within a NavigationView.
- `consoleViewController`: A UIViewController wrapping the log view for UIKit integration.
- `consoleViewEmbeddedInNavigationViewController`: Easily embed the console view in a navigation interface.

## Evolving Features
AMLogger is continuously evolving to meet the needs of modern app development. New features, enhancements, and refinements are regularly added to ensure you have the most powerful and flexible logging framework at your disposal. Stay tuned for updates that bring additional functionality and improved adaptability as the ecosystem evolves.

## Contributing
Contributions are welcome! If you have ideas, bug fixes, or improvements, please submit a pull request or open an issue on the GitHub repository.

## Acknowledgements
Special thanks to the creator of the [Pulse library](https://github.com/kean/pulse) for providing such an incredible framework that I chose to use together with my logging system.

## License
AMLogger is released under the MIT License. Enjoy and happy coding!
