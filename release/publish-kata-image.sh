#!/bin/bash
#Copyright (c) 2018 Intel Corporation
#
#SPDX-License-Identifier: Apache-2.0
#

[ -z "${DEBUG}" ] || set -x

set -o errexit
set -o nounset
set -o pipefail

workdir="${PWD}"

readonly script_name="$(basename "${BASH_SOURCE[0]}")"
readonly script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly project="kata-containers"
GOPATH=${GOPATH:-${HOME}/go}

die() {
	msg="$*"
	echo "ERROR: ${FUNCNAME[1]} ${msg}" >&2
	exit 1
}

usage() {
	return_code=${1:-0}
	cat <<EOT
Usage:

${script_name} [options]  <version>

version: Kata version to create the image.

Create image for a kata version.

options:

-h      : show this help
-p      : push image to github
EOT

	exit "${return_code}"
}

main() {
	push="false"
	while getopts "d:hp" opt; do
		case $opt in
		h) usage 0 ;;
		p) push="true" ;;
		esac
	done

	shift $((OPTIND - 1))
	kata_version=${1:-}
	[ -n "${kata_version}" ] || usage "1"

	image_tarball=$(find -name 'kata-containers-*.tar.gz' | grep "${kata_version}") ||
		"${script_dir}/../obs-packaging/kata-containers-image/build_image.sh" -v "${kata_version}"
	image_tarball=$(find -name 'kata-containers-*.tar.gz' | grep "${kata_version}") || die "file not found ${image_tarball}"

	if [ ${push} == "true" ]; then
		hub -C "${GOPATH}/src/github.com/${project}/agent" release edit -a "${image_tarball}" "${kata_version}"
	else
		echo "Wont push image to github use -p option to do it."
	fi
}

main $@
