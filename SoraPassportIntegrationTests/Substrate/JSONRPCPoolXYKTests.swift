import BigInt
import FearlessUtils
import IrohaCrypto
import RobinHood
import SoraFoundation
import SoraKeystore
@testable import SoraPassport
import XCTest
import xxHash_Swift
import CommonWallet

import XCTest

class JSONRPCPoolXYKTests: NetworkBaseTests {
    func testPools() {
        let url: URL = URL(string: "wss://ws.framenode-3.s3.dev.sora2.soramitsu.co.jp/")!
        let address: AccountAddress = "cnVkoGs3rEMqLqY27c2nfVXJRGdzNJk2ns78DcqtppaSRe8qm"
        let logger = Logger.shared
        let operationQueue = OperationQueue()

        let engine = WebSocketEngine(url: url, logger: logger)

        let storageFactory = StorageKeyFactory()

        let key = try! storageFactory.accountPoolsKeyForId(address.accountId!).toHex(includePrefix: true)

        let operation = JSONRPCListOperation<JSONScaleDecodable<AccountPools>>(
            engine: engine,
            method: RPCMethod.getStorage,
            parameters: [key]
        )

        operationQueue.addOperations([operation], waitUntilFinished: true)

        do {
            guard let pools = try operation.extractResultData()?.underlyingValue else {
                XCTFail("No account pools")
                return
            }

            XCTAssertEqual("0x0200040000000000000000000000000000000000000000000000000000000000", pools.assetIds[0])
            XCTAssertEqual("0x0200050000000000000000000000000000000000000000000000000000000000", pools.assetIds[1])
            Logger.shared.debug("Account pools: \(pools)")

        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    //    poolXYK
    //    properties(AssetId, AssetId): Option<(AccountId,AccountId)>
    //    Properties of particular pool. Base Asset => Target Asset => (Reserves Account Id, Fees Account Id)
    func testPoolProperties() {
        let url: URL = URL(string: "wss://ws.framenode-3.s3.dev.sora2.soramitsu.co.jp/")!
        let baseAsset = "0x0200000000000000000000000000000000000000000000000000000000000000"
        let targetAsset = "0x0200040000000000000000000000000000000000000000000000000000000000"
        let logger = Logger.shared
        let operationQueue = OperationQueue()

        let engine = WebSocketEngine(url: url, logger: logger)

        let storageFactory = StorageKeyFactory()

        let key = try! storageFactory.poolPropertiesKey(
            baseAssetId: Data(hex: baseAsset),
            targetAssetId: Data(hex: targetAsset)
        )
        .toHex(includePrefix: true)

        let operation = JSONRPCListOperation<JSONScaleDecodable<PoolProperties>>(
            engine: engine,
            method: RPCMethod.getStorage,
            parameters: [key]
        )

        operationQueue.addOperations([operation], waitUntilFinished: true)

        do {
            let result = try operation.extractResultData(throwing: BaseOperationError.parentOperationCancelled)

            guard let poolProperties = result.underlyingValue else {
                XCTFail("No PoolProperties")
                return
            }
            Logger.shared.debug("PoolProperties: \(poolProperties)")
            Logger.shared.debug("reservesAccount address: \(poolProperties.reservesAccountId)")
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testPoolReserves() {
        let url: URL = URL(string: "wss://ws.framenode-3.s3.dev.sora2.soramitsu.co.jp/")!
        let baseAsset = "0200000000000000000000000000000000000000000000000000000000000000"
        let targetAsset = "0200040000000000000000000000000000000000000000000000000000000000"
        let logger = Logger.shared
        let operationQueue = OperationQueue()

        let engine = WebSocketEngine(url: url, logger: logger)

        let storageFactory = StorageKeyFactory()

        // reserves(AssetId, AssetId): (Balance,Balance) Updated after last liquidity change operation.
        let key = try! storageFactory.poolReservesKey(
            baseAssetId: Data(hex: baseAsset),
            targetAssetId: Data(hex: targetAsset)
        )
        .toHex(includePrefix: true)

        let operation = JSONRPCListOperation<JSONScaleDecodable<PoolReserves>>(
            engine: engine,
            method: RPCMethod.getStorage,
            parameters: [key]
        )

        operationQueue.addOperations([operation], waitUntilFinished: true)

        do {
            guard let poolReserves = try operation.extractResultData()?.underlyingValue else {
                XCTFail("No Pool Reserves")
                return
            }

            Logger.shared.debug("poolReserves: \(poolReserves)")
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testPoolProviders() {
        let url: URL = URL(string: "wss://ws.framenode-3.s3.dev.sora2.soramitsu.co.jp/")!
        let reservesAccount = "cnTQ1kbv7PBNNQrEb1tZpmK7f4sMKaWQF583on92JL48B9kjq"
        let account = "cnVkoGs3rEMqLqY27c2nfVXJRGdzNJk2ns78DcqtppaSRe8qm"
        let logger = Logger.shared
        let operationQueue = OperationQueue()

        let engine = WebSocketEngine(url: url, logger: logger)

        let storageFactory = StorageKeyFactory()

        // poolProviders(AccountIdOf, AccountIdOf): Option<Balance> Liquidity providers of particular pool.
        let key = try! storageFactory.poolProvidersKey(
            reservesAccountId: reservesAccount.accountId!,
            accountId: account.accountId!
        )
        .toHex(includePrefix: true)

        let operation = JSONRPCListOperation<JSONScaleDecodable<Balance>>(
            engine: engine,
            method: RPCMethod.getStorage,
            parameters: [key]
        )

        operationQueue.addOperations([operation], waitUntilFinished: true)

        do {
            guard let poolProviders = try operation.extractResultData()?.underlyingValue else {
                XCTFail("No PoolProviders")
                return
            }

            Logger.shared.debug("PoolProviders: \(poolProviders)")
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    //    poolXYK
    //    totalIssuances(AccountIdOf): Option<Balance>
    //    Total issuance of particular pool.
    func testPoolTotalIssuances() {
        let url: URL = URL(string: "wss://ws.framenode-3.s3.dev.sora2.soramitsu.co.jp/")!
        let reservesAccount: AccountAddress = "cnTQ1kbv7PBNNQrEb1tZpmK7f4sMKaWQF583on92JL48B9kjq"
        let logger = Logger.shared
        let operationQueue = OperationQueue()

        let engine = WebSocketEngine(url: url, logger: logger)

        let storageFactory = StorageKeyFactory()

        let key = try! storageFactory.accountPoolTotalIssuancesKeyForId(reservesAccount.accountId!)
            .toHex(includePrefix: true)

        let operation = JSONRPCListOperation<JSONScaleDecodable<Balance>>(
            engine: engine,
            method: RPCMethod.getStorage,
            parameters: [key]
        )

        operationQueue.addOperations([operation], waitUntilFinished: true)

        do {
            guard let poolTotalIssuances = try operation.extractResultData()?.underlyingValue else {
                XCTFail("No PoolTotalIssuances")
                return
            }

            Logger.shared.debug("PoolTotalIssuances: \(poolTotalIssuances)")
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    // YOUR POOL SHARE      2.1165251%
    // STRATEGIC BONUS APY  55.1515303%
    // XOR POOLED           2300
    // VAL POOLED           233.14852941
    //
    //    XOR Pooled:
    //    {{ Receiving the reserves first return }} *
    //    {{ Receiving account's pool balance return }}
    //    / {{  Receiving total issuances return }}
    //
    //    {second asset} Pooled:
    //    {{ Receiving the reserves second return }} *
    //    {{ Receiving account's pool balance return }}
    //    / {{  Receiving total issuances return }}
    //
    //    Your pool share:
    //    {{ Receiving account's pool balance return }} / {{  Receiving total issuances return }} * 100%
    func testPoolsDetails() {
        let url: URL = URL(string: "wss://ws.framenode-3.s3.dev.sora2.soramitsu.co.jp/")!
        let baseAsset = "0200000000000000000000000000000000000000000000000000000000000000"
        let address: AccountAddress = "cnVkoGs3rEMqLqY27c2nfVXJRGdzNJk2ns78DcqtppaSRe8qm"
        let logger = Logger.shared
        let operationQueue = OperationQueue()
        let engine = WebSocketEngine(url: url, logger: logger)
        let storageFactory = StorageKeyFactory()

        // accountPoolsOperation
        let accountPoolsOperation = JSONRPCListOperation<JSONScaleDecodable<AccountPools>>(engine: engine, method: RPCMethod.getStorage, parameters: [
            try! storageFactory.accountPoolsKeyForId(address.accountId!).toHex(includePrefix: true),
        ])
        operationQueue.addOperations([accountPoolsOperation], waitUntilFinished: true)

        guard let pools = try? accountPoolsOperation.extractResultData()?.underlyingValue?.assetIds else {
            XCTFail("No pools")
            return
        }

        let selectedAsset = pools.first!

        // poolProperties

        let key = try! storageFactory.poolPropertiesKey(baseAssetId: Data(hex: baseAsset), targetAssetId: Data(hex: selectedAsset)).toHex(includePrefix: true)
        let operation = JSONRPCListOperation<JSONScaleDecodable<PoolProperties>>(
            engine: engine,
            method: RPCMethod.getStorage,
            parameters: [key]
        )

        operationQueue.addOperations([operation], waitUntilFinished: true)

        guard let reservesAccountId = try? operation.extractResultData()?.underlyingValue?.reservesAccountId else {
            XCTFail("No reservesAccount")
            return
        }

        // poolProviders

        let poolProvidersBalanceOperation = JSONRPCListOperation<JSONScaleDecodable<Balance>>(engine: engine, method: RPCMethod.getStorage, parameters: [
            try! storageFactory.poolProvidersKey(reservesAccountId: reservesAccountId.value, accountId: address.accountId!).toHex(includePrefix: true),
        ]
        )

        operationQueue.addOperations([poolProvidersBalanceOperation], waitUntilFinished: true)

        guard let accountPoolBalance = try? poolProvidersBalanceOperation.extractResultData()?.underlyingValue else {
            XCTFail("No poolProvidersBalance")
            return
        }

        print("poolProvidersBalance:\(accountPoolBalance)")

        // totalIssuances
        let accountPoolTotalIssuancesOperation = JSONRPCListOperation<JSONScaleDecodable<Balance>>(engine: engine, method: RPCMethod.getStorage, parameters: [
            try! storageFactory.accountPoolTotalIssuancesKeyForId(reservesAccountId.value).toHex(includePrefix: true),
        ])

        operationQueue.addOperations([accountPoolTotalIssuancesOperation], waitUntilFinished: true)

        guard let totalIssuances = try? accountPoolTotalIssuancesOperation.extractResultData()?.underlyingValue else {
            XCTFail("No totalIssuances")
            return
        }

        let reservesOperation = JSONRPCListOperation<JSONScaleDecodable<PoolReserves>>(engine: engine, method: RPCMethod.getStorage, parameters: [
            try! storageFactory.poolReservesKey(baseAssetId: Data(hex: baseAsset), targetAssetId: Data(hex: selectedAsset)).toHex(includePrefix: true),
        ])

        operationQueue.addOperations([reservesOperation], waitUntilFinished: true)

        guard let reserves = try? reservesOperation.extractResultData()?.underlyingValue else {
            XCTFail("No reserves")
            return
        }

        // XOR Pooled
        let yourPoolShare = Double(accountPoolBalance.value) / Double(totalIssuances.value) * 100
        let xorPooled = Double(reserves.reserves.value * accountPoolBalance.value) / Double(totalIssuances.value)
        let targetPooled = Double(reserves.fees.value * accountPoolBalance.value) / Double(totalIssuances.value)

        print("yourPoolShare: \(yourPoolShare)")
        print("xorPooled: \(xorPooled)")
        print("targetPooled: \(targetPooled)")
    }

    func testPoolsDetails2() {
        let operationQueue = OperationQueue()
        let operation = getPoolList()

        operationQueue.addOperations([operation], waitUntilFinished: true)

        let poolsDetails = try? operation.extractResultData()
        XCTAssertNotNil(poolsDetails)
    }

    func getPoolList() -> BaseOperation<[PoolDetails]> {
        let processingOperation: BaseOperation<[PoolDetails]> = ClosureOperation {
            let url: URL = URL(string: "wss://ws.framenode-3.s3.dev.sora2.soramitsu.co.jp/")!
            let baseAsset = "0200000000000000000000000000000000000000000000000000000000000000"
            let address: AccountAddress = "cnVkoGs3rEMqLqY27c2nfVXJRGdzNJk2ns78DcqtppaSRe8qm"
            let operationQueue = OperationQueue()
            let engine = WebSocketEngine(url: url, logger: Logger.shared)
            let storageFactory = StorageKeyFactory()

            var poolsDetails: [PoolDetails] = []

            // accountPoolsOperation
            let accountPoolsOperation = JSONRPCListOperation<JSONScaleDecodable<AccountPools>>(engine: engine, method: RPCMethod.getStorage, parameters: [
                try! storageFactory.accountPoolsKeyForId(address.accountId!).toHex(includePrefix: true),
            ])
            operationQueue.addOperations([accountPoolsOperation], waitUntilFinished: true)

            guard let pools = try? accountPoolsOperation.extractResultData()?.underlyingValue?.assetIds else {
                return []
            }

            for targetAsset in pools {
                
                // poolProperties

                let key = try! storageFactory.poolPropertiesKey(baseAssetId: Data(hex: baseAsset), targetAssetId: Data(hex: targetAsset)).toHex(includePrefix: true)
                let operation = JSONRPCListOperation<JSONScaleDecodable<PoolProperties>>(
                    engine: engine,
                    method: RPCMethod.getStorage,
                    parameters: [key]
                )

                operationQueue.addOperations([operation], waitUntilFinished: true)

                guard let reservesAccountId = try? operation.extractResultData()?.underlyingValue?.reservesAccountId else {
                    return []
                }

                // poolProviders

                let poolProvidersBalanceOperation = JSONRPCListOperation<JSONScaleDecodable<Balance>>(engine: engine, method: RPCMethod.getStorage, parameters: [
                    try! storageFactory.poolProvidersKey(reservesAccountId: reservesAccountId.value, accountId: address.accountId!).toHex(includePrefix: true),
                ])

                operationQueue.addOperations([poolProvidersBalanceOperation], waitUntilFinished: true)

                guard let accountPoolBalance = try? poolProvidersBalanceOperation.extractResultData()?.underlyingValue else {
                    return []
                }

                print("poolProvidersBalance:\(accountPoolBalance)")

                // totalIssuances
                let accountPoolTotalIssuancesOperation = JSONRPCListOperation<JSONScaleDecodable<Balance>>(engine: engine, method: RPCMethod.getStorage, parameters: [
                    try! storageFactory.accountPoolTotalIssuancesKeyForId(reservesAccountId.value).toHex(includePrefix: true),
                ])

                operationQueue.addOperations([accountPoolTotalIssuancesOperation], waitUntilFinished: true)

                guard let totalIssuances = try? accountPoolTotalIssuancesOperation.extractResultData()?.underlyingValue else {
                    return []
                }

                let reservesOperation = JSONRPCListOperation<JSONScaleDecodable<PoolReserves>>(engine: engine, method: RPCMethod.getStorage, parameters: [
                    try! storageFactory.poolReservesKey(baseAssetId: Data(hex: baseAsset), targetAssetId: Data(hex: targetAsset)).toHex(includePrefix: true),
                ])

                operationQueue.addOperations([reservesOperation], waitUntilFinished: true)

                guard let reserves = try? reservesOperation.extractResultData()?.underlyingValue else {
                    return []
                }

                // XOR Pooled
                let yourPoolShare = Double(accountPoolBalance.value) / Double(totalIssuances.value) * 100
                let xorPooled = Double(reserves.reserves.value * accountPoolBalance.value) / Double(totalIssuances.value)
                let targetPooled = Double(reserves.fees.value * accountPoolBalance.value) / Double(totalIssuances.value)

                let service = SubqueryPoolsFactory(url: WalletAssetId.subqueryHistoryUrl, filter: [])
                let strategicBonusAPYOperation = service.getStrategicBonusAPYOperation()
                strategicBonusAPYOperation.start()

                guard let result = try? strategicBonusAPYOperation.extractNoCancellableResultData() else { return [] }

                let sbAPYL = Double(result.edges.first(where: { $0.node.targetAssetId == targetAsset })?.node.strategicBonusApy ?? "0.0")!

                print("yourPoolShare: \(yourPoolShare)")
                print("sbAPYL: \(sbAPYL)")
                print("xorPooled: \(xorPooled)")
                print("targetPooled: \(targetPooled)")

                poolsDetails.append(PoolDetails(targetAsset: targetAsset, yourPoolShare: yourPoolShare, sbAPYL: sbAPYL, xorPooled: xorPooled, targetAssetPooled: targetPooled))
            }
            
            return poolsDetails
        }

        return processingOperation
    }
}
