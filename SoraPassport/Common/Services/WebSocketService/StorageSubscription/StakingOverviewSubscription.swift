/**
* Copyright Soramitsu Co., Ltd. All Rights Reserved.
* SPDX-License-Identifier: Apache 2.0
*/

import Foundation
import RobinHood

class StakingOverviewSubscription: BaseStorageChildSubscription {
    let eventCenter: EventCenterProtocol

    init(remoteStorageKey: Data,
         localStorageKey: String,
         storage: AnyDataProviderRepository<ChainStorageItem>,
         operationManager: OperationManagerProtocol,
         logger: LoggerProtocol,
         eventCenter: EventCenterProtocol) {
        self.eventCenter = eventCenter

        super.init(remoteStorageKey: remoteStorageKey,
                   localStorageKey: localStorageKey,
                   storage: storage,
                   operationManager: operationManager,
                   logger: logger)
    }

    override func handle(result: Result<DataProviderChange<ChainStorageItem>?, Error>, blockHash: Data?) {
        if case .success(let optionalChange) = result, optionalChange != nil {
            DispatchQueue.main.async {
                self.eventCenter.notify(with: WalletStakingInfoChanged())
            }
        }
    }
}
