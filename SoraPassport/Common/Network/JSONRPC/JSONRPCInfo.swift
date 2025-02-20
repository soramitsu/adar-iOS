/**
* Copyright Soramitsu Co., Ltd. All Rights Reserved.
* SPDX-License-Identifier: Apache 2.0
*/

import Foundation

struct JSONRPCInfo<P: Encodable>: Encodable {
    enum CodingKeys: String, CodingKey {
        case identifier = "id"
        case jsonrpc
        case method
        case params
    }

    let identifier: UInt16
    let jsonrpc: String
    let method: String
    let params: P
}
