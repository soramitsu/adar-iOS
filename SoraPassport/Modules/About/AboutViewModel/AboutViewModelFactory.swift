/**
* Copyright Soramitsu Co., Ltd. All Rights Reserved.
* SPDX-License-Identifier: Apache 2.0
*/

import Foundation

protocol AboutViewModelFactoryProtocol {
    func createAboutViewModels(locale: Locale) -> [AboutOptionViewModelProtocol]
}

final class AboutViewModelFactory: AboutViewModelFactoryProtocol {

    func createAboutViewModels(locale: Locale) -> [AboutOptionViewModelProtocol] {
        AboutOptionViewModel.locale = locale

        let cases: [AboutOption] = [
            .website,
            .opensource(version: ApplicationConfig.shared.version),
            .telegram,
            .writeUs(toEmail: ApplicationConfig.shared.supportEmail),
            .terms,
            .privacy
        ]

        let optionViewModels = cases.map { (option) -> AboutOptionViewModel in
            AboutOptionViewModel(by: option)
        }

        return optionViewModels
    }
}
