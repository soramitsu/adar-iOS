/**
* Copyright Soramitsu Co., Ltd. All Rights Reserved.
* SPDX-License-Identifier: Apache 2.0
*/

import Foundation
import SoraKeystore

final class PersonalUpdateInteractor {
	weak var presenter: PersonalUpdateInteractorOutputProtocol?

    private(set) var settingsManager: SettingsManagerProtocol

    init(settingsManager: SettingsManagerProtocol) {
        self.settingsManager = settingsManager
    }
}

extension PersonalUpdateInteractor: PersonalUpdateInteractorInputProtocol {
    func setup() {
        presenter?.didReceive(username: settingsManager.selectedAccount?.username)
    }

    func update(username: String?) {
        settingsManager.selectedAccount = settingsManager.selectedAccount?.replacingUsername(username ?? "")
        settingsManager.userName = username
        presenter?.didUpdate(username: username)
    }
}
