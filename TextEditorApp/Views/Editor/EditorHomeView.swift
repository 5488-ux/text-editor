import SwiftUI
import UniformTypeIdentifiers

struct EditorHomeView: View {
	@EnvironmentObject private var store: DocumentStore
	@Environment(\.horizontalSizeClass) private var horizontalSizeClass

	@State private var isImporterPresented = false
	@State private var isNewPresented = false
	@State private var isExporterPresented = false
	@State private var activeEditorDocumentID: EditableDocument.ID?
	@State private var exportItem: ExportItem?
	@State private var alert: SimpleAlert?

	private var isCompact: Bool {
		horizontalSizeClass == .compact
	}

	var body: some View {
		Group {
			if isCompact {
				compactContent
			} else {
				regularContent
			}
		}
		.background(LiquidGlassBackground())
		.navigationTitle("文本编辑")
		.navigationBarTitleDisplayMode(.large)
		.toolbar {
			ToolbarItemGroup(placement: .topBarTrailing) {
				Button { isNewPresented = true } label: {
					Image(systemName: "square.and.pencil")
				}
				.accessibilityLabel("新建文本")

				Button { isImporterPresented = true } label: {
					Image(systemName: "square.and.arrow.down")
				}
				.accessibilityLabel("导入文件")
			}
		}
		.fileImporter(
			isPresented: $isImporterPresented,
			allowedContentTypes: [.data],
			allowsMultipleSelection: false
		) { result in
			Task { @MainActor in
				do {
					let urls = try result.get()
					guard let url = urls.first else { return }
					let doc = try await store.importFile(from: url)
					openDocument(doc)
				} catch {
					alert = SimpleAlert(title: "导入失败", message: error.localizedDescription)
				}
			}
		}
		.sheet(isPresented: $isNewPresented) {
			NewDocumentSheet { title, ext, text in
				Task { @MainActor in
					do {
						let doc = try await store.createNew(title: title, fileExtension: ext, initialText: text)
						openDocument(doc)
					} catch {
						alert = SimpleAlert(title: "新建失败", message: error.localizedDescription)
					}
				}
			}
			.presentationDetents([.medium, .large])
		}
		.sheet(isPresented: activeEditorBinding) {
			if let doc = store.document(id: activeEditorDocumentID) {
				EditorDetailView(document: doc) { updatedText in
					store.updateText(for: doc.id, text: updatedText)
				} onExport: {
					prepareExport(for: doc)
				}
				.padding(16)
				.background(LiquidGlassBackground())
				.presentationDetents([.large])
			}
		}
		.fileExporter(
			isPresented: $isExporterPresented,
			document: exportItem,
			contentType: .data,
			defaultFilename: exportItem?.defaultFilename ?? "export.txt"
		) { result in
			switch result {
			case .success:
				break
			case .failure(let error):
				alert = SimpleAlert(title: "导出失败", message: error.localizedDescription)
			}
			exportItem = nil
		}
		.alert(item: $alert) { alert in
			Alert(title: Text(alert.title), message: Text(alert.message), dismissButton: .default(Text("好")))
		}
	}

	private var compactContent: some View {
		ScrollView {
			VStack(spacing: 14) {
				quickActions
				documentSection
			}
			.padding(.horizontal, 16)
			.padding(.top, 10)
			.padding(.bottom, 24)
		}
	}

	private var regularContent: some View {
		VStack(spacing: 12) {
			header
			HStack(spacing: 12) {
				documentList
					.frame(minWidth: 320, maxWidth: 420)
				editorPanel
			}
		}
		.padding(.horizontal, 16)
		.padding(.top, 12)
	}

	private var header: some View {
		LiquidGlassCard {
			HStack(spacing: 12) {
				Image(systemName: "sparkles")
					.font(.title3)
					.foregroundStyle(.secondary)
				VStack(alignment: .leading, spacing: 4) {
					Text("上传任意格式文件")
						.font(.headline)
					Text("预览时显示为 .txt；导出时恢复为原扩展名。")
						.font(.subheadline)
						.foregroundStyle(.secondary)
				}
				Spacer(minLength: 0)
			}
		}
	}

