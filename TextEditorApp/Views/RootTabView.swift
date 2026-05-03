import SwiftUI

struct RootTabView: View {
	var body: some View {
		TabView {
			NavigationStack { EditorHomeView() }
				.tabItem { Label("编辑", systemImage: "doc.text") }

			NavigationStack { ServerView() }
				.tabItem { Label("服务器", systemImage: "antenna.radiowaves.left.and.right") }

			NavigationStack { BackendView() }
				.tabItem { Label("后台", systemImage: "gearshape") }
		}
		.tint(.accentColor)
	}
}

