#!/bin/sh

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
datasetsdir="${scriptdir}/lrgasp-challenge-3_full_data"

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

git_repo="$(jq -r '.arguments[] | select(.name=="nextflow_repo_uri") | .value' "${scriptdir}"/config.json)"
git_tag="$(jq -r '.arguments[] | select(.name=="nextflow_repo_tag") | .value' "${scriptdir}"/config.json)"

# Materialize the repo
git clone -n "${git_repo}" "${repodir}"
cd "${repodir}" && git checkout "${git_tag}"

cd "${repodir}"/lrgasp-challenge-3_full_data/public_ref/

mkdir busco_data && cd busco_data && mkdir lineages && cd lineages

# download the file from https://busco-data.ezlab.org/v5/data/lineages/eutheria_odb10.2021-02-19.tar.gz to ${repodir}/public_ref/
wget https://busco-data.ezlab.org/v5/data/lineages/eutheria_odb10.2021-02-19.tar.gz
# extract the tar.gz file to ${repodir}/public_ref/busco_data/lineages/eutheria_odb10.2021-02-19
tar -xvzf eutheria_odb10.2021-02-19.tar.gz
# remove the tar.gz file
rm eutheria_odb10.2021-02-19.tar.gz

cd .. && cd ..
# download https://lrgasp.s3.amazonaws.com/lrgasp_grcm39_sirvs.fasta using wget
wget https://lrgasp.s3.amazonaws.com/lrgasp_grcm39_sirvs.fasta

cd "${repodir}" 
# Then, remove remnants of previous materialization
rm -rf "${datasetsdir}"
# And last, move the data directory
mv lrgasp-challenge-3_full_data "${datasetsdir}"

