//
//  ScrollableBottomSheet.swift
//  ScrollableBottomSheet
//
//  Created by Phuc Nguyen on 7/22/20.
//  Copyright © 2020 phucnguyen. All rights reserved.
//

import UIKit

public enum BottomSheetStyle {
    case partial
    case full
}

open class ScrollableBottomSheetView: UIView {
    var partialFrame: CGRect = CGRect(
        x: 0,
        y: 0,
        width: UIScreen.main.bounds.width,
        height: UIScreen.main.bounds.height / 2) {
        didSet {
            
        }
    }
    
    var fullFrame: CGRect = CGRect(
        x: 0,
        y: 0,
        width: UIScreen.main.bounds.width,
        height: UIScreen.main.bounds.height - 100) {
        didSet {
            
        }
    }
    
    public var scrollView: UIScrollView? {
        didSet {
            if let scrollView = self.scrollView {
                self.contentView.addSubview(scrollView)
                scrollView.snp.remakeConstraints({ make in
                    make.leading.trailing.equalToSuperview()
                    make.top.equalTo(self.headerView.snp.bottom)
                    make.bottom.equalTo(self.footerView.snp.top)
                    make.height.greaterThanOrEqualTo(0)
                })
            }
        }
    }
    
    public var headerHeight: CGFloat = 0 {
        didSet {
            self.headerView.snp.remakeConstraints { make in
                make.top.leading.trailing.equalToSuperview()
                make.height.equalTo(headerHeight)
            }
        }
    }
    
    public lazy var headerView: UIView = {
        let _view = UIView()
        
        return _view
    }()
    
    public var footerHeight: CGFloat = 0 {
        didSet {
            self.footerView.snp.remakeConstraints { make in
                make.leading.trailing.equalToSuperview()
                make.bottom.equalTo(self.contentView.layoutMarginsGuide)
                make.height.equalTo(footerHeight)
            }
        }
    }
    
    public lazy var footerView: UIView = {
        let _view = UIView()
        
        return _view
    }()
    
    var initialStyle: BottomSheetStyle = .full
    
