![](https://github.com/dta4/d2nsdist/workflows/Dockerization/badge.svg)

## d2nsdist- dockerized DNS forwarder and loadbalancer

**A docker image to run dnsdist.**

> dnsdist website : [dnsdist.org][0]

### Motivation and use case

We had to deal with dockerization and running mostly [WSL][1] and [Docker Desktop CE][2] for development. This works very smooth and we really love it, but it becomes a pain, if you had to deal with different hidden DNS resolvers on your laptop, that are only accessible via VPN or special LAN connections.
Even if your VPN client creates the right [NRTP][3] entries on your host, that are not populated to your WSL console or to your docker daemon. Dynamic DNS resolver adaption is a long running, unsolved issue for WSL and Docker Desktop. Maybe it's addressed in the future by [WSL 2][4] or the [Moby][5] project.
In the meantime we like to use a dockerized DNS proxy running on the host as a workaround. It's configurable during runtime and solves our WSL issues at least. [dnsdist][6] is the Swiss army knife for such use cases.
But of course we like to provide this image for any other [dnsdist][0] related use case.

[0]: https://dnsdist.org
[1]: https://docs.microsoft.com/windows/wsl/
[2]: https://www.docker.com/products/docker-desktop
[3]: https://docs.microsoft.com/powershell/module/dnsclient/get-dnsclientnrptpolicy?view=win10-ps
[4]: https://engineering.docker.com/2019/06/docker-hearts-wsl-2/
[5]: https://mobyproject.org/
[6]: https://ds9a.nl/tmp/dnsdist-md/dnsdist-diagrams.md.html

### Build 'n' Run

It's available via [Dockerhub][7].

Build and run as usual:
```bash
# docker build --tag=d2nsdist .
docker run -p 53:53/udp -p 53:53/tcp -p 5199:5199 -p 8053:8053 \
           -d --restart=unless-stopped --name d2nsdist d2nsdist
docker container stop d2nsdist
```

[7]: https://hub.docker.com/r/dta4/d2nsdist

### Usage

<details>
<summary>pick console key from <code>d2nsdist</code> docker log</summary>

```bash
[~] >>docker logs d2nsdist
Running: /usr/bin/dnsdist --disable-syslog --supervised

Set console key: setKey("CaQ/vT2fLIf2TMqRwbMwbeGGs++5nc61V+BAWAZ4MJ8=")

Added downstream server 8.8.4.4:53
Added downstream server 8.8.8.8:53
Listening on 0.0.0.0:53
...
```

<details>
<summary>always restart <code>d2nsdist</code> with explicit console key</summary>

```bash
docker container stop d2nsdist
docker run -p 53:53/udp -p 53:53/tcp -p 5199:5199 -p 8053:8053 \
           -e CONSOLE_KEY='CaQ/vT2fLIf2TMqRwbMwbeGGs++5nc61V+BAWAZ4MJ8=' \
           -d --restart=always --name d2nsdist d2nsdist
```
</details>

<details>
<summary>install local <code>dnsdist</code> client</summary>

```bash
sudo apt-get install -y dnsdist
```
</details>

<details>
<summary>setup <code>/etc/dnsdist/dnsdist.conf</code></summary>

```
controlSocket("127.0.0.1")
setKey("CaQ/vT2fLIf2TMqRwbMwbeGGs++5nc61V+BAWAZ4MJ8=")
```

<details>
<summary>point your <code>/etc/resolv.conf</code> to <code>d2nsdist</code></summary>

```
# removed symlink to /run/resolvconf/resolv.conf
#
options timeout:2 attempts:2 single-request
nameserver 127.0.0.1
nameserver 8.8.4.4
nameserver 8.8.8.8
```
</details>

From now on you can access...

```bash
# dnsdist console via local client
dnsdist -c
dnsdist -c -e 'showServers()'

# dnsdist console via container client
docker exec -it d2nsdist dnsdist -c
docker exec -it d2nsdist dnsdist -c -e 'showRules()'

# dnsdist API
curl -sS -H 'X-API-Key: token' http://127.0.0.1:8053/api/v1/servers/localhost | jq '.rules[]'
```

**Enjoy!** Point your browser at [http://127.0.0.1:8083](http://127.0.0.1:8083) and log in with any username, and the default `password`.

### Configuration

| environment | default |
| --- | --- |
| CONSOLE_KEY | |
| CONSOLE_ACL | "172.16.0.0/12" "127.0.0.1/8" "::1/128" |
| WEB_PASSWORD | `password` |
| WEB_APITOKEN | `token` |

### Dependencies

We are using:
* [Alpine][10] as container OS
* Alpine [dnsdist][11] packages
* [Tini][12] as explicit `init` for containers instead of `--init`
* [mo][14] as [mustache][13] template engine

[10]: https://alpinelinux.org/
[11]: https://pkgs.alpinelinux.org/package/edge/community/x86_64/dnsdist
[12]: https://github.com/krallin/tini
[13]: https://mustache.github.io/
[14]: https://github.com/tests-always-included/mo

### License

[Apache License Version 2.0](LICENSE)

### Todo

- [ ] provide a valid console key without `makeKey()`
- [ ] how to feed changing downstream servers to d2nsdist?
```powershell
PowerShell.exe -Command 'Get-DnsClientServerAddress -AddressFamily IPv4'`
```

> Written with [StackEdit](https://stackedit.io/).
