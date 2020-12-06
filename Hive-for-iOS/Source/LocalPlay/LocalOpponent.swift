//
//  LocalOpponent.swift
//  Hive-for-iOS
//
//  Created by Joseph Roque on 2020-12-05.
//  Copyright © 2020 Joseph Roque. All rights reserved.
//

import Foundation

enum LocalOpponent: Identifiable {
	case human
	case agent(AgentConfiguration)

	var name: String {
		switch self {
		case .human:
			return "Human"
		case .agent(let agent):
			return agent.name
		}
	}

	var id: UUID {
		switch self {
		case .human:
			return UUID(uuidString: "154b7a56-4520-405c-a44d-1257e20cae1a")!
		case .agent(let agent):
			return agent.id
		}
	}

	var user: Match.User {
		Match.User(id: id, displayName: name, elo: 0, avatarUrl: nil)
	}
}
