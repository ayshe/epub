# epub generator

This is a set of scripts and assets to generate an epub from a set of text files.

## How to use

* Create a folder called chapters
* Add chapter files inside this directory. We suggest 1.txt, 2.txt etc. They need to resolve alphabetically
* Create a folder called includes
* Add includes/foreword.xhtml. Write an HTML snippet for a foreword
* Add includes/afterword.xhtml. Write an HTML snippet for an afterword
* Add includes/cover.jpg. This should be 770 × 1186
* Add includes/settings. This is where you set the environment variables for the ebook (author, title etc)
* Run publish.sh

See the following files for examples

examples/example_foreword.xhtml
examples/example_afterword.xhtml
examples/example_cover.jpg
examples/example_settings

## Titles and sections

Each chapter file (1.txt, 2.txt, etc) must have a title. The format is ##title##
Each chapter file may also optionally have a section. The format is #section#

See examples/example_chapter1.txt and examples/example_chapter2.txt