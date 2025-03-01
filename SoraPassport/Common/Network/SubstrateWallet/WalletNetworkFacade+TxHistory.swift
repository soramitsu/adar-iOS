/**
* Copyright Soramitsu Co., Ltd. All Rights Reserved.
* SPDX-License-Identifier: Apache 2.0
*/

import Foundation
import RobinHood
import CommonWallet
import IrohaCrypto

extension WalletNetworkFacade {
    func createHistoryMergeOperation(
        dependingOn remoteOperation: BaseOperation<WalletRemoteHistoryData>?,
        localOperation: BaseOperation<[TransactionHistoryItem]>?,
        feeAsset: WalletAsset,
        address: String
    ) -> BaseOperation<TransactionHistoryMergeResult> {
        let currentNetworkType = networkType
        let addressFactory = SS58AddressFactory()

        return ClosureOperation {
            let remoteTransactions = try remoteOperation?.extractNoCancellableResultData().historyItems ?? []

            if let localTransactions = try localOperation?.extractNoCancellableResultData(),
               !localTransactions.isEmpty {
                let manager = TransactionHistoryMergeManager(
                    address: address,
                    networkType: currentNetworkType,
                    asset: feeAsset,
                    addressFactory: addressFactory
                )
                return manager.merge(
                    remoteItems: remoteTransactions,
                    localItems: localTransactions
                )
            } else {
                let transactions: [AssetTransactionData] = remoteTransactions.compactMap { item in
                    item.createTransactionForAddress(
                        address,
                        networkType: currentNetworkType,
                        asset: feeAsset,
                        addressFactory: addressFactory
                    )
                }

                return TransactionHistoryMergeResult(
                    historyItems: transactions,
                    identifiersToRemove: []
                )
            }
        }
    }

    func createHistoryMapOperation(
        dependingOn mergeOperation: BaseOperation<TransactionHistoryMergeResult>,
        remoteOperation: BaseOperation<WalletRemoteHistoryData>
    ) -> BaseOperation<AssetTransactionPageData?> {
        ClosureOperation {
            let mergeResult = try mergeOperation.extractNoCancellableResultData()
            let newHistoryContext = try remoteOperation.extractNoCancellableResultData().context

            return AssetTransactionPageData(
                transactions: mergeResult.historyItems.filter { self.assetManager.assetInfo(for: $0.assetId) != nil },
                context: !newHistoryContext.isComplete ? newHistoryContext.toContext() : nil
            )
        }
    }
}
