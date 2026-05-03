import Foundation
import SwiftUI

@MainActor
final class DocumentStore: ObservableObject {
	@Published private(set) var documents: [EditableDocument] = []
	@Published var selectedDocumentID: EditableDocument.ID?

	private let indexFilename = "documents.index.json"
	private let importedFolder = "Imported"

	init() {
		Task { await load() }
	}

	func document(id: EditableDocument.ID?) -> EditableDocument? {
		guard let id else { return nil }
		return documents.first(where: { $0.id == id })
	}

	func updateText(for id: EditableDocument.ID, text: String) {
		guard let index = documents.firstIndex(where: { $0.id == id }) else { return }
		documents[index].lastKnownText = text
		documents[index].updatedAt = Date()
		saveIndexAsync()
	}

	func delete(id: EditableDocument.ID) {
		guard let index = documents.firstIndex(where: { $0.id == id }) else { return }
		let doc = documents.remove(at: index)
		selectedDocumentID = (selectedDocumentID == id) ? nil : selectedDocumentID
		do {
			let url = try storageURL(for: doc)
			try? FileManager.default.removeItem(at: url)
		} catch {
			// ignore best-effort
		}
		saveIndexAsync()
	}

	func importFile(from sourceURL: URL) async throws -> EditableDocument {
		let fileManager = FileManager.default
		let id = UUID()

		let filename = sourceURL.deletingPathExtension().lastPathComponent
		let ext = sourceURL.pathExtension

		let container = try ensureImportedFolder()
		let destination = container.appendingPathComponent("\(id.uuidString).\(ext.isEmpty ? "dat" : ext)")

		var didStart = false
		if sourceURL.startAccessingSecurityScopedResource() { didStart = true }
		defer { if didStart { sourceURL.stopAccessingSecurityScopedResource() } }

		if fileManager.fileExists(atPath: destination.path) {
			try fileManager.removeItem(at: destination)
		}
		try fileManager.copyItem(at: sourceURL, to: destination)

		let data = try Data(contentsOf: destination)
		let decoded = FileTextCodec.decodeBestEffort(data: data)

		let doc = EditableDocument(
			id: id,
			origin: .imported,
			title: filename,
			originalFilename: filename,
			originalFileExtension: ext,
			createdAt: Date(),
			updatedAt: Date(),
			storageRelativePath: "\(importedFolder)/\(destination.lastPathComponent)",
			isLikelyText: decoded.isLikelyText,
			lastKnownText: decoded.text
		)

		documents.insert(doc, at: 0)
		selectedDocumentID = doc.id
		saveIndexAsync()
		return doc
	}

	func createNew(title: String, fileExtension: String, initialText: String) async throws -> EditableDocument {
		let id = UUID()
		let safeTitle = title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Untitled" : title
		let safeExt = fileExtension.trimmingCharacters(in: .whitespacesAndNewlines)

		let container = try ensureImportedFolder()
		let extForStorage = safeExt.isEmpty ? "txt" : safeExt
		let destination = container.appendingPathComponent("\(id.uuidString).\(extForStorage)")

		try initialText.data(using: .utf8)?.write(to: destination, options: [.atomic])

		let doc = EditableDocument(
			id: id,
			origin: .created,
			title: safeTitle,
			originalFilename: safeTitle,
			originalFileExtension: safeExt,
			createdAt: Date(),
			updatedAt: Date(),
			storageRelativePath: "\(importedFolder)/\(destination.lastPathComponent)",
			isLikelyText: true,
			lastKnownText: initialText
		)

		documents.insert(doc, at: 0)
		selectedDocumentID = doc.id
		saveIndexAsync()
		return doc
	}

	func exportURL(for id: EditableDocument.ID) throws -> URL {
		guard let doc = document(id: id) else { throw CocoaError(.fileNoSuchFile) }

		let ext = doc.originalFileExtension.isEmpty ? "txt" : doc.originalFileExtension
		let exportName = "\(doc.originalFilename).\(ext)"

		let temp = FileManager.default.temporaryDirectory
		let url = temp.appendingPathComponent(exportName)
		try doc.lastKnownText.data(using: .utf8)?.write(to: url, options: [.atomic])
		return url
	}

	private func ensureImportedFolder() throws -> URL {
		let base = try appDocumentsDirectory()
		let folder = base.appendingPathComponent(importedFolder, isDirectory: true)
		if !FileManager.default.fileExists(atPath: folder.path) {
			try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true, attributes: nil)
		}
		return folder
	}

	private func storageURL(for document: EditableDocument) throws -> URL {
		let base = try appDocumentsDirectory()
		return base.appendingPathComponent(document.storageRelativePath)
	}

	private func indexURL() throws -> URL {
		let base = try appDocumentsDirectory()
		return base.appendingPathComponent(indexFilename)
	}

	private func appDocumentsDirectory() throws -> URL {
		guard let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
			throw CocoaError(.fileNoSuchFile)
		}
		return url
	}

	private func load() async {
		do {
			let url = try indexURL()
			guard FileManager.default.fileExists(atPath: url.path) else {
				documents = []
				return
			}
			let data = try Data(contentsOf: url)
			let decoded = try JSONDecoder().decode([EditableDocument].self, from: data)
			documents = decoded.sorted(by: { $0.updatedAt > $1.updatedAt })
		} catch {
			documents = []
		}
	}

	private func saveIndexAsync() {
		let docs = documents
		Task.detached(priority: .utility) { [indexFilename] in
			do {
				guard let base = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
				let url = base.appendingPathComponent(indexFilename)
				let data = try JSONEncoder().encode(docs)
				try data.write(to: url, options: [.atomic])
			} catch {
				// ignore
			}
		}
	}
}
