/**
* Copyright Soramitsu Co., Ltd. All Rights Reserved.
* SPDX-License-Identifier: Apache 2.0
*/

import Foundation

enum AccountCreateError: Error {
    case invalidMnemonicSize
    case invalidMnemonicFormat
    case invalidSeed
    case invalidKeystore
    case unsupportedNetwork
    case duplicated
}

extension AccountCreateError: ErrorContentConvertible {
    func toErrorContent(for locale: Locale?) -> ErrorContent {
        let title = R.string.localizable.mnemonicInvalidTitle(preferredLanguages: locale?.rLanguages)
        let message: String

        switch self {
        case .invalidMnemonicSize:
            message = R.string.localizable
                .accessRestoreWordsErrorMessage(preferredLanguages: locale?.rLanguages)
        case .invalidMnemonicFormat:
            message = R.string.localizable
                .accessRestorePhraseErrorMessage(preferredLanguages: locale?.rLanguages)
//        case .invalidSeed:
//            message = R.string.localizable
//                .accountImportInvalidSeed(preferredLanguages: locale?.rLanguages)
//        case .invalidKeystore:
//            message = R.string.localizable
//                .accountImportInvalidKeystore(preferredLanguages: locale?.rLanguages)
//        case .unsupportedNetwork:
//            message = R.string.localizable
//                .commonUnsupportedNetworkMessage(preferredLanguages: locale?.rLanguages)
//        case .duplicated:
//            message = R.string.localizable
//                .accountAddAlreadyExistsMessage(preferredLanguages: locale?.rLanguages)
        default: message = "Wrong"
        }

        return ErrorContent(title: title, message: message)
    }
}
