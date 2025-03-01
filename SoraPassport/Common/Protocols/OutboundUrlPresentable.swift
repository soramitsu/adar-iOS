/**
* Copyright Soramitsu Co., Ltd. All Rights Reserved.
* SPDX-License-Identifier: Apache 2.0
*/

import UIKit

protocol OutboundUrlPresentable {
    @discardableResult
    func open(url: URL) -> Bool
}

extension OutboundUrlPresentable {
    func open(url: URL) -> Bool {
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
            return true
        } else {
            return false
        }
    }
}
