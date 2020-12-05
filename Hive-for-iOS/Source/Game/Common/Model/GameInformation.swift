//
//  GameInformation.swift
//  Hive-for-iOS
//
//  Created by Joseph Roque on 2020-01-24.
//  Copyright © 2020 Joseph Roque. All rights reserved.
//

import SwiftUI
import HiveEngine

enum GameInformation {
	case playerHand(PlayerHand)
	case pieceClass(Piece.Class)
	case stack([Piece])
	case rule(GameRule?)
	case gameEnd(EndState)
	case settings
	case playerMustPass
	case reconnecting(Int)

	init?(fromLink link: String) {
		if link.starts(with: "class:"), let pieceClass = Piece.Class(fromName: String(link.substring(from: 6))) {
			self = .pieceClass(pieceClass)
		} else if link.starts(with: "rule:"), let rule = GameRule(rawValue: String(link.substring(from: 5))) {
			self = .rule(rule)
		} else {
			return nil
		}
	}

	var stack: [Piece]? {
		guard case let .stack(stack) = self else { return nil }
		return stack
	}

	var title: String {
		switch self {
		case .playerHand(let hand): return (hand.isPlayerHand ? "Your" : "Opponent's") + " hand"
		case .pieceClass(let pieceClass): return pieceClass.description
		case .stack: return "Pieces in stack"
		case .rule(let rule): return rule?.title ?? "All rules"
		case .gameEnd(let state):
			if let player = state.winner {
				return "\(player) wins!"
			} else {
				return "It's a tie!"
			}
		case .settings: return "Settings"
		case .playerMustPass: return "No moves available"
		case .reconnecting: return "Disconnected from server"
		}
	}

	var subtitle: String? {
		switch self {
		case .playerHand(let hand): return hand.player.description
		case .pieceClass(let pieceClass): return pieceClass.rules
		case .rule(let rule): return rule?.description
		case .stack: return
			"The following pieces have been [stacked](rule:stacks). A stack's color is identical to the piece " +
				"on top. Only the top piece can be moved, and [mosquitoes](class:Mosquito) can only copy the top piece."
		case .gameEnd(let state):
			var subtitle: String
			if let winner = state.winner {
				if state.wasForfeit {
					if let playingAs = state.playingAs {
						subtitle = "\(playingAs == winner ? "Your opponent has" : "You have") forfeit!"
					} else {
						subtitle = "\(winner.next) has forfeit!"
					}
				} else {
					if let playingAs = state.playingAs {
						subtitle = "\(playingAs == winner ? "You have" : "Your opponent has") surrounded " +
							"\(playingAs == winner ? "your opponent's" : "your") queen and won the game!"
					} else {
						subtitle = "\(winner) has surrounded \(winner.next)'s queen and won the game!"
					}
				}
			} else {
				subtitle = "Both queens have been surrounded in the same turn, which means it's a tie!"
			}

			if state.playingAs == nil {
				subtitle += " Return to the lobby to watch another game."
			} else {
				subtitle += " Return to the lobby to play another game."
			}

			return subtitle
		case .reconnecting(let attempts):
			return "The connection to the server has been lost. The game will automatically attempt to reconnect, " +
				"but if a connection cannot be made, you will forfeit the match. This dialog will dismiss " +
				"automatically if the connection is restored.\n" +
				"Please wait (\(attempts)/\(OnlineGameClient.maxReconnectAttempts))."
		case .playerMustPass:
			return "Abiding by the rules of the game, there is nowhere for you to place a new piece, " +
				"or move an existing piece on the board. You are considered blocked and must [pass](rule:Passing) this turn. " +
				"Your opponent will move again. Dismiss this dialog or tap below to pass your turn."
		case .settings: return nil
		}
	}

	var prefersMarkdown: Bool {
		switch self {
		case .playerHand, .settings: return false
		case .pieceClass, .rule, .stack, .gameEnd, .reconnecting, .playerMustPass: return true
		}
	}

	var dismissable: Bool {
		switch self {
		case .reconnecting: return false
		case .gameEnd, .pieceClass, .playerHand, .rule, .stack, .settings, .playerMustPass: return true
		}
	}

	var hasCloseButton: Bool {
		switch self {
		case .gameEnd, .playerMustPass: return false
		case .pieceClass, .playerHand, .rule, .stack, .settings, .reconnecting: return true
		}
	}
}

// MARK: EndState

extension GameInformation {
	struct EndState {
		let winner: Player?
		let playingAs: Player?
		let wasForfeit: Bool
	}
}

// MARK: PlayerHand

extension GameInformation {
	struct PlayerHand {
		let player: Player
		let playingAs: Player
		let piecesInHand: [Piece]

		var isPlayerHand: Bool {
			playingAs == player
		}

		init(player: Player, playingAs: Player, state: GameState) {
			self.player = player
			self.playingAs = playingAs
			self.piecesInHand = Array(state.unitsInHand[player] ?? []).sorted()
		}
	}
}
