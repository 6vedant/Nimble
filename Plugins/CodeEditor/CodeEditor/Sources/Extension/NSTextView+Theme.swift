//
//  NSTextView+Theme.swift
//  CodeEditor
//
//  Created by Mark Goldin on 20/06/2019.
//  Copyright © 2019 SCADE. All rights reserved.
//

import Foundation
import AppKit

extension NSTextView {
    
    func applyTheme(theme: Theme) {
        
        assert(Thread.isMainThread)
        
        self.backgroundColor = theme.background.color
        self.enclosingScrollView?.backgroundColor = theme.background.color
        self.selectedTextAttributes = [.backgroundColor: theme.selection.usesSystemSetting ? .selectedTextBackgroundColor : theme.selection.color]
        
        // set scroller color considering background color
        self.enclosingScrollView?.scrollerKnobStyle = theme.isDarkTheme ? .light : .default
        
        self.setNeedsDisplay(self.visibleRect, avoidAdditionalLayout: true)
    }
}
