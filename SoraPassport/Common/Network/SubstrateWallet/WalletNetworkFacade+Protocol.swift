/**
* Copyright Soramitsu Co., Ltd. All Rights Reserved.
* SPDX-License-Identifier: Apache 2.0
*/

import Foundation
import CommonWallet
import RobinHood
import IrohaCrypto
import BigInt

extension WalletNetworkFacade: WalletNetworkOperationFactoryProtocol {
    func fetchBalanceOperation(_ assets: [String]) -> CompoundOperationWrapper<[BalanceData]?> {
        let userAssets: [WalletAsset] = assets.compactMap { identifier in
            guard identifier != totalPriceAssetId?.rawValue else {
                return nil
            }

            return accountSettings.assets.first { $0.identifier == identifier }
        }
//hack while Capital can't change order
        let sortedAssets = assetManager.sortedAssets(userAssets, onlyVisible: true)

        let balanceOperation = fetchBalanceInfoForAssets(sortedAssets)
        let priceOperations: [CompoundOperationWrapper<Price?>] = sortedAssets.compactMap {
            //TODO: rawValue is nil now
            if let assetId = WalletAssetId(rawValue: $0.identifier) {
                return fetchPriceOperation(assetId)
            } else {
                return nil
            }
        }

        let mergeOperation: BaseOperation<[BalanceData]?> = ClosureOperation {
            // extract prices

            let prices = priceOperations.compactMap { operation in
                try? operation.targetOperation
                    .extractResultData(throwing: BaseOperationError.parentOperationCancelled)
            }

            // match balance with price and form context

            let balances: [BalanceData]? = try balanceOperation.targetOperation
                .extractResultData(throwing: BaseOperationError.parentOperationCancelled)?
                .map { balanceData in
                    guard let price = prices
                        .first(where: { $0.assetId.rawValue == balanceData.identifier }) else {
                        return balanceData
                    }

                    let context = BalanceContext(context: balanceData.context ?? [:] )
                        .byChangingPrice(price.lastValue, newPriceChange: price.change)
                        .toContext()

                    return BalanceData(identifier: balanceData.identifier,
                                       balance: balanceData.balance,
                                       context: context)
                }

            return (balances ?? [])
        }

        let flatenedPriceOperations: [Operation] = priceOperations
            .reduce(into: []) { (result, compoundOperation) in
                result.append(contentsOf: compoundOperation.allOperations)
        }

        flatenedPriceOperations.forEach { priceOperation in
            balanceOperation.allOperations.forEach { balanceOperation in
                balanceOperation.addDependency(priceOperation)
            }
        }

        let dependencies = balanceOperation.allOperations + flatenedPriceOperations

        dependencies.forEach { mergeOperation.addDependency($0) }

        return CompoundOperationWrapper(targetOperation: mergeOperation,
                                        dependencies: dependencies)
    }

    func fetchTransactionHistoryOperation(
        _ request: WalletHistoryRequest,
        pagination: Pagination
    ) -> CompoundOperationWrapper<AssetTransactionPageData?> {
        let filter = WalletHistoryFilter(string: request.filter)

        let historyContext = TransactionHistoryContext(context: pagination.context ?? [:])

        guard !historyContext.isComplete,
              let feeAsset = accountSettings.assets.first(where: { $0.isFeeAsset }),
              let assetId = WalletAssetId(rawValue: feeAsset.identifier)
        else {
            let pageData = AssetTransactionPageData(
                transactions: [],
                context: nil
            )

            let operation = BaseOperation<AssetTransactionPageData?>()
            operation.result = .success(pageData)
            return CompoundOperationWrapper(targetOperation: operation)
        }

        let remoteHistoryWrapper: CompoundOperationWrapper<WalletRemoteHistoryData>

        if let url = assetId.subqueryHistoryUrl {
            let remoteHistoryFactory = SubqueryHistoryOperationFactory(
                url: url,
                filter: filter
            )

            remoteHistoryWrapper = remoteHistoryFactory.createOperationWrapper(
                for: historyContext,
                address: address,
                count: pagination.count
            )
        } else {
            let context = TransactionHistoryContext(context: [:])
            let result = WalletRemoteHistoryData(historyItems: [], context: context)
            remoteHistoryWrapper = CompoundOperationWrapper.createWithResult(result)
        }

        var dependencies = remoteHistoryWrapper.allOperations

        let localFetchOperation: BaseOperation<[TransactionHistoryItem]>?

        if pagination.context == nil {
            let operation = txStorage.fetchAllOperation(with: RepositoryFetchOptions())
            dependencies.append(operation)

            remoteHistoryWrapper.allOperations.forEach { operation.addDependency($0) }

            localFetchOperation = operation
        } else {
            localFetchOperation = nil
        }

        let mergeOperation = createHistoryMergeOperation(
            dependingOn: remoteHistoryWrapper.targetOperation,
            localOperation: localFetchOperation,
            feeAsset: feeAsset,
            address: address
        )

        dependencies.forEach { mergeOperation.addDependency($0) }

        dependencies.append(mergeOperation)

        if pagination.context == nil {
            let clearOperation = txStorage.saveOperation({ [] }, {
                let mergeResult = try mergeOperation
                    .extractResultData(throwing: BaseOperationError.parentOperationCancelled)
                return mergeResult.identifiersToRemove
            })

            dependencies.append(clearOperation)
            clearOperation.addDependency(mergeOperation)
        }

        let mapOperation = createHistoryMapOperation(
            dependingOn: mergeOperation,
            remoteOperation: remoteHistoryWrapper.targetOperation
        )

        dependencies.forEach { mapOperation.addDependency($0) }

        return CompoundOperationWrapper(
            targetOperation: mapOperation,
            dependencies: dependencies
        )
    }

