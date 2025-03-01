/**
* Copyright Soramitsu Co., Ltd. All Rights Reserved.
* SPDX-License-Identifier: Apache 2.0
*/

import UIKit

class TitleWithSubtitleTableViewCell: UITableViewCell, ModalPickerCellProtocol {
    typealias Model = TitleWithSubtitleViewModel

    @IBOutlet private var titleLabel: UILabel!
    @IBOutlet private var subtitleLabel: UILabel!
    @IBOutlet private var checkmarkImageView: UIImageView!

    var checkmarked: Bool {
        get {
            !checkmarkImageView.isHidden
        }

        set {
            checkmarkImageView.isHidden = !newValue
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        let selectedBackgroundView = UIView()
        selectedBackgroundView.backgroundColor = R.color.themeAccent()!.withAlphaComponent(0.3)
        self.selectedBackgroundView = selectedBackgroundView
    }

    func bind(model: Model) {
        titleLabel.text = model.title
        subtitleLabel.text = model.subtitle
    }
}
