import Foundation
import BitcoinKit
import BitcoinCore
import HdWalletKit
import HsToolKit
import RxSwift

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

    init(extendedKey: String, testMode: Bool, syncMode: BitcoinCore.SyncMode, logger: Logger) {
        let networkType: Kit.NetworkType = testMode ? .testNet : .mainNet

        let extendedKey = try! HDExtendedKey(extendedKey: extendedKey)
        bitcoinKit = try! Kit(extendedKey: extendedKey, walletId: "walletId", syncMode: syncMode, networkType: networkType, confirmationsThreshold: 1, logger: logger.scoped(with: "BitcoinKit"))

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

    func transactionsUpdated(inserted: [TransactionInfo], updated: [TransactionInfo]) {
        transactionsSignal.notify()
    }

    func transactionsDeleted(hashes: [String]) {
        transactionsSignal.notify()
    }

    func balanceUpdated(balance: BalanceInfo) {
        balanceSignal.notify()
    }

    func lastBlockInfoUpdated(lastBlockInfo: BlockInfo) {
        lastBlockSignal.notify()
    }

    public func kitStateUpdated(state: BitcoinCore.KitState) {
        syncStateSignal.notify()
    }

}
