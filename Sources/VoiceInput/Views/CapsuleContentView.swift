import AppKit

/// Capsule-shaped content view with visual effect background
class CapsuleContentView: NSVisualEffectView {

    let waveformView = WaveformView(frame: .zero)
    let textLabel = NSTextField(labelWithString: "")
    let statusLabel = NSTextField(labelWithString: "")

    private let capsuleHeight: CGFloat = 56
    private let capsuleCornerRadius: CGFloat = 28
    private let waveformWidth: CGFloat = 44
    private let waveformHeight: CGFloat = 32
    private let minTextWidth: CGFloat = 160
    private let maxTextWidth: CGFloat = 560
    private let horizontalPadding: CGFloat = 20
    private let elementSpacing: CGFloat = 12

    private var textWidthConstraint: NSLayoutConstraint!
    private var capsuleWidthConstraint: NSLayoutConstraint!

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        // Visual effect configuration
        material = .hudWindow
        state = .active
        blendingMode = .behindWindow
        wantsLayer = true
        layer?.cornerRadius = capsuleCornerRadius
        layer?.masksToBounds = true

        // Waveform view
        waveformView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(waveformView)

        // Text label - shows real-time transcription
        textLabel.translatesAutoresizingMaskIntoConstraints = false
        textLabel.font = NSFont.systemFont(ofSize: 15, weight: .medium)
        textLabel.textColor = .white
        textLabel.backgroundColor = .clear
        textLabel.isBezeled = false
        textLabel.isEditable = false
        textLabel.isSelectable = false
        textLabel.lineBreakMode = .byTruncatingTail
        textLabel.maximumNumberOfLines = 1
        textLabel.cell?.truncatesLastVisibleLine = true
        addSubview(textLabel)

        // Status label (for "Refining..." etc.)
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        statusLabel.font = NSFont.systemFont(ofSize: 13, weight: .regular)
        statusLabel.textColor = NSColor.white.withAlphaComponent(0.6)
        statusLabel.backgroundColor = .clear
        statusLabel.isBezeled = false
        statusLabel.isEditable = false
        statusLabel.isSelectable = false
        statusLabel.isHidden = true
        addSubview(statusLabel)

        // Layout constraints
        textWidthConstraint = textLabel.widthAnchor.constraint(equalToConstant: minTextWidth)
        let initialWidth = horizontalPadding + waveformWidth + elementSpacing + minTextWidth + horizontalPadding
        capsuleWidthConstraint = widthAnchor.constraint(equalToConstant: initialWidth)

        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: capsuleHeight),
            capsuleWidthConstraint,

            // Waveform
            waveformView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: horizontalPadding),
            waveformView.centerYAnchor.constraint(equalTo: centerYAnchor),
            waveformView.widthAnchor.constraint(equalToConstant: waveformWidth),
            waveformView.heightAnchor.constraint(equalToConstant: waveformHeight),

            // Text label
            textLabel.leadingAnchor.constraint(equalTo: waveformView.trailingAnchor, constant: elementSpacing),
            textLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            textWidthConstraint,

            // Status label (overlaps text label)
            statusLabel.leadingAnchor.constraint(equalTo: waveformView.trailingAnchor, constant: elementSpacing),
            statusLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
    }

    // MARK: - Public Interface

    func updateText(_ text: String) {
        textLabel.stringValue = text
        statusLabel.isHidden = true
        textLabel.isHidden = false

        // Calculate desired text width
        let attrString = NSAttributedString(string: text, attributes: [.font: textLabel.font!])
        let textSize = attrString.size()
        let desiredWidth = min(maxTextWidth, max(minTextWidth, textSize.width + 20))

        // Animate width change
        let newCapsuleWidth = horizontalPadding + waveformWidth + elementSpacing + desiredWidth + horizontalPadding

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.25
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            context.allowsImplicitAnimation = true

            textWidthConstraint.animator().constant = desiredWidth
            capsuleWidthConstraint.animator().constant = newCapsuleWidth

            self.superview?.layoutSubtreeIfNeeded()
        }
    }

    func showRefining() {
        textLabel.isHidden = true
        statusLabel.isHidden = false
        statusLabel.stringValue = "Refining…"
    }

    func showListening() {
        textLabel.isHidden = false
        statusLabel.isHidden = true
        textLabel.stringValue = "Listening…"
        textLabel.textColor = NSColor.white.withAlphaComponent(0.5)

        textWidthConstraint.constant = minTextWidth
        let width = horizontalPadding + waveformWidth + elementSpacing + minTextWidth + horizontalPadding
        capsuleWidthConstraint.constant = width
    }

    func resetTextColor() {
        textLabel.textColor = .white
    }
}
