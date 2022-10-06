# BitcoinKit.Swift

Bitcoin wallet toolkit for Swift. This is a full implementation of SPV node including wallet creation/restore, synchronization with network, send/receive transactions, and more.


## Features

- Full SPV implementation for fast mobile performance
- Send/Receive Legacy transactions (*P2PKH*, *P2PK*, *P2SH*)
- [BIP32](https://github.com/bitcoin/bips/blob/master/bip-0032.mediawiki) hierarchical deterministic wallets implementation.
- [BIP39](https://github.com/bitcoin/bips/blob/master/bip-0039.mediawiki) mnemonic code for generating deterministic keys.
- [BIP44](https://github.com/bitcoin/bips/blob/master/bip-0044.mediawiki) multi-account hierarchy for deterministic wallets.
- [BIP21](https://github.com/bitcoin/bips/blob/master/bip-0021.mediawiki) URI schemes, which include payment address, amount, label and other params

### BitcoinKit.swift
- Send/Receive Segwit transactions (*P2WPKH*)
- Send/Receive Segwit transactions compatible with legacy wallets (*P2WPKH-SH*)
- base58, bech32

## Usage

### Initialization

*Kit* requires you to provide mnemonic phrase when it is initialized:

```swift
let words = ["word1", ... , "word12"]
```

#### Bitcoin

```swift
let bitcoinKit = BitcoinKit(withWords: words, walletId: "bitcoin-wallet-id", syncMode: .api, networkType: .mainNet)
```

*Kit* can be configured to work in `.mainNet` or `.testNet`. 

##### `syncMode` parameter
*Kit* can restore existing wallet or create a new one. When restoring, it generates addresses for given wallet according to bip44 protocol, then it pulls all historical transactions for each of those addresses. This is done only once on initial sync. `syncMode` parameter defines where it pulls historical transactions from. When they are pulled, it continues to sync according to [SPV](https://en.bitcoinwiki.org/wiki/Simplified_Payment_Verification) protocol no matter which syncMode was used for initial sync. There are 3 modes available:

- `.full`: Fully synchronizes from peer-to-peer network starting from the block when bip44 was introduced. This mode is the most private (since it fully complies with [SPV](https://en.bitcoinwiki.org/wiki/Simplified_Payment_Verification) protocol), but it takes approximately 2 hours to sync up to now (June 10, 2019).
- `.api`: Transactions before checkpoint are pulled from API(currently [Insight API](https://github.com/bitpay/insight-api) or [BcoinAPI](http://bcoin.io/api-docs/)). Then the rest is synchronized from peer-to-peer network. This is the fastest one, but it's possible for an attacker to learn which addresses you own. Checkpoints are updated with each new release and hardcoded so the blocks validation is not broken.
- `.newWallet`: No need to pull transactions.

##### Additional parameters:
- `confirmationsThreshold`: Minimum number of confirmations required for an unspent output in incoming transaction to be spent (*default: 6*)
- `minLogLevel`: Can be configured for debug purposes if required.

### Starting and Stopping

*Kit* require to be started with `start` command. It will be in synced state as long as it is possible. You can call `stop` to stop it

```swift
bitcoinKit.start()
bitcoinKit.stop()
```

### Getting wallet data

*Kit* hold all kinds of data obtained from and needed for working with blockchain network

#### Current Balance

Balance is provided in `Satoshi`:

```swift
bitcoinKit.balance

// 2937096768
```

#### Last Block Info

Last block info contains `headerHash`, `height` and `timestamp` that can be used for displaying sync info to user:

```swift
bitcoinKit.lastBlockInfo 

// ▿ Optional<BlockInfo>
//  ▿ some : BlockInfo
//    - headerHash : //"00000000000041ae2164b486398415cca902a41214cad72291ee04b212bed4c4"
//    - height : 1446751
//    ▿ timestamp : Optional<Int>
//      - some : 1544097931
```

#### Receive Address

Get an address which you can receive coins to. Receive address is changed each time after you actually get a transaction in which you receive coins to that address

```swift
bitcoinKit.receiveAddress

// "mgv1KTzGZby57K5EngZVaPdPtphPmEWjiS"
```

#### Transactions

*Kit* have `transactions(fromHash: nil, limit: nil)` methods which return `Single<TransactionInfo>`(for BitcoinKit and BitcoinCashKit) [RX Single Observers](https://github.com/ReactiveX/RxSwift/blob/master/Documentation/Traits.md#single).

`TransactionInfo`:
```swift
//   ▿ TransactionInfo
//     - transactionHash : "0f83c9b330f936dc4a2458b7d3bb06dce6647a521bf6d98f9c9d3cdd5f6d2a73"
//     - transactionIndex : 500000
//     ▿ from : 2 elements
//       ▿ 0 : TransactionAddressInfo
//         - address : "mft8jpnf3XwwqhaYSYMSXePFN85mGU4oBd"
//         - mine : true
//       ▿ 1 : TransactionAddressInfo
//         - address : "mnNS5LEQDnYC2xqT12MnQmcuSvhfpem8gt"
//         - mine : true
//     ▿ to : 2 elements
//       ▿ 0 : TransactionAddressInfo
//         - address : "n43efNftHQ1cXYMZK4Dc53wgR6XgzZHGjs"
//         - mine : false
//       ▿ 1 : TransactionAddressInfo
//         - address : "mrjQyzbX9SiJxRC2mQhT4LvxFEmt9KEeRY"
//         - mine : true
//     - amount : -800378
//     ▿ blockHeight : Optional<Int>
//       - some : 1446602
//    ▿ timestamp : Optional<Int>
//       - some : 1543995972
```

### Creating new transaction

In order to create new transaction, call `send(to: String, value: Int, feeRate: Int)` method on *Kits*

```swift
try bitcoinKit.send(to: "mrjQyzbX9SiJxRC2mQhT4LvxFEmt9KEeRY", value: 1000000, feeRate: 10000)
```

This first validates a given address and amount, creates new transaction, then sends it over the peers network. If there's any error with given address/amount or network, it raises an exception.

#### Validating transaction before send

One can validate address and fee by using following methods:

```swift
try bitcoinKit.validate(address: "mrjQyzbX9SiJxRC2mQhT4LvxFEmt9KEeRY")
try bitcoinKit.fee(for: 1000000, toAddress: "mrjQyzbX9SiJxRC2mQhT4LvxFEmt9KEeRY", senderPay: true, feeRate: 10000)
```
`senderPay` parameter defines who pays the fee

### Parsing BIP21 URI

You can use `parse` method to parse a BIP21 URI:

```swift
bitcoinKit.parse(paymentAddress: "bitcoin:175tWpb8K1S7NmH4Zx6rewF9WQrcZv245W?amount=50&label=Luke-Jr&message=Donation%20for%20project%20xyz")

// ▿ BitcoinPaymentData
//   - address : "175tWpb8K1S7NmH4Zx6rewF9WQrcZv245W"
//   - version : nil
//   ▿ amount : Optional<Double>
//     - some : 50.0
//   ▿ label : Optional<String>
//     - some : "Luke-Jr"
//   ▿ message : Optional<String>
//     - some : "Donation for project xyz"
//   - parameters : nil

```

### Subscribing to BitcoinKit data

*Kits* provide with data like transactions, blocks, balance, kits state in real-time. `BitcoinCoreDelegate` protocol must be implemented and set to *Kits* instance to receive that data.

```swift
class Manager {

	init(words: [String]) {
		bitcoinKit = BitcoinKit(withWords: words, walletId: "bitcoin-wallet-id")
        bitcoinKit.delegate = self
    }

}

extension Manager: BitcoinCoreDelegate {

    func transactionsUpdated(inserted: [TransactionInfo], updated: [TransactionInfo]) {
    }

    func transactionsDeleted(hashes: [String]) {
    }

    func balanceUpdated(balance: Int) {
    }

    func lastBlockInfoUpdated(lastBlockInfo: BlockInfo) {
    }

    public func kitStateUpdated(state: BitcoinCore.KitState) {
		// BitcoinCore.KitState can be one of 3 following states:
		// .synced
		// .syncing(progress: Double)
		// .notSynced
		// 
		// These states can be used to implement progress bar, etc
    }
    
}
```
Listener events are run in a dedicated background thread. It can be switched to main thread by setting the  ```delegateQueue``` property to ```DispatchQueue.main```

```swift
bitcoinKit.delegateQueue = DispatchQueue.main
```

## Prerequisites

* Xcode 10.0+
* Swift 5+
* iOS 11+

## Installation

### Swift Package Manager

The [Swift Package Manager](https://swift.org/package-manager/) is a tool for automating the distribution of Swift code
and is integrated into the `swift` compiler. It is in early development, but DashCryptoKit does support its use on
supported platforms.

Once you have your Swift package set up, adding DashCryptoKit as a dependency is as easy as adding it to
the `dependencies` value of your `Package.swift`.

```swift
dependencies: [
    .package(url: "https://github.com/horizontalsystems/BitcoinKit.Swift.git", .upToNextMajor(from: "1.0.0"))
]
```

## Example Project

All features of the library are used in example project. It can be referred as a starting point for usage of the library.

## License

The `BitcoinKit` toolkit is open source and available under the terms of the [MIT License](https://github.com/horizontalsystems/BitcoinKit.Swift/blob/master/LICENSE).

