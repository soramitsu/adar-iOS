/**
* Copyright Soramitsu Co., Ltd. All Rights Reserved.
* SPDX-License-Identifier: Apache 2.0
*/

import Foundation

final class AddMainWireframe: OnboardingMainWireframeProtocol {
    func showSignup(from view: OnboardingMainViewProtocol?) {
        guard let usernameSetup = UsernameSetupViewFactory.createViewForAdding() else {
            return
        }

        if let navigationController = view?.controller.navigationController {
            navigationController.pushViewController(usernameSetup.controller, animated: true)
        }
    }

    func showAccountRestore(from view: OnboardingMainViewProtocol?) {
        guard let restorationController = AccountImportViewFactory
            .createViewForAdding()?.controller else {
            return
        }

        if let navigationController = view?.controller.navigationController {
            navigationController.pushViewController(restorationController, animated: true)
        }
    }
//do we need it?
    func showKeystoreImport(from view: OnboardingMainViewProtocol?) {
        if
            let navigationController = view?.controller.navigationController,
            navigationController.topViewController == view?.controller,
            navigationController.presentedViewController == nil {
            showAccountRestore(from: view)
        }
    }
}
