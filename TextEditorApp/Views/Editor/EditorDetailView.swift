import SwiftUI

struct EditorDetailView: View {
	let document: EditableDocument
	let onChange: (String) -> Void
	let onExport: () -> Void

	@State private var text: String
	@State private var isShowingInfo = false

	init(document: EditableDocument, onChange: @escaping (String) -> Void, onExport: @escaping () -> Void) {
		self.document = document
		self.onChange = onChange
		self.onExport = onExport
		self._text = State(initialValue: document.lastKnownText)
	}

	var body: some View {
		VStack(alignment: .leading, spacing: 12) {
			HStack(spacing: 10) {
				VStack(alignment: .leading, spacing: 2) {
					Text(document.title).font(.headline).lineLimit(1)
					Text("预览：\(document.previewDisplayName)")
						.font(.caption)
						.foregroundStyle(.secondary)
				}
				Spacer()
				Button { onExport() } label: { Label("导出", systemImage: "square.and.arrow.up") }
					.buttonStyle(.bordered)
				Button { isShowingInfo.toggle() } label: { Image(systemName: "info.circle") }
					.buttonStyle(.borderless)
					.popover(isPresented: $isShowingInfo) {
						infoView.presentationCompactAdaptation(.popover)
					}
			}

			Divider().opacity(0.6)

			TextEditor(text: $text)
				.font(.system(.body, design: .monospaced))
				.scrollContentBackground(.hidden)
				.padding(12)
				.background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
				.overlay(
					RoundedRectangle(cornerRadius: 16, style: .continuous)
						.strokeBorder(.white.opacity(0.18), lineWidth: 1)
				)
				.onChange(of: text) { _, newValue in
					onChange(newValue)
				}
		}
		.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
	}

	private var infoView: some View {
		VStack(alignment: .leading, spacing: 8) {
			Text("文件信息").font(.headline)
			Text("原始：\(document.originalDisplayName)").font(.subheadline)
			Text("保存时将使用原扩展名：\(document.originalFileExtension.isEmpty ? "txt" : document.originalFileExtension)")
				.font(.subheadline)
			Text("内容类型：\(document.isLikelyText ? "文本" : "二进制/不确定（以文本形式预览）")")
				.font(.subheadline)
				.foregroundStyle(.secondary)
		}
		.padding(16)
		.frame(width: 360)
	}
}

