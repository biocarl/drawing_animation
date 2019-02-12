#Renames files!

#Remove whitespaces of filenames.
for f in *\ *;do
  echo "try move $f"
  mv "$f" "${f// /_}";
done

#Apply svg convert
for ff in `ls *.{jpg,jpeg,png,gif} | sort -V`; do
  echo "try convert $ff"
  bash convert.sh $ff
done;
