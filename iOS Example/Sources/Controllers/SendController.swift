import BitcoinCore
import Combine
import Hodler
import UIKit

class SendController: UIViewController {
    private var cancellables = Set<AnyCancellable>()

    @IBOutlet var addressTextField: UITextField?
    @IBOutlet var amountTextField: UITextField?
    @IBOutlet var coinLabel: UILabel?
    @IBOutlet var feeLabel: UILabel?
    @IBOutlet var timeLockSwitch: UISwitch?
    @IBOutlet var sendButton: UIButton!
    @IBOutlet var picker: UIPickerView?

    private var timeIntervalStrings = ["Hour", "Month", "Half Year", "Year"]
    private var timeIntervals: [HodlerPlugin.LockTimeInterval] = [.hour, .month, .halfYear, .year]
    private var selectedTimeInterval: HodlerPlugin.LockTimeInterval = .hour

    private var adapter: BaseAdapter?
    private let segmentedControl = UISegmentedControl()
    private var timeLockEnabled = false

    override func viewDidLoad() {
        super.viewDidLoad()

        segmentedControl.addTarget(self, action: #selector(onSegmentChanged), for: .valueChanged)
        picker?.dataSource = self
        picker?.delegate = self

        Manager.shared.adapterSubject
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.updateAdapters()
            }
            .store(in: &cancellables)

        updateAdapters()
    }

    private func updateAdapters() {
        segmentedControl.removeAllSegments()

        adapter = Manager.shared.adapter

        if let adapter {
            segmentedControl.insertSegment(withTitle: adapter.coinCode, at: 0, animated: false)
        }

        if let adapter = adapter as? BitcoinAdapter {
            update(watchAccount: adapter.watchAccount)
        }

        navigationItem.titleView = segmentedControl

        segmentedControl.selectedSegmentIndex = 0
        segmentedControl.sendActions(for: .valueChanged)
    }

    private func update(watchAccount: Bool) {
        addressTextField?.isEnabled = !watchAccount
        amountTextField?.isEnabled = !watchAccount
        feeLabel?.isEnabled = !watchAccount
        timeLockSwitch?.isEnabled = !watchAccount
        picker?.isHidden = watchAccount
        sendButton.isEnabled = !watchAccount
    }

    private func updateFee() {
        var address: String? = nil

        if let addressStr = addressTextField?.text {
            do {
                try currentAdapter?.validate(address: addressStr)
                address = addressStr
            } catch {}
        }

        guard let amountString = amountTextField?.text, let amount = Decimal(string: amountString) else {
            feeLabel?.text = "Fee: "
            return
        }

        var pluginData = [UInt8: IPluginData]()
        if timeLockEnabled {
            pluginData[HodlerPlugin.id] = HodlerData(lockTimeInterval: selectedTimeInterval)
        }

        if let fee = currentAdapter?.fee(for: amount, address: address, pluginData: pluginData) {
            feeLabel?.text = "Fee: \(fee.formattedAmount)"
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)

        view.endEditing(true)
    }

    @objc func onSegmentChanged() {
        coinLabel?.text = currentAdapter?.coinCode
        updateFee()
    }

    @IBAction func onAddressEditEnded(_: Any) {
        updateFee()
    }

    @IBAction func onAmountEditEnded(_: Any) {
        updateFee()
    }

    @IBAction func onTimeLockSwitchToggle(_: Any) {
        timeLockEnabled = !timeLockEnabled
        updateFee()
    }

    @IBAction func setMaxAmount() {
        var address: String? = nil

        if let addressStr = addressTextField?.text {
            do {
                try currentAdapter?.validate(address: addressStr)
                address = addressStr
            } catch {}
        }

        var pluginData = [UInt8: IPluginData]()
        if timeLockEnabled {
            pluginData[HodlerPlugin.id] = HodlerData(lockTimeInterval: selectedTimeInterval)
        }

        if let maxAmount = currentAdapter?.availableBalance(for: address, pluginData: pluginData) {
            amountTextField?.text = "\(maxAmount)"
            onAmountEditEnded(0)
        }
    }

    @IBAction func setMinAmount() {
        var address: String? = nil

        if let addressStr = addressTextField?.text {
            do {
                try currentAdapter?.validate(address: addressStr)
                address = addressStr
            } catch {}
        }

        if let minAmount = try? currentAdapter?.minSpendableAmount(for: address) {
            amountTextField?.text = "\(minAmount)"
            onAmountEditEnded(0)
        }
    }

    @IBAction func send() {
        guard let address = addressTextField?.text else {
            return
        }

        do {
            try currentAdapter?.validate(address: address)
        } catch {
            show(error: "Invalid address")
            return
        }

        guard let amountString = amountTextField?.text, let amount = Decimal(string: amountString) else {
            show(error: "Invalid amount")
            return
        }

        var pluginData = [UInt8: IPluginData]()
        if timeLockEnabled {
            pluginData[HodlerPlugin.id] = HodlerData(lockTimeInterval: selectedTimeInterval)
        }

        do {
            try currentAdapter?.send(to: address, amount: amount, sortType: .shuffle, pluginData: pluginData)

            addressTextField?.text = ""
            amountTextField?.text = ""

            showSuccess(address: address, amount: amount)
        } catch {
            show(error: "Send failed: \(error)")
        }
    }

    private func show(error: String) {
        let alert = UIAlertController(title: "Send Error", message: error, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .cancel))
        present(alert, animated: true)
    }

    private func showSuccess(address: String, amount: Decimal) {
        let alert = UIAlertController(title: "Success", message: "\(amount.formattedAmount) sent to \(address)", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .cancel))
        present(alert, animated: true)
    }

    private var currentAdapter: BaseAdapter? {
        guard segmentedControl.selectedSegmentIndex != -1, segmentedControl.selectedSegmentIndex < 1 else {
            return nil
        }

        return adapter
    }
}

extension SendController: UIPickerViewDataSource {
    public func numberOfComponents(in _: UIPickerView) -> Int {
        1
    }

    public func pickerView(_: UIPickerView, numberOfRowsInComponent _: Int) -> Int {
        timeIntervals.count
    }
}

extension SendController: UIPickerViewDelegate {
    public func pickerView(_: UIPickerView, widthForComponent _: Int) -> CGFloat {
        130
    }

    public func pickerView(_: UIPickerView, rowHeightForComponent _: Int) -> CGFloat {
        30
    }

    public func pickerView(_: UIPickerView, titleForRow row: Int, forComponent _: Int) -> String? {
        timeIntervalStrings[row]
    }

    public func pickerView(_: UIPickerView, didSelectRow row: Int, inComponent _: Int) {
        selectedTimeInterval = timeIntervals[row]
    }
}
