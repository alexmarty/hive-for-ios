//
//  HiveAPI.swift
//  Hive-for-iOS
//
//  Created by Joseph Roque on 2020-01-14.
//  Copyright © 2020 Joseph Roque. All rights reserved.
//

import Foundation
import Combine
import Loaf
import WebSocketKit

enum HiveAPIError: LocalizedError {
	case networkingError(Error)
	case invalidResponse
	case invalidHTTPResponse(Int)
	case invalidData
	case missingData
	case notImplemented
	case unauthorized

	var errorDescription: String {
		switch self {
		case .networkingError:
			return "Network error"
		case .invalidResponse, .invalidData:
			return "Could not parse response"
		case .unauthorized:
			return "Unauthorized"
		case .invalidHTTPResponse(let code):
			if (500..<600).contains(code) {
				return "Server error (\(code))"
			} else {
				return "Unexpected HTTP error (\(code))"
			}
		case .missingData:
			return "Could not find data"
		case .notImplemented:
			return "The method has not been implemented"
		}
	}

	var loaf: Loaf {
		Loaf(self.errorDescription, state: .error)
	}
}

typealias HiveAPIPromise<Success> = Future<Success, HiveAPIError>.Promise

class HiveAPI: ObservableObject {
	static let baseURL = URL(string: "https://db8560f4.ngrok.io")!

	private var apiGroup: URL { HiveAPI.baseURL.appendingPathComponent("api") }
	private var userGroup: URL { apiGroup.appendingPathComponent("users") }
	private var matchGroup: URL { apiGroup.appendingPathComponent("matches") }

	// MARK: - Authentication

	private var account: Account!
	private var tokenValidation: AnyCancellable?

	func setAccount(to account: Account) {
		self.account = account
		self.validateToken(in: account)
	}

	private func applyAuth(to request: inout URLRequest) {
		guard let token = account.token else { return }
		applyAuth(token: token, to: &request)
	}

	private func applyAuth(token: String, to request: inout URLRequest) {
		request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
	}

	private func validateToken(in account: Account) {
		guard let userId = account.userId, let token = account.token else { return }
		account.tokenStatus = .validating
		tokenValidation = checkToken(userId: userId, token: token)
			.receive(on: DispatchQueue.main)
			.sink(
				receiveCompletion: { [weak self] result in
					if case let .failure(error) = result {
						self?.handleValidationError(account: account, error: error)
					}
				},
				receiveValue: { result in
					account.tokenStatus = result ? .valid : .invalid
					account.isAuthenticated = result
				}
			)
	}

	private func handleValidationError(account: Account, error: HiveAPIError) {
		assert(Thread.isMainThread, "Account error not handled on the main thread")

		switch error {
		case .invalidData, .invalidResponse, .missingData, .notImplemented, .unauthorized:
			account.tokenStatus = .invalid
			try? account.clear()
		case .invalidHTTPResponse(let code):
			print("Token validation failed: \(code)")
			account.tokenStatus = .validationError
		case .networkingError(let networkError):
			print("Token validation failed: \(networkError)")
			account.tokenStatus = .validationError
		}
	}

	// MARK: - Users

