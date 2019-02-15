REPO=../../img/drawing_animation/
echo "This I got: $1"
cd $1
convert -dispose previous -layers OptimizeFrame -delay 1x20 -loop 0 `ls -v *.png` final.gif

# With pause on last frame
convert final.gif \( +clone -set delay 150 \) +swap +delete  "../${REPO}/${1}.gif"

#duration 1sec, resolutionFactor 1.0
rm final.gif

#Without pause - uncomment line below and comment the previous steps above
# mv final.gif "../${REPO}/${1}.gif"
