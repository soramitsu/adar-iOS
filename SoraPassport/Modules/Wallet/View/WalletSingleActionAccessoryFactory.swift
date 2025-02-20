/**
* Copyright Soramitsu Co., Ltd. All Rights Reserved.
* SPDX-License-Identifier: Apache 2.0
*/

import Foundation
import CommonWallet

struct WalletSingleActionAccessoryFactory: CommonWallet.AccessoryViewFactoryProtocol {
    static func createAccessoryView(
        from _: WalletAccessoryViewType,
        style _: WalletAccessoryStyleProtocol?,
        target: Any?,
        completionSelector: Selector?
    ) -> CommonWallet.AccessoryViewProtocol {
        let view = R.nib.walletSingleActionAccessoryView(owner: nil)!

        if let target = target, let selector = completionSelector {
            view.actionButton.addTarget(target, action: selector, for: .touchUpInside)
        }

        return view
    }
}

struct WalletTransactionDetailsAccessoryFactory: CommonWallet.AccessoryViewFactoryProtocol {
    static func createAccessoryView(
        from _: WalletAccessoryViewType,
        style _: WalletAccessoryStyleProtocol?,
        target: Any?,
        completionSelector: Selector?
    ) -> CommonWallet.AccessoryViewProtocol {
        let view = R.nib.walletTransactionDetailsAccessoryView(owner: nil)!

        if let target = target, let selector = completionSelector {
            view.actionButton.addTarget(target, action: selector, for: .touchUpInside)
        }

        return view
    }
}
