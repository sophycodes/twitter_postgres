#!/bin/sh

# list all of the files that will be loaded into the database
# for the first part of this assignment, we will only load a small test zip file with ~10000 tweets
# but we will write are code so that we can easily load an arbitrary number of files
files='
test-data.zip
'

echo 'load normalized'
for file in $files; do
    python3 load_tweets.py \
        --db=postgresql://postgres:pass@localhost:9877/postgres \
        --inputs=$file
done

echo 'load denormalized'
for file in $files; do
    python3 -c "
import zipfile, sys
with zipfile.ZipFile('$file') as z:
    for name in z.namelist():
        with z.open(name) as f:
            for line in f:
                sys.stdout.buffer.write(line.replace(b'\x00', b''))
" | psql postgresql://postgres:pass@localhost:9876/postgres -c \
    "\COPY tweets_jsonb (data) FROM STDIN CSV QUOTE E'\x01' DELIMITER E'\x02';"
done
