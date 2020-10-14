//
//  SettingsListViewModel.swift
//  Hive-for-iOS
//
//  Created by Joseph Roque on 2020-05-17.
//  Copyright © 2020 Joseph Roque. All rights reserved.
//

import Combine
import SwiftUI

enum SettingsListViewAction: BaseViewAction {
	case onAppear
	case switchGameMode(current: Preferences.GameMode)

	case logout
	case exit
}

enum SettingsListAction: BaseAction {
	case loadProfile
	case setGameMode(Preferences.GameMode)
	case logout
	case closeSettings
}

class SettingsListViewModel: ViewModel<SettingsListViewAction>, ObservableObject {
	@Published var logoutResult: Loadable<Bool> {
		didSet {
			switch logoutResult {
			case .failed, .loaded:
				actions.send(.closeSettings)
				showAccount = false
			case .loading, .notLoaded:
				break
			}
		}
	}

	@Published var user: Loadable<User>
	@Published var showAttributions: Bool = false
	@Published var showAccount: Bool
	@Published var preferences = Preferences()
	@Published var needsRefresh: Bool = false {
		didSet {
			guard needsRefresh else { return }
			needsRefresh = false
		}
	}

	private let actions = PassthroughSubject<SettingsListAction, Never>()
	var actionsPublisher: AnyPublisher<SettingsListAction, Never> {
		actions.eraseToAnyPublisher()
	}

	init(user: Loadable<User>, logoutResult: Loadable<Bool>, showAccount: Bool) {
		_user = .init(initialValue: user)
		_logoutResult = .init(initialValue: logoutResult)
		self.showAccount = showAccount
	}

	override func postViewAction(_ viewAction: SettingsListViewAction) {
		switch viewAction {
		case .onAppear:
			actions.send(.loadProfile)
		case .switchGameMode(let current):
			switchGameMode(from: current)

		case .exit:
			actions.send(.closeSettings)
		case .logout:
			actions.send(.logout)
		}
	}

	private func switchGameMode(from gameMode: Preferences.GameMode) {
		let next: Preferences.GameMode
		switch gameMode {
		case .ar: next = .sprite
		case .sprite: next = .ar
		}

		actions.send(.setGameMode(next))
	}
}

// MARK: - Strings

extension SettingsListViewModel {
	var appName: String {
		Bundle.main.infoDictionary?["CFBundleName"] as? String ?? ""
	}

	var appVersion: String {
		Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
	}
}
