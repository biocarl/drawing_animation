REPO=../../img/drawing_animation/
echo "This I got: $1"
cd $1
convert -dispose previous -layers OptimizeFrame -delay 1x10 -loop 0 `ls -v *.png` final.gif
convert final.gif \( +clone -set delay 150 \) +swap +delete  "../${REPO}/${1}.gif"
#duration 1sec, resolutionFactor 1.0
rm final.gif
