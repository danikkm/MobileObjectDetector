//
//  CameraModuleEnum.swift
//  MobileObjectDetector
//
//  Created by Daniel Dluznevskij on 2020-12-22.
//

enum CameraType {
    case frontFacing
    case backFacing
}

enum DetectionState {
    case inactive
    case active
}

enum FrameRateMode {
    case smooth
    case normal
}

extension FrameRateMode: Codable {
    enum Key: CodingKey {
        case rawValue
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: Key.self)
        let rawValue = try container.decode(Int.self, forKey: .rawValue)
        switch rawValue {
        case 0:
            self = .smooth
        case 1:
            self = .normal
        default:
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: container.codingPath,
                    debugDescription: "Unable to decode enum."
                )
            )
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: Key.self)
        switch self {
        case .smooth:
            try container.encode(0, forKey: .rawValue)
        case .normal:
            try container.encode(1, forKey: .rawValue)
        }
    }
    
}
