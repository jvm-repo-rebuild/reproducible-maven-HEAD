#!/bin/bash

cat <(echo "| dist | groupId | artifactId | build | version | Reproducibility |"
echo "| ---- | ------- | ------------------ | ----- | ------- | --------------- |"

for buildspec in `find maven -name *.buildspec -print | sort`
do
  . $buildspec

  groupDir=$(echo ${groupId} | tr '.' '/')
  buildinfo="`dirname ${buildspec}`/`basename ${buildinfo}`"

  echo -n "| [`dirname ${buildspec} | cut -c 7-`](https://downloads.apache.org/`dirname ${buildspec}`) "
  echo -n "| [`echo ${groupId} | sed s/org.apache.maven/o.a.m/`](https://repo.maven.apache.org/maven2/${groupDir}) "
  echo -n "| [${artifactId}](https://repo.maven.apache.org/maven2/${groupDir}/${artifactId}) "
  echo -n "| [spec](https://github.com/jvm-repo-rebuild/reproducible-maven-HEAD/tree/master/${buildspec}) "
  [ -f ${buildinfo} ] && echo -n "/ [info](https://github.com/jvm-repo-rebuild/reproducible-maven-HEAD/tree/master/"`basename ${buildinfo}`") "

  . ${buildinfo}.compare
  echo -n "| ${version} "
  if [ $? -eq 0 ]; then
    echo -n "| "
    [ ${ok} -gt 0 ] && echo -n "${ok} :heavy_check_mark: "
    [ ${ko} -gt 0 ] && echo -n " ${ko} [:warning:](https://github.com/jvm-repo-rebuild/reproducible-maven-HEAD/tree/master/${buildinfo}.compare) "
  else
    echo -n "| :x: "
  fi
  echo "|"

done) > summary-table.md

lead='^<!-- BEGIN GENERATED CONTENT -->$'
tail='^<!-- END GENERATED CONTENT -->$'
sed -e "/$lead/,/$tail/{ /$lead/{p; r summary-table.md
        }; /$tail/p; d }" README.md > README.md.tmp

mv README.md.tmp README.md

rm summary-table.md
