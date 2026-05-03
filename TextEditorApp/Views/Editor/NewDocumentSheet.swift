import SwiftUI

struct NewDocumentSheet: View {
	let onCreate: (String, String, String) -> Void

	@Environment(\.dismiss) private var dismiss

	@State private var title = ""
	@State private var ext = "txt"
	@State private var text = ""

	var body: some View {
		NavigationStack {
			Form {
				Section("名称") {
					TextField("例如：Notes", text: $title)
						.textInputAutocapitalization(.never)
						.autocorrectionDisabled()
				}
				Section("格式") {
					TextField("例如：txt / md / json", text: $ext)
						.textInputAutocapitalization(.never)
						.autocorrectionDisabled()
				}
				Section("内容") {
					TextEditor(text: $text)
						.frame(minHeight: 160)
						.font(.system(.body, design: .monospaced))
				}
			}
			.navigationTitle("新建文本")
			.navigationBarTitleDisplayMode(.inline)
			.toolbar {
				ToolbarItem(placement: .cancellationAction) {
					Button("取消") { dismiss() }
				}
				ToolbarItem(placement: .confirmationAction) {
					Button("创建") {
						onCreate(title, ext, text)
						dismiss()
					}
					.disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
				}
			}
		}
	}
}

