/**
* Copyright Soramitsu Co., Ltd. All Rights Reserved.
* SPDX-License-Identifier: Apache 2.0
*/

import UIKit
import SoraUI

protocol AccessoryViewFactoryProtocol: class {
    static func createAccessoryView(target: Any?,
                                    completionSelector: Selector?) -> AccessoryViewProtocol
    static func createActionTitleView(with title: String,
                                      target: Any?,
                                      actionHandler: Selector?) -> SoraButton
}

final class AccessoryViewFactory: AccessoryViewFactoryProtocol {
    static func createAccessoryView(target: Any?,
                                    completionSelector: Selector?) -> AccessoryViewProtocol {
        let view = R.nib.accessoryView(owner: nil)!

        view.titleColor = UIColor.accessoryTitle
        view.titleFont = UIFont.accessoryTitle

        if let target = target, let selector = completionSelector {
            view.actionButton.addTarget(target, action: selector, for: .touchUpInside)
        }

        return view
    }

    static func createActionTitleView(with title: String,
                                      target: Any?,
                                      actionHandler: Selector?) -> SoraButton {
        let actionButton = SoraButton()
        actionButton.imageWithTitleView?.titleColor = UIColor.actionTitle
        actionButton.imageWithTitleView?.titleFont = UIFont.accessoryTitle
        actionButton.imageWithTitleView?.title = title
        actionButton.roundedBackgroundView?.fillColor = .clear
        actionButton.roundedBackgroundView?.highlightedFillColor = .clear
        actionButton.roundedBackgroundView?.shadowOpacity = 0.0
        actionButton.contentInsets = UIEdgeInsets(top: 8.0, left: 0.0, bottom: 8.0, right: 16.0)
        actionButton.changesContentOpacityWhenHighlighted = true

        if let target = target, let selector = actionHandler {
            actionButton.addTarget(target, action: selector, for: .touchUpInside)
        }

        return actionButton
    }
}
