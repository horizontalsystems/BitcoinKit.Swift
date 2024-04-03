import BitcoinCore
import Combine
import Foundation
import HdWalletKit
import HsToolKit

class Manager {
    static let shared = Manager()
    private static let syncModes: [BitcoinCore.SyncMode] = [.full, .api]

    private let restoreDataKey = "restore_data"
    private let syncModeKey = "syncMode"

    let adapterSubject = PassthroughSubject<Void, Never>()
    var adapter: BitcoinAdapter?

    init() {
        if let restoreData = savedRestoreData, let syncModeIndex = savedSyncModeIndex {
            DispatchQueue.global(qos: .userInitiated).async {
                self.initAdapter(restoreData: restoreData, syncMode: Manager.syncModes[syncModeIndex])
            }
        }
    }

    func login(restoreData: String, syncModeIndex: Int) {
        save(restoreData: restoreData)
        save(syncModeIndex: syncModeIndex)
        clearKits()

        DispatchQueue.global(qos: .userInitiated).async {
            self.initAdapter(restoreData: restoreData, syncMode: Manager.syncModes[syncModeIndex])
        }
    }

    func logout() {
        clearUserDefaults()
        adapter = nil
    }

    private func initAdapter(restoreData: String, syncMode: BitcoinCore.SyncMode) {
        let configuration = Configuration.shared
        let logger = Logger(minLogLevel: Configuration.shared.minLogLevel)

        let words = restoreData.components(separatedBy: .whitespacesAndNewlines)
        if words.count > 1 {
            adapter = BitcoinAdapter(words: words, purpose: configuration.purpose, testMode: configuration.testNet, syncMode: syncMode, logger: logger)
        } else {
            do {
                _ = try HDExtendedKey(extendedKey: restoreData)
                adapter = BitcoinAdapter(extendedKey: restoreData, purpose: configuration.purpose, testMode: configuration.testNet, syncMode: syncMode, logger: logger)
            } catch {
                adapter = nil
            }
        }

        adapterSubject.send()
    }

    var savedRestoreData: String? {
        UserDefaults.standard.value(forKey: restoreDataKey) as? String
    }

    var savedSyncModeIndex: Int? {
        if let syncModeIndex = UserDefaults.standard.value(forKey: syncModeKey) as? Int {
            return syncModeIndex
        }
        return nil
    }

    private func save(restoreData: String) {
        UserDefaults.standard.set(restoreData, forKey: restoreDataKey)
        UserDefaults.standard.synchronize()
    }

    private func save(syncModeIndex: Int) {
        UserDefaults.standard.set(syncModeIndex, forKey: syncModeKey)
        UserDefaults.standard.synchronize()
    }

    private func clearUserDefaults() {
        UserDefaults.standard.removeObject(forKey: restoreDataKey)
        UserDefaults.standard.removeObject(forKey: syncModeKey)
        UserDefaults.standard.synchronize()
    }

    private func clearKits() {
        BitcoinAdapter.clear()
    }
}
