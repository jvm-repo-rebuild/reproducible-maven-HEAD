#!/bin/bash

cat <(echo "| groupId | artifactId | build | HEAD version | Reproducibility |"
echo "| ------- | ------------------ | ----- | ------------ | ----- |"

count=0
countOk=0
sumOk=0
sumKo=0
prevDist=""
for buildspec in `find maven -name *.buildspec -print | sort`
do
  count=$(($count+1))
  . $buildspec

  dist="`dirname ${buildspec}`"
  if [ "${prevDist}" != "${dist}" ]; then
    echo -n "| "
    echo "| **dist = [${dist}](https://downloads.apache.org/`dirname ${buildspec}`)** "
    prevDist="${dist}"
  fi

  groupDir=$(echo ${groupId} | tr '.' '/')
  buildinfo="`dirname ${buildspec}`/`basename ${buildinfo}`"

  echo -n "| [`echo ${groupId} | sed s/org.apache.maven/m/`](https://repo.maven.apache.org/maven2/${groupDir}) "
  echo -n "| [${artifactId}](https://repo.maven.apache.org/maven2/${groupDir}/${artifactId}) "
  echo -n "| [spec](https://github.com/jvm-repo-rebuild/reproducible-maven-HEAD/tree/master/${buildspec}) "
  [ -f ${buildinfo} ] && echo -n "/ [info](https://github.com/jvm-repo-rebuild/reproducible-maven-HEAD/tree/master/"`ls ${buildinfo}`") "

  . ${buildinfo}.compare
  echo -n "| ${version} "
  if [ $? -eq 0 ]; then
    echo -n "| "
    [ ${ok} -gt 0 ] && echo -n "${ok} :heavy_check_mark: "
    [ ${ko} -gt 0 ] && echo -n " ${ko} [:warning:](https://github.com/jvm-repo-rebuild/reproducible-maven-HEAD/tree/master/`ls ${buildinfo}.compare`) "
  else
    echo -n "| :x: "
  fi
  echo "|"

  [ ${ko} -eq 0 ] && countOk=$(($countOk + 1))
  sumOk=$(($sumOk + ${ok}))
  sumKo=$(($sumKo + ${ko}))
done
echo -n "|  | **${count} = ${countOk} :heavy_check_mark: + $((${count}-${countOk})) :warning:** "
echo -n "| **$((${countOk}*100/${count}))% :heavy_check_mark:** "
echo "|  | **${sumOk} :heavy_check_mark: ${sumKo} :warning:** |"
echo "**Total: ${count} sub-projects = ${countOk} :heavy_check_mark: + $((${count}-${countOk})) :warning:
   = $((${countOk}*100/${count}))% :heavy_check_mark:**
   " > summary.md
) > summary-table.md

lead='^<!-- BEGIN GENERATED CONTENT -->$'
tail='^<!-- END GENERATED CONTENT -->$'
sed -e "/$lead/,/$tail/{ /$lead/{p; r summary.md
        r summary-table.md
        }; /$tail/p; d }" README.md > README.md.tmp

mv README.md.tmp README.md

rm summary.md
rm summary-table.md
