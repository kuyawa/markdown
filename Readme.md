# Markdown in Swift

This library parses Markdown in Swift without any external resources. It's Linux compatible, plug and play, fire and forget.

Use:

    let mkdn = "This is **bold** and this *italic* see?"
    let html = Markdown().parse(mkdn)
    print(html)

Simple huh?

It uses RegularExpressions everywhere, eat babies and kick kitties, and it is not O log N whatever optimized, but it works without importing a thousand external libraries and that's all it counts.

All you need is this simple and beautiful file [markdown.swift](https://github.com/kuyawa/markdown/blob/master/Markdown/Markdown.swift)

##TODO:

\- Fix paragraphs and line breaks

If you are a RegEx guru please drop me a hand or simply fork and contribute to the world, no need for licenses, attributions or anything, just happy coding :D
