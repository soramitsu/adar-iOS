/**
* Copyright Soramitsu Co., Ltd. All Rights Reserved.
* SPDX-License-Identifier: Apache 2.0
*/

import Foundation
import CommonWallet
import IrohaCrypto
import FearlessUtils

final class WalletQREncoder: WalletQREncoderProtocol {
    let username: String?
    let networkType: SNAddressType
    let publicKey: Data

    private lazy var substrateEncoder = SubstrateQREncoder()
    private lazy var addressFactory = SS58AddressFactory()

    init(networkType: SNAddressType, publicKey: Data, username: String?) {
        self.networkType = networkType
        self.publicKey = publicKey
        self.username = username
    }

    func encode(receiverInfo: ReceiveInfo) throws -> Data {
        let accountId = try Data(hexString: receiverInfo.accountId)

        let address = try addressFactory.address(fromAccountId: accountId, type: networkType)

        let info = SoraSubstrateQRInfo(address: address,
                                   rawPublicKey: publicKey,
                                   username: username,
                                   assetId: receiverInfo.assetId!)
        return try substrateEncoder.encode(info: info)
    }
}

final class WalletQRDecoder: WalletQRDecoderProtocol {
    private lazy var addressFactory = SS58AddressFactory()
    private let substrateDecoder: SubstrateQRDecoder
    private let assets: [WalletAsset]

    init(networkType: SNAddressType, assets: [WalletAsset]) {
        substrateDecoder = SubstrateQRDecoder(chainType: networkType)
        self.assets = assets
    }

    func decode(data: Data) throws -> ReceiveInfo {
        let info: SoraSubstrateQRInfo = try substrateDecoder.decode(data: data)

        let accountId = try addressFactory.accountId(fromAddress: info.address,
                                                     type: substrateDecoder.chainType)
        guard let asset = assets.first(where: { $0.identifier == info.assetId }) else {
            throw TransferPresenterError.missingAsset
        }
        return ReceiveInfo(accountId: accountId.toHex(),
                           assetId: asset.identifier,
                           amount: nil,
                           details: nil)
    }
}

final class WalletQRCoderFactory: WalletQRCoderFactoryProtocol {
    let networkType: SNAddressType
    let publicKey: Data
    let username: String?
    let assets: [WalletAsset]

    init(networkType: SNAddressType, publicKey: Data, username: String?, assets: [WalletAsset]) {
        self.networkType = networkType
        self.publicKey = publicKey
        self.username = username
        self.assets = assets
    }

    func createEncoder() -> WalletQREncoderProtocol {
        WalletQREncoder(networkType: networkType,
                        publicKey: publicKey,
                        username: username)
    }

    func createDecoder() -> WalletQRDecoderProtocol {
        WalletQRDecoder(networkType: networkType, assets: assets)
    }
}
