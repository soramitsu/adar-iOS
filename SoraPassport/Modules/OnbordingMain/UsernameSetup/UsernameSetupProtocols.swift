/**
* Copyright Soramitsu Co., Ltd. All Rights Reserved.
* SPDX-License-Identifier: Apache 2.0
*/

import SoraFoundation

protocol UsernameSetupViewProtocol: ControllerBackedProtocol {
    func set(viewModel: InputViewModelProtocol)
}

protocol UsernameSetupPresenterProtocol: class {
    func setup()
    func proceed()
    func activateURL(_ url: URL)
}

protocol UsernameSetupWireframeProtocol: AlertPresentable, WebPresentable {
    func proceed(from view: UsernameSetupViewProtocol?, username: String)
}

protocol UsernameSetupViewFactoryProtocol: class {
	static func createViewForOnboarding() -> UsernameSetupViewProtocol?
    static func createViewForAdding() -> UsernameSetupViewProtocol?
}
