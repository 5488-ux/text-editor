import SwiftUI

struct ServerView: View {
	var body: some View {
		VStack(spacing: 16) {
			Image(systemName: "wrench.and.screwdriver")
				.font(.system(size: 42))
				.foregroundStyle(.secondary)
			Text("测试功能未开放").font(.title3)
			Text("这里将用于连接服务器（占位页）。")
				.foregroundStyle(.secondary)
		}
		.frame(maxWidth: .infinity, maxHeight: .infinity)
		.padding(24)
		.background(LiquidGlassBackground())
		.navigationTitle("连接服务器")
		.navigationBarTitleDisplayMode(.large)
	}
}

