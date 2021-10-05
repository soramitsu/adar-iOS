/**
* Copyright Soramitsu Co., Ltd. All Rights Reserved.
* SPDX-License-Identifier: Apache 2.0
*/

import Foundation
import CommonWallet
import SoraFoundation
import FearlessUtils

enum TransactionHistoryViewModelFactoryError: Error {
    case missingAsset
    case unsupportedType
}

final class TransactionHistoryViewModelFactory: HistoryItemViewModelFactoryProtocol {
    let amountFormatterFactory: NumberFormatterFactoryProtocol
    let dateFormatter: LocalizableResource<DateFormatter>
    let assets: [WalletAsset]

    let iconGenerator: PolkadotIconGenerator = PolkadotIconGenerator()

    init(amountFormatterFactory: NumberFormatterFactoryProtocol,
         dateFormatter: LocalizableResource<DateFormatter>,
         assets: [WalletAsset]) {
        self.amountFormatterFactory = amountFormatterFactory
        self.dateFormatter = dateFormatter
        self.assets = assets
    }

    func createItemFromData(_ data: AssetTransactionData,
                            commandFactory: WalletCommandFactoryProtocol,
                            locale: Locale) throws -> WalletViewModelProtocol {
                                                            //legacy conversion
        let assetId = data.assetId.count > 5 ? data.assetId : WalletAssetId(rawValue: data.assetId)?.chainId
        guard let asset = assets.first(where: { $0.identifier == assetId }) else {
            throw TransactionHistoryViewModelFactoryError.missingAsset
        }

        var amount = amountFormatterFactory.createTokenFormatter(for: asset)
            .value(for: locale)
            .stringFromDecimal(data.amount.decimalValue)
            ?? ""

        switch data.direction {
        case .incoming :
            amount = "\(String.amountIncrease) \(amount)"
        case .outgoing :
            amount = "\(String.amountDecrease) \(amount)"
        }

        let details = dateFormatter.value(for: locale)
            .string(from: Date(timeIntervalSince1970: TimeInterval(data.timestamp)))

        let imageViewModel: WalletImageViewModelProtocol?
        let icon: UIImage?

        if let address = data.peerName {
            icon = try? iconGenerator.generateFromAddress(address)
                        .imageWithFillColor(R.color.baseBackground()!,
                                        size: CGSize(width: 32.0, height: 32.0),
                                        contentScale: UIScreen.main.scale)
        } else {
            icon = nil
        }

        if let currentIcon = icon {
            imageViewModel = WalletStaticImageViewModel(staticImage: currentIcon)
        } else {
            imageViewModel = nil
        }

        guard let transactionType = TransactionType(rawValue: data.type) else {
            throw TransactionHistoryViewModelFactoryError.unsupportedType
        }

        let command = commandFactory.prepareTransactionDetailsCommand(with: data)

        return HistoryItemViewModel(title: data.peerName?.soraConcat ?? "",
                                    details: details,
                                    amount: amount,
                                    direction: transactionType,
                                    status: data.status,
                                    imageViewModel: imageViewModel,
                                    command: command)
    }
}
