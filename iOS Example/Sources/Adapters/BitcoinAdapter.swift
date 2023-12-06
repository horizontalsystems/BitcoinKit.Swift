import BitcoinCore
import BitcoinKit
import Foundation
import HdWalletKit
import HsToolKit

class BitcoinAdapter: BaseAdapter {
    let bitcoinKit: Kit

    init(words: [String], purpose: Purpose, testMode: Bool, syncMode: BitcoinCore.SyncMode, logger: Logger) {
        let networkType: Kit.NetworkType = testMode ? .testNet : .mainNet
        guard let seed = Mnemonic.seed(mnemonic: words) else {
            fatalError("Cant create BitcoinSeed")
        }

        bitcoinKit = try! Kit(seed: seed, purpose: purpose, walletId: "walletId", syncMode: syncMode, networkType: networkType, confirmationsThreshold: 1, logger: logger.scoped(with: "BitcoinKit"))

        super.init(name: "Bitcoin", coinCode: "BTC", abstractKit: bitcoinKit)
        bitcoinKit.delegate = self
    }

    init(extendedKey: String, purpose: Purpose, testMode: Bool, syncMode: BitcoinCore.SyncMode, logger: Logger) {
        let networkType: Kit.NetworkType = testMode ? .testNet : .mainNet

        let extendedKey = try! HDExtendedKey(extendedKey: extendedKey)
        bitcoinKit = try! Kit(extendedKey: extendedKey, purpose: purpose, walletId: "walletId", syncMode: syncMode, networkType: networkType, confirmationsThreshold: 1, logger: logger.scoped(with: "BitcoinKit"))

        super.init(name: "Bitcoin", coinCode: "BTC", abstractKit: bitcoinKit)
        bitcoinKit.delegate = self
    }

    class func clear() {
        try? Kit.clear()
    }
}

extension BitcoinAdapter: BitcoinCoreDelegate {
    var watchAccount: Bool {
        bitcoinKit.watchAccount
    }

    func transactionsUpdated(inserted _: [TransactionInfo], updated _: [TransactionInfo]) {
        transactionsSubject.send()
    }

    func transactionsDeleted(hashes _: [String]) {
        transactionsSubject.send()
    }

    func balanceUpdated(balance _: BalanceInfo) {
        balanceSubject.send()
    }

    func lastBlockInfoUpdated(lastBlockInfo _: BlockInfo) {
        lastBlockSubject.send()
    }

    public func kitStateUpdated(state _: BitcoinCore.KitState) {
        syncStateSubject.send()
    }
}
