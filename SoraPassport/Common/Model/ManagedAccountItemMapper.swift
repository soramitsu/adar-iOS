/**
* Copyright Soramitsu Co., Ltd. All Rights Reserved.
* SPDX-License-Identifier: Apache 2.0
*/

import Foundation
import RobinHood
import CoreData
import IrohaCrypto

enum ManagedAccountItemMapperError: Error {
    case invalidEntity
}

final class ManagedAccountItemMapper: CoreDataMapperProtocol {
    typealias DataProviderModel = ManagedAccountItem
    typealias CoreDataEntity = CDAccountItem

    var entityIdentifierFieldName: String {
        #keyPath(CoreDataEntity.identifier)
    }

    func populate(entity: CDAccountItem,
                  from model: DataProviderModel,
                  using context: NSManagedObjectContext) throws {
        entity.identifier = model.address
        entity.cryptoType = Int16(model.cryptoType.rawValue)
        entity.networkType = Int16(model.networkType)
        entity.publicKey = model.publicKeyData
        entity.username = model.username
        entity.order = model.order
    }

    func transform(entity: CDAccountItem) throws -> DataProviderModel {
        guard
            let address = entity.identifier,
            let username = entity.username,
            let cryptoType = CryptoType(rawValue: UInt8(entity.cryptoType)),
            let publicKeyData = entity.publicKey else {
            throw ManagedAccountItemMapperError.invalidEntity
        }
        let networkType = SNAddressType(UInt8(entity.networkType))
        return ManagedAccountItem(address: address,
                                  cryptoType: cryptoType,
                                  networkType: networkType,
                                  username: username,
                                  publicKeyData: publicKeyData,
                                  order: entity.order)
    }
}
