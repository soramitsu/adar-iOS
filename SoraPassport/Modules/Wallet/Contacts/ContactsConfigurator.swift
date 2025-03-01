/**
* Copyright Soramitsu Co., Ltd. All Rights Reserved.
* SPDX-License-Identifier: Apache 2.0
*/

import Foundation
import IrohaCrypto
import CommonWallet
import SoraFoundation

final class ContactsConfigurator {
    private var localSearchEngine: ContactsLocalSearchEngine

    private lazy var contactsViewStyle: ContactsViewStyleProtocol = {
        let searchTextStyle = WalletTextStyle(font: UIFont.styled(for: .paragraph3),
                                              color: R.color.baseContentPrimary()!)
        let searchPlaceholderStyle = WalletTextStyle(font: UIFont.styled(for: .paragraph3),
                                                     color: R.color.baseContentQuaternary()!)

        let searchStroke = WalletStrokeStyle(color: R.color.baseBorderSecondary()!,
                                             lineWidth: 1.0)
        let searchFieldStyle = WalletRoundedViewStyle(fill: R.color.baseBackground()!,
                                                      cornerRadius: 8.0,
                                                      stroke: searchStroke)

        return ContactsViewStyle(backgroundColor: R.color.brandWhite()!,
                                 searchHeaderBackgroundColor: R.color.brandWhite()!,
                                 searchTextStyle: searchTextStyle,
                                 searchPlaceholderStyle: searchPlaceholderStyle,
                                 searchFieldStyle: searchFieldStyle,
                                 searchIndicatorStyle: R.color.baseBorderSecondary()!,
                                 searchIcon: R.image.helpIcon(),
                                 searchSeparatorColor: .clear,
                                 tableSeparatorColor: R.color.baseBorderSecondary()!,
                                 actionsSeparator: WalletStrokeStyle(color: .clear, lineWidth: 0.0))
    }()

    private lazy var contactCellStyle: ContactCellStyleProtocol = {
        let iconStyle = WalletNameIconStyle(background: .white,
                                            title: WalletTextStyle(font: UIFont.styled(for: .paragraph3), color: .black),
                                            radius: 12.0)
        return ContactCellStyle(title:
                                    WalletTextStyle(font: UIFont.styled(for: .paragraph3),
                                                    color: .white),
                                nameIcon: iconStyle,
                                accessoryIcon: R.image.iconSmallArrow(),
                                lineBreakMode: .byTruncatingMiddle,
                                selectionColor: R.color.brandSoramitsuRed()!.withAlphaComponent(0.3))
    }()

    private lazy var sectionHeaderStyle: ContactsSectionStyleProtocol = {
        let title = WalletTextStyle(font: UIFont.styled(for: .uppercase1),
                                    color: R.color.baseBorderSecondary()!)
        return ContactsSectionStyle(title: title,
                                    uppercased: true,
                                    height: 0.0,
                                    displaysSeparatorForLastCell: false)
    }()

    init(networkType: SNAddressType) {
        let viewModelFactory = ContactsViewModelFactory(dataStorageFacade: SubstrateDataStorageFacade.shared)
        localSearchEngine = ContactsLocalSearchEngine(networkType: networkType,
                                                      contactViewModelFactory: viewModelFactory)
    }

    func configure(builder: ContactsModuleBuilderProtocol) {
        let listViewModelFactory = ContactsListViewModelFactory()

        let searchPlaceholder = LocalizableResource { locale in
            R.string.localizable
                .selectAccountAddress(preferredLanguages: LocalizationManager.shared.selectedLocale.rLanguages)
        }

        builder
            .with(cellClass: ContactTableViewCell.self, for: ContactsConstants.contactCellIdentifier)
            .with(localSearchEngine: localSearchEngine)
            .with(listViewModelFactory: listViewModelFactory)
            .with(canFindItself: false)
            .with(supportsLiveSearch: true)
            .with(searchEmptyStateDataSource: WalletEmptyStateDataSource.search)
            .with(contactsEmptyStateDataSource: WalletEmptyStateDataSource.contacts)
            .with(viewStyle: contactsViewStyle)
            .with(contactCellStyle: contactCellStyle)
            .with(sectionHeaderStyle: sectionHeaderStyle)
            .with(searchPlaceholder: searchPlaceholder)
            .with(viewModelFactoryWrapper: localSearchEngine.contactViewModelFactory)
    }
}
