#This script is optimized for images with a monocolor background. Works most of the time.
file=$1
tmp="${file%%.*}.ppm"
svg="${file%%.*}.svg"
echo "$tmp"
#1) Convert to ppm
# mogrify -format ppm $1
convert $1 -fill none -fuzz 7% -draw 'matte 0,0 floodfill' -flop  -draw 'matte 0,0 floodfill' -flop -normalize $tmp

#2) Extract svg
potrace -s $tmp
#delete tmp
rm $tmp

#3) Minimize svg
svgo -i $svg
