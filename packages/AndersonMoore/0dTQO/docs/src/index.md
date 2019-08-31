#Documentation Title
 
Some text describing the package.
 
## Subtitle
 
More text
 
## Tutorials
 
```@contents
Pages = [
    "tutorials/page1.md",
    "tutorials/page2.md",
    "tutorials/page3.md"
    ]
Depth = 2
```
 
## Another Section
```@contents
Pages = [
    "sec2/page1.md",
    "sec2/page2.md",
    "sec2/page3.md"
    ]
Depth = 2
```
 
## Index
 
```@index
```

At the top we explain the page. The next part adds 3 pages to a "Tutorial" section of the documentation, and then 3 pages to a "Another Section" section of the documentation. Now inside /docs/src make the directories tutorial and sec2, and add the appropriate pages page1.md, page2.md, page3.md. These are the Markdown files that the documentation will use to build the pages.

To build a page, you can do something like as follows:

# Title
 
Some text describing this section
 
## Subtitle
 
```@docs
AMA.sphere_vol
AMA.quadratic
AMA.quadratic2
```
