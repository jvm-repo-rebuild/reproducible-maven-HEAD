#!/usr/bin/env bash

fatal()
{
  echo "fatal: $1" 1>&2
  exit 1
}

usage()
{
  echo "usage: $0 [-r] <file.buildspec>
  -r: rebuild also latest release" 1>&2
  exit 1
}

rebuildLatest='false'
while getopts ":r" option; do
  case "${option}" in
    r)
      rebuildLatest='true'
      ;;
    *)
      usage
      ;;
  esac
done
shift $((OPTIND-1))

buildspec=$1
[ -z "${buildspec}" ] && usage

echo "Rebuilding from spec ${buildspec}"

. ${buildspec} || fatal "could not source ${buildspec}"

echo "- ${groupId}:${artifactId}"
echo "- gitRepo: ${gitRepo}"
echo "- jdk: ${jdk}"
echo "- command: ${command}"
echo "- buildinfo: ${buildinfo}"

base="$PWD"

pushd `dirname ${buildspec}` >/dev/null || fatal "could not move into ${buildspec}"

# prepare source, using provided Git repository
[ -d buildcache ] || mkdir buildcache
cd buildcache
[ -d ${artifactId} ] || git clone ${gitRepo} ${artifactId} || fatal "failed to clone ${artifactId}"
cd ${artifactId}
git checkout master || fatal "failed to git checkout master"
git pull || fatal "failed to git pull"

pwd

# the effective rebuild command for latest, adding artifact:buildinfo goal to compare with central content
mvn_rebuild_latest="${command} -V -e artifact:buildinfo -Dreference.repo=central -Dreference.compare.save -Dbuildinfo.reproducible"
# the effective rebuild commands for master HEAD, adding artifact:buildinfo goal and install on first run to compare on second
mvn_rebuild_1="${command} -V -e install:install artifact:buildinfo"
mvn_rebuild_2="${command} -V -e artifact:buildinfo -Dreference.repo=central -Dreference.compare.save -Dbuildinfo.reproducible"

mvnBuildDocker() {
  local mvnCommand mvnImage crlfDocker
  mvnCommand="$1"
  crlfDocker="no"
  # select Docker image to match required JDK version: https://hub.docker.com/_/maven
  case ${jdk} in
    6 | 7)
      mvnImage=maven:3.6.1-jdk-${jdk}-alpine
      crlfDocker="yes"
      ;;
    8)
      mvnImage=maven:3.6.3-jdk-${jdk}-slim
      crlfDocker="yes"
      ;;
    9)
      mvnImage=maven:3-jdk-${jdk}-slim
      ;;
    14)
      mvnImage=maven:3.6.3-jdk-${jdk}
      ;;
    15 | 16 | 17)
      mvnImage=maven:3.6.3-openjdk-${jdk}-slim
      ;;
    *)
      mvnImage=maven:3.6.3-jdk-${jdk}-slim
  esac

  echo "Rebuilding using Docker image ${mvnImage}"
  local docker_command="docker run -it --rm --name rebuild-central -v $PWD:/var/maven/app -v $base:/var/maven/.m2 -v $base/.npm:/.npm -u $(id -u ${USER}):$(id -g ${USER}) -e MAVEN_CONFIG=/var/maven/.m2 -w /var/maven/app"
  local mvn_docker_params="-Duser.home=/var/maven"
  if [[ "${newline}" == crlf* ]]
  then
    if [[ "${crlfDocker}" == "yes" ]]
    then
      echo -e "\033[2m${docker_command} ${mvnImage} \033[1m${mvnCommand} ${mvn_docker_params} -Dline.separator=\$'\\\\r\\\\n'\033[0m"
      ${docker_command} ${mvnImage} ${mvnCommand} ${mvn_docker_params} -Dline.separator=$'\r\n'
    else
      mvnCommand="$(echo "${mvnCommand}" | sed "s_^mvn _/var/maven/.m2/mvncrlf _")"
      echo -e "\033[2m${docker_command} ${mvnImage} \033[1m${mvnCommand} ${mvn_docker_params}\033[0m"
      ${docker_command} ${mvnImage} ${mvnCommand} ${mvn_docker_params}
    fi
  else
    echo -e "\033[2m${docker_command} ${mvnImage} \033[1m${mvnCommand} ${mvn_docker_params}\033[0m"
    ${docker_command} ${mvnImage} ${mvnCommand} ${mvn_docker_params}
  fi
}

# TODO not tested
mvnBuildLocal() {
  local mvnCommand="$1"

  echo "Rebuilding using local JDK ${jdk}"
  # TODO need to define settings with ${base}/repository local repository to avoid mixing reproducible-central dependencies with day to day builds
  if [[ "${newline}" == crlf* ]]
  then
    ${mvnCommand} -Dline.separator=$'\r\n'
  else
    ${mvnCommand}
  fi
}