	private var quickActions: some View {
		HStack(spacing: 12) {
			EditorActionTile(
				title: "新建",
				subtitle: "自定义格式",
				systemImage: "doc.badge.plus",
				tint: .blue
			) {
				isNewPresented = true
			}

			EditorActionTile(
				title: "导入",
				subtitle: "任意文件",
				systemImage: "folder.badge.plus",
				tint: .orange
			) {
				isImporterPresented = true
			}
		}
	}

	private var documentSection: some View {
		LiquidGlassCard {
			VStack(alignment: .leading, spacing: 12) {
				HStack {
					Label("最近文档", systemImage: "clock")
						.font(.headline)
					Spacer()
					Text("\(store.documents.count)")
						.font(.subheadline.weight(.medium))
						.foregroundStyle(.secondary)
				}

				if store.documents.isEmpty {
					CompactEmptyState()
						.frame(maxWidth: .infinity)
						.padding(.vertical, 42)
				} else {
					VStack(spacing: 8) {
						ForEach(store.documents) { doc in
							DocumentRowButton(
								document: doc,
								isSelected: doc.id == store.selectedDocumentID,
								onOpen: { openDocument(doc) },
								onExport: { prepareExport(for: doc) },
								onDelete: { deleteDocument(doc) }
							)
						}
					}
				}
			}
		}
	}

	private var documentList: some View {
		LiquidGlassCard {
			VStack(alignment: .leading, spacing: 10) {
				HStack {
					Text("文档").font(.headline)
					Spacer()
					Text("\(store.documents.count)")
						.font(.subheadline)
						.foregroundStyle(.secondary)
				}

				if store.documents.isEmpty {
					CompactEmptyState()
						.frame(maxWidth: .infinity, minHeight: 240)
				} else {
					ScrollView {
						VStack(spacing: 8) {
							ForEach(store.documents) { doc in
								DocumentRowButton(
									document: doc,
									isSelected: doc.id == store.selectedDocumentID,
									onOpen: { openDocument(doc) },
									onExport: { prepareExport(for: doc) },
									onDelete: { deleteDocument(doc) }
								)
							}
						}
					}
				}
			}
		}
	}

	private var editorPanel: some View {
		LiquidGlassCard {
			if let doc = store.document(id: store.selectedDocumentID) {
				EditorDetailView(document: doc) { updatedText in
					store.updateText(for: doc.id, text: updatedText)
				} onExport: {
					prepareExport(for: doc)
				}
			} else {
				ContentUnavailableView("未选择文档", systemImage: "cursorarrow.click", description: Text("从左侧列表选择一个文档开始编辑。"))
					.frame(maxWidth: .infinity, minHeight: 240)
			}
		}
		.frame(maxWidth: .infinity)
	}

	private var activeEditorBinding: Binding<Bool> {
		Binding(
			get: { activeEditorDocumentID != nil },
			set: { isPresented in
				if !isPresented {
					activeEditorDocumentID = nil
				}
			}
		)
	}

	private func openDocument(_ doc: EditableDocument) {
		store.selectedDocumentID = doc.id
		if isCompact {
			activeEditorDocumentID = doc.id
		}
	}

	private func deleteDocument(_ doc: EditableDocument) {
		if activeEditorDocumentID == doc.id {
			activeEditorDocumentID = nil
		}
		store.delete(id: doc.id)
	}

	private func prepareExport(for doc: EditableDocument) {
		do {
			let url = try store.exportURL(for: doc.id)
			exportItem = ExportItem(url: url, defaultFilename: doc.originalDisplayName)
			isExporterPresented = true
		} catch {
			alert = SimpleAlert(title: "导出失败", message: error.localizedDescription)
		}
	}
}

