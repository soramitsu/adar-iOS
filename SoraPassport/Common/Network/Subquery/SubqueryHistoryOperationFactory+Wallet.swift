/**
* Copyright Soramitsu Co., Ltd. All Rights Reserved.
* SPDX-License-Identifier: Apache 2.0
*/

import Foundation
import RobinHood

extension SubqueryHistoryOperationFactory: WalletRemoteHistoryFactoryProtocol {
    func createOperationWrapper(
        for context: TransactionHistoryContext,
        address: String,
        count: Int
    ) -> CompoundOperationWrapper<WalletRemoteHistoryData> {
        let queryOperation = createOperation(address: address, count: count, cursor: context.cursor)

        let mappingOperation = ClosureOperation<WalletRemoteHistoryData> {
            guard let response = try? queryOperation.extractNoCancellableResultData()
            else {
                return WalletRemoteHistoryData(historyItems: [], context: TransactionHistoryContext(context: [:]))
            }

            let pageInfo = response.historyElements.pageInfo
            let items = response.historyElements.nodes

            let context = TransactionHistoryContext(
                cursor: pageInfo.endCursor,
                isComplete: pageInfo.endCursor == nil
            )

            return WalletRemoteHistoryData(
                historyItems: items,
                context: context
            )
        }

        mappingOperation.addDependency(queryOperation)

        return CompoundOperationWrapper(targetOperation: mappingOperation, dependencies: [queryOperation])
    }
}
