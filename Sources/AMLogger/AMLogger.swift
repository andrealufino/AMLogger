//
//  AMLogger.swift
//  AMLKit
//
//  Created by Andrea Mario Lufino on 24/03/23.
//


#if canImport(Pulse) && canImport(PulseUI) && canImport(OSLog)
import Foundation
import OSLog
import SwiftUI
#if canImport(UIKit) && canImport(CryptoKit)
import UIKit
import CryptoKit
#endif

import Pulse
import PulseUI


/// Summary of the file
///
/// ``AMLogger``
/// ``AMLoggerMessage``
/// ``AMLoggerPrivacy``
/// ``AMLoggerLabel``


/// # Pulse
///
/// https://github.com/kean/Pulse
/// https://kean-docs.github.io/pulse/documentation/pulse/gettingstarted
///
/// Add this to the Info.plist to enable remote logging (via Bonjour):
///
/// ```
/// <key>NSLocalNetworkUsageDescription</key>
/// <string>Network usage required only for development purposes</string>
/// <key>NSBonjourServices</key>
/// <array>
///   <string>_pulse._tcp</string>
/// </array>
/// ```


/// Thanks to [Christian Tietze](https://christiantietze.de/posts/2019/07/swift-is-debugger-attached/).
/// See also his answer on [stackoverflow](https://stackoverflow.com/questions/4744826/detecting-if-ios-app-is-run-in-debugger/56836695#56836695).
private let isDebuggerAttached: Bool = {
    var debuggerIsAttached = false

    var name: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_PID, getpid()]
    var info: kinfo_proc = kinfo_proc()
    var info_size = MemoryLayout<kinfo_proc>.size

    let success = name.withUnsafeMutableBytes { (nameBytePtr: UnsafeMutableRawBufferPointer) -> Bool in
        guard let nameBytesBlindMemory = nameBytePtr.bindMemory(to: Int32.self).baseAddress else { return false }
        return -1 != sysctl(nameBytesBlindMemory, 4, &info, &info_size, nil, 0)
    }

    if !success {
        debuggerIsAttached = false
    }

    if !debuggerIsAttached && (info.kp_proc.p_flag & P_TRACED) != 0 {
        debuggerIsAttached = true
    }

    return debuggerIsAttached
}()

/// Check if is running in preview.
private let isRunningInPreview: Bool = ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"


// MARK: - Logger

/// This class is built on top of a big open source library: [Pulse](https://github.com/kean/Pulse) and using the `OSLog`
/// APIs to make it compatible with Xcode 15 and above.
///
/// The logging methods are the following:
/// - ``info(_:context:label:metadata:file:function:line:)``
/// - ``debug(_:context:metadata:file:function:line:)``
/// - ``warning(_:context:label:metadata:file:function:line:)``
/// - ``error(_:context:label:metadata:file:function:line:)``
/// - ``critical(_:context:metadata:file:function:line:)``
///
/// When one of these method is called, we use both `OSLog` and `Pulse`. The log in the console
/// arrives from `OSLog` apis and `Pulse` is used to save the whole log history that can be viewed using
/// one of these shorthands that returns a view or a controller:
/// - ``consoleView``
/// - ``consoleViewController``
/// - ``consoleViewEmbeddedInNavigationViewController``
///
/// > Important:
/// Don’t create an instance of `AMLoggerMessage`. Instead, provide an interpolated string as the message
///  parameter and the system converts it automatically.
///
///  > Important:
///  If you're developing SwiftUI and you're using the Preview feature all the logs are printed using the
///  `print(:)` function and not using the `OSLog` and `Pulse` feature. This is mainly because `OSLog` is
///  not supported in preview and would result in no message in the Preview tab of the Xcode console.
public struct AMLogger: Sendable {
    