    var cardPanStartingTopConstant : CGFloat = 30.0
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.setupViews()
        self.setupLayout()
    }
    
    var contentTopConstraint: ConstraintMakerEditable!
    
    public init(frame: CGRect, style: BottomSheetStyle) {
        super.init(frame: frame)
        
        self.initialStyle = style
        
        self.setupViews()
        self.setupLayout()
    }
    
    private lazy var topIndicatorView: UIView = {
        let _view = UIView()
        _view.backgroundColor = .white
        _view.layer.cornerRadius = 3.0
        _view.clipsToBounds = true
        
        return _view
    }()
    
    private lazy var containerView: UIView = {
        let _view = UIView()
        _view.backgroundColor = .clear
        
        return _view
    }()
    
    private lazy var contentView: UIView = {
        let _view = UIView()
        _view.backgroundColor = .white
        
        return _view
    }()
    
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    open func animateShow() {
        self.isHidden = false
        self.scrollView?.isScrollEnabled = self.initialStyle == .full
        let initialHeight: CGFloat = self.initialStyle == .full
        ? self.fullFrame.size.height
        : self.partialFrame.size.height
        self.contentTopConstraint.constraint.layoutConstraints.first?.constant = UIScreen.main.bounds.size.height - initialHeight
        UIView.animate(withDuration: 0.4, delay: 0.0, usingSpringWithDamping: 0.8, initialSpringVelocity: 1, animations: {
            self.layoutIfNeeded()
            self.alpha = 1.0
        }, completion: { _ in
            
        })
    }
    
    open func animateHide() {
        self.contentTopConstraint.constraint.layoutConstraints.first?.constant = UIScreen.main.bounds.size.height
        UIView.animate(withDuration: 0.4, delay: 0.0, usingSpringWithDamping: 0.8, initialSpringVelocity: 1, animations: {
            self.layoutIfNeeded()
            self.alpha = 0.0
        }, completion: { _ in
            self.isHidden = true
        })
    }
    
    private func setupViews() {
        self.addSubview(self.containerView)
        
        self.containerView.addSubview(self.topIndicatorView)
        self.containerView.addSubview(self.contentView)
        
        self.contentView.addSubview(self.headerView)
        self.contentView.addSubview(self.footerView)
        
        let viewCornerRadius: CGFloat = 16
        
        if #available(iOS 11.0, *) {
            self.contentView.layer.cornerRadius = viewCornerRadius
            self.contentView.clipsToBounds = true
            self.contentView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        } else {
            let rect = UIScreen.main.bounds
            let path = UIBezierPath(roundedRect: rect, byRoundingCorners: [.topLeft, .topRight], cornerRadii: CGSize(width: viewCornerRadius, height: viewCornerRadius))
            let maskLayer = CAShapeLayer()
            maskLayer.frame = rect
            maskLayer.path = path.cgPath
            self.contentView.layer.mask = maskLayer
        }
        
        let viewTapGesture: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapView(_:)))
        viewTapGesture.cancelsTouchesInView = false
        viewTapGesture.delegate = self
        
        self.addGestureRecognizer(viewTapGesture)
        
        self.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        
        self.isHidden = true
        self.alpha = 0
        
        let panGesture: UIPanGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(panView(_:)))
        panGesture.delaysTouchesBegan = false
        panGesture.delaysTouchesEnded = false
        self.containerView.addGestureRecognizer(panGesture)
    }
    
    @objc func tapView(_ regconizer: UITapGestureRecognizer) {
        self.animateHide()
    }
    
    @objc func panView(_ regconizer: UIPanGestureRecognizer) {
        guard let topConstant = contentTopConstraint.constraint.layoutConstraints.first?.constant else { return }
        let translation = regconizer.translation(in: self)
        
        switch regconizer.state {
        case .began:
            cardPanStartingTopConstant = topConstant
        case .changed :
            if self.cardPanStartingTopConstant + translation.y > 1.0 {
                self.contentTopConstraint.constraint.layoutConstraints.first?.constant = self.cardPanStartingTopConstant + translation.y
            }
        case .ended:
            let isScrollFromTop: Bool = cardPanStartingTopConstant == (UIScreen.main.bounds.height - self.fullFrame.size.height)
            let thresholdRatio: CGFloat = isScrollFromTop ? 2 / 3 : 1 / 3
            let fullThreshold: CGFloat = UIScreen.main.bounds.height - (self.fullFrame.size.height + self.partialFrame.size.height) * thresholdRatio
            let partialThreshold: CGFloat = UIScreen.main.bounds.height - self.partialFrame.size.height * 2 / 3
            
            if topConstant < fullThreshold  {
                self.showContent(style: .full)
            } else if topConstant >= fullThreshold && topConstant < partialThreshold {
                self.showContent(style: .partial)
            } else {
                self.animateHide()
            }
        default:
            break
        }
    }
    
    private func setupLayout() {
        self.contentView.snp.makeConstraints { make in
            make.bottom.leading.trailing.equalToSuperview()
        }
        
        self.topIndicatorView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.centerX.equalToSuperview()
            make.height.equalTo(6)
            make.width.equalTo(48)
            make.bottom.equalTo(self.contentView.snp.top).offset(-8)
        }
        
        self.headerView.snp.remakeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(headerHeight)
        }
        
        self.footerView.snp.remakeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(self.contentView.layoutMarginsGuide)
            make.height.equalTo(footerHeight)
        }
        
        self.containerView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview().priorityLow()
            contentTopConstraint = make.top.equalToSuperview().offset(UIScreen.main.bounds.height)
        }
    }
    
    private func showContent(style: BottomSheetStyle = .full) {
        self.layoutIfNeeded()
        
        let initialHeight: CGFloat = style == .full
        ? self.fullFrame.size.height
        : self.partialFrame.size.height
        let topConstraint = UIScreen.main.bounds.height - initialHeight
        
        self.contentTopConstraint.constraint.layoutConstraints.first?.constant = topConstraint
        self.scrollView?.isScrollEnabled = style == .full
        UIView.animate(withDuration: 0.4, delay: 0.0, usingSpringWithDamping: 0.8, initialSpringVelocity: 3, animations: {
            self.layoutIfNeeded()
        }, completion: { _ in
            
        })
    }
}

extension ScrollableBottomSheetView: UIGestureRecognizerDelegate {
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if gestureRecognizer is UITapGestureRecognizer {
            return touch.view == self
        }
        
        return true
    }
}

extension ScrollableBottomSheetView: UIScrollViewDelegate {
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        print("did scroll")
    }
}

