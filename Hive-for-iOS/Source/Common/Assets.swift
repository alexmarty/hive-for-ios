//
//  Assets.swift
//  Hive-for-iOS
//
//  Created by Joseph Roque on 2020-01-13.
//  Copyright © 2020 Joseph Roque. All rights reserved.
//

import SwiftUI
import UIKit

// MARK: - Images

enum ImageAsset {
	static let glyph = UIImage(named: "Glyph")!
	static let joseph = UIImage(named: "Joseph")!
	static let borderlessGlyph = UIImage(named: "Icons/BorderlessGlyph")!

	enum Icon {
		static let hand = UIImage(named: "Icons/Hand")!
		static let close = UIImage(named: "Icons/Close")!
	}

	enum Movement {
		static let move = UIImage(named: "Movement/Move")!
		static let place = UIImage(named: "Movement/Place")!
		static let yoink = UIImage(named: "Movement/Yoink")!
		static let pass = UIImage(named: "Movement/Pass")!
	}
}

// MARK: - Colors

enum ColorAsset: String {
	case primary = "Colors/Primary"
	case background = "Colors/Background"
	case backgroundLight = "Colors/BackgroundLight"
	case backgroundDark = "Colors/BackgroundDark"

	case text = "Colors/Text"
	case textSecondary = "Colors/TextSecondary"

	case separator = "Colors/Separator"

	case clear = "Colors/Clear"
	case white = "Colors/White"
}

extension UIColor {
	convenience init(_ asset: ColorAsset) {
		self.init(named: asset.rawValue)!
	}
}

extension Color {
	init(_ asset: ColorAsset) {
		self.init(UIColor(asset))
	}
}