    func transferMetadataOperation(_ info: TransferMetadataInfo)
        -> CompoundOperationWrapper<TransferMetaData?> {
        nodeOperationFactory.transferMetadataOperation(info)
    }

    func transferOperation(_ info: TransferInfo) -> CompoundOperationWrapper<Data> {
        do {
            let currentNetworkType = networkType

            let transferWrapper = nodeOperationFactory.transferOperation(info)

            let addressFactory = SS58AddressFactory()

            let destinationId = try Data(hexString: info.destination)
            let destinationAddress = try addressFactory
                .address(fromAccountId: destinationId,
                         type: currentNetworkType)
            let contactSaveWrapper = contactsOperationFactory.saveByAddressOperation(destinationAddress)

            let txSaveOperation = txStorage.saveOperation({
                switch transferWrapper.targetOperation.result {
                case .success(let txHash):
                    let item = try TransactionHistoryItem
                        .createFromTransferInfo(info,
                                                transactionHash: txHash,
                                                networkType: currentNetworkType,
                                                addressFactory: addressFactory)
                    return [item]
                case .failure(let error):
                    throw error
                case .none:
                    throw BaseOperationError.parentOperationCancelled
                }
            }, { [] })

            transferWrapper.allOperations.forEach { transaferOperation in
                txSaveOperation.addDependency(transaferOperation)

                contactSaveWrapper.allOperations.forEach { $0.addDependency(transaferOperation) }
            }

            let completionOperation: BaseOperation<Data> = ClosureOperation {
                try txSaveOperation
                    .extractResultData(throwing: BaseOperationError.parentOperationCancelled)

                try contactSaveWrapper.targetOperation
                    .extractResultData(throwing: BaseOperationError.parentOperationCancelled)

                return try transferWrapper.targetOperation
                            .extractResultData(throwing: BaseOperationError.parentOperationCancelled)
            }

            let dependencies = [txSaveOperation] + contactSaveWrapper.allOperations +
                transferWrapper.allOperations

            completionOperation.addDependency(txSaveOperation)
            completionOperation.addDependency(contactSaveWrapper.targetOperation)

            return CompoundOperationWrapper(targetOperation: completionOperation,
                                            dependencies: dependencies)
        } catch {
            return CompoundOperationWrapper.createWithError(error)
        }
    }

    func searchOperation(_ searchString: String) -> CompoundOperationWrapper<[SearchData]?> {
        let fetchOperation = contactsOperation()

        let normalizedSearch = searchString.lowercased()

        let filterOperation: BaseOperation<[SearchData]?> = ClosureOperation {
            let result = try fetchOperation.targetOperation
                .extractResultData(throwing: BaseOperationError.parentOperationCancelled)

            return result?.filter {
                ($0.firstName.lowercased().range(of: normalizedSearch) != nil) ||
                ($0.lastName.lowercased().range(of: normalizedSearch) != nil)
            }
        }

        let dependencies = fetchOperation.allOperations
        dependencies.forEach { filterOperation.addDependency($0) }

        return CompoundOperationWrapper(targetOperation: filterOperation,
                                        dependencies: dependencies)
    }

    func contactsOperation() -> CompoundOperationWrapper<[SearchData]?> {
        let currentNetworkType = networkType

        let accountsOperation = accountsRepository.fetchAllOperation(with: RepositoryFetchOptions())
        let contactsOperation = contactsOperationFactory.fetchContactsOperation()
        let mapOperation: BaseOperation<[SearchData]?> = ClosureOperation {
            let accounts = try accountsOperation
                .extractResultData(throwing: BaseOperationError.parentOperationCancelled)

            let existingAddresses = Set<String>(
                accounts.map { $0.address }
            )

            let addressFactory = SS58AddressFactory()

            let accountsResult = try accounts.map {
                try SearchData.createFromAccountItem($0,
                                                     addressFactory: addressFactory)
            }

            let contacts = try contactsOperation.targetOperation
                .extractResultData(throwing: BaseOperationError.parentOperationCancelled)
                .filter({ !existingAddresses.contains($0.peerAddress) })

            let contactsResult = try contacts.map { contact in
                try SearchData.createFromContactItem(contact,
                                                     networkType: currentNetworkType,
                                                     addressFactory: addressFactory)
            }

            return accountsResult + contactsResult
        }

        mapOperation.addDependency(contactsOperation.targetOperation)
        mapOperation.addDependency(accountsOperation)

        let dependencies = contactsOperation.allOperations + [accountsOperation]

        return CompoundOperationWrapper(targetOperation: mapOperation,
                                        dependencies: dependencies)
    }

    func withdrawalMetadataOperation(_ info: WithdrawMetadataInfo)
        -> CompoundOperationWrapper<WithdrawMetaData?> {
        nodeOperationFactory.withdrawalMetadataOperation(info)
    }

    func withdrawOperation(_ info: WithdrawInfo) -> CompoundOperationWrapper<Data> {
        nodeOperationFactory.withdrawOperation(info)
    }
}
