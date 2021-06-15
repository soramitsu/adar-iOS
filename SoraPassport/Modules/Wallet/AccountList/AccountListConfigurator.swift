import Foundation
import CommonWallet
import RobinHood
import SoraFoundation
import CoreData

final class AccountListConfigurator {
    let logger: LoggerProtocol
    let viewModelFactory: AccountListViewModelFactory
    let assetStyleFactory: AssetStyleFactory
    let headerViewModel: WalletHeaderViewModel

    init(address: String,
         chain: Chain,
         commandDecorator: WalletCommandDecoratorFactoryProtocol,
         headerViewModel: WalletHeaderViewModel,
         logger: LoggerProtocol) {

        self.logger = logger
        self.headerViewModel = headerViewModel
        assetStyleFactory = AssetStyleFactory()

        let amountFormatterFactory = AmountFormatterFactory()
//        let accountCommandFactory = WalletSelectAccountCommandFactory()

        viewModelFactory = AccountListViewModelFactory(address: address,
                                                       chain: chain,
                                                       assetCellStyleFactory: assetStyleFactory,
                                                       commandDecorator: commandDecorator,
                                                       amountFormatterFactory: amountFormatterFactory/*,
                                                       priceAsset: priceAsset,
                                                       accountCommandFactory: accountCommandFactory,
                                                       purchaseProvider: purchaseProvider*/)
    }


    func configure(builder: AccountListModuleBuilderProtocol) {
        do {
            let localHeaderViewModel = headerViewModel

            try builder
            .with(minimumContentHeight: localHeaderViewModel.itemHeight)
            .with(minimumVisibleAssets: 3)
            .inserting(viewModelFactory: { localHeaderViewModel }, at: 0)
            .with(cellNib: UINib(resource: R.nib.walletAccountHeaderView),
                  for: localHeaderViewModel.cellReuseIdentifier)
            .with(cellNib: UINib(resource: R.nib.assetCollectionViewCell),
                  for: ConfigurableAssetConstants.cellReuseIdentifier)
            .withActions(cellNib: UINib(resource: R.nib.actionsViewCell))
            .with(assetCellStyleFactory: assetStyleFactory)
            .with(listViewModelFactory: viewModelFactory)
        } catch {
            logger.error("Can't customize account list: \(error)")
        }
    }
}
