a="python-udfs/f_null_syns(varchar)/function.sql python-udfs/f_next_business_day(date)/input.csv python-udfs/f_null_syns(varchar)/function.sql"
folders=""
for file in $a; do
  folders="$folders $(dirname $file)"
done
echo "$folders" | tr " " "\n" | sort | uniq | tr "\n" " "
