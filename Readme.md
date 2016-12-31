# Markdown in Swift

This library parses Markdown in Swift without any external resources.

Use:

    let mkdn = "This is **bold** and this *italic* see?"
    let html = Markdown().parse(mkdn)
    print(html)

Simple huh?

#TODO:

\- Fix paragraphs and line breaks

