/**
* Copyright Soramitsu Co., Ltd. All Rights Reserved.
* SPDX-License-Identifier: Apache 2.0
*/

import Foundation
import FearlessUtils

struct JSONScaleDecodable<T: ScaleDecodable>: Decodable {
    let underlyingValue: T?

    init(value: T?) {
        self.underlyingValue = value
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if container.decodeNil() {
            underlyingValue = nil
        } else {
            let value = try container.decode(String.self)
            let data = try Data(hexString: value)
            let scaleDecoder = try ScaleDecoder(data: data)
            underlyingValue = try T.init(scaleDecoder: scaleDecoder)
        }
    }
}
