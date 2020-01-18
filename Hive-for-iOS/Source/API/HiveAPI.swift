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

enum HiveAPIError: LocalizedError {
	case networkingError(Error)
	case invalidResponse
	case invalidHTTPResponse(Int)
	case invalidData
	case missingData

	var errorDescription: String {
		switch self {
		case .networkingError:
			return "Network error"
		case .invalidResponse, .invalidData:
			return "Could not parse response"
		case .invalidHTTPResponse(let code):
			if (500..<600).contains(code) {
				return "Server error (\(code))"
			} else {
				return "Unexpected HTTP error (\(code))"
			}
		case .missingData:
			return "Could not find data"
		}
	}

	var loaf: Loaf {
		return Loaf(self.errorDescription, state: .error)
	}
}

typealias HiveAPIPromise<Success> = Future<Success, HiveAPIError>.Promise

struct HiveAPI {

	static let shared = HiveAPI()

	private init() { }

	// MARK: - Rooms

	func rooms() -> Future<[Room], HiveAPIError> {
		print("Fetching rooms")
		return Future { promise in
			if Bool.random() == true {
				print("Returning rooms")
				promise(.success(Room.rooms))
			} else {
				print("Returning error")
				promise(.failure(.invalidResponse))
			}
		}
	}

	func room(id: String) -> Future<Room, HiveAPIError> {
		print("Fetching room \(id)")
		return Future { promise in
			if let room = Room.rooms.first(where: { $0.id == id }) {
				promise(.success(room))
			} else {
				promise(.failure(.invalidData))
			}
		}
	}

	// MARK: - Common

	private func handleResponse<Result: Codable>(data: Data?, response: URLResponse?, error: Error?, promise: HiveAPIPromise<Result>) {
		guard error == nil else {
			promise(.failure(.networkingError(error!)))
			return
		}

		guard let response = response as? HTTPURLResponse else {
			promise(.failure(.invalidResponse))
			return
		}

		guard (200..<400).contains(response.statusCode) else {
			promise(.failure(.invalidHTTPResponse(response.statusCode)))
			return
		}

		let decoder = JSONDecoder()
		guard let data = data, let result = try? decoder.decode(Result.self, from: data) else {
			promise(.failure(.invalidData))
			return
		}

		promise(.success(result))
	}

	private func handleVoidResponse(data: Data?, response: URLResponse?, error: Error?, promise: HiveAPIPromise<Bool>) {
		guard error == nil else {
			promise(.failure(.networkingError(error!)))
			return
		}

		guard let response = response as? HTTPURLResponse else {
			promise(.failure(.invalidResponse))
			return
		}

		guard (200..<400).contains(response.statusCode) else {
			promise(.failure(.invalidHTTPResponse(response.statusCode)))
			return
		}

		promise(.success(true))
	}
}
