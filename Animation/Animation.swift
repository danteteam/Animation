//
//  Animation.swift
//  GuessPointApp
//
//  Created by Ivan Brazhnikov on 19.08.15.
//  Copyright (c) 2015 Ivan Brazhnikov. All rights reserved.
//

import UIKit

private let DefaultAnimationTimeInterval: NSTimeInterval = 0.5
private let DefaultAnimationDelay: NSTimeInterval = 0
private let DefaultSpringDumping: CGFloat = 1.0
private let DefaultSpringDumpingInitialVelocity: CGFloat = 1.0


public class BaseAnimation {
    public typealias Block =  ()->()
    private var before: Block!
    private var after: Block!
    
    private init() {}
    
    public func before(block: Block!)-> Self {
        self.before = block
        return self
        
    }
    
    public func after(block: Block!)-> Self {
        self.after = block
        return self
    }
    
}

public class Animation: BaseAnimation {
    
    private var animations: [AnyObject] = []
    public override init() { }
    
    public func next() -> SingleItem{
        return SingleItem(parent: self)
    }
    
    public func next(animation: ()->Void) -> SingleItem{
        let item = SingleItem(parent: self)
        item.animation = animation
        return item
    }
    
    public func parallel() -> BatchAnimation {
        return BatchAnimation(parent: self)
    }
    
    public func start(animated: Bool = true){
        before?()
        if animated {
            runAnimationWithIndex(0)
        } else {
            runActions()
        }
    }
    
    
    public func runActions() {
        for a in animations {
            if let single = a as? SingleItem {
                single.before?()
                single.animation?()
                single.after?()
            } else if let a = a as? BatchAnimation {
                for item in a.animations {
                    item.before?()
                    item.animation?()
                    item.after?()
                }
            }
        }
        after?()
        
    }
    private func runAnimationWithIndex(index: Int) {
        if index == animations.count {
            after?()
        } else {
            let a: AnyObject = animations[index]
            if let s = a as? SingleItem {
                s.runWithCompletion({ (complete) -> Void in
                    self.runAnimationWithIndex(index + 1)
                })
                
            } else if let b = a as? BatchAnimation {
                b.runWithCompletion({ (complete) -> Void in
                    self.runAnimationWithIndex(index + 1)
                })
            } else {
                assertionFailure("Unknown object in animation stack: \(a)")
            }
        }
    }
    
    public class Item : BaseAnimation{
        private var animation: Block!
        private var delay: NSTimeInterval!
        private var duration: NSTimeInterval!
        private var springDumping: CGFloat!
        private var initialSpringVelocity: CGFloat!
        private var options: UIViewAnimationOptions!
        
        
        public func animation(block: Block!)-> Self {
            self.animation = block
            return self
        }
        
        public func delay(value: NSTimeInterval)-> Self {
            self.delay = value
            return self
        }
        
        public func duration(value: NSTimeInterval)-> Self {
            self.duration = value
            return self
        }
        
        public func springDumping(value: CGFloat) -> Self {
            self.springDumping = value
            return self
        }
        
        public func initialSpringVelocity(value: CGFloat) -> Self {
            self.initialSpringVelocity = value
            return self
        }
        
        public func options(value: UIViewAnimationOptions) -> Self {
            self.options = value
            return self
        }
        
        public func runWithCompletion(completion: (Bool)->Void){
            self.before?()
            UIView.animateWithDuration(
                self.duration ?? DefaultAnimationTimeInterval,
                delay: self.delay ?? DefaultAnimationDelay ,
                usingSpringWithDamping: self.springDumping ?? DefaultSpringDumping,
                initialSpringVelocity: self.initialSpringVelocity ?? DefaultSpringDumpingInitialVelocity,
                options: self.options ?? UIViewAnimationOptions(), animations: { () -> Void in
                    self.animation?()
                }, completion: { (complete: Bool) -> Void in
                    self.after?()
                    completion(complete)
            })
        }
        
    }
    
    public class SingleItem: Item {
        
        private let parent: Animation
        
        private init(parent: Animation) {
            self.parent = parent
            super.init()
        }
        
        public func done() -> Animation {
            parent.animations.append(self)
            return parent
        }
        
        public func next() -> SingleItem {
            return done().next()
        }
        
        public func next(animation: ()->Void) -> SingleItem {
            return done().next(animation)
        }
        
        public func start() {
            parent.start()
        }
        
        public func start(animated: Bool){
            parent.start(animated)
        }
    }
    
    public class BatchItem: Item {
        
        private let parent: BatchAnimation
        
        private init(parent: BatchAnimation) {
            self.parent = parent
            super.init()
        }
        
        public func done() -> BatchAnimation {
            parent.animations.append(self)
            return parent
        }
    }
    
    
    public class BatchAnimation : BaseAnimation {
        
        let parent: Animation
        var animations = [Item]()
        
        init(parent: Animation) {
            self.parent = parent
            super.init()
        }
        
        public func next() -> BatchItem {
            return BatchItem(parent: self)
        }
        
        public func endParallel()-> Animation {
            parent.animations.append(self)
            return parent
        }
        
        public func runWithCompletion(completion: (Bool)-> Void){
            before?()
            var count: Int = 0
            for s in animations {
                s.runWithCompletion({ (complete) -> Void in
                    count += 1
                    if count >= self.animations.count {
                        self.after?()
                        completion(complete)
                    }
                })
            }
        }
    }
    
    
    
    
}

