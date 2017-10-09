//
//  Logging.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 08.10.17.
//

struct Log {

	private init() { }

	enum Level {
		case info, debug, warn, error

		var toString: String {
			switch self {
			case .info: return "INFO"
			case .debug: return "DEBUG"
			case .warn: return "WARN"
			case .error: return "ERROR"
			}
		}
	}

	static func info(_ args: Any?...) { Log.log(level: .info, args: args) }
	static func debug(_ args: Any?...) { Log.log(level: .debug, args: args) }
	static func warn(_ args: Any?...) { Log.log(level: .warn, args: args) }
	static func error(_ args: Any?...) { Log.log(level: .error, args: args) }

	private static func log(level: Log.Level, args: [Any?]) {
		let entry: String = Log.serialize(level: level, args: args)
		Swift.print(entry)
	}

	private static func serialize(level: Log.Level, args: [Any?]) -> String {
		let argStrings: [String] = args.flatMap { arg in
			if let arg = arg {
				return String(describing: arg)
			}
			return nil
		}

		let argString: String = argStrings.joined(separator: " ")
		let levelString: String = level.toString

		return ["[", levelString, "]\t", argString].joined()
	}

}