    /// The session var to enable the network request monitoring.
    @MainActor private static var session: URLSessionProtocol? = nil
#if os(iOS) && canImport(WormholySwift)
    /// This returns `true` if the environment variable `WORMHOLY_SHAKE_ENABLED`
    /// is set to `YES`, `false` otherwise. When a new value is set,the `setenv(_:_:_)`
    /// function is called to write it in the `WORMHOLY_SHAKE_ENABLED` var.
    ///
    /// Import the Wormholy framework adding the package to your project,
    /// this is the url: [https://github.com/pmusolino/Wormholy](https://github.com/pmusolino/Wormholy).
    @MainActor public static var isWormholyShakeEnabled: Bool {
        get { ProcessInfo.processInfo.environment["WORMHOLY_SHAKE_ENABLED"] == "YES" }
        set { setenv("WORMHOLY_SHAKE_ENABLED", newValue ? "YES" : "NO", 1) }
    }
#endif
    
    /// The string that replaces the information marked as private during
    /// session where debugger is not attached.
    static let privateLevelReplacementString: String = "🔒"
    
    /// The label associated with the logger instance.
    public let label: Label
    
    /// The `Logger` object from the `OSLog` framework.
    private let logger: Logger
    
    /// Init a new logger instance with a specific label associated to it.
    /// - Parameter subsystem: The subsystem associated to the logger. Default value is the bundle identifier.
    /// - Parameter label: The label associated to the logger.
    public init(subsystem: String = Bundle.main.infoDictionary!["CFBundleIdentifier"] as! String, label: Label) {
        self.label = label
        self.logger = Logger.init(subsystem: subsystem, category: label.value)
    }
}


// MARK: - Network Logger

public extension AMLogger {
    
    /// Start monitoring network requests.
    ///
    /// > Important:
    /// This is still an experiment feature.
    @MainActor
    static func startMonitoringNetworkRequests() {
        if isDebuggerAttached {
            session = URLSessionProxy(configuration: .default)
        } else {
            session = URLSession(configuration: .default)
        }
    }
    
    /// Enable remote logging to see the logs on the
    /// Pulse app on macOS.
    ///
    /// Be sure to add this to the Info.plist file of your app:
    ///
    /// ```
    /// <key>NSLocalNetworkUsageDescription</key>
    /// <string>Network usage required only for development purposes</string>
    /// <key>NSBonjourServices</key>
    /// <array>
    ///   <string>_pulse._tcp</string>
    /// </array>
    /// ```
    ///
    /// > Important: Call this only for debug builds, not for production ones.
    @MainActor
    static func enableRemoteLogging() {
        RemoteLogger.shared.isAutomaticConnectionEnabled = true
    }
    
#if os(iOS) && canImport(WormholySwift)
    /// Open the Wormholy view manually.
    ///
    /// Import the Wormholy framework adding the package to your project,
    /// this is the url: [https://github.com/pmusolino/Wormholy](https://github.com/pmusolino/Wormholy).
    @MainActor
    static func openWormholyView() {
        NotificationCenter.default.post(name: Notification.Name(rawValue: "wormholy_fire"), object: nil)
    }
#endif
}


// MARK: Logging instance methods

public extension AMLogger {
    
