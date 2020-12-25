//
//  BasicButton.swift
//  Hive-for-iOS
//
//  Created by Joseph Roque on 2020-06-28.
//  Copyright © 2020 Joseph Roque. All rights reserved.
//

import SwiftUI

typealias PrimaryButton = BasicButton<Never>

struct BasicButton<Label>: View where Label: View {
	@Environment(\.horizontalSizeClass) var horizontalSizeClass: UserInterfaceSizeClass?

	private let label: Label?
	private let title: String?
	private let action: () -> Void
	private var background: ColorAsset = .highlightPrimary
	private var foreground: ColorAsset = .white

	init(_ title: String, action: @escaping () -> Void) {
		self.title = title
		self.action = action
		self.label = nil
	}

	init(action: @escaping () -> Void, @ViewBuilder label: () -> Label) {
		self.title = nil
		self.action = action
		self.label = label()
	}

	var body: some View {
		Button(action: action, label: {
			if label != nil {
				label
			} else {
				Text(title ?? "")
					.font(.body)
					.foregroundColor(Color(foreground))
					.padding(.vertical)
					.frame(height: 48)
					.limitWidth(forSizeClass: horizontalSizeClass)
					.background(
						RoundedRectangle(cornerRadius: .s)
							.fill(Color(background))
					)
			}
		})
	}
}

// MARK: - Modifiers

extension BasicButton where Label == Never {
	func buttonBackground(_ color: ColorAsset) -> PrimaryButton {
		var button = self
		button.background = color
		return button
	}

	func buttonForeground(_ color: ColorAsset) -> PrimaryButton {
		var button = self
		button.foreground = color
		return button
	}
}

// MARK: - Preview

#if DEBUG
struct BasicButtonPreview: PreviewProvider {
	static var previews: some View {
		VStack {
			PrimaryButton("Logout") { }
			BasicButton {
				// Does nothing
			} label: {
				Image(uiImage: UIImage(systemName: "clock")!)
			}
		}
	}
}
#endif
