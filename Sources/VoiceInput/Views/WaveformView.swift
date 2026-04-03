import AppKit
import QuartzCore

/// 5-bar waveform visualization driven by real-time audio RMS levels
class WaveformView: NSView {

    // Bar configuration
    private let barCount = 5
    private let barWeights: [CGFloat] = [0.5, 0.8, 1.0, 0.75, 0.55]
    private let barWidth: CGFloat = 4.0
    private let barSpacing: CGFloat = 3.0
    private let barCornerRadius: CGFloat = 2.0
    private let minBarHeight: CGFloat = 4.0
    private let maxBarHeight: CGFloat = 28.0

    // Smooth envelope parameters
    private let attackRate: Float = 0.40
    private let releaseRate: Float = 0.15
    private let jitterAmount: Float = 0.04

    // State
    private var barLayers: [CALayer] = []
    private var smoothedLevel: Float = 0
    private var displayLink: CVDisplayLink?
    private var currentRMS: Float = 0

    // Bar color
    private let barColor = NSColor.white.withAlphaComponent(0.9)

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        wantsLayer = true
        layer?.masksToBounds = true

        // Create bar layers
        for _ in 0..<barCount {
            let bar = CALayer()
            bar.backgroundColor = barColor.cgColor
            bar.cornerRadius = barCornerRadius
            bar.anchorPoint = CGPoint(x: 0.5, y: 0.5) // Grow from center
            layer?.addSublayer(bar)
            barLayers.append(bar)
        }

        layoutBars()
    }

    override func layout() {
        super.layout()
        layoutBars()
    }

    private func layoutBars() {
        let totalBarWidth = CGFloat(barCount) * barWidth + CGFloat(barCount - 1) * barSpacing
        let startX = (bounds.width - totalBarWidth) / 2
        let centerY = bounds.height / 2

        for (i, bar) in barLayers.enumerated() {
            let x = startX + CGFloat(i) * (barWidth + barSpacing)
            let height = minBarHeight
            let y = centerY - height / 2

            CATransaction.begin()
            CATransaction.setDisableActions(true)
            bar.frame = CGRect(x: x, y: y, width: barWidth, height: height)
            CATransaction.commit()
        }
    }

    // MARK: - RMS Update

    func updateRMS(_ level: Float) {
        currentRMS = level
    }

    // MARK: - Animation (called from DisplayLink)

    func tick() {
        let raw = currentRMS

        // Smooth envelope: attack (rising) is faster, release (falling) is slower
        if raw > smoothedLevel {
            smoothedLevel = attackRate * raw + (1 - attackRate) * smoothedLevel
        } else {
            smoothedLevel = releaseRate * raw + (1 - releaseRate) * smoothedLevel
        }

        let totalBarWidth = CGFloat(barCount) * barWidth + CGFloat(barCount - 1) * barSpacing
        let startX = (bounds.width - totalBarWidth) / 2
        let centerY = bounds.height / 2

        CATransaction.begin()
        CATransaction.setAnimationDuration(0.05)
        CATransaction.setAnimationTimingFunction(CAMediaTimingFunction(name: .easeOut))

        for (i, bar) in barLayers.enumerated() {
            let weight = barWeights[i]

            // Apply ±4% random jitter
            let jitter = 1.0 + Float.random(in: -jitterAmount...jitterAmount)
            let level = CGFloat(smoothedLevel * jitter) * weight

            // Map level to bar height
            let height = max(minBarHeight, minBarHeight + (maxBarHeight - minBarHeight) * level)
            let x = startX + CGFloat(i) * (barWidth + barSpacing)
            let y = centerY - height / 2

            bar.frame = CGRect(x: x, y: y, width: barWidth, height: height)
        }

        CATransaction.commit()
    }

    // MARK: - Start / Stop Animation

    private var displayTimer: Timer?

    func startAnimating() {
        smoothedLevel = 0
        // Use Timer on main thread (~60fps)
        displayTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { [weak self] _ in
            self?.tick()
        }
        RunLoop.main.add(displayTimer!, forMode: .common)
    }

    func stopAnimating() {
        displayTimer?.invalidate()
        displayTimer = nil

        // Reset bars to minimum height
        let totalBarWidth = CGFloat(barCount) * barWidth + CGFloat(barCount - 1) * barSpacing
        let startX = (bounds.width - totalBarWidth) / 2
        let centerY = bounds.height / 2

        CATransaction.begin()
        CATransaction.setAnimationDuration(0.2)
        for (i, bar) in barLayers.enumerated() {
            let x = startX + CGFloat(i) * (barWidth + barSpacing)
            let y = centerY - minBarHeight / 2
            bar.frame = CGRect(x: x, y: y, width: barWidth, height: minBarHeight)
        }
        CATransaction.commit()
    }
}
