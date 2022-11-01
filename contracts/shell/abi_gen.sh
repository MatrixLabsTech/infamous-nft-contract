#!/bin/bash
# generate abi json
all_abi="{"
for file in ./build/infamousNFT/bytecode_modules/*
do
    if test -f $file
    then
        echo $file
        abi=$(cat $file | od -v -t x1 -A n | tr -d ' \n')
        line="\"$file\":\"$abi\","
        all_abi="$all_abi$line"
    fi
done
all_abi=`echo ${all_abi%?}`
all_abi="$all_abi}"

mkdir -p ./deployed-airtifact
echo $all_abi > deployed-airtifact/compiled.json
echo 'compiled gen at deployed-airtifact/compiled.json'

