//
//  Markdown.swift
//  Created by Kuyawa on 2016/12/30
//

import Foundation


#if os(macOS) || os(iOS) || os(tvOS) || os(watchOS)
    import Darwin
#elseif os(Linux)
    import Glibc
#endif


// Linux compatibility
#if os(Linux)
    typealias NSRegularExpression = RegularExpression
    typealias NSTextCheckingResult = TextCheckingResult
    extension TextCheckingResult {
        func rangeAt(_ n: Int) -> NSRange {
            return self.range(at: n)
        }
    }
#endif


// Useful extensions
extension String {
    func trim() -> String {
        return self.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    func match(_ pattern: String) -> Bool {
        guard self.characters.count > 0 else { return false }
        if let first = self.range(of: pattern, options: .regularExpression) {
            let match = self.substring(with: first)
            return !match.isEmpty
        }
        
        return false
    }
    
    func remove(_ pattern: String) -> String {
        guard self.characters.count > 0 else { return self }
        if let first = self.range(of: pattern, options: .regularExpression) {
            return self.replacingCharacters(in: first, with: "")
        }
        
        return self
    }
    
    func prepend(_ text: String) -> String {
        return text + self
    }
    
    func append(_ text: String) -> String {
        return self + text
    }
 
    func enclose(_ fence: (String, String)?) -> String {
        return (fence?.0 ?? "") + self + (fence?.1 ?? "")
    }
}

extension NSMutableString {
    func matchAndReplace(_ rex: String, _ rep: String, options: NSRegularExpression.Options? = []) {
        let regex = try? NSRegularExpression(pattern: rex, options: options!)
        let range = NSRange(location: 0, length: self.length)
        regex?.replaceMatches(in: self, options: [], range: range, withTemplate: rep)
    }
}


class Markdown {
    
    func parse(_ text: String) -> String {
        var md = NSMutableString(string: text)
        
        cleanHtml(&md)
        parseHeaders(&md)
        parseBold(&md)
        parseItalic(&md)
        parseDeleted(&md)
        parseImages(&md)
        parseLinks(&md)
        parseUnorderedLists(&md)
        parseOrderedLists(&md)
        parseBlockquotes(&md)
        parseCodeBlock(&md)
        parseCodeInline(&md)
        parseHorizontalRule(&md)
        parseParagraphs(&md)
        
        return String(describing: md)
    }
    
    func cleanHtml(_ md: inout NSMutableString) {
        md.matchAndReplace("<.*?>", "")
    }
    
    func parseHeaders(_ md: inout NSMutableString) {
        md.matchAndReplace("^###(.*)?", "<h3>$1</h3>", options: [.anchorsMatchLines])   // ### Title H3
        md.matchAndReplace("^##(.*)?", "<h2>$1</h2>", options: [.anchorsMatchLines])    // ## Title H2
        md.matchAndReplace("^#(.*)?", "<h1>$1</h1>", options: [.anchorsMatchLines])     // # Title H1
    }
    
    func parseBold(_ md: inout NSMutableString) {
        md.matchAndReplace("\\*\\*(.*?)\\*\\*", "<b>$1</b>")    // this is **bold** see?
    }
    
    func parseItalic(_ md: inout NSMutableString) {
        md.matchAndReplace("\\*(.*?)\\*", "<i>$1</i>")          // this is *italic* see?
    }
    
    func parseDeleted(_ md: inout NSMutableString) {
        md.matchAndReplace("~~(.*?)~~", "<s>$1</s>")            // this is ~~deleted~~ see?
    }
    
    func parseImages(_ md: inout NSMutableString) {
        md.matchAndReplace("!\\[(\\d+)x(\\d+)\\]\\((.*?)\\)", "<img src=\"$3\" width=\"$1\" height=\"$2\" />")  // ![300x200](kitty.jpg)
        md.matchAndReplace("!\\[(.*?)\\]\\((.*?)\\)", "<img alt=\"$1\" src=\"$2\" />")                          // ![Cute Cat](kitty.jpg)
    }
    
    func parseLinks(_ md: inout NSMutableString) {
        md.matchAndReplace("\\[(.*?)\\]\\((.*?)\\)", "<a href=\"$2\">$1</a>")       // [Swift](http://swift.org)
        md.matchAndReplace("\\[http(.*?)\\]", "<a href=\"http$1\">http$1</a>")      // [http://swift.org]
        md.matchAndReplace("\\shttp(.*?)\\s", " <a href=\"http$1\">http$1</a> ")    // http://swift.org
    }
    
    func parseUnorderedLists(_ md: inout NSMutableString) {
        //md.matchAndReplace("^\\*(.*)?", "<li>$1</li>", options: [.anchorsMatchLines])
        parseBlock(&md, format: "^\\*", blockEnclose: ("<ul>", "</ul>"), lineEnclose: ("<li>", "</li>"))            // * unordered lists
    }
    
    func parseOrderedLists(_ md: inout NSMutableString) {
        parseBlock(&md, format: "^\\d+[\\.|-]", blockEnclose: ("<ol>", "</ol>"), lineEnclose: ("<li>", "</li>"))    // 1. ordered lists
    }
    
    func parseBlockquotes(_ md: inout NSMutableString) {
        //md.matchAndReplace("^>(.*)?", "<blockquote>$1</blockquote>", options: [.anchorsMatchLines])
        parseBlock(&md, format: "^>", blockEnclose: ("<blockquote>", "</blockquote>"))  // > Some quote
        parseBlock(&md, format: "^:", blockEnclose: ("<blockquote>", "</blockquote>"))  // : Some quote
    }
    
    func parseCodeBlock(_ md: inout NSMutableString) {
        md.matchAndReplace("```(.*?)```", "<pre>$1</pre>", options: [.dotMatchesLineSeparators])    // ````let swift = "awesome"````
        parseBlock(&md, format: "^\\s{4}", blockEnclose: ("<pre>", "</pre>"))                       //     let swift = "awesome"
    }
    
    func parseCodeInline(_ md: inout NSMutableString) {
        md.matchAndReplace("`(.*?)`", "<code>$1</code>")    // `let swift = "awesome"`
    }
    
    func parseHorizontalRule(_ md: inout NSMutableString) {
        md.matchAndReplace("---", "<hr>")   // --- rule here
    }
    
    func parseParagraphs(_ md: inout NSMutableString) {
        md.matchAndReplace("\n\n([^\n]+)\n\n", "\n\n<p>$1</p>\n\n", options: [.dotMatchesLineSeparators])
    }
    
    func parseBlock(_ md: inout NSMutableString, format: String, blockEnclose: (String, String), lineEnclose: (String, String)? = nil) {
        let lines = md.components(separatedBy: .newlines)
        var result = [String]()
        var isBlock = false
        var isFirst = true
        
        for line in lines {
            var text = line
            if text.match(format) {
                isBlock = true
                if isFirst { result.append(blockEnclose.0); isFirst = false }
                text = text.remove(format)
                text = text.trim().enclose(lineEnclose)
            } else if isBlock {
                isBlock = false
                isFirst = true
                text = text.append(blockEnclose.1+"\n")
            }
            result.append(text)
        }

        if isBlock { result.append(blockEnclose.1) } // close open blocks
        
        md = NSMutableString(string: result.joined(separator: "\n"))
    }
    
}


// End