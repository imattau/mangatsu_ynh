#!/bin/bash

# Compute the Vite base path that gets baked into the built JS bundle at
# build time: React Router's `basename`, the service worker's registration
# scope, and the shareable comic URL all read `import.meta.env.BASE_URL`,
# which Vite derives from this at build time (see upstream commit 99593e7,
# "feat: support deploying under a URL subpath"). Always has a trailing
# slash; "/" itself for a root install.
mangatsu_base_path() {
	if [ "${path:-/}" = "/" ]; then
		printf '/'
	else
		printf '%s/' "${path%/}"
	fi
}

# Because the base path is baked into the JS bundle rather than resolved at
# runtime, a change_url (new domain/path) needs a full rebuild, not just a
# regenerated NGINX vhost — see build_mangatsu's caller in scripts/change_url.
build_mangatsu() {
	pushd "$install_dir" >/dev/null
	npm ci --no-audit --no-fund
	VITE_BASE_PATH="$(mangatsu_base_path)" npm run build
	# Mangatsu is a pure client-side SPA: nothing runs the built app through
	# Node at runtime, only NGINX serving static files from dist/. Drop
	# node_modules once the build is done to keep the on-disk footprint at
	# roughly the size of dist/ instead of ~600M of build-time dependencies.
	ynh_safe_rm "$install_dir/node_modules"
	popd >/dev/null
	chown -R www-data: "$install_dir"
}
