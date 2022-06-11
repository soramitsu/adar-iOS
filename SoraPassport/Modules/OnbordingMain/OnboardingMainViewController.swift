import UIKit
import SoraUI
import SoraFoundation

final class OnboardingMainViewController: UIViewController, OnboardingMainViewProtocol, HiddableBarWhenPushed {
    var presenter: OnboardingMainPresenterProtocol!

    @IBOutlet weak var logo: UIImageView!
    @IBOutlet weak var createAccountButton: NeumorphismButton!
    @IBOutlet weak var importAccountButton: NeumorphismButton!

    @IBOutlet weak var logoTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var logoToTitleConstraint: NSLayoutConstraint!
    @IBOutlet weak var titleToSubtitleConstraint: NSLayoutConstraint!
    @IBOutlet weak var subtitleToDescriptionConstraint: NSLayoutConstraint!

    let soraLabelText = "SORA"

    var locale: Locale?

    override func viewDidLoad() {
        super.viewDidLoad()

        configure()
        presenter.setup()
    }

    func configure() {
        view.backgroundColor = R.color.neumorphism.base()
        logo.image = R.image.adarlogo()
        configureButtons()
    }

    fileprivate func configureButtons() {
        let locale = locale ?? Locale.current

        createAccountButton.setTitle(R.string.localizable.create_account_title(preferredLanguages: locale.rLanguages), for: .normal)
        createAccountButton.font = UIFont.styled(for: .button)
        createAccountButton.color = R.color.neumorphism.buttonDarkGrey()!
        importAccountButton.setTitle(R.string.localizable.recoveryTitleV2(preferredLanguages: locale.rLanguages), for: .normal)
        importAccountButton.font = UIFont.styled(for: .button)
        importAccountButton.setTitleColor(R.color.neumorphism.buttonTextDark(), for: .normal)
    }

    @IBAction func createAccountPressed(_ sender: Any) {
        presenter.activateSignup()
    }

    @IBAction func importAccountPressed(_ sender: Any) {
        presenter.activateAccountRestore()
    }
}
