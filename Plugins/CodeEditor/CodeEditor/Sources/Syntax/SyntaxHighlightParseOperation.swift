//
//  SyntaxHighlightParseOperation.swift
//
//  CodeEditor
//
//  Created by Mark Goldin on 19/06/2019.
//  Copyright © 2019 SCADE. All rights reserved.
//

import Foundation

private struct QuoteCommentItem {
    
    let type: SyntaxType
    let token: Token
    let role: Role
    let range: NSRange
    
    
    enum Token: Equatable {
        
        case inlineComment
        case blockComment
        case string(String)
    }
    
    
    struct Role: OptionSet {
        
        let rawValue: Int
        
        static let begin = Role(rawValue: 1 << 0)
        static let end   = Role(rawValue: 1 << 1)
    }
}



// MARK: -

final class SyntaxHighlightParseOperation: Operation, ProgressReporting {
    
    struct ParseDefinition {
        
        var extractors: [SyntaxType: [HighlightExtractable]]
        var pairedQuoteTypes: [String: SyntaxType]  // dict for quote pair to extract with comment
        var inlineCommentDelimiter: String?
        var blockCommentDelimiters: Pair<String>?
    }
    
    
    
    // MARK: Public Properties
    
    let string: String
    let progress: Progress  // can be updated from a background thread
    
    private(set) var highlights: [SyntaxType: [NSRange]]?
    
    
    // MARK: Private Properties
    
    private let definition: ParseDefinition
    private let parseRange: NSRange
    
    
    
    // MARK: -
    // MARK: Lifecycle
    
    required init(definition: ParseDefinition, string: String, range parseRange: NSRange) {
        
        self.definition = definition
        self.string = string
        self.parseRange = parseRange
        
        // +1 for extractCommentsWithQuotes()
        // +1 for highlighting
        self.progress = Progress(totalUnitCount: Int64(definition.extractors.count + 2))
        
        super.init()
        
        self.progress.cancellationHandler = { [weak self] in
            self?.cancel()
        }
    }
    
    
    
    // MARK: Operation Methods
    
    /// is ready to run
    override var isReady: Bool {
        
        return true
    }
    
    
    /// parse string in background and return extracted highlight ranges per syntax types
    override func main() {
        
        highlights = extractHighlights()
        
        guard !isCancelled else { return }
        
        progress.localizedDescription = "Applying colors to text"
    }
    
    
    
    // MARK: Private Methods
    
