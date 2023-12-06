import BitcoinCore
import Combine
import UIKit

class ReceiveController: UIViewController {
    private var cancellables = Set<AnyCancellable>()

    @IBOutlet var addressLabel: UILabel?

    private var adapter: BaseAdapter?
    private let segmentedControl = UISegmentedControl()

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Receive"

        addressLabel?.layer.cornerRadius = 8
        addressLabel?.clipsToBounds = true

        Manager.shared.adapterSubject
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.updateAdapters()
            }
            .store(in: &cancellables)

        updateAdapters()
        segmentedControl.addTarget(self, action: #selector(onSegmentChanged), for: .valueChanged)
    }

    private func updateAdapters() {
        segmentedControl.removeAllSegments()

        adapter = Manager.shared.adapter

        if let adapter {
            segmentedControl.insertSegment(withTitle: adapter.coinCode, at: 0, animated: false)
        }

        navigationItem.titleView = segmentedControl

        segmentedControl.selectedSegmentIndex = 0
        segmentedControl.sendActions(for: .valueChanged)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        segmentedControl.sendActions(for: .valueChanged)
    }

    @objc func onSegmentChanged() {
        updateAddress()

        currentAdapter?.printDebugs()
    }

    func updateAddress() {
        addressLabel?.text = "  \(currentAdapter?.receiveAddress() ?? "")  "
    }

    @IBAction func onAddressTypeChanged(_: Any) {
        updateAddress()
    }

    @IBAction func copyToClipboard() {
        if let address = addressLabel?.text?.trimmingCharacters(in: .whitespaces) {
            UIPasteboard.general.setValue(address, forPasteboardType: "public.plain-text")

            let alert = UIAlertController(title: "Success", message: "Address copied", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .cancel))
            present(alert, animated: true)
        }
    }

    private var currentAdapter: BaseAdapter? {
        guard segmentedControl.selectedSegmentIndex != -1, segmentedControl.selectedSegmentIndex < 1 else {
            return nil
        }

        return adapter
    }
}
