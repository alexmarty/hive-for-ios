//
//  User.swift
//  Hive-for-iOS
//
//  Created by Joseph Roque on 2020-03-30.
//  Copyright © 2020 Joseph Roque. All rights reserved.
//

import Foundation

struct User: Identifiable, Decodable, Equatable {
	static let anonymousUserDisplayName = "Anonymous"

	let id: UUID
	let displayName: String
	let elo: Int
	let avatarUrl: URL?
	let isGuest: Bool
	let activeMatches: [Match]?
	let pastMatches: [Match]?
}

#if DEBUG
extension User {
	static var users: [User] = [
		User(
			id: UUID(),
			displayName: "Joseph",
			elo: 1000,
			avatarUrl: nil, //URL(string: "https://avatars1.githubusercontent.com/u/6619581?v=4"),
			isGuest: false,
			activeMatches: Match.matches,
			pastMatches: Match.matches
		),
	]
}
#endif
