# Changes to each subfolder and runs toGif.sh
dirs=($(find . -type d))
for dir in "${dirs[@]}"; do
  echo "Processing $dir beeing in $PWD"
  bash toGif.sh $(basename "$dir") #parent will fail
done
