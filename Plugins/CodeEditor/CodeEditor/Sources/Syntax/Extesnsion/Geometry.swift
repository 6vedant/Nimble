//
//  Geometry.swift
//  CodeEditor
//
//  Created by Mark Goldin on 19/06/2019.
//  Copyright © 2019 SCADE. All rights reserved.
//

import CoreGraphics

// MARK: Scalable

protocol Scalable {
    
    func scaled(to scale: CGFloat) -> Self
}


extension CGPoint: Scalable {
    
    func scaled(to scale: CGFloat) -> CGPoint {
        
        return CGPoint(x: scale * self.x, y: scale * self.y)
    }
    
}


extension CGSize: Scalable {
    
    func scaled(to scale: CGFloat) -> CGSize {
        
        return CGSize(width: scale * self.width, height: scale * self.height)
    }
    
}


extension CGRect: Scalable {
    
    func scaled(to scale: CGFloat) -> CGRect {
        
        return CGRect(x: scale * self.origin.x, y: scale * self.origin.y, width: scale * self.width, height: scale * self.height)
    }
    
}



// MARK: - Syntax Sugares

extension CGPoint {
    
    static prefix func - (point: CGPoint) -> CGPoint {
        
        return CGPoint(x: -point.x, y: -point.y)
    }
    
    
    func offsetBy(dx: CGFloat = 0, dy: CGFloat = 0) -> CGPoint {
        
        return CGPoint(x: self.x + dx, y: self.y + dy)
    }
    
    
    func offset(by point: CGPoint) -> CGPoint {
        
        return self.offsetBy(dx: point.x, dy: point.y)
    }
    
}


extension CGSize {
    
    static let unit = CGSize(width: 1, height: 1)
    static let infinite = CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
    
    
    var rotated: CGSize {
        
        return CGSize(width: self.height, height: self.width)
    }
}


extension CGRect {
    
    var mid: CGPoint {
        
        return CGPoint(x: self.midX, y: self.midY)
    }
    
    
    func offset(by point: CGPoint) -> CGRect {
        
        return self.offsetBy(dx: point.x, dy: point.y)
    }
    
    
    func inset(by point: CGPoint) -> CGRect {
        
        return self.insetBy(dx: point.x, dy: point.y)
    }
    
}



// MARK: CGFloat

extension CGFloat {
    
    /// round to decimal places value
    func rounded(to places: Int) -> CGFloat {
        
        let divisor = pow(10.0, CGFloat(places))
        return (self * divisor).rounded() / divisor
    }
    
}
