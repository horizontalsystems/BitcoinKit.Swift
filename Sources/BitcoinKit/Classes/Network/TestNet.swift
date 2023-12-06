import BitcoinCore

class TestNet: INetwork {
    private static let testNetDiffDate = 1_329_264_000 // February 16th 2012

    let bundleName = "Bitcoin"

    let pubKeyHash: UInt8 = 0x6F
    let privateKey: UInt8 = 0xEF
    let scriptHash: UInt8 = 0xC4
    let bech32PrefixPattern: String = "tb"
    let xPubKey: UInt32 = 0x0435_87CF
    let xPrivKey: UInt32 = 0x0435_8394
    let magic: UInt32 = 0x0B11_0907
    let port = 18333
    let coinType: UInt32 = 1
    let sigHash: SigHashType = .bitcoinAll
    var syncableFromApi: Bool = true
    var blockchairChainId: String = "bitcoin/testnet"

    let dnsSeeds = [
        "testnet-seed.bitcoin.petertodd.org", // Peter Todd
        "testnet-seed.bitcoin.jonasschnelli.ch", // Jonas Schnelli
        "testnet-seed.bluematt.me", // Matt Corallo
        "testnet-seed.bitcoin.schildbach.de", // Andreas Schildbach
        "bitcoin-testnet.bloqseeds.net", // Bloq
    ]

    let dustRelayTxFee = 3000 // https://github.com/bitcoin/bitcoin/blob/c536dfbcb00fb15963bf5d507b7017c241718bf6/src/policy/policy.h#L50
}