	func login(login: LoginData) -> AnyPublisher<AccessToken, HiveAPIError> {
		Future { promise in
			let url = self.userGroup.appendingPathComponent("login")

			let auth = String(format: "%@:%@", login.email, login.password)
			let authData = auth.data(using: String.Encoding.utf8)!
			let base64Auth = authData.base64EncodedString()

			var request = self.buildBaseRequest(to: url, withAuth: false)
			request.httpMethod = "POST"
			request.setValue("Basic \(base64Auth)", forHTTPHeaderField: "Authorization")

			URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
				self?.handleResponse(data: data, response: response, error: error, promise: promise)
			}.resume()
		}
		.eraseToAnyPublisher()
	}

	func signup(signup: SignupData) -> AnyPublisher<UserSignup, HiveAPIError> {
		Future { promise in
			let url = self.userGroup.appendingPathComponent("signup")

			let encoder = JSONEncoder()
			guard let signupData = try? encoder.encode(signup) else {
				return promise(.failure(.invalidData))
			}

			var request = self.buildBaseRequest(to: url, withAuth: false)
			request.httpMethod = "POST"
			request.httpBody = signupData

			URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
				self?.handleResponse(data: data, response: response, error: error, promise: promise)
			}.resume()
		}
		.eraseToAnyPublisher()
	}

	func checkToken(userId: User.ID, token: String) -> AnyPublisher<Bool, HiveAPIError> {
		Future<TokenValidation, HiveAPIError> { promise in
			let url = self.userGroup.appendingPathComponent("validate")

			var request = self.buildBaseRequest(to: url, withAuth: false)
			request.httpMethod = "GET"
			self.applyAuth(token: token, to: &request)

			URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
				self?.handleResponse(data: data, response: response, error: error, promise: promise)
			}.resume()
		}
		.map { result in userId == result.userId }
		.eraseToAnyPublisher()
	}

	func logout() -> AnyPublisher<Bool, HiveAPIError> {
		Future { promise in
			let url = self.userGroup.appendingPathComponent("logout")

			var request = self.buildBaseRequest(to: url)
			request.httpMethod = "DELETE"

			URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
				self?.handleVoidResponse(data: data, response: response, error: error, promise: promise)
			}.resume()
		}
		.eraseToAnyPublisher()
	}

	// MARK: - Matches

	func openMatches() -> AnyPublisher<[Match], HiveAPIError> {
		Future { promise in
			let url = self.matchGroup.appendingPathComponent("open")

			var request = self.buildBaseRequest(to: url)
			request.httpMethod = "GET"

			URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
				self?.handleResponse(data: data, response: response, error: error, promise: promise)
			}.resume()
		}
		.eraseToAnyPublisher()
	}

	func matchDetails(id: Match.ID) -> AnyPublisher<Match, HiveAPIError> {
		Future { promise in
			let url = self.matchGroup.appendingPathComponent(id.uuidString)

			var request = self.buildBaseRequest(to: url)
			request.httpMethod = "GET"

			URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
				self?.handleResponse(data: data, response: response, error: error, promise: promise)
			}.resume()
		}
		.eraseToAnyPublisher()
	}

	func joinMatch(id: Match.ID) -> AnyPublisher<JoinMatchResponse, HiveAPIError> {
		Future { promise in
			let url = self.matchGroup
				.appendingPathComponent(id.uuidString)
				.appendingPathComponent("join")

			var request = self.buildBaseRequest(to: url)
			request.httpMethod = "POST"

			URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
				self?.handleResponse(data: data, response: response, error: error, promise: promise)
			}.resume()
		}
		.eraseToAnyPublisher()
	}

	func createMatch() -> AnyPublisher<CreateMatchResponse, HiveAPIError> {
		Future { promise in
			let url = self.matchGroup.appendingPathComponent("new")

			var request = self.buildBaseRequest(to: url)
			request.httpMethod = "POST"

			URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
				self?.handleResponse(data: data, response: response, error: error, promise: promise)
			}.resume()
		}
		.eraseToAnyPublisher()
	}

	// MARK: - Common

	private func buildBaseRequest(to url: URL, withAuth: Bool = true) -> URLRequest {
		var request = URLRequest(url: url)
		request.addValue("application/json", forHTTPHeaderField: "Content-Type")
		request.addValue("application/json", forHTTPHeaderField: "Accept")
		if withAuth {
			applyAuth(to: &request)
		}
		return request
	}

	private func handleResponse<Result: Decodable>(
		data: Data?,
		response: URLResponse?,
		error: Error?,
		promise: HiveAPIPromise<Result>
	) {
		guard error == nil else {
			return promise(.failure(.networkingError(error!)))
		}

		guard let response = response as? HTTPURLResponse else {
			return promise(.failure(.invalidResponse))
		}

		guard (200..<400).contains(response.statusCode) else {
			if response.statusCode == 401 {
				try? account.clear()
				return promise(.failure(.unauthorized))
			}
			return promise(.failure(.invalidHTTPResponse(response.statusCode)))
		}

		let decoder = JSONDecoder()
		decoder.dateDecodingStrategy = .iso8601
		guard let data = data, let result = try? decoder.decode(Result.self, from: data) else {
			return promise(.failure(.invalidData))
		}

		promise(.success(result))
	}

	private func handleVoidResponse(data: Data?, response: URLResponse?, error: Error?, promise: HiveAPIPromise<Bool>) {
		guard error == nil else {
			return promise(.failure(.networkingError(error!)))
		}

		guard let response = response as? HTTPURLResponse else {
			return promise(.failure(.invalidResponse))
		}

		guard (200..<400).contains(response.statusCode) else {
			if response.statusCode == 401 {
				try? account.clear()
				return promise(.failure(.unauthorized))
			}
			return promise(.failure(.invalidHTTPResponse(response.statusCode)))
		}

		promise(.success(true))
	}
}

//#if DEBUG
//class MockHiveAPI: HiveAPI {
//	func login(login: LoginData) -> AnyPublisher<AccessToken, HiveAPIError> {
//		PassthroughSubject().eraseToAnyPublisher()
//	}
//
//	func signup(signup: SignupData) -> AnyPublisher<UserSignup, HiveAPIError> {
//		PassthroughSubject().eraseToAnyPublisher()
//	}
//
//	func checkToken(userId: User.ID, token: String) -> AnyPublisher<Bool, HiveAPIError> {
//		PassthroughSubject().eraseToAnyPublisher()
//	}
//
//	func logout() -> AnyPublisher<Bool, HiveAPIError> {
//		PassthroughSubject().eraseToAnyPublisher()
//	}
//
//	func openMatches() -> AnyPublisher<[Match], HiveAPIError> {
//		PassthroughSubject().eraseToAnyPublisher()
//	}
//
//	func matchDetails(id: Match.ID) -> AnyPublisher<Match, HiveAPIError> {
//		PassthroughSubject().eraseToAnyPublisher()
//	}
//
//	func joinMatch(id: Match.ID) -> AnyPublisher<JoinMatchResponse, HiveAPIError> {
//		PassthroughSubject().eraseToAnyPublisher()
//	}
//
//	func createMatch() -> AnyPublisher<CreateMatchResponse, HiveAPIError> {
//		PassthroughSubject().eraseToAnyPublisher()
//	}
//}
//#endif
