import SwiftUI

@main
struct TextEditorApp: App {
	@StateObject private var store = DocumentStore()

	var body: some Scene {
		WindowGroup {
			RootTabView()
				.environmentObject(store)
		}
	}
}

