/**
* Copyright Soramitsu Co., Ltd. All Rights Reserved.
* SPDX-License-Identifier: Apache 2.0
*/

import Foundation
import FearlessUtils
import BigInt

struct AccountInfo: ScaleDecodable {
    let nonce: UInt32
    let consumers: UInt32
    let providers: UInt32
    let data: AccountData

    init(v27: AccountInfoV27) {
        self.nonce = v27.nonce
        self.consumers = v27.refcount
        self.providers = 0
        self.data = v27.data
    }

    init(scaleDecoder: ScaleDecoding) throws {
        nonce = try UInt32(scaleDecoder: scaleDecoder)
        consumers = try UInt32(scaleDecoder: scaleDecoder)
        providers = try UInt32(scaleDecoder: scaleDecoder)
        data = try AccountData(scaleDecoder: scaleDecoder)
    }
}

struct AccountInfoV27: ScaleDecodable {
    let nonce: UInt32
    let refcount: UInt32
    let data: AccountData

    init(scaleDecoder: ScaleDecoding) throws {
        nonce = try UInt32(scaleDecoder: scaleDecoder)
        refcount = try UInt32(scaleDecoder: scaleDecoder)
        data = try AccountData(scaleDecoder: scaleDecoder)
    }
}

struct AccountData: ScaleDecodable {
    let free: Balance
    let reserved: Balance
    let miscFrozen: Balance
    let feeFrozen: Balance

    init(scaleDecoder: ScaleDecoding) throws {
        free = try Balance(scaleDecoder: scaleDecoder)
        reserved = try Balance(scaleDecoder: scaleDecoder)
        miscFrozen = try Balance(scaleDecoder: scaleDecoder)
        feeFrozen = try Balance(scaleDecoder: scaleDecoder)
    }

    init(free: BigUInt = 0, reserved: BigUInt = 0, miscFrozen: BigUInt = 0, feeFrozen: BigUInt = 0) {
        self.free = Balance(value: free)
        self.reserved = Balance(value: reserved)
        self.miscFrozen = Balance(value: miscFrozen)
        self.feeFrozen = Balance(value: feeFrozen)
    }
}

struct BalanceInfo: Decodable {
    @StringCodable var balance: BigUInt
}

struct Balance: ScaleCodable {
    let value: BigUInt

    init(value: BigUInt) {
        self.value = value
    }

    init(scaleDecoder: ScaleDecoding) throws {
        let data = try scaleDecoder.read(count: 16)
        value = BigUInt(Data(data.reversed()))
        try scaleDecoder.confirm(count: 16)
    }

    func encode(scaleEncoder: ScaleEncoding) throws {
        var encodedData: [UInt8] = value.serialize().reversed()

        while encodedData.count < 16 {
            encodedData.append(0)
        }

        scaleEncoder.appendRaw(data: Data(encodedData))
    }
}
