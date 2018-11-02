#!/bin/sh

source src/settings

if [ -d "epub" ]; then
	rm -rf epub;
fi;

mkdir epub;

mkdir epub/META-INF
mkdir epub/OEBPS
mkdir epub/OEBPS/assets

cp includes/mimetype epub/mimetype
cp includes/stylesheet.css epub/OEBPS
cp includes/container.xml epub/META-INF
cp includes/com.apple.ibooks.display-options.xml epub/META-INF
cp includes/*.ttf epub/OEBPS/assets

cat includes/book_head.opf > book.opf.tmp
cat includes/toc_head.ncx > toc.ncx.tmp
echo "<manifest>" > book.opf.manifest.tmp
echo "<spine toc='ncx'>" > book.opf.spine.tmp

PLAY_ORDER=1

function parse {
    INPUT=$1
    DESTINATION=$2
    FRAGMENT_TITLE=$3
    FRAGMENT_ID=$4

    cat includes/content_head.html > tmp
    cat $INPUT >> tmp
    sed -i '' -E 's/\[(.*)\]/<strong>\1<br \/><br \/><\/strong>/g' tmp
    sed -i '' -E 's/^\#\#\#([ a-zA-Z]+)\#\#\#/<h3\>\1\<\/h3\>/g' tmp
    sed -i '' -E 's/^\#.+\#[^ a-zA-Z]*$//g' tmp
    sed -i '' -E 's/^\// \//g' tmp
    sed -i '' -E 's/(^[^\<].*)([\w,\. ]*)\/([^\<\>\/]+)\/([\w,\. ]*)/\1\2\<em\>\3\<\/em\>\4/g' tmp
    sed -i '' -E 's/---/\<div class="wp-nocaption alignnone size-full wp-image-20"\>\<img class="alignnone size-full wp-image-20" src="assets\/break.png" alt="break" width="120" height="56"\/\>\<\/div\>/' tmp
    sed -i '' -E 's/(^[^\<].+$)/\<p class="para"\>\1\<\/p\>\ /' tmp
    cat includes/content_foot.html >> tmp
    sed -i '' -E 's/{{FRAGMENT_TITLE}}/'"$FRAGMENT_TITLE"'/g' tmp
    mv tmp epub/OEBPS/$DESTINATION

    reference $DESTINATION "$FRAGMENT_TITLE" $FRAGMENT_ID
}
function reference {
    DESTINATION=$1
    FRAGMENT_TITLE=$2
    FRAGMENT_ID=$3

    echo "<item id='$FRAGMENT_ID' href='OEBPS/$DESTINATION' media-type='application/xhtml+xml' />" >> book.opf.manifest.tmp

    echo "<itemref idref='$FRAGMENT_ID' linear='yes' />" >> book.opf.spine.tmp

    echo "<navPoint id='$FRAGMENT_ID' playOrder='$PLAY_ORDER'>" >> toc.ncx.tmp
    echo "<navLabel><text>$FRAGMENT_TITLE</text></navLabel>" >> toc.ncx.tmp
    echo "<content src='OEBPS/$DESTINATION' />" >> toc.ncx.tmp
    echo "</navPoint>" >> toc.ncx.tmp
    let PLAY_ORDER=PLAY_ORDER+1
}

function set_fields {
    SRC=$1
    sed -i '' 's/{{ID}}/'"$ID"'/g' $SRC
    sed -i '' 's/{{TITLE}}/'"$TITLE"'/g' $SRC
    sed -i '' 's/{{AUTHOR}}/'"$AUTHOR"'/g' $SRC
    sed -i '' 's/{{DATE}}/'"$DATE"'/g' $SRC
    sed -i '' 's/{{PUBLISHER}}/'"$PUBLISHER"'/g' $SRC
    sed -i '' 's/{{AUTHOR_FILE_AS}}/'"$AUTHOR_FILE_AS"'/g' $SRC
    sed -i '' 's/{{PUBLISH_YEAR}}/'"$PUBLISH_YEAR"'/g' $SRC
    sed -i '' 's/{{PUBLISH_CITY}}/'"$PUBLISH_CITY"'/g' $SRC
}

WORDCOUNT=`cat src/chapters/*.txt | sed -e 's/---//g' | wc | awk '{ print $2 }'`
cat src/chapters/*.txt | sed -E 's/#//g' | sed -E 's/---//g' | sed -E 's/\///g' > wc.txt

parse includes/cover.html cover.html Cover cover

echo "<div id='title-page'><h1 class='title'>{{TITLE}}</h1><h2 class='subtitle'></h2><h3 class='author'>{{AUTHOR}}</h3><h4 class='author'></h4><h4 class='publisher'>{{PUBLISHER}}</h4><h5 class='publisher-city'>{{PUBLISH_CITY}}</h5></div>" > stage.tmp
parse stage.tmp TitlePage.html "Title Page" TitlePage

echo "<div id='copyright-page'><div class='ugc'><p>{{TITLE}} Copyright &#169; {{PUBLISH_YEAR}} by {{AUTHOR}}. </p><p>This book was written during <a href='http://nanowrimo.org/'>National Novel Writing Month 2018</a>.</p></div></div>" > stage.tmp
parse stage.tmp Copyright.html "Copyright" Copyright

cat includes/content_head.html > toc.html.tmp
sed -i '' -E 's/{{FRAGMENT_TITLE}}/Table of Contents/g' toc.html.tmp
echo "<div id='toc'><h1>Contents</h1><ul>" >> toc.html.tmp
reference Toc.html "Table of Contents" Toc

parse src/foreword.txt Foreword.html Foreword Foreword

echo "<li class='front-matter'><a href='TitlePage.html'><span class='toc-chapter-title'> Title</span></a></li>" >> toc.html.tmp
echo "<li class='front-matter'><a href='Copyright.html'><span class='toc-chapter-title'> Copyright</span></a></li>" >> toc.html.tmp
echo "<li class='front-matter foreword'><a href='Foreword.html'><span class='toc-chapter-title'> Foreword</span></a></li>" >> toc.html.tmp

CHAPTER=1
SECTION=1
for i in `ls src/chapters/*.txt`; do
    SECTIONTITLE=`cat $i | grep ^\#[^#] | sed 's/\#//g'`
    PAGETITLE=`cat $i | grep ^\#\#[^#] | sed 's/\#\#//g'`
    DEST=`echo $i | sed -E 's/.*\/(.*)\.txt/\1.html/'`;

    if [ -z "$SECTIONTITLE" ]; then
        echo Chapter $CHAPTER : $PAGETITLE;
        echo "<li class='chapterstandard'><a href='Chapter$DEST'><span class='toc-chapter-title'> $CHAPTER. $PAGETITLE</span></a></li>" >> toc.html.tmp
    else
        echo Section: $SECTIONTITLE
        echo Chapter $CHAPTER : $PAGETITLE;
        echo "<div class='part introduction ' id='Part$SECTION'><div class='part-title-wrap'><h3 class='part-number'>$SECTION</h3><h1 class='part-title'><a href='Toc.html'>$SECTIONTITLE</a></h1></div></div>" > stage.tmp
        parse stage.tmp Part$SECTION.html "$SECTIONTITLE" Part$SECTION
        echo "<li class='part'><a href='Part$SECTION.html'><span class='toc-chapter-title'>$SECTIONTITLE</span></a></li>" >> toc.html.tmp
        echo "<li class='chapterstandard'><a href='Chapter$DEST'><span class='toc-chapter-title'> $CHAPTER. $PAGETITLE</span></a></li>" >> toc.html.tmp
        let SECTION=SECTION+1
    fi

    echo "<div class='chapter standard' id='Chapter$CHAPTER'><div class='chapter-title-wrap'><h3 class='chapter-number'>$CHAPTER</h3><h2 class='chapter-title'><a href='Toc.html'>$PAGETITLE</a></h2></div><div class='ugc chapter-ugc'>" > stage.tmp
    cat $i >> stage.tmp
    echo >> stage.tmp
    echo "</div></div>" >> stage.tmp
    parse stage.tmp Chapter$DEST "$PAGETITLE" Chapter$CHAPTER
    rm stage.tmp
    let CHAPTER=CHAPTER+1
done;

let REF=1
for i in `ls src/*.jpg`; do
    FILE=`echo $i | sed -E 's/.*\/(.*\.*)/\1/'`
    echo $FILE;
	echo \<item href=\"OEBPS/assets/$FILE\" id=\"id$REF\" media-type=\"image/jpeg\" properties=\"cover-image\"/\> >> book.opf.manifest.tmp
	cp $i epub/OEBPS/assets
    let REF=REF+1
done;
for i in `ls src/*.png`; do
    FILE=`echo $i | sed -E 's/.*\/(.*\.*)/\1/'`
    echo $FILE;
	echo \<item href=\"OEBPS/assets/$FILE\" id=\"id$REF\" media-type=\"image/png\"/\> >> book.opf.manifest.tmp
	cp $i epub/OEBPS/assets
    let REF=REF+1
done;

parse src/afterword.txt Afterword.html Afterword Afterword
echo "<li class='back-matter'><a href='Afterword.html'><span class='toc-chapter-title'> Afterword</span></a></li>" >> toc.html.tmp

echo "</ul></div>" >> toc.html.tmp
cat includes/content_foot.html >> toc.html.tmp
mv toc.html.tmp epub/OEBPS/Toc.html

echo "<item id='media-Quantico-Bold' href='OEBPS/assets/Quantico-Bold.ttf' media-type='application/x-font-ttf' />" >> book.opf.manifest.tmp
echo "<item id='media-Quantico-BoldItalic' href='OEBPS/assets/Quantico-BoldItalic.ttf' media-type='application/x-font-ttf' />" >> book.opf.manifest.tmp
echo "<item id='media-Quantico-Italic' href='OEBPS/assets/Quantico-Italic.ttf' media-type='application/x-font-ttf' />" >> book.opf.manifest.tmp
echo "<item id='media-Quantico-Regular' href='OEBPS/assets/Quantico-Regular.ttf' media-type='application/x-font-ttf' />" >> book.opf.manifest.tmp
echo "<item id='ncx' href='toc.ncx' media-type='application/x-dtbncx+xml' />" >> book.opf.manifest.tmp
echo "<item id='stylesheet' href='OEBPS/stylesheet.css'  media-type='text/css' />" >> book.opf.manifest.tmp


echo "</manifest>" >> book.opf.manifest.tmp
echo "</spine>" >> book.opf.spine.tmp

cat book.opf.manifest.tmp >> book.opf.tmp
rm book.opf.manifest.tmp

cat book.opf.spine.tmp >> book.opf.tmp
rm book.opf.spine.tmp

for i in `find epub/OEBPS -maxdepth 1 -type f`; do
    set_fields $i
done

cat includes/book_foot.opf >> book.opf.tmp
cat includes/toc_foot.ncx >> toc.ncx.tmp

set_fields book.opf.tmp
set_fields toc.ncx.tmp

mv book.opf.tmp epub/book.opf
mv toc.ncx.tmp epub/toc.ncx

if [ -f "$PACKAGE.epub" ]; then
	rm -f $PACKAGE.epub;
fi;

cd epub
zip -X -0 ../$PACKAGE.epub mimetype
zip -X -u ../$PACKAGE.epub toc.ncx
zip -X -u ../$PACKAGE.epub book.opf
zip -X -u -r ../$PACKAGE.epub OEBPS
zip -X -u -r ../$PACKAGE.epub META-INF
cd ..
rm -rf epub

echo Generated $PACKAGE.epub. Wordcount: $WORDCOUNT
