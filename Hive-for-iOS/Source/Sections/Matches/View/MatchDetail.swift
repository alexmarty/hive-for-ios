//
//  MatchDetail.swift
//  Hive-for-iOS
//
//  Created by Joseph Roque on 2020-01-15.
//  Copyright © 2020 Joseph Roque. All rights reserved.
//

import SwiftUI
import HiveEngine

struct MatchDetail: View {
	private let initialId: Match.ID?

	@Environment(\.presentationMode) var presentationMode
	@EnvironmentObject private var account: Account
	@EnvironmentObject private var api: HiveAPI
	@ObservedObject private var viewModel: MatchDetailViewModel
	private var gameViewModel = HiveGameViewModel()

	@State private var inGame: Bool = false
	@State private var exiting: Bool = false

	init(id: Match.ID?) {
		self.initialId = id
		self.viewModel = MatchDetailViewModel(nil)
	}

	private func playerSection(match: Match) -> some View {
		HStack(spacing: 0) {
			MatchUserSummary(
				match.host,
				isReady: self.viewModel.isPlayerReady(id: match.host?.id),
				iconSize: .l
			)
			Spacer()
			MatchUserSummary(
				match.opponent,
				isReady: self.viewModel.isPlayerReady(id: match.opponent?.id),
				alignment: .trailing,
				iconSize: .l
			)
		}
	}

	var expansionSection: some View {
		VStack(alignment: .leading) {
			Text("Expansions")
				.bold()
				.body()
				.foregroundColor(Color(.text))
				.frame(minWidth: 0, maxWidth: .infinity, alignment: .center)
			HStack(spacing: .l) {
				Spacer()
				ForEach(GameState.Option.expansions, id: \.rawValue) { option in
					self.expansionOption(for: option, enabled: self.viewModel.gameOptions.contains(option))
				}
				Spacer()
			}
		}
	}

	private func expansionOption(for option: GameState.Option, enabled: Bool) -> some View {
		Button(action: {
			self.viewModel.optionEnabled(option: option).wrappedValue.toggle()
		}, label: {
			ZStack {
				Text(option.preview ?? "")
					.subtitle()
					.foregroundColor(
						enabled
							? Color(.primary)
							: Color(.textSecondary)
					)
				Hex()
					.stroke(
						enabled
							? Color(.primary)
							: Color(.textSecondary),
						lineWidth: CGFloat(5)
					)
					.squareImage(.l)
			}
		})
		.disabled(!viewModel.userIsHost)
	}

	private var otherOptionsSection: some View {
		VStack(alignment: .leading) {
			Text("Other options")
				.bold()
				.body()
				.foregroundColor(Color(.text))
				.frame(minWidth: 0, maxWidth: .infinity, alignment: .center)
			ForEach(GameState.Option.nonExpansions, id: \.rawValue) { option in
				Toggle(option.rawValue, isOn: self.viewModel.optionEnabled(option: option))
					.disabled(!self.viewModel.userIsHost)
					.foregroundColor(Color(.text))
			}
		}
	}

	private var exitButton: some View {
		Button(action: {
			self.exiting = true
		}, label: {
			Text("Leave")
		})
	}

	private var startButton: some View {
		if viewModel.showStartButton {
			return AnyView(Button(action: {
				self.viewModel.postViewAction(.startGame)
			}, label: {
				Text(viewModel.startButtonText)
			}))
		} else {
			return AnyView(EmptyView())
		}
	}

	var body: some View {
		ScrollView {
			NavigationLink(
				destination: HiveGame(
					onGameEnd: { self.presentationMode.wrappedValue.dismiss() },
					stateBuilder: { self.viewModel.gameState }
				).environmentObject(gameViewModel),
				isActive: self.$inGame,
				label: { EmptyView() }
			)

			if self.viewModel.match == nil {
				Text("Loading")
			} else {
				VStack(spacing: .m) {
					self.playerSection(match: self.viewModel.match!)
					Divider().background(Color(.divider))
					self.expansionSection
					Divider().background(Color(.divider))
					self.otherOptionsSection
				}
			}
		}
		.padding(.horizontal, length: .m)
		.navigationBarTitle(Text(viewModel.navigationBarTitle), displayMode: .inline)
		.navigationBarItems(leading: exitButton)
		.navigationBarItems(trailing: startButton)
		.onAppear {
			self.viewModel.setAccount(to: self.account)
			self.viewModel.setAPI(to: self.api)
			self.viewModel.postViewAction(.onAppear(self.initialId))
		}
		.onDisappear { self.viewModel.postViewAction(.onDisappear) }
		.onReceive(self.viewModel.$gameState) {
			self.gameViewModel.setAccount(to: self.account)
			self.gameViewModel.setClient(to: self.viewModel.client)
			self.inGame = $0 != nil
		}
		.onReceive(self.viewModel.leavingMatch) {
			self.presentationMode.wrappedValue.dismiss()
		}
		.popoverSheet(isPresented: self.$exiting) {
			PopoverSheetConfig(
				title: "Leave match?",
				message: "Are you sure you want to leave this match?",
				buttons: [
					PopoverSheetConfig.ButtonConfig(title: "Leave", type: .destructive) {
						self.viewModel.postViewAction(.exitGame)
					},
					PopoverSheetConfig.ButtonConfig(title: "Stay", type: .cancel) {
						self.exiting = false
					},
				]
			)
		}
		.loaf(self.$viewModel.errorLoaf)
	}
}

private extension GameState.Option {
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
struct MatchDetailPreview: PreviewProvider {
	static var previews: some View {
		let account = Account()
		let api = HiveAPI(account: account)

		return MatchDetail(id: nil)
			.environmentObject(account)
			.environmentObject(api)
			.background(Color(.background).edgesIgnoringSafeArea(.all))
//		MatchDetail(viewModel: MatchDetailViewModel(match: Match.matches[1]))
//			.background(Color(.background).edgesIgnoringSafeArea(.all))
	}
}
#endif
