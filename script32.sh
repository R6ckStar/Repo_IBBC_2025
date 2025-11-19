#!/bin/bash

sample_info=samples.txt
files=($(cut -f 2 "$sample_info"))


for filesfq in ${files[@]}; do


    echo "$filesfq"


done
