/**
* Copyright Soramitsu Co., Ltd. All Rights Reserved.
* SPDX-License-Identifier: Apache 2.0
*/

import UIKit
import CommonWallet
import SoraUI

final class WalletSingleActionAccessoryView: UIView {
    @IBOutlet private(set) var actionButton: SoraButton!
}

extension WalletSingleActionAccessoryView: CommonWallet.AccessoryViewProtocol {
    var contentView: UIView {
        self
    }

    var isActionEnabled: Bool {
        get {
            actionButton.isEnabled
        }
        set(newValue) {
            actionButton.isEnabled = newValue
        }
    }

    var extendsUnderSafeArea: Bool { true }

    func bind(viewModel: AccessoryViewModelProtocol) {
        actionButton.imageWithTitleView?.title = viewModel.action
        actionButton.invalidateLayout()
    }
}
