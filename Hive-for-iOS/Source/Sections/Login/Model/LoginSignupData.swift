//
//  LoginSignupData.swift
//  Hive-for-iOS
//
//  Created by Joseph Roque on 2020-03-30.
//  Copyright © 2020 Joseph Roque. All rights reserved.
//

struct LoginSignupData {
	let email: String
	let displayName: String
	let password: String
	let verifyPassword: String

	var login: LoginData {
		LoginData(email: email, password: password)
	}

	var signup: SignupData {
		SignupData(email: email, displayName: displayName, password: password, verifyPassword: verifyPassword)
	}
}

struct LoginData: Codable {
	let email: String
	let password: String
}

struct SignupData: Codable {
	let email: String
	let displayName: String
	let password: String
	let verifyPassword: String
}
