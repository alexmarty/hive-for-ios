//
//  LobbyRow.swift
//  Hive-for-iOS
//
//  Created by Joseph Roque on 2020-01-14.
//  Copyright © 2020 Joseph Roque. All rights reserved.
//

import SwiftUI
import HiveEngine

struct LobbyRow: View {
	let match: Match

	private func optionsPreview(for options: Set<GameState.Option>) -> some View {
		HStack(spacing: .s) {
			ForEach(GameState.Option.expansions, id: \.rawValue) { option in
				optionPreview(for: option, enabled: options.contains(option))
			}
		}
	}

	private func optionPreview(for option: GameState.Option, enabled: Bool) -> some View {
		ZStack {
			Text(option.preview ?? "")
				.font(.caption)
				.foregroundColor(enabled
					? Color(.textRegular)
					: Color(.textSecondary)
				)
			Hex()
				.stroke(
					enabled
						? Color(.highlightPrimary)
						: Color(.highlightPrimary).opacity(0.4),
					lineWidth: CGFloat(2)
				)
				.squareImage(.m)
		}
	}

	var body: some View {
		VStack(alignment: .leading, spacing: Metrics.Spacing.s.rawValue) {
			HStack(spacing: .m) {
				UserPreview(match.host?.summary)
					.foregroundColor(Color(.textRegular))
				Spacer()
				optionsPreview(for: match.gameOptionSet)
			}
			if let formattedDate = match.createdAt?.formatted {
				Text("Created \(formattedDate)")
					.font(.caption2)
					.foregroundColor(Color(.textSecondary))
			}
		}
	}
}

private extension GameState.Option {
	var preview: String? {
		switch self {
		case .mosquito: return "M"
		case .ladyBug: return "L"
		case .pillBug: return "P"
		case .noFirstMoveQueen, .allowSpecialAbilityAfterYoink: return nil
		}
	}
}

private extension Date {
	var formatted: String {
		RelativeDateTimeFormatter().localizedString(for: self, relativeTo: Date())
	}
}

// MARK: - Preview

#if DEBUG
struct LobbyRowPreview: PreviewProvider {
	static var previews: some View {
		List {
			LobbyRow(match: Match.matches[0])
			LobbyRow(match: Match.matches[1])
		}
	}
}
#endif
