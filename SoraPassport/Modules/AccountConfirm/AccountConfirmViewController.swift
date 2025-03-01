/**
* Copyright Soramitsu Co., Ltd. All Rights Reserved.
* SPDX-License-Identifier: Apache 2.0
*/

import UIKit
import SoraFoundation
import SoraUI
import AudioToolbox

final class AccountConfirmViewController: UIViewController, AdaptiveDesignable {
    private struct Constants {
        static let externalMargin: CGFloat = 6.0
        static let itemsSpacing: CGFloat = 8.0
        static let internalMargin: CGFloat = 2.0
        static let itemContentInsets: UIEdgeInsets = UIEdgeInsets(top: 6.0,
                                                                  left: 8.0,
                                                                  bottom: 6.0,
                                                                  right: 8.0)
        static let cornerRadius: CGFloat = 24.0
    }

    private struct Position {
        let leading: NSLayoutConstraint
        let top: NSLayoutConstraint
    }

    var presenter: AccountConfirmPresenterProtocol!

    @IBOutlet private var scrollView: UIScrollView!
    @IBOutlet private var contentView: UIView!
    @IBOutlet private var detailsLabel: UILabel!
    @IBOutlet private var submittedChipsContainer: UIView!
    @IBOutlet private var pendingChipsContainer: UIView!

    @IBOutlet private var nextButton: SoraButton!
    @IBOutlet private var skipButton: SoraButton!

    @IBOutlet private var topPlaneHeight: NSLayoutConstraint!
    @IBOutlet private var bottomPlaneHeight: NSLayoutConstraint!

    private var minHeight: CGFloat = 0.0

    var wordTransitionAnimation = BlockViewAnimator(duration: 0.25,
                                                    options: [.curveEaseOut])

    var retryAnimation = TransitionAnimator(type: .fade,
                                            duration: 0.25)

    var wrongSequenceAnimation = ShakeAnimator(duration: 0.5,
                                               options: [.curveEaseInOut])

    private var contentWidth: CGFloat = 0.0

    private var pendingButtons: [RoundedButton] = []
    private var submittedButtons: [RoundedButton] = []
    private var positions: [RoundedButton: Position] = [:]
    private var originalPositions: [RoundedButton: Position] = [:]

    lazy var nextButtonTitle: LocalizableResource<String> = LocalizableResource { locale in
        R.string.localizable.accountConfirmationTitle(preferredLanguages: locale.rLanguages)
    }
    lazy var skipButtonTitle: LocalizableResource<String> = LocalizableResource { locale in
        R.string.localizable.claimSkip(preferredLanguages: locale.rLanguages)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupNavigationItem()
        setupLocalization()
        configureLayout()
        updateNextButton()

        presenter.setup()
    }

    private func configureLayout() {
        contentWidth = baseDesignSize.width * designScaleRatio.width - 2.0 * Constants.externalMargin
    }

    private func setupLocalization() {
        guard let locale = localizationManager?.selectedLocale else {
            return
        }

        title = R.string.localizable.accountConfirmationTitle(preferredLanguages: locale.rLanguages)

        detailsLabel.font = UIFont.styled(for: .title3)
        detailsLabel.text = R.string.localizable
            .mnemonicConfirmText(preferredLanguages: locale.rLanguages)

        nextButton.title = nextButtonTitle.value(for: locale)

        skipButton.title = skipButtonTitle.value(for: locale)
    }

    private func createButton() -> RoundedButton {
        let button = RoundedButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.roundedBackgroundView?.shadowOpacity = 0.0
        button.contentInsets = Constants.itemContentInsets
        button.roundedBackgroundView?.fillColor = R.color.baseBackground()!
        button.roundedBackgroundView?.highlightedFillColor = R.color.baseBackgroundHover()!
        button.roundedBackgroundView?.cornerRadius = Constants.cornerRadius
        button.imageWithTitleView?.titleColor = R.color.baseContentPrimary()!
        button.imageWithTitleView?.titleFont = UIFont.styled(for: .paragraph2)
        button.changesContentOpacityWhenHighlighted = true

        button.addTarget(self,
                         action: #selector(actionItem),
                         for: .touchUpInside)

        return button
    }

