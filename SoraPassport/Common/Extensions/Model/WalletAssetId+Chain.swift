import Foundation
import IrohaCrypto

extension WalletAssetId {
    var chain: Chain? {
        switch self {
        case .xor:
            return .sora
        case .val:
            return .sora
        case .pswap:
            return .sora
        }
    }

    var chainId: String {
        switch self {
        case .pswap:
            return "0x0200050000000000000000000000000000000000000000000000000000000000"
        case .val:
            return "0x0200040000000000000000000000000000000000000000000000000000000000"
        case .xor:
            return "0x0200000000000000000000000000000000000000000000000000000000000000"
        }
    }

    var isFeeAsset: Bool {
        switch self {
        case .xor:
            return true
        default:
            return false
        }
    }
}
