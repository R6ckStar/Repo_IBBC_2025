#!/bin/bash

sample_info=samples.txt
files=($(cut -f 3 "$sample_info"))


for filesfq in ${files[@]}; do


    echo "$filesfq"


done
