//  Copyright © 2017 Schibsted. All rights reserved.

import UIKit

extension UIFont {

    // This is the actual default font size on iOS
    // which is not the same as reported by `UIFont.systemFontSize`
    static let defaultSize: CGFloat = 17

    struct RelativeSize {
        let factor: CGFloat
    }

    var fontWeight: UIFont.Weight {
        guard let traits = fontDescriptor.object(forKey: UIFontDescriptor.AttributeName.traits) as? [UIFontDescriptor.TraitKey: Any],
            let weight = traits[UIFontDescriptor.TraitKey.weight] as? UIFont.Weight else {
            return UIFont.Weight.regular
        }
        return weight
    }

    static func font(with parts: [Any]) throws -> UIFont {
        var font: UIFont!
        var fontSize: CGFloat!
        var traits = UIFontDescriptorSymbolicTraits()
        var fontWeight: UIFont.Weight?
        for part in parts {
            switch part {
            case let part as UIFont:
                font = part
            case let trait as UIFontDescriptorSymbolicTraits:
                traits.insert(trait)
            case let weight as UIFont.Weight:
                fontWeight = weight
            case let size as NSNumber:
                fontSize = CGFloat(truncating: size)
            case let size as UIFont.RelativeSize:
                fontSize = (fontSize ?? font?.pointSize ?? defaultSize) * size.factor
            case let style as UIFontTextStyle:
                let preferredFont = UIFont.preferredFont(forTextStyle: style)
                fontSize = preferredFont.pointSize
                font = font ?? preferredFont
            default:
                throw Expression.Error.message("Invalid font specifier `\(part)`")
            }
        }
        return self.font(font, withSize: fontSize, weight: fontWeight, traits: traits)
    }

    static func font(
        _ font: UIFont?,
        withSize fontSize: CGFloat?,
        weight: UIFont.Weight?,
        traits: UIFontDescriptorSymbolicTraits
    ) -> UIFont {
        let fontSize = fontSize ?? font?.pointSize ?? defaultSize
        let font = font ?? {
            if traits.contains(.traitMonoSpace), let font = UIFont(name: "Courier", size: fontSize) {
                return font
            }
            return systemFont(ofSize: fontSize, weight: weight ?? .regular)
        }()
        let fontNames = UIFont.fontNames(forFamilyName: font.familyName)
        if fontNames.isEmpty {
            let fontTraits = font.fontDescriptor.symbolicTraits.union(traits)
            if let descriptor = font.fontDescriptor.withSymbolicTraits(fontTraits) {
                return UIFont(descriptor: descriptor, size: fontSize)
            }
        }
        var bestMatch = UIFont(descriptor: font.fontDescriptor, size: fontSize)
        var bestMatchQuality = 0
        for name in fontNames {
            let font = UIFont(name: name, size: fontSize)!
            let fontTraits = font.fontDescriptor.symbolicTraits
            var matchQuality = 0
            for trait in [
                // NOTE: traitBold is handled using weight argument
                .traitCondensed,
                .traitExpanded,
                .traitItalic,
                .traitMonoSpace,
            ] as [UIFontDescriptorSymbolicTraits] where traits.contains(trait) && fontTraits.contains(trait) {
                matchQuality += 1
            }
            if fontTraits.contains(.traitItalic), !traits.contains(.traitItalic) {
                matchQuality -= 1
            }
            if font.fontWeight == weight {
                matchQuality += 1
            }
            if matchQuality > bestMatchQuality {
                bestMatchQuality = matchQuality
                bestMatch = font
            }
        }
        return bestMatch
    }
}

