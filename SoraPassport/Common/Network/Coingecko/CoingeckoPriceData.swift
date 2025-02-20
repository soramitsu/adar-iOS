/**
* Copyright Soramitsu Co., Ltd. All Rights Reserved.
* SPDX-License-Identifier: Apache 2.0
*/

import Foundation
import CommonWallet

struct CoingeckoPriceData: Codable, Equatable {
    let usdPrice: Decimal
    let usdDayChange: Decimal?

    enum CodingKeys: String, CodingKey {
        case usdPrice = "usd"
        case usdDayChange = "usd_24h_change"
    }
}
