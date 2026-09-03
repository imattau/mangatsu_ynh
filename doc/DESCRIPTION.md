# Mangatsu for YunoHost

Mangatsu is a comic and manga reader/publisher for the Nostr network.
Comics and chapters are published as Nostr events, image assets are stored
on Blossom servers, and a reader's saved library, Blossom server list, and
reading progress are synced across devices through their own Nostr account.

This YunoHost package builds and serves the static Vite/React web client
only. It does not install a Nostr relay or a Blossom server — Mangatsu
talks to relays and Blossom servers configured in the app's own Settings
screen (sensible public defaults are compiled in; there is no install-time
override for them yet).

Sign-in is Nostr-based (browser extension/NIP-07, pasted `nsec`, or
bunker/NIP-46), entirely independent of YunoHost accounts and LDAP.
Uploads (CBZ/PDF, converted to WebP) happen client-side in the browser; the
server never sees comic content beyond serving the static app shell.
