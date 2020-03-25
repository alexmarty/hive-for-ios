//
//  HiveSpriteManager.swift
//  Hive-for-iOS
//
//  Created by Joseph Roque on 2020-03-21.
//  Copyright © 2020 Joseph Roque. All rights reserved.
//

import SpriteKit
import HiveEngine

class HiveSpriteManager {
	private(set) var pieceSprites: [Piece: SKSpriteNode] = [:]
	private(set) var pieceSpriteVisibility: [Piece: Bool] = [:]
	private(set) var positionSprites: [Position: SKSpriteNode] = [:]

	func sprite(
		for piece: Piece,
		initialSize: CGSize,
		initialScale: CGPoint,
		initialOffset: CGPoint,
		blank: Bool = false
	) -> SKSpriteNode {
		if let sprite = pieceSprites[piece] {
			if blank && pieceSpriteVisibility[piece] == true {
				sprite.texture = SKTexture(imageNamed: "Pieces/Blank")
				pieceSpriteVisibility[piece] = false
			} else if !blank && pieceSpriteVisibility[piece] == false {
				sprite.texture = SKTexture(imageNamed: "Pieces/\(piece.class.description)")
				pieceSpriteVisibility[piece] = true
			}

			return sprite
		}

		let sprite = SKSpriteNode(from: piece)
		sprite.name = "Piece-\(piece.notation)"
		sprite.zPosition = 1
		sprite.anchorPoint = CGPoint(x: 0.5, y: 0.5)
		sprite.size = initialSize
		sprite.position = Position.origin.point(scale: initialScale, offset: initialOffset)

		pieceSprites[piece] = sprite
		pieceSpriteVisibility[piece] = blank
		return sprite
	}

	func piece(from sprite: SKNode) -> Piece? {
		guard let name = sprite.name else { return nil }
		let notation = name.starts(with: "Piece-") ? name.substring(from: 6) : ""
		return Piece(notation: notation)
	}

	func sprite(
		for position: Position,
		initialSize: CGSize,
		initialScale: CGPoint,
		initialOffset: CGPoint
	) -> SKSpriteNode {
		if let sprite = positionSprites[position] {
			return sprite
		}

		let sprite = SKSpriteNode(imageNamed: "Pieces/Blank")
		sprite.name = "Position-\(position.description)"
		sprite.size = initialSize
		sprite.position = position.point(scale: initialScale, offset: initialOffset)
		sprite.anchorPoint = CGPoint(x: 0.5, y: 0.5)
		resetAppearance(sprite: sprite)
		sprite.colorBlendFactor = 1
		sprite.zPosition = -1

		let positionLabel = SKLabelNode(text: position.description)
		positionLabel.name = "Label"
		positionLabel.horizontalAlignmentMode = .center
		positionLabel.verticalAlignmentMode = .center
		positionLabel.fontSize = 12
		positionLabel.zPosition = 1
		sprite.addChild(positionLabel)

		#warning("TODO: change text anchor point to center")

		positionSprites[position] = sprite
		return sprite
	}

	func hidePositionLabel(for position: Position, hidden: Bool) {
		let sprite = self.sprite(for: position, initialSize: .zero, initialScale: .zero, initialOffset: .zero)
		sprite.childNode(withName: "Label")?.isHidden = hidden
	}

	func resetAppearance(sprite: SKSpriteNode, gameState: GameState? = nil) {
		if sprite.name?.starts(with: "Piece-") ?? false {
			guard let piece = self.piece(from: sprite) else { return }
			sprite.color = piece.owner == .white ? UIColor(.white) : UIColor(.primary)
			sprite.alpha = gameState?.unitIsTopOfStack[piece] ?? true ? 1 : 0.5
		} else if sprite.name?.starts(with: "Position-") ?? false {
			sprite.color = UIColor(.backgroundLight)
		}
	}
}
