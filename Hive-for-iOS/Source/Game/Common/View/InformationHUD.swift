//
//  InformationHUD.swift
//  Hive-for-iOS
//
//  Created by Joseph Roque on 2020-01-28.
//  Copyright © 2020 Joseph Roque. All rights reserved.
//

import SwiftUI
import HiveEngine

struct InformationHUD: View {
	let information: GameInformation
	let state: GameState

	private func debugView(for information: GameInformation) -> some View {
		return Text(information.description(in: state))
	}

	var body: some View {
		HStack {
			Image(uiImage: ImageAsset.glyph)
				.resizable()
				.squareImage(.m)
			debugView(for: information)
		}
	}
}

#if DEBUG
struct InformationHUDPreview: PreviewProvider {
	static var previews: some View {
		InformationHUD(information: .pieceClass(.ant), state: GameState())
	}
}
#endif