    /// extract all highlight ranges in the parse range
    private func extractHighlights() -> [SyntaxType: [NSRange]] {
        
        var highlights = [SyntaxType: [NSRange]]()
        
        // extract standard highlight ranges
        for syntaxType in SyntaxType.allCases {
            guard let extractors = definition.extractors[syntaxType] else { continue }
            
            self.progress.localizedDescription = String(format: "Extracting %@…", syntaxType.name)
            
            let childProgress = Progress(totalUnitCount: Int64(extractors.count), parent: progress, pendingUnitCount: 1)
            let atomicRanges = Atomic<[NSRange]>([], attributes: .concurrent)
            
            DispatchQueue.concurrentPerform(iterations: extractors.count) { (index: Int) in
                guard !childProgress.isCancelled else { return }
                
                let extractedRanges = extractors[index].ranges(in: string, range: parseRange) { (stop) in
                    stop = childProgress.isCancelled
                }
                
                atomicRanges.asyncMutate {
                    $0 += extractedRanges
                    childProgress.completedUnitCount += 1
                }
            }
            
            highlights[syntaxType] = atomicRanges.value
            childProgress.completedUnitCount = childProgress.totalUnitCount
        }
        
        guard !self.isCancelled else { return [:] }
        
        // extract comments and quoted text
        progress.localizedDescription = String(format: "Extracting %@…", "comments and quoted texts")
        highlights.merge(extractCommentsWithQuotes()) { $0 + $1 }
        
        guard !isCancelled else { return [:] }
        
        let sanitized = highlights.sanitized()
        
        progress.completedUnitCount += 1
        
        return sanitized
    }
    
    
    /// extract ranges of quoted texts as well as comments in the parse range
    private func extractCommentsWithQuotes() -> [SyntaxType: [NSRange]] {
        
        let string = self.string as NSString
        var positions = [QuoteCommentItem]()
        
        if let delimiters = self.definition.blockCommentDelimiters {
            positions += string.ranges(of: delimiters.begin, range: self.parseRange)
                .map { QuoteCommentItem(type: .comments, token: .blockComment, role: .begin, range: $0) }
            positions += string.ranges(of: delimiters.end, range: self.parseRange)
                .map { QuoteCommentItem(type: .comments, token: .blockComment, role: .end, range: $0) }
        }
        
        if let delimiter = self.definition.inlineCommentDelimiter {
            positions += string.ranges(of: delimiter, range: self.parseRange)
                .flatMap { range -> [QuoteCommentItem] in
                    var lineEnd = 0
                    string.getLineStart(nil, end: &lineEnd, contentsEnd: nil, for: range)
                    let endRange = NSRange(location: lineEnd, length: 0)
                    
                    return [QuoteCommentItem(type: .comments, token: .inlineComment, role: .begin, range: range),
                            QuoteCommentItem(type: .comments, token: .inlineComment, role: .end, range: endRange)]
                }
        }
        
        for (quote, type) in self.definition.pairedQuoteTypes {
            positions += string.ranges(of: quote, range: self.parseRange)
                .map { QuoteCommentItem(type: type, token: .string(quote), role: [.begin, .end], range: $0) }
        }
        
        // remove escaped ones
        positions.removeAll { self.string.isCharacterEscaped(at: $0.range.location) }
        
        // sort by location
        positions.sort {
            if $0.range.location < $1.range.location { return true }
            if $0.range.location > $1.range.location { return false }
            
            if $0.range.isEmpty { return true }
            if $1.range.isEmpty { return false }
            
            guard $0.role.rawValue == $1.role.rawValue else {
                return $0.role.rawValue > $1.role.rawValue
            }
            return $0.range.length > $1.range.length
        }
        
        // scan quoted strings and comments in the parse range
        var highlights = [SyntaxType: [NSRange]]()
        var seekLocation = self.parseRange.location
        var searchingItem: QuoteCommentItem?
        
        for position in positions {
            // search next begin delimiter
            guard let item = searchingItem else {
                if position.role.contains(.begin), position.range.location >= seekLocation {
                    searchingItem = position
                }
                continue
            }
            
            // search corresponding end delimiter
            if position.role.contains(.end), position.token == item.token {
                let range = NSRange(item.range.lowerBound..<position.range.upperBound)
                
                highlights[item.type, default: []].append(range)
                
                searchingItem = nil
                seekLocation = range.upperBound
            }
        }
        
        // highlight until the end if not closed
        if let item = searchingItem {
            let range = NSRange(item.range.lowerBound..<self.parseRange.upperBound)
            
            highlights[item.type, default: []].append(range)
        }
        
        return highlights
    }
    
}



// MARK: - Private Functions

private extension Dictionary where Key == SyntaxType, Value == [NSRange] {
    
    /// Remove duplicated ranges.
    ///
    /// - Note:
    /// This sanitization reduces the performance time of `SyntaxParser.apply(highlights:range:)` significantly.
    /// Adding temporary attribute to a layoutManager is quite sluggish,
    /// so we want to remove useless highlighting ranges as many as possible beforehand.
    ///
    /// - Returns: Sanitized syntax highlight dictionary.
    func sanitized() -> [SyntaxType: [NSRange]] {
        
        var registeredIndexes = IndexSet()
        
        return SyntaxType.allCases.reversed()
            .reduce(into: [SyntaxType: IndexSet]()) { (dict, type) in
                guard let ranges = self[type] else { return }
                
                let indexes = ranges
                    .compactMap { Range<Int>($0) }
                    .reduce(into: IndexSet()) { $0.insert(integersIn: $1) }
                    .subtracting(registeredIndexes)
                
                guard !indexes.isEmpty else { return }
                
                registeredIndexes.formUnion(indexes)
                dict[type] = indexes
            }
            .mapValues { $0.rangeView.map { NSRange($0) } }
    }
    
}
