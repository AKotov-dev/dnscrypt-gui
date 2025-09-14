DNSCrypt-GUI - GUI for managing the dnscrypt-proxy server
--

**Dependencies:** gtk2, dnscrypt-proxy >= 2.1.0, polkit, systemd

`dnscrypt-proxy` encrypts the communication channel between you and the DNS server. Encryption of DNS traffic will protect you from man-in-the-middle (MITM) attacks, in which an attacker is wedged into the communication channel. Now the provider will not be able to freely read and log the history of your work on the Internet.

The `DNSCrypt-GUI` settings are optimal by default. It remains to start the local proxy server with the `Start` button and set its address in the DNS settings of the network card (by default, 127.0.0.1). If the server is up, it is automatically put into auto-upload. Green indicator - the server is running, yellow - waiting/problem. The `Stop` button stops the server and disables its autoloading.

Used servers with DNSCrypt support without logging (except google): https://dnscrypt.info/public-servers/

Starting with `v1.0` it is possible to check the system for DNS leaks (blue `Resolvers:` link next to the list of DNS servers). If the system uses a global proxy (for example `xray-core` or another), then with the browser already open, the site will most likely show information about DNS wrapped in a proxy. To see the clean result - just close the browser and click the `Resolvers:` link. In this case, it should pick up your local dns (127.0.0.1) from the `/etc/resolv.conf` file, if the network connection is configured correctly. In any case, you will receive valuable information for your security.

![](https://github.com/AKotov-dev/dnscrypt-gui/blob/main/ScreenShot2.png)

Testing was carried out by the `WireShark` network analyzer and showed high encryption efficiency. Without encryption with the `dns` filter, visited sites are easily and clearly tracked. With encryption enabled, this type of traffic disappears and turns into a chaotic stream of characters. Such encryption does not affect the performance in any way, but it has a positive effect on security.

Made and tested in Mageia Linux.
