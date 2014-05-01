cd "$(dirname "$0")"
rm bridges.zip
zip -r bridges.zip ../src/*
zip -r bridges.zip haxelib.json
haxelib submit bridges.zip