    private func apply(words: [String]) {
        clearButtons()

        let newPendingButtons: [RoundedButton] = words.map { word in
            let button = createButton()
            button.imageWithTitleView?.title = word
            return button
        }

        newPendingButtons.forEach { contentView.addSubview($0) }

        pendingButtons = newPendingButtons

        let rows = createRowsFromButtons(pendingButtons)
        minHeight = layoutRows(rows, on: pendingChipsContainer) + 2 * Constants.internalMargin

        layoutButtons()

        updateNextButton()
    }

    private func clearButtons() {
        pendingButtons.forEach { $0.removeFromSuperview() }
        submittedButtons.forEach { $0.removeFromSuperview() }

        pendingButtons = []
        submittedButtons = []
        positions = [:]
        originalPositions = [:]
    }

    private func setupNavigationItem() {
        let infoItem = UIBarButtonItem(image: R.image.iconRetry(),
                                       style: .plain,
                                       target: self,
                                       action: #selector(actionRetry))
        navigationItem.rightBarButtonItem = infoItem
    }

    private func updateNextButton() {
        nextButton.isEnabled = pendingButtons.isEmpty && !submittedButtons.isEmpty
    }

    @objc private func actionRetry() {
        presenter.requestWords()
    }

    @IBAction private func actionNext() {
        guard pendingButtons.isEmpty else {
            return
        }

        let words: [String] = submittedButtons.reduce(into: []) { (list, button) in
            if let title = button.imageWithTitleView?.title {
                list.append(title)
            }
        }

        presenter.confirm(words: words)
    }

    @IBAction private func actionSkip() {
        presenter.skip()
    }
}

extension AccountConfirmViewController {
    private func layoutButtons() {
        layoutPendingButtons()
        layoutSubmittedButtons()
    }

    private func layoutSubmittedButtons() {
        let rows = createRowsFromButtons(submittedButtons)
        let height = layoutRows(rows, on: submittedChipsContainer)
        topPlaneHeight.constant = max(minHeight, height + 2.0 * Constants.internalMargin)
    }

    private func layoutPendingButtons() {
        let rows = createRowsFromButtons(pendingButtons)
        let height = layoutRows(rows, on: pendingChipsContainer)
        bottomPlaneHeight.constant = max(minHeight, height + 2.0 * Constants.internalMargin)
    }

    private func createRowsFromButtons(_ buttons: [RoundedButton]) -> [[RoundedButton]] {
        let availableWidth = contentWidth - 2.0 * Constants.internalMargin

        var targetButtonIndex = 0

        var rows: [[RoundedButton]] = []

        var row: [RoundedButton] = []

        var remainedWidth = availableWidth

        while targetButtonIndex < buttons.count {
            let size = buttons[targetButtonIndex].intrinsicContentSize

            if size.width <= remainedWidth {
                row.append(buttons[targetButtonIndex])

                remainedWidth -= size.width + Constants.itemsSpacing

                targetButtonIndex += 1
            } else {
                if !row.isEmpty {
                    rows.append(row)
                    row = []
                } else {
                    break
                }

                remainedWidth = availableWidth
            }
        }

        if !row.isEmpty {
            rows.append(row)
        }

        return rows
    }

