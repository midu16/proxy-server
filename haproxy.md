# Configure a reverse proxy to facilitate the conectivity between an ipv4 source to an ipv6 cluster

## Need
We have a host configured with ipv4 interfaces and we need to connect to another host configured with IPv6 interfaces.


## Solution
Implement a haproxy solution, deploying the haproxy as a pod.

The proxy will be hearing at some ports and depending in our configuration, it will redirect the received traffic from **IPv4** to the desired **IPv6** configured hosts.


## Configuration file
* To provide the proxy we need to include some configuration at the **haproxy.cfg** configuration file.
* By default the file will be placed at this path:
```/etc/haproxy/haproxy.cfg```

### Usage
#### global
This section defines global parameters that will apply to the whole configuration.
```
global
    log 127.0.0.1 local0 
    chroot      /var/lib/haproxy
    pidfile     /var/run/haproxy.pid
    maxconn     4000
    user        haproxy
    group       haproxy
    daemon
    stats socket /var/lib/haproxy/stats
    ssl-default-bind-ciphers PROFILE=SYSTEM
    ssl-default-server-ciphers PROFILE=SYSTEM
```

#### defaults
This section defines default values set for some parameters.

Copy like this, nothing needs to be modified.
```
defaults
    log                     global
    option                  httplog
    option                  dontlognull
    option http-server-close
    option forwardfor       except 127.0.0.0/8
    option                  redispatch
    retries                 3
    timeout http-request    10s
    timeout queue           1m
    timeout connect         10s
    timeout client          1m
    timeout server          1m
    timeout http-keep-alive 10s
    timeout check           10s
    maxconn                 3000
```

#### frontend (stats)
This section defines relevant parameters:
* proxy will be hearing at port **50.000** for **IPv4** traffic.
* stats dashboard will be available on **/stats**.
* user/password to grant access.
```
frontend stats 
    bind *:50000
    stats enable
    stats uri /stats
    stats auth admin:password
    stats refresh 10s
    mode http
```

#### frontend
You will need to repeat this section, for each individual port: **80** (http), **443** (https), **6443** (ocp).

This section defines relevant parameters for the OCP requests:
* proxy will be hearing at port **6443** for **IPv4** traffic.
* requests to **cluster-name** (ocp-disconnected.fede.ipv6.lab) will be redirected to what is **is_cluster0** label.
* **cluster0-6443** will be linked with **is_cluster0** label.
```
frontend main6443
    bind *:6443
    mode tcp
    tcp-request inspect-delay 3s
    tcp-request content capture req.ssl_sni len 100
    log-format "capture0: %[capture.req.hdr(0)]"
    acl is_cluster0 req.ssl_sni -m reg ocp-disconnected.fede.ipv6.lab
    use_backend cluster0-6443 if is_cluster0
    default_backend cluster0-6443
```

#### backend
You will need to repeat this section, for each individual port: **80** (http), **443** (https), **6443** (ocp).

This section includes the hosts that will receive the requests forwarded to port **6443**.

* **balance:** source --> means that if one client request was forwarded to cluster0-master0, next request from the same client will be forwarded again to the same host until is unavailable.
* **mode**: tcp --> can be tcp or http.
* Include one **server** line for every host included in the cluster.
```
backend cluster0-6443
    balance source
    mode tcp
    server cluster0-master0 2620:52:0:1305::100:6443 check sni req.ssl_sni
    server cluster0-master1 2620:52:0:1305::101:6443 check sni req.ssl_sni
    server cluster0-master2 2620:52:0:1305::102:6443 check sni req.ssl_sni
```


## Create the haproxy pod
This will deploy one container named **haproxy** that will be our reverse proxy.

* Run this command:
```
podman run -d --name haproxy --rm --network host -v /etc/haproxy/haproxy.cfg:/usr/local/etc/haproxy/haproxy.cfg:z docker.io/library/haproxy:2.3
```

* The deployed container will be like this:
![alt text](https://github.com/feferran/proxy-server/blob/main/haproxy-container.png "haproxy container")


## haproxy dashboard
Haproxy service has a web interface where you can connect to get the traffic stats/data received by the host, available here:
[http://\<ip-address>\:50000/stats](http://<ip-address>:50000/stats)

* The interface look like this:
![alt text](https://github.com/feferran/proxy-server/blob/main/haproxy-dashboard.png "haproxy dashboard")
