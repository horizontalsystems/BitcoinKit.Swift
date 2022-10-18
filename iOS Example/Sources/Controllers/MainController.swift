import UIKit

class MainController: UITabBarController {
    public var watchAccount: Bool = false

    override func viewDidLoad() {
        super.viewDidLoad()

        var controllers = [UIViewController]()

        let balanceNavigation = UINavigationController(rootViewController: BalanceController())
        balanceNavigation.tabBarItem.title = "Balance"
        balanceNavigation.tabBarItem.image = UIImage(named: "Balance Tab Bar Icon")

        controllers.append(balanceNavigation)

        let transactionsNavigation = UINavigationController(rootViewController: TransactionsController())
        transactionsNavigation.tabBarItem.title = "Transactions"
        transactionsNavigation.tabBarItem.image = UIImage(named: "Transactions Tab Bar Icon")

        controllers.append(transactionsNavigation)

        if !watchAccount {
            let sendNavigation = UINavigationController(rootViewController: SendController())
            sendNavigation.tabBarItem.title = "Send"
            sendNavigation.tabBarItem.image = UIImage(named: "Send Tab Bar Icon")

            controllers.append(sendNavigation)
        }

        let receiveNavigation = UINavigationController(rootViewController: ReceiveController())
        receiveNavigation.tabBarItem.title = "Receive"
        receiveNavigation.tabBarItem.image = UIImage(named: "Receive Tab Bar Icon")

        controllers.append(receiveNavigation)
        viewControllers = controllers
    }

}