    private func layoutRows(_ rows: [[RoundedButton]], on plane: UIView) -> CGFloat {
        var currentY = Constants.internalMargin

        let availableWidth = contentWidth - 2.0 * Constants.internalMargin

        var totalHeight: CGFloat = 0.0

        for row in rows {
            var width = row.reduce(CGFloat(0.0)) { (result, item) in
                return result + item.intrinsicContentSize.width
            }

            width += CGFloat(row.count - 1) * Constants.itemsSpacing

            let height = row.reduce(CGFloat(0.0)) { (result, item) in
                return max(result, item.intrinsicContentSize.height)
            }

            var originX = Constants.internalMargin

            for item in row {
                let size = item.intrinsicContentSize

                if let position = positions[item] {
                    position.leading.isActive = false
                    position.top.isActive = false
                }

                let leading = item.leadingAnchor.constraint(equalTo: contentView.leadingAnchor,
                                                            constant: originX)

                let itemY = currentY + height / 2.0 - size.height / 2.0
                let top = item.topAnchor.constraint(equalTo: plane.topAnchor,
                                                    constant: itemY)

                leading.isActive = true
                top.isActive = true

                positions[item] = Position(leading: leading, top: top)

                originX += size.width + Constants.itemsSpacing
            }

            currentY += height + Constants.itemsSpacing

            totalHeight += height
        }

        return totalHeight + CGFloat(rows.count - 1) * Constants.itemsSpacing
    }

    @objc private func actionItem(_ sender: AnyObject) {
        guard let button = sender as? RoundedButton else {
            return
        }

        if let index = pendingButtons.firstIndex(of: button) {
            pendingButtons.remove(at: index)
            submittedButtons.append(button)

            originalPositions[button] = positions[button]

            let animationBlock = {
                button.roundedBackgroundView?.fillColor = R.color.baseBackground()!
                button.roundedBackgroundView?.highlightedFillColor = R.color.baseBackgroundHover()!
                button.changesContentOpacityWhenHighlighted = true
                self.layoutSubmittedButtons()

                self.contentView.layoutIfNeeded()
            }

            wordTransitionAnimation.animate(block: animationBlock,
                                            completionBlock: nil)
        } else if let index = submittedButtons.firstIndex(of: button) {
            submittedButtons.remove(at: index)
            pendingButtons.append(button)

            let currentPosition = positions[button]
            positions[button] = originalPositions[button]

            let animationBlock = {
                button.roundedBackgroundView?.fillColor = R.color.baseBackground()!
                button.roundedBackgroundView?.highlightedFillColor = R.color.baseBackgroundHover()!
                button.changesContentOpacityWhenHighlighted = false

                currentPosition?.leading.isActive = false
                currentPosition?.top.isActive = false

                if let originalPosition = self.originalPositions[button] {
                    originalPosition.leading.isActive = true
                    originalPosition.top.isActive = true
                }

                self.layoutSubmittedButtons()

                self.contentView.layoutIfNeeded()
            }

            wordTransitionAnimation.animate(block: animationBlock,
                                            completionBlock: nil)
        }

        updateNextButton()
    }
}

extension AccountConfirmViewController: AccountConfirmViewProtocol {
    func didReceive(words: [String], afterConfirmationFail: Bool) {
        if afterConfirmationFail {
            wrongSequenceAnimation.animate(view: contentView) { _ in
                self.apply(words: words)
                self.retryAnimation.animate(view: self.contentView,
                                            completionBlock: nil)
            }

            let alertView = UIAlertController(title: R.string.localizable.commonErrorGeneralTitle(), message: R.string.localizable.mnemonicInvalid(), preferredStyle: .alert)

            let useAction = UIAlertAction(
                title: R.string.localizable.commonOk(),
                style: .default) { (_: UIAlertAction) -> Void in
            }
            alertView.addAction(useAction)

            self.present(alertView, animated: true, completion: nil)
            AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
        } else {
            apply(words: words)

            self.retryAnimation.animate(view: self.contentView,
                                        completionBlock: nil)
        }
    }
}

extension AccountConfirmViewController: Localizable {
    func applyLocalization() {
        if isViewLoaded {
            setupLocalization()
            view.setNeedsLayout()
        }
    }
}
