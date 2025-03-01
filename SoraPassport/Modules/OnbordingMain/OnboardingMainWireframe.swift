/**
* Copyright Soramitsu Co., Ltd. All Rights Reserved.
* SPDX-License-Identifier: Apache 2.0
*/

import Foundation

final class OnboardingMainWireframe: OnboardingMainWireframeProtocol {
    lazy var rootAnimator: RootControllerAnimationCoordinatorProtocol = RootControllerAnimationCoordinator()

    func showSignup(from view: OnboardingMainViewProtocol?) {
        guard let usernameSetup = UsernameSetupViewFactory.createViewForOnboarding() else {
            return
        }

        if let navigationController = view?.controller.navigationController {
            navigationController.pushViewController(usernameSetup.controller, animated: true)
        }
    }

    func showAccountRestore(from view: OnboardingMainViewProtocol?) {
        guard let restorationController = AccountImportViewFactory
            .createViewForOnboarding()?.controller else {
            return
        }

        if let navigationController = view?.controller.navigationController {
            navigationController.pushViewController(restorationController, animated: true)
        }
    }

    func showKeystoreImport(from view: OnboardingMainViewProtocol?) {
        if
            let navigationController = view?.controller.navigationController,
            navigationController.viewControllers.count == 1,
            navigationController.presentedViewController == nil {
            showAccountRestore(from: view)
        }
    }
}
