/**
* Copyright Soramitsu Co., Ltd. All Rights Reserved.
* SPDX-License-Identifier: Apache 2.0
*/

import Foundation

struct InvitedUserData: Codable, Equatable {
    enum CodingKeys: String, CodingKey {
        case userId
        case walletAccountId
        case timestamp = "registrationDate"
    }

    var userId: String
    var walletAccountId: String
    var timestamp: Int64
}

extension InvitedUserData {
    var registrationDate: Date {
        Date(timeIntervalSince1970: TimeInterval(timestamp))
    }
}
