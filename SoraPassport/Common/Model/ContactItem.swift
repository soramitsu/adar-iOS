/**
* Copyright Soramitsu Co., Ltd. All Rights Reserved.
* SPDX-License-Identifier: Apache 2.0
*/

import Foundation
import RobinHood

struct ContactItem: Codable {
    enum CodingKeys: String, CodingKey {
        case peerAddress
        case peerName
        case targetAddress
        case updatedAt
    }

    let peerAddress: String
    let peerName: String?
    let targetAddress: String
    let updatedAt: Int64
}

extension ContactItem: Identifiable {
    var identifier: String { targetAddress + peerAddress }
}
