import SwiftUI
import UniformTypeIdentifiers

struct EditorHomeView: View {
	@EnvironmentObject private var store: DocumentStore
	@Environment(\.horizontalSizeClass) private var horizontalSizeClass

	@State private var isImporterPresented = false
	@State private var isNewPresented = false
	@State private var isExporterPresented = false
	@State private var exportItem: ExportItem?
	@State private var alert: SimpleAlert?

	var body: some View {
		VStack(spacing: 12) {
			header
			content
		}
		.padding(.horizontal, 16)
		.padding(.top, 12)
		.background(LiquidGlassBackground())
		.navigationTitle("文本编辑")
		.navigationBarTitleDisplayMode(.large)
		.toolbar {
			ToolbarItemGroup(placement: .topBarTrailing) {
				Button { isNewPresented = true } label: { Image(systemName: "square.and.pencil") }
				Button { isImporterPresented = true } label: { Image(systemName: "square.and.arrow.down") }
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
					_ = try await store.importFile(from: url)
				} catch {
					alert = SimpleAlert(title: "导入失败", message: error.localizedDescription)
				}
			}
		}
		.sheet(isPresented: $isNewPresented) {
			NewDocumentSheet { title, ext, text in
				Task { @MainActor in
					do {
						_ = try await store.createNew(title: title, fileExtension: ext, initialText: text)
					} catch {
						alert = SimpleAlert(title: "新建失败", message: error.localizedDescription)
					}
				}
			}
			.presentationDetents([.medium, .large])
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

	private var content: some View {
		if horizontalSizeClass == .compact {
			VStack(spacing: 12) {
				documentList
					.frame(maxHeight: 320)
				editorPanel
			}
		} else {
			HStack(spacing: 12) {
				documentList
					.frame(minWidth: 320, maxWidth: 420)
				editorPanel
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
					ContentUnavailableView("暂无文档", systemImage: "doc", description: Text("右上角导入文件，或新建一个文本。"))
						.frame(maxWidth: .infinity, minHeight: 240)
				} else {
					List(selection: $store.selectedDocumentID) {
						ForEach(store.documents) { doc in
							VStack(alignment: .leading, spacing: 3) {
								Text(doc.title).font(.body).lineLimit(1)
								Text("预览：\(doc.previewDisplayName)")
									.font(.caption)
									.foregroundStyle(.secondary)
							}
							.tag(doc.id)
							.contextMenu {
								Button {
									do {
										let url = try store.exportURL(for: doc.id)
										exportItem = ExportItem(url: url, defaultFilename: doc.originalDisplayName)
										isExporterPresented = true
									} catch {
										alert = SimpleAlert(title: "导出失败", message: error.localizedDescription)
									}
								} label: {
									Label("导出", systemImage: "square.and.arrow.up")
								}

								Button(role: .destructive) {
									store.delete(id: doc.id)
								} label: {
									Label("删除", systemImage: "trash")
								}
							}
						}
						.onDelete { indexSet in
							for index in indexSet {
								guard index < store.documents.count else { continue }
								store.delete(id: store.documents[index].id)
							}
						}
					}
					.listStyle(.plain)
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
					do {
						let url = try store.exportURL(for: doc.id)
						exportItem = ExportItem(url: url, defaultFilename: doc.originalDisplayName)
						isExporterPresented = true
					} catch {
						alert = SimpleAlert(title: "导出失败", message: error.localizedDescription)
					}
				}
			} else {
				ContentUnavailableView("未选择文档", systemImage: "cursorarrow.click", description: Text("从左侧列表选择一个文档开始编辑。"))
					.frame(maxWidth: .infinity, minHeight: 240)
			}
		}
		.frame(maxWidth: .infinity)
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
