/**
* Copyright Soramitsu Co., Ltd. All Rights Reserved.
* SPDX-License-Identifier: Apache 2.0
*/

import Foundation
import FearlessUtils
import IrohaCrypto
import RobinHood
import BigInt

struct TransactionSubscriptionResult {
    let processingResult: ExtrinsicProcessingResult
    let extrinsicHash: Data
    let blockNumber: UInt64
    let txIndex: UInt16
}

private typealias ResultAndFeeOperationWrapper =
    CompoundOperationWrapper<(TransactionSubscriptionResult, Decimal)>

final class TransactionSubscription {
    let engine: JSONRPCEngine
    let address: String
    let chain: Chain
    let runtimeService: RuntimeCodingServiceProtocol
    let addressFactory: SS58AddressFactoryProtocol
    let txStorage: AnyDataProviderRepository<TransactionHistoryItem>
    let contactOperationFactory: WalletContactOperationFactoryProtocol
    let storageRequestFactory: StorageRequestFactoryProtocol
    let operationManager: OperationManagerProtocol
    let eventCenter: EventCenterProtocol
    let logger: LoggerProtocol

    init(
        engine: JSONRPCEngine,
        address: String,
        chain: Chain,
        addressFactory: SS58AddressFactoryProtocol,
        runtimeService: RuntimeCodingServiceProtocol,
        txStorage: AnyDataProviderRepository<TransactionHistoryItem>,
        contactOperationFactory: WalletContactOperationFactoryProtocol,
        storageRequestFactory: StorageRequestFactoryProtocol,
        operationManager: OperationManagerProtocol,
        eventCenter: EventCenterProtocol,
        logger: LoggerProtocol
    ) {
        self.engine = engine
        self.address = address
        self.chain = chain
        self.runtimeService = runtimeService
        self.contactOperationFactory = contactOperationFactory
        self.storageRequestFactory = storageRequestFactory
        self.txStorage = txStorage
        self.operationManager = operationManager
        self.eventCenter = eventCenter
        self.logger = logger
        self.addressFactory = addressFactory
    }

    func process(blockHash: Data) {
        do {
            logger.debug("Did start fetching block: \(blockHash.toHex(includePrefix: true))")

            let fetchBlockOperation: JSONRPCOperation<[String], SignedBlock> =
                JSONRPCOperation(
                    engine: engine,
                    method: RPCMethod.getChainBlock,
                    parameters: [blockHash.toHex(includePrefix: true)]
                )

            let coderFactoryOperation = runtimeService.fetchCoderFactoryOperation()

            let eventsKey = try StorageKeyFactory().key(from: .events)
            let eventsWrapper: CompoundOperationWrapper<[StorageResponse<[EventRecord]>]> =
                storageRequestFactory.queryItems(
                    engine: engine,
                    keys: { [eventsKey] },
                    factory: { try coderFactoryOperation.extractNoCancellableResultData() },
                    storagePath: .events,
                    at: blockHash
                )

            eventsWrapper.allOperations.forEach { $0.addDependency(coderFactoryOperation) }

            let parseOperation = createParseOperation(
                for: address,
                dependingOn: fetchBlockOperation,
                eventsOperation: eventsWrapper.targetOperation,
                coderOperation: coderFactoryOperation
            )

            parseOperation.addDependency(fetchBlockOperation)
            parseOperation.addDependency(eventsWrapper.targetOperation)

            let txSaveOperation = createTxSaveOperation(
                for: address,
                dependingOn: parseOperation
            )

            let contactSaveWrapper = createContactSaveWrapper(
                dependingOn: parseOperation,
                contactOperationFactory: contactOperationFactory,
                chain: chain
            )

            txSaveOperation.addDependency(parseOperation)
            contactSaveWrapper.allOperations.forEach { $0.addDependency(parseOperation) }

            txSaveOperation.completionBlock = {
                switch parseOperation.result {
                case let .success(items):
                    self.logger.debug("Did complete block processing")
                    if !items.isEmpty {
                        DispatchQueue.main.async {
                            self.eventCenter.notify(with: WalletNewTransactionInserted())
                        }
                    }
                case let .failure(error):
                    self.logger.error("Did fail block processing: \(error)")
                case .none:
                    self.logger.error("Block processing cancelled")
                }
            }

            let operations: [Operation] = {
                var array = [Operation]()
                array.append(contentsOf: eventsWrapper.allOperations)
                array.append(contentsOf: contactSaveWrapper.allOperations)
                array.append(fetchBlockOperation)
                array.append(coderFactoryOperation)
                array.append(parseOperation)
                array.append(txSaveOperation)
                return array
            }()

            operationManager.enqueue(operations: operations, in: .transient)
        } catch {
            logger.error("Block processing failed: \(error)")
        }
    }
}

