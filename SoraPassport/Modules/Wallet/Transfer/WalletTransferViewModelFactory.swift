/**
* Copyright Soramitsu Co., Ltd. All Rights Reserved.
* SPDX-License-Identifier: Apache 2.0
*/

import Foundation
import CommonWallet
import FearlessUtils
import SoraKeystore

struct WalletTransferViewModelFactory {

    weak var commandFactory: WalletCommandFactoryProtocol?

    private let iconGenerator = PolkadotIconGenerator()
    let assets: [WalletAsset]
    let assetManager: AssetManagerProtocol
    let amountFormatterFactory: NumberFormatterFactoryProtocol

    init(assets: [WalletAsset],
         assetManager: AssetManagerProtocol,
         amountFormatterFactory: NumberFormatterFactoryProtocol) {
        self.assets = assets
        self.assetManager = assetManager
        self.amountFormatterFactory = amountFormatterFactory
    }

}

extension WalletTransferViewModelFactory: TransferViewModelFactoryOverriding {

    func createReceiverViewModel(_ inputState: TransferInputState,
                                 payload: TransferPayload,
                                 locale: Locale) throws ->  MultilineTitleIconViewModelProtocol? {

        let icon = try iconGenerator.generateFromAddress(payload.receiverName)
            .imageWithFillColor(.white,
                                size: CGSize(width: 24.0, height: 24.0),
                                contentScale: UIScreen.main.scale)

        let command = SendToContactCommand(nextAction: {
            UIPasteboard.general.string = payload.receiverName
            let success = ModalAlertFactory.createSuccessAlert(R.string.localizable.commonCopied(preferredLanguages: locale.rLanguages))
            try? commandFactory?.preparePresentationCommand(for: success).execute()
        })

        return WalletSoraReceiverViewModel(text: payload.receiverName,
                                           icon: icon,
                                           title: R.string.localizable.transactionReceiverTitle(preferredLanguages: locale.rLanguages),
                                           command: command)

    }

    func createSelectedAssetViewModel(_ inputState: TransferInputState,
                                      selectedAssetState: SelectedAssetState,
                                      payload: TransferPayload,
                                      locale: Locale) throws -> AssetSelectionViewModelProtocol? {
        let title: String
        let subtitle: String
        let details: String

        guard
            let asset = assets.first(where: { $0.identifier == payload.receiveInfo.assetId })
        else {
            return nil
        }

        title =  "\(asset.symbol)"
        subtitle = asset.identifier

        let amountFormatter = amountFormatterFactory.createDisplayFormatter(for: asset)

        if let balanceData = inputState.balance,
           let formattedBalance = amountFormatter.value(for: locale)
                .stringFromDecimal(balanceData.balance.decimalValue) {
            details = "\(formattedBalance)"
        } else {
            details = ""
        }

        let symbolViewModel: WalletImageViewModelProtocol?
        if  let assetInfo = assetManager.assetInfo(for: asset.identifier),
            let iconString = assetInfo.icon {
            symbolViewModel = WalletSvgImageViewModel(svgString: iconString)
        } else {
            symbolViewModel = nil
        }

        return WalletTokenViewModel(state: selectedAssetState,
                                    header: "",
                                    title: title,
                                    subtitle: subtitle,
                                    details: details,
                                    icon: nil,
                                    iconViewModel: symbolViewModel)
    }

    func createAssetSelectionTitle(_ inputState: TransferInputState,
                                   payload: TransferPayload,
                                   locale: Locale) throws -> String? {
        let assetState = SelectedAssetState(isSelecting: false, canSelect: false)

        guard let viewModel = try createSelectedAssetViewModel(inputState,
                                                               selectedAssetState: assetState,
                                                               payload: payload,
                                                               locale: locale) else {
            return nil
        }

        if !viewModel.details.isEmpty {
            return "\(viewModel.title) - \(viewModel.details)"
        } else {
            return viewModel.title
        }
    }

    func createAccessoryViewModel(_ inputState: TransferInputState,
                                  payload: TransferPayload?,
                                  locale: Locale) throws -> AccessoryViewModelProtocol? {
        let action = R.string.localizable.transactionContinue(preferredLanguages: locale.rLanguages)
        return AccessoryViewModel(title: "", action: action)
    }
}
