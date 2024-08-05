## for cosign: cosign must be installed, COSIGN_PASSWORD and COSIGN_KEY_PATH must be set
## for trivy:  trivy must be installed

# build_image
#   1. full image name:            ghcr.io/joshgav/podtato-head/entry
#   2. full tag:                   latest-distroless
#   3. part name or empty string:  body
#   4. context dir:                /home/joshgav/src/projects/podtato-head/podtato-head-microservices
#   5. path to file:               cmd/entry/Dockerfile
#   6. base run image:             gcr.io/distroless/static:latest
#   7. ghcr username:              joshgav
#   8. push too:                   true

function build_image() {
	local image_name=${1}
	local image_tag=${2:-latest}
	# if set adds build arg PART=${part_name}
	local part_name=${3}
	local context_dir=${4}
	local relative_path_to_dockerfile=${5}
	# base for last stage of multistage build
	local base_run_image=${6:-scratch}
	# used to set image label setting owner; required by ghcr
	local registry_user=${7}
	local push_too=${8}

	if [[ -n "${PUSH_TO_REGISTRY}" ]]; then
		push_too=true
	fi

	if [[ -n "${GITHUB_USER}" && -z "${registry_user}" ]]; then
		echo "INFO: assigning var GITHUB_USER as registry user for ghcr"
		registry_user=${GITHUB_USER}
	fi

	if [[ -z "${registry_user}" ]]; then
		echo "INFO: defaulting registry user for ghcr to \"podtato-head\""
		registry_user=podtato-head
	fi

	echo "INFO: building image ${image_name}:${image_tag}"
	echo "INFO: with context dir ${context_dir}; Dockerfile ${relative_path_to_dockerfile}"

	docker buildx build \
		--tag "${image_name}:${image_tag}" \
		--build-arg "GITHUB_USER=${registry_user}" \
		--build-arg "BASE_RUN_IMAGE=${base_run_image}" \
		${part_name:+--build-arg "PART=${part_name}"} \
		--file "${context_dir}/${relative_path_to_dockerfile}" \
		--platform "linux/amd64,linux/arm64" \
		${context_dir}
	result=$?

	if [[ -n "${push_too}" && ("${push_too}" != "false") ]]; then
		echo "INFO: pushing image ${image_name}:${image_tag}"
		docker push "${image_name}:${image_tag}"
	fi

	sign_images=$(if type -P cosign >/dev/null; then echo 1; else echo 0; fi)
	if [[ ${sign_images} == 1 && -n "${COSIGN_PASSWORD}" && -n "${COSIGN_KEY_PATH}" ]]; then
		echo "INFO: signing ${image_name}:${image_tag} using cosign version" \
			$(cosign version --json | jq -r '.GitVersion')
		cosign sign --key "${COSIGN_KEY_PATH}" \
			--annotations version=${image_tag} \
			"${image_name}:${image_tag}"
	fi

	scan_images=$(if type -P trivy >/dev/null; then echo 1; else echo 0; fi)
	if [[ ${scan_images} == 1 ]]; then
		echo "INFO: scanning ${image_name} using trivy version" \
			$(trivy --version | head -1 | sed -E 's/^Version: (.*)$/\1/')
		trivy image \
			--format table \
			--severity "HIGH,CRITICAL" \
			--no-progress \
			${image_name}
	fi
}