private struct EditorActionTile: View {
	let title: String
	let subtitle: String
	let systemImage: String
	let tint: Color
	let action: () -> Void

	var body: some View {
		Button(action: action) {
			HStack(spacing: 10) {
				Image(systemName: systemImage)
					.font(.title3)
					.foregroundStyle(tint)
					.frame(width: 34, height: 34)
					.background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 10, style: .continuous))

				VStack(alignment: .leading, spacing: 2) {
					Text(title)
						.font(.headline)
						.foregroundStyle(.primary)
					Text(subtitle)
						.font(.caption)
						.foregroundStyle(.secondary)
				}
				Spacer(minLength: 0)
			}
			.padding(12)
			.frame(maxWidth: .infinity, minHeight: 70)
			.background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
			.overlay(
				RoundedRectangle(cornerRadius: 18, style: .continuous)
					.strokeBorder(.white.opacity(0.18), lineWidth: 1)
			)
		}
		.buttonStyle(.plain)
	}
}

private struct DocumentRowButton: View {
	let document: EditableDocument
	let isSelected: Bool
	let onOpen: () -> Void
	let onExport: () -> Void
	let onDelete: () -> Void

	var body: some View {
		Button(action: onOpen) {
			HStack(spacing: 12) {
				Image(systemName: document.isLikelyText ? "doc.text" : "doc.zipper")
					.font(.title3)
					.foregroundStyle(document.isLikelyText ? .blue : .orange)
					.frame(width: 36, height: 36)
					.background((document.isLikelyText ? Color.blue : Color.orange).opacity(0.12), in: RoundedRectangle(cornerRadius: 10, style: .continuous))

				VStack(alignment: .leading, spacing: 4) {
					Text(document.title)
						.font(.subheadline.weight(.semibold))
						.foregroundStyle(.primary)
						.lineLimit(1)
					Text(documentSubtitle)
						.font(.caption)
						.foregroundStyle(.secondary)
						.lineLimit(1)
				}

				Spacer(minLength: 0)

				Image(systemName: "chevron.right")
					.font(.caption.weight(.semibold))
					.foregroundStyle(.tertiary)
			}
			.padding(10)
			.background(isSelected ? Color.blue.opacity(0.08) : Color.white.opacity(0.34), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
		}
		.buttonStyle(.plain)
		.contextMenu {
			Button(action: onExport) {
				Label("导出", systemImage: "square.and.arrow.up")
			}
			Button(role: .destructive, action: onDelete) {
				Label("删除", systemImage: "trash")
			}
		}
	}

	private var documentSubtitle: String {
		let ext = document.originalFileExtension.isEmpty ? "txt" : document.originalFileExtension
		return "预览 \(document.previewDisplayName) · 保存 .\(ext)"
	}
}

private struct CompactEmptyState: View {
	var body: some View {
		VStack(spacing: 12) {
			Image(systemName: "doc.text.magnifyingglass")
				.font(.system(size: 44))
				.foregroundStyle(.tertiary)
			Text("暂无文档")
				.font(.headline)
			Text("新建文本，或从文件里导入一个文档。")
				.font(.subheadline)
				.foregroundStyle(.secondary)
				.multilineTextAlignment(.center)
		}
	}
}

private struct SimpleAlert: Identifiable {
	let id = UUID()
	let title: String
	let message: String
}

struct ExportItem: FileDocument, Identifiable {
	static var readableContentTypes: [UTType] { [.data] }

	let id = UUID()
	let url: URL
	let defaultFilename: String

	init(url: URL, defaultFilename: String) {
		self.url = url
		self.defaultFilename = defaultFilename
	}

	init(configuration: ReadConfiguration) throws {
		throw CocoaError(.fileReadUnknown)
	}

	func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
		let data = try Data(contentsOf: url)
		return FileWrapper(regularFileWithContents: data)
	}
}
