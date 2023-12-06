import BitcoinCore
import Combine
import Foundation

class BaseAdapter {
    var feeRate: Int { 3 }
    private let coinRate: Decimal = pow(10, 8)

    let name: String
    let coinCode: String

    private let abstractKit: AbstractKit

    let lastBlockSubject = PassthroughSubject<Void, Never>()
    let syncStateSubject = PassthroughSubject<Void, Never>()
    let balanceSubject = PassthroughSubject<Void, Never>()
    let transactionsSubject = PassthroughSubject<Void, Never>()

    init(name: String, coinCode: String, abstractKit: AbstractKit) {
        self.name = name
        self.coinCode = coinCode
        self.abstractKit = abstractKit
    }

    func transactionRecord(fromTransaction transaction: TransactionInfo) -> TransactionRecord {
        var from = [TransactionInputOutput]()
        var to = [TransactionInputOutput]()

        for input in transaction.inputs {
            from.append(TransactionInputOutput(
                mine: input.mine, address: input.address, value: input.value,
                changeOutput: false, pluginId: nil, pluginData: nil
            ))
        }

        for output in transaction.outputs {
            guard output.value > 0 else {
                continue
            }

            to.append(TransactionInputOutput(
                mine: output.mine, address: output.address, value: output.value,
                changeOutput: output.changeOutput, pluginId: output.pluginId, pluginData: output.pluginData
            ))
        }

        return TransactionRecord(
            uid: transaction.uid,
            transactionHash: transaction.transactionHash,
            transactionIndex: transaction.transactionIndex,
            interTransactionIndex: 0,
            status: TransactionStatus(rawValue: transaction.status.rawValue) ?? TransactionStatus.new,
            type: transaction.type,
            blockHeight: transaction.blockHeight,
            amount: Decimal(transaction.amount) / coinRate,
            fee: transaction.fee.map { Decimal($0) / coinRate },
            date: Date(timeIntervalSince1970: Double(transaction.timestamp)),
            from: from,
            to: to,
            conflictingHash: transaction.conflictingHash
        )
    }

    private func convertToSatoshi(value: Decimal) -> Int {
        let coinValue: Decimal = value * coinRate

        let handler = NSDecimalNumberHandler(roundingMode: .plain, scale: 0, raiseOnExactness: false, raiseOnOverflow: false, raiseOnUnderflow: false, raiseOnDivideByZero: false)
        return NSDecimalNumber(decimal: coinValue).rounding(accordingToBehavior: handler).intValue
    }

    func transactions(fromUid: String?, type: TransactionFilterType? = nil, limit: Int) -> [TransactionRecord] {
        abstractKit.transactions(fromUid: fromUid, type: type, limit: limit)
            .compactMap {
                transactionRecord(fromTransaction: $0)
            }
    }
}

extension BaseAdapter {
    var lastBlockPublisher: AnyPublisher<Void, Never> {
        lastBlockSubject
            .throttle(for: .milliseconds(200), scheduler: RunLoop.current, latest: true)
            .eraseToAnyPublisher()
    }

    var syncStatePublisher: AnyPublisher<Void, Never> {
        syncStateSubject
            .throttle(for: .milliseconds(200), scheduler: RunLoop.current, latest: true)
            .eraseToAnyPublisher()
    }

    var balancePublisher: AnyPublisher<Void, Never> {
        balanceSubject.eraseToAnyPublisher()
    }

    var transactionsPublisher: AnyPublisher<Void, Never> {
        transactionsSubject.eraseToAnyPublisher()
    }

    func start() {
        abstractKit.start()
    }

    func refresh() {
        abstractKit.start()
    }

    var spendableBalance: Decimal {
        Decimal(abstractKit.balance.spendable) / coinRate
    }

    var unspendableBalance: Decimal {
        Decimal(abstractKit.balance.unspendable) / coinRate
    }

    var lastBlockInfo: BlockInfo? {
        abstractKit.lastBlockInfo
    }

    var syncState: BitcoinCore.KitState {
        abstractKit.syncState
    }

    func receiveAddress() -> String {
        abstractKit.receiveAddress()
    }

    func validate(address: String) throws {
        try abstractKit.validate(address: address)
    }

    func validate(amount: Decimal, address: String?) throws {
        guard amount <= availableBalance(for: address) else {
            throw SendError.insufficientAmount
        }
    }

    func send(to address: String, amount: Decimal, sortType: TransactionDataSortType, pluginData: [UInt8: IPluginData] = [:]) throws {
        let satoshiAmount = convertToSatoshi(value: amount)
        _ = try abstractKit.send(to: address, value: satoshiAmount, feeRate: feeRate, sortType: sortType, pluginData: pluginData)
    }

    func availableBalance(for address: String?, pluginData: [UInt8: IPluginData] = [:]) -> Decimal {
        let amount = (try? abstractKit.maxSpendableValue(toAddress: address, feeRate: feeRate, pluginData: pluginData)) ?? 0
        return Decimal(amount) / coinRate
    }

    func maxSpendLimit(pluginData: [UInt8: IPluginData]) -> Int? {
        do {
            return try abstractKit.maxSpendLimit(pluginData: pluginData)
        } catch {
            return 0
        }
    }

    func minSpendableAmount(for address: String?) throws -> Decimal {
        try Decimal(abstractKit.minSpendableValue(toAddress: address)) / coinRate
    }

    func fee(for value: Decimal, address: String?, pluginData: [UInt8: IPluginData] = [:]) -> Decimal {
        do {
            let amount = convertToSatoshi(value: value)
            let fee = try abstractKit.fee(for: amount, toAddress: address, feeRate: feeRate, pluginData: pluginData)
            return Decimal(fee) / coinRate
        } catch {
            return 0
        }
    }

    func printDebugs() {
        print(abstractKit.debugInfo)
        print()
        print(abstractKit.statusInfo)
    }

    func rawTransaction(transactionHash: String) -> String? {
        abstractKit.rawTransaction(transactionHash: transactionHash)
    }
}

enum SendError: Error {
    case insufficientAmount
}
