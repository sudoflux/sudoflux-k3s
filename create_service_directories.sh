#!/bin/bash
while read dirname others; do
    mkdir "$dirname"
done < services.txt
