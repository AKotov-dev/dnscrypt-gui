DNSCrypt-GUI - GUI for managing the dnscrypt-proxy server
--
**Announcement:** Starting with `dnscrypt-proxy-v1.1` - switching to self-contained RPM/DEB packages. If `dnscrypt-proxy` is currently installed `from the repository`, remove it to avoid conflicts! On Ubuntu-like systems, port 53 may be in use. Either change the dnscrypt-proxy port or finally throw out systemd-resolved.

RPM dependencies: systemd libcap-utils gtk2  
DEB dependencies: systemd libcap2-bin libgtk2.0-0

+ /opt/dnscrypt-gui - dnscrypt-gui directory + sources
+ /etc/systemd/user/dnscrypt-proxy.service - startup service
+ ~/.conf/dnscrypt-gui/dnscrypt-gui.conf - dnscrypt-gui configuration
+ ~/.conf/dnscrypt-gui/dnscrypt-proxy.toml - dnscrypt-proxy configuration
+ ~/.conf/dnscrypt-gui/{public-resolvers.md.minisig, public-resolvers.md} - up-to-date resolver list and signature

![](https://github.com/AKotov-dev/dnscrypt-gui/blob/main/ScreenShot2.png)

**Motivation for the switch self-contained RPM/DEB packages**
----
On different Linux systems, `dnscrypt-proxy` packages are built with different startup services: Fedora has one, LUbuntu-22.04 has two (including a socket, which needs to be disabled before stopping dnscryp-proxy and generally monitored), and LUbuntu-25.04 has three services (I haven't specified the purpose of the third, as using this useful tool with two services is quite problematic). Accordingly, the decision was made to throw out everything unnecessary and build everything necessary, including the GUI.

Now the dnscrypt-proxy package is no longer needed in the system (if installed, remove it immediately, it will only ruin everything), nor are root privileges required to run the service. Just a lightweight GUI, the latest version of dnscryp-proxy from the developer's GitHub, and, of course, security.

**Note: If dnscrypt-proxy is currently installed from the repository, remove it to avoid conflicts! On Ubuntu-like systems, port 53 may be in use. Either change the dnscrypt-proxy port or finally throw out systemd-resolved.**

Description
----
`dnscrypt-proxy` encrypts the communication channel between you and the DNS server. Encryption of DNS traffic will protect you from man-in-the-middle (MITM) attacks, in which an attacker is wedged into the communication channel. Now the provider will not be able to freely read and log the history of your work on the Internet.

The `DNSCrypt-GUI` settings are optimal by default. It remains to start the local proxy server with the `Restart` button and set its address in the DNS settings of the network card (by default, 127.0.0.1). If the server is up, it is automatically put into auto-upload. `Green` indicator - the server is running, `Yellow` - waiting/problem. The `Stop` button stops the server and disables its autoloading.

Starting with `v1.0` it is possible to check the system for DNS leaks (blue `Resolvers:` link next to the list of DNS servers). If the system uses a global proxy (for example `xray-core` or another), then with the browser already open, the site will most likely show information about DNS wrapped in a proxy. To see the clean result - just close the browser and click the `Resolvers:` link. In this case, it should pick up your local dns (127.0.0.1) from the `/etc/resolv.conf` file, if the network connection is configured correctly. In any case, you will receive valuable information for your security.

Testing was carried out by the `WireShark` network analyzer and showed high encryption efficiency. Without encryption with the `dns` filter, visited sites are easily and clearly tracked. With encryption enabled, this type of traffic disappears and turns into a chaotic stream of characters. Such encryption does not affect the performance in any way, but it has a positive effect on security.

