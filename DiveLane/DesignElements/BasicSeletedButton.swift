//
//  BasicSeletedButton.swift
//  DiveLane
//
//  Created by Anton Grigorev on 11/01/2019.
//  Copyright © 2019 Matter Inc. All rights reserved.
//

import UIKit

class BasicSelectedButton: UIButton {
    
    let animation = AnimationController()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        let height: CGFloat = Constants.buttons.heights.main
        self.layer.cornerRadius = height / 2
        self.clipsToBounds = true
        
        self.backgroundColor = Colors.secondMain
        self.setTitleColor(Colors.firstMain, for: .normal)
        self.layer.borderWidth = 0.0
        //self.layer.borderColor = Colors.firstMain.cgColor
        self.addTarget(self, action: #selector(buttonTouchedDown(_:)), for: .touchDown)
        self.addTarget(self, action: #selector(buttonTouchedUp(_:)), for: .touchCancel)
        self.addTarget(self, action: #selector(buttonTouchedDown(_:)), for: .touchDragInside)
        self.addTarget(self, action: #selector(buttonTouchedUp(_:)), for: .touchDragOutside)
    }
    
    @objc func buttonTouchedDown(_ sender: UIButton) {
        animation.pressButtonStartedAnimation(for: sender)
    }
    
    @objc func buttonTouchedUp(_ sender: UIButton) {
        animation.pressButtonCanceledAnimation(for: sender)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}