import Foundation

enum FileTextCodec {
	static func decodeBestEffort(data: Data) -> (text: String, isLikelyText: Bool) {
		if data.isEmpty { return ("", true) }

		if let string = String(data: data, encoding: .utf8) {
			return (string, true)
		}
		if let string = String(data: data, encoding: .utf16) {
			return (string, true)
		}
		if let string = String(data: data, encoding: .utf16LittleEndian) {
			return (string, true)
		}
		if let string = String(data: data, encoding: .utf16BigEndian) {
			return (string, true)
		}
		if let string = String(data: data, encoding: .isoLatin1) {
			return (string, false)
		}

		let base64 = data.base64EncodedString(options: [.lineLength64Characters, .endLineWithLineFeed])
		return ("[Binary file]\n\n(base64)\n\(base64)", false)
	}
}

