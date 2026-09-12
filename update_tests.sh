#!/bin/sh
for i in `ls ./tests/*.c`; do
  echo $i;
  ./clan $i -o $i.scop;
done

for i in `ls ./tests/unitary/*.c`; do
  echo $i; ./clan $i -o $i.scop;
done

for i in `ls ./tests/must_fail/*.c`; do
  echo $i; ./clan $i -o $i.scop;
done

for i in `ls ./tests/autoscop/*.c`; do
  echo $i;
  ./clan -autoscop $i -o $i.scop;
done

for i in `ls ./tests/modulo_acess/*.c`; do
  echo $i;
  ./clan $i -o $i.scop;
done


for i in ./tests/nonaffine/*.c; do
  echo "$i";
  ./clan "$i" -o "$i.scop";
  ./clan -extbody "$i" -o "$i.extbody.scop";
done
