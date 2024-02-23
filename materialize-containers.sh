#!/bin/sh

git_repo=https://github.com/TianYuan-Liu/lrgasp-challenge-3_benchmarking_docker.git
git_tag=6ef76e40856103b2de2a1f00711cc805956e54e0

docker_tag=0.9.2

set -e

scriptdir="$(dirname "$0")"
case "$scriptdir" in
	/*)
		true
		;;
	.)
		scriptdir="$(pwd)"
		;;
	*)
		scriptdir="$(pwd)/${scriptdir}"
		;;
esac

repodir="${scriptdir}/the_repo"
cleanup() {
	set +e
	# This is needed in order to avoid
	# potential "permission denied" messages
	if [ -e "${repodir}" ] ; then
		chmod -R u+w "${repodir}"
		rm -rf "${repodir}"
	fi
}
trap cleanup EXIT ERR

rm -rf "${repodir}"
git clone -n "${git_repo}" "${repodir}"
cd "${repodir}" && git checkout "${git_tag}"

# Build the container images from the docker recipes
bash build.sh "${docker_tag}"
