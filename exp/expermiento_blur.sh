cd ../src
for i in $(seq 40 40 480)
do
  ./genimg $i 0 120 255 file.bmp
  cd tests
  echo -n "size"$i" = "; ./runTests asm2 blur ../file.bmp aca.bmp
  cd ..
done
