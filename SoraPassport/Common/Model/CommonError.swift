/**
* Copyright Soramitsu Co., Ltd. All Rights Reserved.
* SPDX-License-Identifier: Apache 2.0
*/

import Foundation

enum CommonError: Error {
    case undefined
}

extension CommonError: ErrorContentConvertible {
    func toErrorContent(for locale: Locale?) -> ErrorContent {
        let title: String
        let message: String

        switch self {
        case .undefined:
            title = R.string.localizable.commonError()
//                .commonUndefinedErrorTitle(preferredLanguages: locale?.rLanguages)
            message = "commonUndefinedErrorMessage"//R.string.localizable
//                .commonUndefinedErrorMessage(preferredLanguages: locale?.rLanguages)
        }

        return ErrorContent(title: title, message: message)
    }
}
