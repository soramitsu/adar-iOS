/**
* Copyright Soramitsu Co., Ltd. All Rights Reserved.
* SPDX-License-Identifier: Apache 2.0
*/

import Foundation
import CommonWallet

struct WalletSoraDefinitionFactory: WalletFormDefinitionFactoryProtocol {
    func createDefinitionWithBinder(
        _ binder: WalletFormViewModelBinderProtocol,
        itemFactory: WalletFormItemViewFactoryProtocol
    ) -> WalletFormDefining {
        WalletSoraDefinition(binder: binder, itemViewFactory: itemFactory)
    }
}
