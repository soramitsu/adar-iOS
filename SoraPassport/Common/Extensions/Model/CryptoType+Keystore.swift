/**
* Copyright Soramitsu Co., Ltd. All Rights Reserved.
* SPDX-License-Identifier: Apache 2.0
*/

import Foundation

extension CryptoType {
    var supportsSeedFromSecretKey: Bool {
        switch self {
        case .ed25519, .ecdsa:
            return true
        case .sr25519:
            return false
        }
    }
}
