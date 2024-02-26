#!/bin/sh

git_repo=https://github.com/inab/lrgasp-challenge-3_benchmarking_docker.git
git_tag=48cc87bb6f21f94b4b14ae4b1f6cf7a72e871333

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