extension TransactionSubscription {
    private func createTxSaveOperation(
        for address: String,
        dependingOn processingOperaton: BaseOperation<[TransactionSubscriptionResult]>
    ) -> BaseOperation<Void> {
        txStorage.saveOperation({
            let addressFactory = SS58AddressFactory()
            return try processingOperaton.extractNoCancellableResultData().compactMap { result in
                let fee = Decimal.fromSubstrateAmount(
                    result.processingResult.fee ?? BigUInt(0),
                    precision: 18
                ) ?? .zero
                return TransactionHistoryItem.createFromSubscriptionResult(
                    result, fee: fee,
                    address: address,
                    addressFactory: addressFactory
                )
            }
        }, { [] })
    }

    private func createContactSaveWrapper(
        dependingOn processingOperaton: BaseOperation<[TransactionSubscriptionResult]>,
        contactOperationFactory: WalletContactOperationFactoryProtocol,
        chain: Chain
    ) -> CompoundOperationWrapper<Void> {
        let addressFactory = SS58AddressFactory()
        let networkType = SNAddressType(chain: chain)
        let extractionOperation = ClosureOperation<Set<Data>> {
            try processingOperaton.extractNoCancellableResultData()
                .reduce(into: Set<Data>()) { result, item in
                    if let peerId = item.processingResult.peerId {

                        let address = try addressFactory.accountId(
                            fromAddress: peerId,
                            type: networkType
                        )

                        result.insert(address)
                    }
                }
        }

        let saveOperation = OperationCombiningService<Void>(operationManager: operationManager) {
            try extractionOperation.extractNoCancellableResultData().map { peerId in
                let address = try addressFactory.addressFromAccountId(data: peerId, type: networkType)
                return contactOperationFactory.saveByAddressOperation(address)
            }
        }.longrunOperation()

        saveOperation.addDependency(extractionOperation)

        let mapOperation = ClosureOperation<Void> {
            _ = try saveOperation.extractNoCancellableResultData()
            return
        }

        mapOperation.addDependency(saveOperation)

        let dependencies = [extractionOperation, saveOperation]

        return CompoundOperationWrapper(
            targetOperation: mapOperation,
            dependencies: dependencies
        )
    }

    private func createParseOperation(
        for address: AccountAddress,
        dependingOn fetchOperation: BaseOperation<SignedBlock>,
        eventsOperation: BaseOperation<[StorageResponse<[EventRecord]>]>,
        coderOperation: BaseOperation<RuntimeCoderFactoryProtocol>
    ) -> BaseOperation<[TransactionSubscriptionResult]> {
        ClosureOperation<[TransactionSubscriptionResult]> {
            let block = try fetchOperation
                .extractResultData(throwing: BaseOperationError.parentOperationCancelled)
                .block

            let eventRecords = try eventsOperation.extractNoCancellableResultData().first?.value ?? []

            guard let blockNumberData = BigUInt.fromHexString(block.header.number) else {
                throw BaseOperationError.unexpectedDependentResult
            }

            let coderFactory = try coderOperation.extractNoCancellableResultData()

            let accountId = try SS58AddressFactory().accountId(from: address).toHex(includePrefix: true)
            let extrinsicProcessor = ExtrinsicProcessor(accountId: accountId)

            return block.extrinsics.enumerated().compactMap { index, hexExtrinsic in
                do {
                    let data = try Data(hexString: hexExtrinsic)
                    let extrinsicHash = try data.blake2b32()

                    guard let processingResult = extrinsicProcessor.process(
                        extrinsicIndex: UInt32(index),
                        extrinsicData: data,
                        eventRecords: eventRecords,
                        coderFactory: coderFactory
                    ) else {
                        return nil
                    }

                    return TransactionSubscriptionResult(
                        processingResult: processingResult,
                        extrinsicHash: extrinsicHash,
                        blockNumber: UInt64(blockNumberData),
                        txIndex: UInt16(index)
                    )
                } catch {
                    return nil
                }
            }
        }
    }
}
