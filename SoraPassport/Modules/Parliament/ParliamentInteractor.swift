/**
* Copyright Soramitsu Co., Ltd. All Rights Reserved.
* SPDX-License-Identifier: Apache 2.0
*/

import UIKit

final class ParliamentInteractor {
    weak var presenter: ParliamentInteractorOutputProtocol!
}

extension ParliamentInteractor: ParliamentInteractorInputProtocol {

}
