import BitcoinCore
import HdWalletKit
import HsToolKit

class Configuration {
    static let shared = Configuration()

    let minLogLevel: Logger.Level = .verbose
    let testNet = false
    let purpose = Purpose.bip84
    let defaultWords = [
        //        "current force clump paper shrug extra zebra employ prefer upon mobile hire",
        "popular game latin harvest silly excess much valid elegant illness edge silk",
    ]
}