    /// Call this function to capture information that may be helpful, but isn’t essential, for troubleshooting.
    func info(
        _ message: Message,
        context: Any? = nil,
        label: Label? = nil,
        metadata: [String: Any]? = nil,
        file: String = #file,
        function: String = #function,
        line: Int = #line)
    {
        let formattedMessage = formatMessage(message, file: file, function: function, line: line)
        if isRunningInPreview {
            print(formattedMessage)
        } else {
            logger.info("\(formattedMessage)")
            LoggerStore.shared.storeMessage(
                label: label?.value ?? self.label.value,
                level: .info,
                message: formattedMessage,
                metadata: metadata?.pulseMetadata,
                file: file,
                function: function,
                line: UInt(line)
            )
        }
    }
    
    /// Debug-level messages to use in a development environment while actively debugging.
    func debug(
        _ message: Message,
        context: Any? = nil,
        metadata: [String: Any]? = nil,
        file: String = #file,
        function: String = #function,
        line: Int = #line)
    {
        let formattedMessage = formatMessage(message, file: file, function: function, line: line)
        if isRunningInPreview {
            print(formattedMessage)
        } else {
            logger.debug("\(formattedMessage)")
            LoggerStore.shared.storeMessage(
                label: self.label.value,
                level: .debug,
                message: formattedMessage,
                metadata: metadata?.pulseMetadata,
                file: file,
                function: function,
                line: UInt(line)
            )
        }
    }
    
    /// Warning-level messages for reporting unexpected non-fatal failures.
    func warning(
        _ message: Message,
        context: Any? = nil,
        label: Label? = nil,
        metadata: [String: Any]? = nil,
        file: String = #file,
        function: String = #function,
        line: Int = #line)
    {
        let formattedMessage = formatMessage(message, file: file, function: function, line: line)
        if isRunningInPreview {
            print(formattedMessage)
        } else {
            logger.warning("\(formattedMessage)")
            LoggerStore.shared.storeMessage(
                label: label?.value ?? self.label.value,
                level: .warning,
                message: formattedMessage,
                metadata: metadata?.pulseMetadata,
                file: file,
                function: function,
                line: UInt(line)
            )
        }
    }
    
    /// Error-level messages for reporting critical errors and failures.
    func error(
        _ message: Message,
        context: Any? = nil,
        label: Label? = nil,
        metadata: [String: Any]? = nil,
        file: String = #file,
        function: String = #function,
        line: Int = #line)
    {
        let formattedMessage = formatMessage(message, file: file, function: function, line: line)
        if isRunningInPreview {
            print(formattedMessage)
        } else {
            logger.error("\(formattedMessage)")
            LoggerStore.shared.storeMessage(
                label: label?.value ?? self.label.value,
                level: .error,
                message: formattedMessage,
                metadata: metadata?.pulseMetadata,
                file: file,
                function: function,
                line: UInt(line)
            )
        }
    }
    
    /// Fault-level messages for capturing system-level or multi-process errors only.
    func critical(
        _ message: Message,
        context: Any? = nil,
        metadata: [String: Any]? = nil,
        file: String = #file,
        function: String = #function,
        line: Int = #line)
    {
        let formattedMessage = formatMessage(message, file: file, function: function, line: line)
        if isRunningInPreview {
            print(formattedMessage)
        } else {
            logger.critical("\(formattedMessage)")
            LoggerStore.shared.storeMessage(
                label: self.label.value,
                level: .critical,
                message: formattedMessage,
                metadata: metadata?.pulseMetadata,
                file: file,
                function: function,
                line: UInt(line)
            )
        }
    }
}


// MARK: - Log view

public extension AMLogger {
    
#if !os(macOS)
    
    /// A SwiftUI view that can be presented anywhere and contains the logs.
    /// This is usually good enough to be presented within SwiftUI apps or
    /// embedded in a custom view controller using `UIHostingController`.
    /// In that case you can use ``consoleViewController``
    /// or ``consoleViewEmbeddedInNavigationViewController``.
    @MainActor
    @ViewBuilder static var consoleView: some View {
        
        NavigationView {
            ConsoleView()
        }
    }
#endif
    
#if os(iOS) && canImport(UIKit)
    
    /// The ``consoleView`` as ``UIViewController``.
    @MainActor
    static var consoleViewController: UIViewController {
        return UIHostingController(rootView: consoleView)
    }
    
    /// The ``consoleViewController`` embedded in a ``UINavigationController``.
    @MainActor
    static var consoleViewEmbeddedInNavigationViewController: UINavigationController {
        return UINavigationController(rootViewController: consoleViewController)
    }
    
#endif
}


// MARK: - Format message

private extension AMLogger {
    
    /// Create the right message to show in the console print, merging all the info in a single string.
    /// - Parameters:
    ///   - message: The message.
    ///   - file: The file.
    ///   - function: The function.
    ///   - line: The line.
    /// - Returns: The formatted message to print.
    func formatMessage(_ message: Message, file: String, function: String, line: Int) -> String {
        
        let messageString = String("\(message.value)")
        let formattedFile = String(file.split(separator: "/").last!).split(separator: ".").first!
        
        return "[\(formattedFile).\(function)():\(line)] - \(messageString)"
    }
}


// MARK: Loggers

public extension AMLogger {

    /// The logger for generic logs.
    static let generic: AMLogger =                              .init(label: .generic)
    /// The logger for network-related logs.
    static let network: AMLogger =                              .init(label: .network)
    /// The logger for view lifecycle-related logs.
    static let viewLifecycle: AMLogger =                        .init(label: .viewLifecycle)
    /// The logger for UI-related logs.
    static let ui: AMLogger =                                   .init(label: .ui)
    /// The logger for database-related logs.
    static let database: AMLogger =                             .init(label: .database)
    /// The logger for SwiftData-related logs.
    static let swiftData: AMLogger =                            .init(label: .swiftData)
    /// The logger for CoreData-related logs.
    static let coreData: AMLogger =                             .init(label: .coreData)
    /// The logger for filesystem-related logs.
    static let filesystem: AMLogger =                           .init(label: .filesystem)
    /// The logger for SwiftData store migration-related logs.
    static let swiftDataStoreMigration: AMLogger =              .init(label: .swiftDataStoreMigration)
    /// The logger for SwiftData lightweight migration-related logs.
    static let swiftDataLightweightMigration: AMLogger =        .init(label: .swiftDataLightweightMigration)
    /// The logger for SwiftData custom migration-related logs.
    static let swiftDataCustomMigration: AMLogger =             .init(label: .swiftDataCustomMigration)
    /// The logger for Realm migration-related logs.
    static let realmMigration: AMLogger =                       .init(label: .realmMigration)
    /// The logger for data migration-related logs.
    static let dataMigration: AMLogger =                        .init(label: .dataMigration)
    /// The logger for data model-related logs.
    static let dataModel: AMLogger =                            .init(label: .dataModel)
    /// The logger for data persistence-related logs.
    static let dataPersistence: AMLogger =                      .init(label: .dataPersistence)
    /// The logger for data validation-related logs.
    static let dataValidation: AMLogger =                       .init(label: .dataValidation)
    /// The logger for data transformation-related logs.
    static let dataTransformation: AMLogger =                   .init(label: .dataTransformation)
    /// The logger for data manipulation-related logs.
    static let dataManipulation: AMLogger =                     .init(label: .dataManipulation)
    /// The logger for data access-related logs.
    static let dataAccess: AMLogger =                           .init(label: .dataAccess)
    /// The logger for data caching-related logs.
    static let dataCaching: AMLogger =                          .init(label: .dataCaching)
    /// The logger for widget-related logs.
    static let widget: AMLogger =                               .init(label: .widget)
    /// The logger for home screen widget-related logs.
    static let homeScreenWidget: AMLogger =                     .init(label: .homeScreenWidget)
    /// The logger for lock screen widget-related logs.
    static let lockScreenWidget: AMLogger =                     .init(label: .lockScreenWidget)
    /// The logger for API-related logs.
    static let api: AMLogger =                                  .init(label: .api)
    /// The logger for graphic-related logs.
    static let graphic: AMLogger =                              .init(label: .graphic)
    /// The logger for social-related logs.
    static let social: AMLogger =                               .init(label: .social)
    /// The logger for date management-related logs.
    static let dateManagement: AMLogger =                       .init(label: .dateManagement)
    /// The logger for localization-related logs.
    static let localization: AMLogger =                         .init(label: .localization)
    /// The logger for maps-related logs.
    static let maps: AMLogger =                                 .init(label: .maps)
    /// The logger for animation-related logs.
    static let animation: AMLogger =                            .init(label: .animation)
    /// The logger for analytics-related logs.
    static let analytics: AMLogger =                            .init(label: .analytics)
    /// The logger for performance-related logs.
    static let performance: AMLogger =                          .init(label: .performance)
    /// The logger for charts-related logs.
    static let charts: AMLogger =                               .init(label: .charts)
    /// The logger for StoreKit-related logs.
    static let storeKit: AMLogger =                             .init(label: .storeKit)
}


// MARK: Dictionary and Pulse

private extension Dictionary where Key == String, Value == Any {
    
    var pulseMetadata: [String: LoggerStore.MetadataValue] {
        return mapValues { value in
            if let string = value as? String {
                return .string(string)
            } else {
                return .stringConvertible("\(value)")
            }
        }
    }
}


// MARK: - Message

public extension AMLogger {
    
    /// This is the message passed to the `AMLogger`.
    ///
    /// This offers the possibility to add options to the interpolated string, such as
    /// a privacy field (see ``AMLoggerPrivacy``).
    struct Message: ExpressibleByStringLiteral, ExpressibleByStringInterpolation {
        
        public struct AMLoggerInterpolation: StringInterpolationProtocol {
            
            public typealias StringLiteralType = String
            
            public var output: String = ""
            public var components: [(value: String, privacy: Privacy)] = []
            
            public init(literalCapacity: Int, interpolationCount: Int) {
                output.reserveCapacity(literalCapacity)
            }
            
            public mutating func appendLiteral(_ literal: String) {
                components.append((literal, .public))
                output += literal
            }
            
            public mutating func appendInterpolation<T>(_ value: T, privacy: Privacy = .public) {
                
                components.append(("\(value)", privacy))
                
                if isDebuggerAttached {
                    output += "\(value)"
                } else {
                    switch privacy {
                    case .public:
                        output += "\(value)"
                    case .private:
                        output += AMLogger.privateLevelReplacementString
                    case .hashed:
                        let valueAsString = "\(value)"
                        let valueAsData = Data(valueAsString.utf8)
                        let hashedValue = SHA256.hash(data: valueAsData)
                        let hashedString = hashedValue.compactMap { String(format: "%02x", $0) }.joined()
                        output += "\(hashedString)"
                    }
                }
            }
            
            // TODO: Solve this issue.
            // This will conflict with the function above, due to having the same name and params.
            //        public mutating func appendInterpolation<T>(_ value: @autoclosure @escaping () -> T, privacy: AMLoggerPrivacy = .public) {
            //
            //            components.append(("\(String(describing: value))", privacy))
            //
            //            if isDebuggerAttached {
            //                output += "\(String(describing: value))"
            //            } else {
            //                switch privacy {
            //                case .public:
            //                    output += "\(String(describing: value))"
            //                case .private:
            //                    output += AMLogger.privateLevelReplacementString
            //                case .hashed:
            //                    let valueAsString = "\(String(describing: value))"
            //                    output += "\(valueAsString.hashValue)"
            //                }
            //            }
            //        }
        }
        
        /// The actual composed string after evaluating options.
        public let value: String
        /// The components of the string, as an array of tuple containing `string` and `privacy`.
        public let components: [(value: String, privacy: Privacy)]
        
        public init(stringLiteral value: String) {
            self.value = value
            self.components = [(value, .public)]
        }
        
        public init<T>(value: T) {
            self.value = "\(value)"
            self.components = [("\(value)", .public)]
        }
        
        public init(stringInterpolation: AMLoggerInterpolation) {
            self.value = stringInterpolation.output
            self.components = stringInterpolation.components
        }
    }
}


// MARK: - Privacy

public extension AMLogger {
    
    /// This represents the privacy level of a single message.
    /// It's applied to the interpolation string in the `AMLoggerMessage`.
    enum Privacy: Hashable, Codable {
        /// Public message.
        case `public`
        /// The private level.
        ///
        /// Using this privacy level will result in the string to be
        /// replaced using the ``AMLogger/privateLevelReplacementString`` value.
        case `private`
        /// Using this privacy level will result in the string to be
        /// replaced using its hash value. It could be useful to identify the same value,
        /// keeping the privacy, within a debug session.
        case hashed
        
        /// `true` if the privacy level is public, `false` otherwise.
        var isPublic: Bool      { self == .public }
        /// `true` if the privacy level is private, `false` otherwise.
        var isPrivate: Bool     { self == .private }
        /// `true` if the privacy level is hashed, `false` otherwise.
        var isHashed: Bool      { self == .hashed }
        /// `true` if the privacy level is not public, `false` otherwise.
        var isNotPublic: Bool   { !isPublic }
    }
}


// MARK: - Label (or category)

public extension AMLogger {
    
    /// This is just a convenience typealias for `Label`.
    typealias Category = Label
    
    /// This struct offers common labels useful to categorize logs.
    /// The best practice would be to extend it if you need to add more categories.
    struct Label: Sendable {
        
        /// The actual `String` value of the label.
        public let value: String
        
        /// Init a new `Label` with the passed value.
        /// - Parameter value: The value of the label.
        public init(_ value: String) {
            self.value = value
        }
        
        /// This label should refer to generic type of logs.
        public static let generic                           = Self.init("Generic")
        /// This label should refer to network-related logs.
        public static let network                           = Self.init("Network")
        /// This label should refer to view lifecycle-related logs.
        public static let viewLifecycle                     = Self.init("View Lifecycle")
        /// This label should refer to UI-related logs.
        public static let ui                                = Self.init("UI")
        /// This label should refer to database-related logs.
        public static let database                          = Self.init("Database")
        /// This label should refer to SwiftData-related logs.
        public static let swiftData                         = Self.init("SwiftData")
        /// This label should refer to CoreData-related logs.
        public static let coreData                          = Self.init("CoreData")
        /// This label should refer to filesystem-related logs.
        public static let filesystem                        = Self.init("Filesystem")
        /// This label should refer to SwiftData store migration-related logs.
        public static let swiftDataStoreMigration           = Self.init("SwiftData Store Migration")
        /// This label should refer to SwiftData lightweight migration-related logs.
        public static let swiftDataLightweightMigration     = Self.init("SwiftData Lightweight Migration")
        /// This label should refer to SwiftData custom migration-related logs.
        public static let swiftDataCustomMigration          = Self.init("SwiftData Custom Migration")
        /// This label should refer to Realm migration-related logs.
        public static let realmMigration                    = Self.init("Realm Migration")
        /// This label should refer to data migration-related logs.
        public static let dataMigration                     = Self.init("Data Migration")
        /// This label should refer to data model-related logs.
        public static let dataModel                         = Self.init("Data Model")
        /// This label should refer to data persistence-related logs.
        public static let dataPersistence                   = Self.init("Data Persistence")
        /// This label should refer to data validation-related logs.
        public static let dataValidation                    = Self.init("Data Validation")
        /// This label should refer to data transformation-related logs.
        public static let dataTransformation                = Self.init("Data Transformation")
        /// This label should refer to data manipulation-related logs.
        public static let dataManipulation                  = Self.init("Data Manipulation")
        /// This label should refer to data access-related logs.
        public static let dataAccess                        = Self.init("Data Access")
        /// This label should refer to data caching-related logs.
        public static let dataCaching                       = Self.init("Data Caching")
        /// This label should refer to widget-related logs.
        public static let widget                            = Self.init("Widget")
        /// This label should refer to home screen widget-related logs.
        public static let homeScreenWidget                  = Self.init("Home Screen Widget")
        /// This label should refer to lock screen widget-related logs.
        public static let lockScreenWidget                  = Self.init("Lock Screen Widget")
        /// This label should refer to API-related logs.
        public static let api                               = Self.init("API")
        /// This label should refer to graphic-related logs.
        public static let graphic                           = Self.init("Graphic")
        /// This label should refer to social-related logs.
        public static let social                            = Self.init("Social")
        /// This label should refer to date management-related logs.
        public static let dateManagement                    = Self.init("Date Management")
        /// This label should refer to localization-related logs.
        public static let localization                      = Self.init("Localization")
        /// This label should refer to maps-related logs.
        public static let maps                              = Self.init("Maps")
        /// This label should refer to animation-related logs.
        public static let animation                         = Self.init("Animation")
        /// This label should refer to analytics-related logs.
        public static let analytics                         = Self.init("Analytics")
        /// This label should refer to performance-related logs.
        public static let performance                       = Self.init("Performance")
        /// This label should refer to charts-related logs.
        public static let charts                            = Self.init("Charts")
        /// This label should refer to StoreKit-related logs.
        public static let storeKit                          = Self.init("StoreKit")
    }
}

#endif

