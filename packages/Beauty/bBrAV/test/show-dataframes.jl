using DataFrames

# test DataFrame output as html
html = "<table class=\"data-frame\"><theard><tr><th>Heading</th></tr></theard><tr><td>Item 1</td></tr><tr><td>Item 2</td></tr></table>"
@test showoutput("text/html", DataFrame(Heading=["Item 1", "Item 2"])) == html

# test categorical DataFrame
html = "<table class=\"data-frame\"><theard><tr><th>Names</th></tr></theard><tr><td>Alice</td></tr><tr><td>Bea</td></tr></table>"
@test showoutput("text/html", categorical!(DataFrame(Names=["Alice", "Bea"]), :Names)) == html
