//
//  GameClient.swift
//  Hive-for-iOS
//
//  Created by Joseph Roque on 2020-01-24.
//  Copyright © 2020 Joseph Roque. All rights reserved.
//

import Combine
import Foundation
import HiveEngine
import Starscream

enum GameClientEvent {
	case message(GameServerMessage)
	case connected
	case alreadyConnected
	case closed(String, UInt16)
}

enum GameClientError: LocalizedError {
	case usingOfflineAccount
	case notPrepared
	case failedToConnect
	case missingURL
	case webSocketError(Error?)
}

enum GameClientConfiguration {
	case offline(GameState, Player, AgentConfiguration)
	case online(URL, Account?)
}

protocol GameClient {
	var subject: PassthroughSubject<GameClientEvent, GameClientError>? { get }
	var isConnected: Bool { get }
	var isPrepared: Bool { get }

	func prepare(configuration: GameClientConfiguration)
	func openConnection() -> AnyPublisher<GameClientEvent, GameClientError>
	func reconnect() -> AnyPublisher<GameClientEvent, GameClientError>
	func close()
	func send(_ message: GameClientMessage)
}
