/**
* Copyright Soramitsu Co., Ltd. All Rights Reserved.
* SPDX-License-Identifier: Apache 2.0
*/

import Foundation
import FearlessUtils

struct SuperIdentity: Codable {
    let parentAccountId: Data
    let data: ChainData

    var name: String? {
        if case .raw(let value) = data {
            return String(data: value, encoding: .utf8)
        } else {
            return nil
        }
    }

    init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()

        parentAccountId = try container.decode(Data.self)
        data = try container.decode(ChainData.self)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()

        try container.encode(parentAccountId)
        try container.encode(data)
    }
}
