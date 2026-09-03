# Packaging decisions

Non-obvious choices made while packaging Mangatsu, and why.

1. **No systemd service, no runtime Node process.** Mangatsu is a pure
   client-side SPA (Nostr relays and Blossom servers are talked to
   directly from the browser). NGINX serves `$install_dir/dist` as static
   files; Node/npm are only used at build time (install/upgrade/change_url).

2. **Subpath install requires baking the path into the JS bundle, so
   `change_url` rebuilds instead of just regenerating NGINX.** Upstream
   (as of commit `99593e7`, "feat: support deploying under a URL
   subpath") reads the base path once, at build time, via
   `import.meta.env.BASE_URL` — it drives React Router's `basename`, the
   service worker's registration scope, and the shareable comic URL. A
   typical static-SPA `change_url` only needs a new NGINX vhost; this one
   also has to rerun `npm run build` with the new `VITE_BASE_PATH` (see
   `scripts/_common.sh`'s `build_mangatsu`/`mangatsu_base_path`), or the
   app would keep routing/registering its service worker against the old
   path after a domain or path change.

3. **`node_modules` is deleted after every build.** Nothing runs the app
   through Node at runtime, so keeping ~600M of build-time dependencies
   around after `npm run build` finishes would just waste disk. `disk =
   "700M"` in the manifest sizes for the build-time peak, not the ~15M
   steady-state footprint of `dist/` alone.

4. **Backup/restore cover `$install_dir/dist` only.** `install`/`upgrade`/
   `change_url` always re-fetch the full source from the pinned release
   tarball and rebuild from scratch, so backing up the source tree,
   `package.json`, or `node_modules` would be redundant. This matches
   `resources.sources.main` being the single source of truth for the app
   code — see also [armada_ynh](https://github.com/YunoHost-Apps/armada_ynh),
   which uses the same pattern for its own static Vite SPA.

5. **`init_main_permission` defaults to `visitors` (public).** Mangatsu's
   sign-in is Nostr-based and independent of YunoHost/LDAP accounts — the
   feed and library aren't meaningfully usable behind an SSO gate that has
   nothing to do with the app's own auth. `ldap = false` / `sso = false`
   in `[integration]` reflect the same thing.

6. **Pinned to the `v0.1.0` tag, not a floating commit.** Until this
   package was prepared, upstream had no releases at all (`version:
   0.0.0`, `master`-only). `v0.1.0` was tagged specifically so this
   package (and its `autoupdate.strategy = "latest_github_tag"`) has a
   real, addressable release to track instead of an arbitrary commit SHA.

7. **No install-time relay/Blossom-server configuration.** Default relays
   and Blossom servers are hardcoded source-level constants upstream
   (`src/stores/relayStore.ts`, `src/stores/blossomStore.ts`), not exposed
   through `VITE_*` env vars the way e.g. Armada exposes
   `VITE_APP_RELAYS`. Surfacing them as install questions would need an
   upstream change first; for now, readers/publishers set their relays and
   Blossom servers post-install via the in-app Settings screen (synced to
   their Nostr profile, kind `10002`/`10063`), which upstream already
   supports well.
