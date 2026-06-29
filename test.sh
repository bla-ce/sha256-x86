#!/bin/bash

declare -a strings=("" "The quick brown fox jumps over the lazy dog" "The quick brown fox jumps over the lazy dog." "Hello, World!")

for i in "${strings[@]}"
do
  bash_sha=$(echo -n "$i" | sha256sum)
  x86_sha=$(echo -n "$i" | ./bin/sha256)

  if [ "$bash_sha" = "$x86_sha" ]; then
    echo "TEST ($i): equal"
  else
    echo "TEST ($i): not equal"
    echo "Expected: $bash_sha"
    echo "Expected: $x86_sha"
  fi
done
