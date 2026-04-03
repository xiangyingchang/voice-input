import AppKit

/// Manages the floating capsule window display, animations, and content updates
class FloatingWindowManager {

    private var panel: FloatingPanel?
    private var contentView: CapsuleContentView?
    private var isVisible = false

    private let capsuleHeight: CGFloat = 56
    private let bottomOffset: CGFloat = 80 // Distance from bottom of screen

    // MARK: - Show / Hide

    func show() {
        guard !isVisible else { return }
        isVisible = true

        let capsule = CapsuleContentView(frame: .zero)
        capsule.translatesAutoresizingMaskIntoConstraints = false
        contentView = capsule

        let panel = FloatingPanel()
        self.panel = panel

        // Container view for centering
        let container = NSView(frame: .zero)
        container.wantsLayer = true
        container.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(capsule)

        panel.contentView = container

        NSLayoutConstraint.activate([
            capsule.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            capsule.centerYAnchor.constraint(equalTo: container.centerYAnchor),
        ])

        // Position at bottom center of main screen
        if let screen = NSScreen.main {
            let screenFrame = screen.visibleFrame
            let panelWidth: CGFloat = 700 // Max possible width with padding
            let panelHeight: CGFloat = capsuleHeight + 20

            let x = screenFrame.midX - panelWidth / 2
            let y = screenFrame.minY + bottomOffset

            panel.setFrame(NSRect(x: x, y: y, width: panelWidth, height: panelHeight), display: false)
        }

        // Initial state for spring animation
        panel.alphaValue = 0
        capsule.layer?.setAffineTransform(CGAffineTransform(scaleX: 0.8, y: 0.8))

        panel.orderFrontRegardless()
        capsule.showListening()
        capsule.waveformView.startAnimating()

        // Spring entry animation (0.35s)
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.35
            context.timingFunction = CAMediaTimingFunction(controlPoints: 0.175, 0.885, 0.32, 1.275)
            context.allowsImplicitAnimation = true

            panel.animator().alphaValue = 1.0
            capsule.layer?.setAffineTransform(.identity)
        }
    }

    func hide() {
        guard isVisible, let panel = panel, let capsule = contentView else { return }
        isVisible = false

        capsule.waveformView.stopAnimating()

        // Exit scale animation (0.22s)
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.22
            context.timingFunction = CAMediaTimingFunction(name: .easeIn)
            context.allowsImplicitAnimation = true

            panel.animator().alphaValue = 0
            capsule.layer?.setAffineTransform(CGAffineTransform(scaleX: 0.85, y: 0.85))
        }, completionHandler: { [weak self] in
            panel.orderOut(nil)
            self?.panel = nil
            self?.contentView = nil
        })
    }

    // MARK: - Updates

    func updateRMS(level: Float) {
        contentView?.waveformView.updateRMS(level)
    }

    func updateText(_ text: String) {
        guard let capsule = contentView else { return }
        capsule.resetTextColor()
        capsule.updateText(text)
    }

    func showRefining() {
        contentView?.showRefining()
    }
}
