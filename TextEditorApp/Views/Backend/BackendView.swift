import SwiftUI

struct BackendView: View {
	private let githubRepo = URL(string: "https://github.com/5488-ux/text-editor")!

	var body: some View {
		ScrollView {
			VStack(spacing: 12) {
				overviewCard
				aboutCard
				changelogCard
				githubCard
			}
			.padding(16)
		}
		.background(LiquidGlassBackground())
		.navigationTitle("后台")
		.navigationBarTitleDisplayMode(.large)
	}

	private var overviewCard: some View {
		LiquidGlassCard {
			VStack(alignment: .leading, spacing: 10) {
				HStack {
					Label("总览", systemImage: "chart.bar.doc.horizontal").font(.headline)
					Spacer()
				}
				OverviewGrid()
			}
		}
	}

	private var aboutCard: some View {
		LiquidGlassCard {
			VStack(alignment: .leading, spacing: 10) {
				Label("公告 / 版本号", systemImage: "megaphone").font(.headline)
				Text("当前版本：\(Bundle.main.shortVersion) (\(Bundle.main.buildNumber))")
					.font(.subheadline)
					.foregroundStyle(.secondary)
				Text("公告：欢迎试用。连接服务器功能尚未开放。")
					.font(.subheadline)
			}
		}
	}

	private var changelogCard: some View {
		LiquidGlassCard {
			VStack(alignment: .leading, spacing: 10) {
				Label("更新日志", systemImage: "list.bullet.rectangle").font(.headline)
				Text("0.1.0\n- 支持导入任意文件并以 .txt 预览\n- 支持新建文本（自定义扩展名）\n- 支持导出时恢复原扩展名\n- 三栏底部导航：编辑 / 服务器 / 后台")
					.font(.subheadline)
					.foregroundStyle(.secondary)
					.frame(maxWidth: .infinity, alignment: .leading)
			}
		}
	}

	private var githubCard: some View {
		LiquidGlassCard {
			VStack(alignment: .leading, spacing: 10) {
				Label("GitHub 连接", systemImage: "link").font(.headline)
				Link(destination: githubRepo) { Text(githubRepo.absoluteString).font(.subheadline) }
			}
		}
	}
}

private struct OverviewGrid: View {
	@EnvironmentObject private var store: DocumentStore

	private var importedCount: Int { store.documents.filter { $0.origin == .imported }.count }
	private var createdCount: Int { store.documents.filter { $0.origin == .created }.count }

	var body: some View {
		Grid(horizontalSpacing: 12, verticalSpacing: 12) {
			GridRow {
				OverviewTile(title: "文档总数", value: "\(store.documents.count)", symbol: "doc.on.doc")
				OverviewTile(title: "导入", value: "\(importedCount)", symbol: "square.and.arrow.down")
			}
			GridRow {
				OverviewTile(title: "新建", value: "\(createdCount)", symbol: "square.and.pencil")
				OverviewTile(title: "本地", value: "沙盒存储", symbol: "internaldrive")
			}
		}
	}
}

private struct OverviewTile: View {
	let title: String
	let value: String
	let symbol: String

	var body: some View {
		VStack(alignment: .leading, spacing: 8) {
			HStack { Image(systemName: symbol).foregroundStyle(.secondary); Spacer() }
			Text(value).font(.title3.weight(.semibold))
			Text(title).font(.caption).foregroundStyle(.secondary)
		}
		.padding(12)
		.frame(maxWidth: .infinity, alignment: .leading)
		.background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
		.overlay(
			RoundedRectangle(cornerRadius: 16, style: .continuous)
				.strokeBorder(.white.opacity(0.16), lineWidth: 1)
		)
	}
}

private extension Bundle {
	var shortVersion: String { object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0.0.0" }
	var buildNumber: String { object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "0" }
}

