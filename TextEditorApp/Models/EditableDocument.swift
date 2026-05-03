import Foundation

struct EditableDocument: Identifiable, Codable, Hashable {
	enum Origin: String, Codable {
		case imported
		case created
	}

	var id: UUID
	var origin: Origin

	var title: String
	var originalFilename: String
	var originalFileExtension: String

	var createdAt: Date
	var updatedAt: Date

	var storageRelativePath: String
	var isLikelyText: Bool
	var lastKnownText: String

	var originalDisplayName: String {
		if originalFileExtension.isEmpty { return originalFilename }
		return "\(originalFilename).\(originalFileExtension)"
	}

	var previewDisplayName: String {
		"\(originalFilename).txt"
	}
}

