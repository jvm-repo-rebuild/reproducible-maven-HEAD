#!/bin/bash

cat <(echo "| groupId | artifactId: buildspec  | latest release: Reproducibility | HEAD version: Reproducibility |"
echo "| ------- | ------------------------- | ----------------- | ----------------- |"

count=0
countHEADOk=0
sumHEADOk=0
sumHEADKo=0
countLatestOk=0
sumLatestOk=0
sumLatestKo=0
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
  echo -n "| [${artifactId}](https://repo.maven.apache.org/maven2/${groupDir}/${artifactId}): "
  echo -n "[spec](https://github.com/jvm-repo-rebuild/reproducible-maven-HEAD/tree/master/${buildspec}) "

  echo -n "| x.y.z "

  . ${buildinfo}.compare
  echo -n "| [${version}](https://github.com/jvm-repo-rebuild/reproducible-maven-HEAD/tree/master/"`ls ${buildinfo}`"): "
  [ ${ok} -gt 0 ] && echo -n "${ok} :heavy_check_mark: "
  [ ${ko} -gt 0 ] && echo -n " ${ko} [:warning:](https://github.com/jvm-repo-rebuild/reproducible-maven-HEAD/tree/master/`ls ${buildinfo}.compare`) "
  echo "|"

  [ ${ko} -eq 0 ] && countHEADOk=$(($countHEADOk + 1))
  sumHEADOk=$(($sumHEADOk + ${ok}))
  sumHEADKo=$(($sumHEADKo + ${ko}))
done

# temporary hard coded latest figures
countLatestOk=6
sumLatestOk=53
sumLatestKo=529

echo -n "| | **${count}** "

echo -n "| **${countLatestOk} :heavy_check_mark: + $((${count}-${countLatestOk})) :warning: = "
echo -n "$((${countLatestOk}*100/${count}))% :heavy_check_mark:: "
echo -n "${sumLatestOk} :heavy_check_mark: ${sumLatestKo} :warning:** "

echo -n "| **${countHEADOk} :heavy_check_mark: + $((${count}-${countHEADOk})) :warning: = "
echo -n "$((${countHEADOk}*100/${count}))% :heavy_check_mark:: "
echo "${sumHEADOk} :heavy_check_mark: ${sumHEADKo} :warning:** |"
echo "Total: Apache Maven consists in ${count} sub-projects:

- **Latest release Reproducibility: ${countLatestOk} :heavy_check_mark: + $((${count}-${countLatestOk})) :warning:
   = $((${countLatestOk}*100/${count}))% :heavy_check_mark:**

- **HEAD Reproducibility: ${countHEADOk} :heavy_check_mark: + $((${count}-${countHEADOk})) :warning:
   = $((${countHEADOk}*100/${count}))% :heavy_check_mark:**
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
