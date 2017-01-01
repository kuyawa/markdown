//
//  ViewController.swift
//  Markdown
//
//  Created by Mac Mini on 12/30/16.
//  Copyright © 2016 Armonia. All rights reserved.
//

import Cocoa
import Foundation
import WebKit

class ViewController: NSViewController {

    @IBOutlet weak var textMark: NSTextView!
    @IBOutlet weak var textHtml: NSTextView!
    @IBOutlet weak var textView: WebView!
    
    override func viewDidAppear() {
        testMarkdown()
    }

    func testMarkdown() {
        let url   = Bundle.main.url(forResource: "Test",  withExtension: "html")
        let style = Bundle.main.url(forResource: "Style", withExtension: "html")
        let base  = URL(fileURLWithPath: url!.path)
        let css   = try! String(contentsOf: style!)
        let mkdn  = try! String(contentsOf: url!)
        let html  = Markdown().parse(mkdn)

        textMark.string = mkdn
        textHtml.string = html
        textView.mainFrame.loadHTMLString(css+html, baseURL: base)
    }

}


// End
