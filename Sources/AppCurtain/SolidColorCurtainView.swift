import UIKit

/// Solid color curtain with centered title text.
@MainActor
public final class SolidColorCurtainView: UIView {
    private let titleLabel = UILabel()

    public init(color: UIColor, title: String) {
        super.init(frame: .zero)
        backgroundColor = color
        titleLabel.text = title
        configureTitleLabel()
        addSubview(titleLabel)
    }

    public required init?(coder: NSCoder) {
        return nil
    }

    public var title: String {
        get { titleLabel.text ?? "" }
        set { titleLabel.text = newValue }
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        let inset: CGFloat = 24
        let maxWidth = bounds.width - (inset * 2)
        let size = titleLabel.sizeThatFits(CGSize(width: maxWidth, height: .greatestFiniteMagnitude))
        titleLabel.frame = CGRect(
            x: (bounds.width - min(size.width, maxWidth)) / 2,
            y: (bounds.height - size.height) / 2,
            width: min(size.width, maxWidth),
            height: size.height
        )
    }

    private func configureTitleLabel() {
        titleLabel.textColor = .white
        titleLabel.font = UIFont.preferredFont(forTextStyle: .title2)
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 2
    }
}
