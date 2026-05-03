import SwiftUI

struct LiquidGlassBackground: View {
	var body: some View {
		Rectangle()
			.fill(.ultraThinMaterial)
			.ignoresSafeArea()
			.overlay {
				LinearGradient(
					colors: [
						Color.accentColor.opacity(0.14),
						Color.cyan.opacity(0.10),
						Color.purple.opacity(0.10)
					],
					startPoint: .topLeading,
					endPoint: .bottomTrailing
				)
				.blendMode(.plusLighter)
				.ignoresSafeArea()
			}
	}
}

struct LiquidGlassCard<Content: View>: View {
	@ViewBuilder var content: Content

	var body: some View {
		content
			.padding(14)
			.background(.thinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
			.overlay(
				RoundedRectangle(cornerRadius: 22, style: .continuous)
					.strokeBorder(.white.opacity(0.16), lineWidth: 1)
			)
			.shadow(color: .black.opacity(0.10), radius: 14, x: 0, y: 8)
	}
}

