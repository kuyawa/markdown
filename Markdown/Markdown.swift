//
//  Markdown.swift
//  Markdown
//
//  Created by Mac Mini on 12/30/16.
//  Copyright © 2016 Armonia. All rights reserved.
//

import Foundation

/*
 
 TODO: Paragraphs
 - insert p and br tags for paragraphs, loop all lines?
 - if line does not start with < consider it a starting paragraph
 - if it ends in double newline consider it an end of paragraph (furst pass before BR)
 - if it ends in a single newline without block tag consider it a BR tag
 
 */

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
        
        return String(md)
    }
    
    func cleanHtml(_ md: inout NSMutableString) {
        md.matchAndReplace("<.*?>", "")
    }
    
    func cleanBreaks() {
        //
    }
    
    func parseHeaders(_ md: inout NSMutableString) {
        md.matchAndReplace("^###(.*)?", "<h3>$1</h3>", options: [.anchorsMatchLines])
        md.matchAndReplace("^##(.*)?", "<h2>$1</h2>", options: [.anchorsMatchLines])
        md.matchAndReplace("^#(.*)?", "<h1>$1</h1>", options: [.anchorsMatchLines])
    }
    
    func parseBold(_ md: inout NSMutableString) {
        md.matchAndReplace("\\*\\*(.*?)\\*\\*", "<b>$1</b>")
    }
    
    func parseItalic(_ md: inout NSMutableString) {
        md.matchAndReplace("\\*(.*?)\\*", "<i>$1</i>")
    }
    
    func parseDeleted(_ md: inout NSMutableString) {
        md.matchAndReplace("~~(.*?)~~", "<s>$1</s>")
    }
    
    func parseImages(_ md: inout NSMutableString) {
        md.matchAndReplace("!\\[(\\d+)x(\\d+)\\]\\((.*?)\\)", "<img src=\"$3\" width=\"$1\" height=\"$2\" />")
        md.matchAndReplace("!\\[(.*?)\\]\\((.*?)\\)", "<img alt=\"$1\" src=\"$2\" />")
    }
    
    func parseLinks(_ md: inout NSMutableString) {
        md.matchAndReplace("\\[(.*?)\\]\\((.*?)\\)", "<a href=\"$2\">$1</a>")
        md.matchAndReplace("\\[http(.*?)\\]", "<a href=\"http$1\">http$1</a>")
        md.matchAndReplace("\\shttp(.*?)\\s", " <a href=\"http$1\">http$1</a> ")
    }
    
    func parseUnorderedLists(_ md: inout NSMutableString) {
        //md.matchAndReplace("^\\*(.*)?", "<li>$1</li>", options: [.anchorsMatchLines])
        parseBlock(&md, format: "^\\*", blockEnclose: ("<ul>", "</ul>"), lineEnclose: ("<li>", "</li>"))
    }
    
    func parseOrderedLists(_ md: inout NSMutableString) {
        parseBlock(&md, format: "^\\d+[\\.|-]", blockEnclose: ("<ol>", "</ol>"), lineEnclose: ("<li>", "</li>"))
    }
    
    func parseBlockquotes(_ md: inout NSMutableString) {
        //md.matchAndReplace("^>(.*)?", "<blockquote>$1</blockquote>", options: [.anchorsMatchLines])
        parseBlock(&md, format: "^>", blockEnclose: ("<blockquote>", "</blockquote>"))
        parseBlock(&md, format: "^:", blockEnclose: ("<blockquote>", "</blockquote>"))
    }
    
    func parseCodeBlock(_ md: inout NSMutableString) {
        md.matchAndReplace("```(.*?)```", "<pre>$1</pre>", options: [.dotMatchesLineSeparators])
        parseBlock(&md, format: "^\\s{4}", blockEnclose: ("<pre>", "</pre>"))
    }
    
    func parseCodeInline(_ md: inout NSMutableString) {
        md.matchAndReplace("`(.*?)`", "<code>$1</code>")
    }
    
    func parseHorizontalRule(_ md: inout NSMutableString) {
        md.matchAndReplace("---", "<hr>")
    }
    
    func parseParagraphsBR(_ md: inout NSMutableString) {
        md.matchAndReplace("^([^<|^\\s<])(.*?)$", "$1$2<br>", options: [.anchorsMatchLines])
        md.matchAndReplace("^$", "<br>", options: [.anchorsMatchLines])
        //md.matchAndReplace("(<pre>.*?)<br>(.*?</pre>)", "$1$2", options: [.dotMatchesLineSeparators])
        md.matchAndReplace("(<pre>^(<br>).*?</pre>)", "$0|$1|$2|$3", options: [.dotMatchesLineSeparators])
        //cleanBreaks("pre")
    }

    /*
    func parseParagraphsBR2(_ md: inout NSMutableString) {
        let lines = md.components(separatedBy: .newlines)
        var result = [String]()
        
        for line in lines {
            if !line.hasPrefix("<") {
                result.append(line.append("<br>"))
            } else {
                result.append(line)
            }
        }
        
        md = NSMutableString(string: result.joined(separator: "\n"))
    }
    */
    
    func parseParagraphs(_ md: inout NSMutableString) {
        md.matchAndReplace("\n([^\n]+)\n", "\n<p>$1</p>\n", options: [.anchorsMatchLines])
    }
    
    /*
    func parseParagraphs(_ md: inout NSMutableString) {
        let lines = md.components(separatedBy: .newlines)
        var result = [String]()
        var isBlock = false
        var isFirst = true
        
        for line in lines {
            var text = line
            
            if text.hasPrefix("<") || text.trim().isEmpty {
                isBlock = false
                isFirst = true
                result.append("</p>")
                //result.append(text)
            } else {
                isBlock = true
                if isFirst { result.append("<p>"); isFirst = false }
                if !text.trim().isEmpty {
                    text = text.append("<br>")
                }
            }

            result.append(text)
        }
        
        if isBlock { result.append("</p>") } // close open blocks
        
        md = NSMutableString(string: result.joined(separator: "\n"))
    }
    */
    
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
                text = text.append(blockEnclose.1)
            }
            result.append(text)
        }

        if isBlock { result.append(blockEnclose.1) } // close open blocks
        
        md = NSMutableString(string: result.joined(separator: "\n"))
    }
    
}