# by default, build with Docker
# TODO: on parameter, use instead mvnBuildLocal after selecting JDK
#   jenv shell ${jdk}
#   sdk use java ${jdk}

if ${rebuildLatest}
then
  echo "******************************************************"
  echo "* rebuilding latest release and comparing to central *"
  echo "******************************************************"
  # git checkout latest tag then rebuild latest release
  if [ -z "${latest}" ]
  then
    # auto-detect last Git tag
    gitTag="`git describe --abbrev=0`"
    version="${gitTag}"
    echo "last Git tag is ${gitTag}"
  else
    version="${latest}"
    echo "configured latest is ${latest} with Git tag ${gitTag}"
  fi
  git checkout ${gitTag} || fatal "failed to git checkout latest ${version}"
  if [ "${newline}" == "crlf" ]
  then
    echo "converting newlines to crlf"
    git ls-files --eol | grep w/lf | cut -c 40- | xargs -d '\n' unix2dos
  fi
  mvnBuildDocker "${mvn_rebuild_latest}" || fatal "failed to build latest"
  git reset --hard

  dos2unix ${buildinfo}* || fatal "failed to convert buildinfo newlines"
  sed -i 's/\(reference_[^=]*\)=\([^"].*\)/\1="\2"/' ${buildinfo}*.compare # waiting for MARTIFACT-19
  cp ${buildinfo}* ../.. || fatal "failed to copy buildinfo artifacts latest ${version}"

  . ${buildinfo}*.compare
  if [[ ${ko} > 0 ]]
  then
    echo -e "    ok=${ok}"
    echo -e "    okFiles=\"${okFiles}\""
    echo -e "    \033[31;1mko=${ko}\033[0m"
    echo -e "    koFiles=\"${koFiles}\""
    if [ -n "${reference_java_version}" ]
    then
      echo -e "    check .buildspec \033[1mjdk=${jdk}\033[0m vs reference \033[1mjava.version=${reference_java_version}\033[0m"
    fi
    if [ -n "${reference_os_name}" ]
    then
      echo -e "    check .buildspec \033[1mnewline=${newline}\033[0m vs reference \033[1mos.name=${reference_os_name}\033[0m"
    fi
  else
    echo -e "    \033[32;1mok=${ok}\033[0m"
    echo -e "    okFiles=\"${okFiles}\""
  fi
fi

# work on master HEAD
git checkout master || fatal "failed to git checkout master"
currentCommit="`git rev-parse HEAD`"
prevCommitFile="../`basename $(pwd)`.HEAD"
if [ "${currentCommit}" == "`cat ${prevCommitFile}`" ]
then
  echo "*******************************************"
  echo "* no new commit on HEAD, skipping rebuild *"
  echo "*******************************************"
  echo "$(pwd).HEAD"
else
  echo "*******************************************************"
  echo "* rebuilding master HEAD SNAPSHOT twice and comparing *"
  echo "*******************************************************"
  if [ "${newline}" == "crlf" ]
  then
    echo "converting newlines to crlf"
    git ls-files --eol | grep w/lf | cut -c 40- | xargs -d '\n' unix2dos
  fi
  # rebuild HEAD SNAPSHOT twice
  mvnBuildDocker "${mvn_rebuild_1}" || fatal "failed to build first time"
  mvnBuildDocker "${mvn_rebuild_2}" || fatal "failed to build second time"
  git reset --hard

  dos2unix ${buildinfo}* || fatal "failed to convert buildinfo newlines"
  sed -i 's/\(reference_[^=]*\)=\([^"].*\)/\1="\2"/' ${buildinfo}*.compare # waiting for MARTIFACT-19
  cp ${buildinfo}* ../.. || fatal "failed to copy buildinfo artifacts HEAD"
  # TODO detect if buildinfo.commit has changed: if not, restore previous buildinfo since update is mostly noise

  . ${buildinfo}*.compare
  if [[ ${ko} > 0 ]]
  then
    echo -e "    ok=${ok}"
    echo -e "    okFiles=\"${okFiles}\""
    echo -e "    \033[31;1mko=${ko}\033[0m"
    echo -e "    koFiles=\"${koFiles}\""
    if [ -n "${reference_java_version}" ]
    then
      echo -e "    check .buildspec \033[1mjdk=${jdk}\033[0m vs reference \033[1mjava.version=${reference_java_version}\033[0m"
    fi
    if [ -n "${reference_os_name}" ]
    then
      echo -e "    check .buildspec \033[1mnewline=${newline}\033[0m vs reference \033[1mos.name=${reference_os_name}\033[0m"
    fi
  else
    echo -e "    \033[32;1mok=${ok}\033[0m"
    echo -e "    okFiles=\"${okFiles}\""
  fi

  echo -n "${currentCommit}" > ${prevCommitFile}
fi

echo

popd > /dev/null
