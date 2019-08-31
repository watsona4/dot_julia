using Weave

weave("src/index.Rmd", informat="markdown",
      out_path = "src/", doctype = "github") 
