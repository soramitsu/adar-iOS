import Foundation
import UIKit
import Lottie
import SnapKit

class SplashViewController: UIViewController, SplashViewProtocol {

    var presenter: SplashPresenter!

    private lazy var splash: SplashView = {
        return R.nib.launchScreen(owner: nil)!
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(splash)
        splash.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }

    func animate(duration animationDurationBase: Double, completion: @escaping () -> Void) {
        completion()
    }
}
