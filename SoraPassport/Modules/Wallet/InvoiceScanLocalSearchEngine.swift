/**
* Copyright Soramitsu Co., Ltd. All Rights Reserved.
* SPDX-License-Identifier: Apache 2.0
*/

import Foundation
import CommonWallet
import IrohaCrypto

final class InvoiceScanLocalSearchEngine: InvoiceLocalSearchEngineProtocol {
    let networkType: SNAddressType

    private lazy var addressFactory = SS58AddressFactory()

    init(networkType: SNAddressType) {
        self.networkType = networkType
    }

    func searchByAccountId(_ accountIdHex: String) -> SearchData? {
        guard let accountId = try? Data(hexString: accountIdHex) else {
            return nil
        }

        guard let address = try? addressFactory
            .addressFromAccountId(data: accountId, type: networkType) else {
            return nil
        }

        let context = ContactContext(destination: .local)
        return SearchData(
            accountId: accountIdHex,
            firstName: address,
            lastName: "",
            context: context.toContext()
        )
    }
}
