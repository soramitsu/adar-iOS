/**
* Copyright Soramitsu Co., Ltd. All Rights Reserved.
* SPDX-License-Identifier: Apache 2.0
*/

import Foundation

struct StringScaleMapper<T: LosslessStringConvertible>: Codable {
    let value: T

    init(value: T) {
        self.value = value
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        let strValue = try container.decode(String.self)

        guard let convertedValue = T(strValue) else {
            throw DecodingError.dataCorruptedError(in: container,
                                                   debugDescription: "Can't decode value: \(strValue)")
        }

        self.value = convertedValue
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(String(value))
    }
}
