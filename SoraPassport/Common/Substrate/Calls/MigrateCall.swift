/**
* Copyright Soramitsu Co., Ltd. All Rights Reserved.
* SPDX-License-Identifier: Apache 2.0
*/

import Foundation
import FearlessUtils

struct MigrateCall: Codable {
    @BytesCodable var irohaAddress: String
    @BytesCodable var irohaPublicKey: String
    @BytesCodable var irohaSignature: String

    enum CodingKeys: String, CodingKey {
        case irohaAddress = "iroha_address"
        case irohaPublicKey = "iroha_public_key"
        case irohaSignature = "iroha_signature"
    }
}
