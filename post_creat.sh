#!/bin/bash
echo "post create start"

touch $PWD/_posts/$(date +%Y-%m-%d)-$1.md

echo "post create end"
