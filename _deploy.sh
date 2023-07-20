#!/bin/sh

# Deploy site to server

set -e
umask 022

# Calculate hashes to append as query parameters to the paths in /static
echo 'Calculating hashes…'
find static -type d -exec mkdir -p _data/hashes/{} \; >/dev/null
# This one replaces "." with "-" and prepends it if filename starts with a digit
find static -type f -not -name '.DS_Store' -exec sh -c 'echo "\"$(xxh32sum "$0" | cut -d " " -f 1 | xxd -r -p | base64 | sed s/=//g | tr +/ -_)\"" > "_data/hashes/$(dirname "$0")/$(basename "$0" | cut -c 1 | sed "s/[0-9]/-/" | grep "\-")$(basename "$0" | tr . -).json"' {} \;

cobalt build

find _site -name '*.css' -exec css-html-js-minify --quiet --overwrite {} \;
echo 'CSS minified.'

echo 'Precompressing…'
find -E _site -type f -not -regex '.*\.(png|zip|7z|jpeg|webp|br|gz|zst|html)' -not -size '1' -exec gzip -k --best {} \; -exec brotli {} \;

chmod -R a+rX _site

echo 'Touch YubiKey'
rsync -r --progress --del _site/ http:/srv/www/gtrr/

rm -r _site/ && echo 'Build files removed.'
