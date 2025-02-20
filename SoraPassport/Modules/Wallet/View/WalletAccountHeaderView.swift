/**
* Copyright Soramitsu Co., Ltd. All Rights Reserved.
* SPDX-License-Identifier: Apache 2.0
*/

import UIKit
import CommonWallet
import SoraUI
import SoraFoundation

final class WalletAccountHeaderView: UICollectionViewCell {
    @IBOutlet private(set) var titleLabel: UILabel!
    @IBOutlet weak var scanButton: RoundedButton!
    @IBOutlet weak var moreButton: RoundedButton!
    @IBOutlet weak var sendButton: RoundedButton!
    @IBOutlet weak var receiveButton: RoundedButton!

    var viewModel: WalletViewModelProtocol?

    override func awakeFromNib() {
        super.awakeFromNib()

        localizationManager = LocalizationManager.shared
        titleLabel.font = UIFont.styled(for: .display1)

        scanButton.addTarget(self, action: #selector(scanTouch), for: .touchUpInside)
        sendButton.addTarget(self, action: #selector(sendTouch), for: .touchUpInside)
        receiveButton.addTarget(self, action: #selector(receiveTouch), for: .touchUpInside)
        moreButton.addTarget(self, action: #selector(moreTouch), for: .touchUpInside)
    }

    @objc func scanTouch() {
        if let model = viewModel as? WalletHeaderViewModel {
            try? model.scanCommand?.execute()
        }
    }

    @objc func sendTouch() {
        if let model = viewModel as? WalletHeaderViewModel {
            try? model.sendCommand?.execute()
        }
    }

    @objc func receiveTouch() {
        if let model = viewModel as? WalletHeaderViewModel {
            try? model.receiveCommand?.execute()
        }
    }

    @objc func moreTouch() {
        if let model = viewModel as? WalletHeaderViewModel {
            try? model.manageCommand?.execute()
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        viewModel = nil
    }

    private func setupLocalization() {
        let languages = localizationManager?.preferredLocalizations
        titleLabel.text = R.string.localizable.walletTitle(preferredLanguages: languages)
    }
}

extension WalletAccountHeaderView: Localizable {
    func applyLocalization() {
        setupLocalization()

        if superview != nil {
            setNeedsLayout()
        }
    }
}

extension WalletAccountHeaderView: WalletViewProtocol {

    func bind(viewModel: WalletViewModelProtocol) {
        self.viewModel = viewModel
    }
}
