//
//  CircularProgressView.swift
//  xdrip
//
//  Created by Albert Garipov on 06.12.2024.
//  Copyright © 2024 Johan Degraeve. All rights reserved.
//

import UIKit

protocol TimerHandleDelegate {
    func counterUpdateTimeValue(with sender: CircularProgressView, newValue: Int)
    func didStartTimer(sender: CircularProgressView)
    func didEndTimer(sender: CircularProgressView)
}

@IBDesignable class CircularProgressView: UIView {
    var delegate: TimerHandleDelegate?
    
    // Make var available in storyboard as well
    @IBInspectable public var barLineWidth: CGFloat = 15.0
    @IBInspectable public var barBackLineColor: UIColor = .lightGray
    @IBInspectable public var isTextLabelHidden: Bool = false
    @IBInspectable public var timerFinishingText: String?

    // Public vars
    public var isMovingClockWise = true

    // Private vars
    private var timer: Timer?
    private var elapsedTime: TimeInterval = 0
    private var interval: TimeInterval = 1
    private let fireInterval: TimeInterval = 0.01
    
    private lazy var counterLabel: UILabel = {
        let label = UILabel()
        label.textColor = .systemBackground
        label.numberOfLines  = 3
        self.addSubview(label)
        label.adjustsFontSizeToFitWidth = true
        label.textAlignment = .center
        label.frame = self.bounds
        return label
    }()
    
    private var currentCounterValue: Int = 0 {
        didSet {
            if !isTextLabelHidden {
                counterLabel.text = getMinutesAndSeconds(remainingSeconds: currentCounterValue)
            }
            delegate?.counterUpdateTimeValue(with: self, newValue: currentCounterValue)
        }
    }

    // MARK: View Life cycle
    override public init(frame: CGRect) {
        if frame.width != frame.height {
            fatalError("Please use a rectangle frame for CircularProgressView")
        }
        super.init(frame: frame)
        layer.cornerRadius = frame.width / 2
        clipsToBounds = true
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override public func draw(_ rect: CGRect) {
        super.draw(rect)
        guard let context = UIGraphicsGetCurrentContext() else { return }

        let radius = (rect.width - barLineWidth) / 2
        let currentAngle: CGFloat = CGFloat((.pi * 2 * elapsedTime) / (10 * 60))

        context.setLineWidth(barLineWidth)

        context.setStrokeColor(barBackLineColor.cgColor)
        context.addArc(
            center: CGPoint(x: rect.midX, y: rect.midY),
            radius: radius,
            startAngle: -.pi / 2,
            endAngle: .pi * 3 / 2,
            clockwise: false
        )
        context.strokePath()

        // Foreground Circle (filling progress)
        let progressColor = getProgressColor()
        context.setStrokeColor(progressColor.cgColor)
        context.addArc(
            center: CGPoint(x: rect.midX, y: rect.midY),
            radius: radius,
            startAngle: -.pi / 2,
            endAngle: -.pi / 2 + currentAngle,
            clockwise: false // Progress fills clockwise
        )
        context.strokePath()
    }


    // MARK: Starts the timer and the animation.
    public func start(interval: TimeInterval = 1) {
        self.delegate?.didStartTimer(sender: self)
        self.interval = interval
        elapsedTime = 0
        currentCounterValue = 0
        timer?.invalidate()
        timer = Timer(timeInterval: fireInterval, target: self, selector: #selector(timerFired(_:)), userInfo: nil, repeats: true)
        RunLoop.main.add(timer!, forMode: .common)
    }

    public func reset() {
        self.currentCounterValue = 0
        timer?.invalidate()
        self.elapsedTime = 0
        setNeedsDisplay()
    }
    
    public func end() {
        timer?.invalidate()
        delegate?.didEndTimer(sender: self)
    }
    
    private func getMinutesAndSeconds(remainingSeconds: Int) -> String {
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60
        let secondString = seconds < 10 ? "0\(seconds)" : "\(seconds)"
        return "\(minutes):\(secondString)"
    }

    private func getProgressColor() -> UIColor {
        switch elapsedTime {
        case 0..<5 * 60:
            return .green
        case 5 * 60..<10 * 60:
            return .yellow
        default:
            return .red
        }
    }

    @objc private func timerFired(_ timer: Timer) {
        elapsedTime += fireInterval
        currentCounterValue = Int(elapsedTime)
        setNeedsDisplay()
    }
}
