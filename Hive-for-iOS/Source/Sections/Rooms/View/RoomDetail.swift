//
//  RoomDetailView.swift
//  Hive-for-iOS
//
//  Created by Joseph Roque on 2020-01-15.
//  Copyright © 2020 Joseph Roque. All rights reserved.
//

import SwiftUI
import HiveEngine

struct RoomDetail: View {
	@ObservedObject private var viewModel: RoomDetailViewModel
	@State private var inGame = false

	init(viewModel: RoomDetailViewModel) {
		self.viewModel = viewModel
	}

	var startButton: some View {
		NavigationLink(
			destination: GameContainer(isActive: self.$inGame, state: self.viewModel.gameState),
			isActive: self.$inGame
		) {
			Text("Start")
		}
	}

	private func playerSection(room: Room) -> some View {
		HStack(spacing: 0) {
			Spacer()
			PlayerPreview(room.host, iconSize: Metrics.Image.larger)
			Spacer()
			PlayerPreview(room.host, alignment: .trailing, iconSize: Metrics.Image.larger)
			Spacer()
		}
	}

	private func expansionSection(options: GameOptionData) -> some View {
		VStack(alignment: .leading) {
			Text("Expansions")
				.font(.system(size: Metrics.Text.subtitle))
				.foregroundColor(.text)
			ForEach(GameState.Options.expansions, id: \.rawValue) { option in
				Toggle(option.rawValue, isOn: self.viewModel.options.binding(for: option))
					.foregroundColor(Assets.Color.text.color)
			}
		}
	}

	private func otherOptionsSection(options: GameOptionData) -> some View {
		VStack(alignment: .leading) {
			Text("Other options")
				.font(.system(size: Metrics.Text.subtitle))
				.foregroundColor(.text)
			ForEach(GameState.Options.nonExpansions, id: \.rawValue) { option in
				Toggle(option.rawValue, isOn: self.viewModel.options.binding(for: option))
					.foregroundColor(Assets.Color.text.color)
			}
		}
	}

	var body: some View {
		List {
			if self.viewModel.room == nil {
				Text("Loading")
			} else {
				self.playerSection(room: self.viewModel.room!)
					.padding(.vertical, Metrics.Spacing.standard)
				self.expansionSection(options: self.viewModel.options)
				self.otherOptionsSection(options: self.viewModel.options)
			}
		}
		.navigationBarTitle(Text("Room \(viewModel.roomId)"), displayMode: .inline)
		.navigationBarItems(trailing: startButton)
		.onAppear { self.viewModel.postViewAction(.onAppear) }
		.onDisappear { self.viewModel.postViewAction(.onDisappear) }
		.loaf(self.$viewModel.errorLoaf)
	}
}

private extension GameState.Options {
	var preview: String? {
		switch self {
		case .mosquito: return "M"
		case .ladyBug: return "L"
		case .pillBug: return "P"
		default: return nil
		}
	}
}

#if DEBUG
struct RoomDetailPreview: PreviewProvider {
	static var previews: some View {
		RoomDetail(viewModel: RoomDetailViewModel(room: Room.rooms[0]))
	}
}
#endif
