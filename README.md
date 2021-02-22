**DNSCrypt-GUI** - GUI for managing the dnscrypt-proxy server

Dependencies: `dnscrypt-proxy`

`dnscrypt-proxy` encrypts the communication channel between you and the DNS server. Encryption of DNS traffic will protect you from man-in-the-middle (MITM) attacks, in which an attacker is wedged into the communication channel. Now the provider will not be able to freely read and log the history of your work on the Internet.

The `DNSCrypt-GUI` settings are optimal by default. It remains to start the local proxy server with the `Start` button and set its address in the DNS settings of the network card (by default, 127.0.0.2). If the server is up, it is automatically put into auto-upload. Green indicator - the server is running, yellow - waiting/problem. The "Stop" button stops the server and disables its autoloading.

Used servers with DNSCrypt support without logging (except google): https://dnscrypt.info/public-servers/

Cloudflare `Resolver` (default) is recommended as the fastest. `Fallback` is a DNS server for emergency name resolution. `Server IP` = 127.0.0.2 is selected because the port on 127.0.0.1 may be occupied by another service.

Testing was carried out by the WireShark network analyzer and showed high encryption efficiency. Without encryption with the `dns` filter, visited sites are easily and clearly tracked. With encryption enabled, this type of traffic disappears and turns into a chaotic stream of characters. Such encryption does not affect the performance in any way, but it has a positive effect on security.

Made and tested in Mageia Linux-8.
