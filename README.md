# k8sup

Using One Docker container to bootstrap a HA Kubernetes cluster with auto cluster discovery.

Default behavior:
1. If only one cluster is discovered, join it automatically.
2. If more than one cluster are discovered, start a new cluster.

You can specify the same cluster ID (or name) to multiple nodes that it will make them become the same cluster. Conversely, You can also specify a different cluster ID (or name) to start node(s) as another cluster.

```
Options:
-n, --network=NETINFO          SubnetID/Mask or Host IP address or NIC name
                               e. g. "192.168.11.0/24" or "192.168.11.1"
                               or "eth0"
-c, --cluster=CLUSTER_ID       Join a specified cluster
    --k8s-version=VERSION      Specify k8s version (Default: 1.5.8)
    --max-etcd-members=NUM     Maximum etcd member size (Default: 3)
    --restore                  Try to restore etcd data and start a new cluster
    --k8s-insecure-port=PORT   Kube-apiserver insecure port (Default: 8080)
    --worker                   Force to run as k8s worker and etcd proxy
    --debug                    Enable debug mode
-r, --registry=REGISTRY        Registry of docker image
                               (Default: 'quay.io/coreos' and 'gcr.io/google_containers')
-v, --version                  Show k8sup version
-h, --help                     This help text
```

Examples:

Run k8s on CoreOS:
```
$ CLUSTER_ID_OR_NAME="my-cluster"
$ NETADDR="192.168.56.0/24"
$ docker pull cdxvirt/k8sup:latest
$ docker run -d \
    --privileged \
    --net=host \
    --pid=host \
    --restart=always \
    -v /run/torcx/bin/docker:/bin/docker:ro \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v /run/torcx/unpack/docker/lib:/host/lib:ro \
    -v /lib/modules:/lib/modules:ro \
    -v /etc/cni:/etc/cni \
    -v /var/lib/cni:/var/lib/cni \
    -v /var/lib/etcd:/var/lib/etcd \
    -v /var/lib/kubelet:/var/lib/kubelet \
    -v /etc/kubernetes:/etc/kubernetes \
    --name=k8sup \
    cdxvirt/k8sup:latest \
    --cluster="${CLUSTER_ID_OR_NAME}" \
    --network="${NETADDR}"
```

Stop k8s on CoreOS:
```
$ docker run \
    --privileged \
    --net=host \
    --pid=host \
    --rm=true \
    -v /run/torcx/bin/docker:/bin/docker:ro \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v /run/torcx/unpack/docker/lib:/host/lib:ro \
    -v /lib/modules:/lib/modules:ro \
    -v /usr/sbin/modprobe:/usr/sbin/modprobe:ro \
    -v /opt/bin:/opt/bin:rw \
    -v /etc/cni:/etc/cni \
    -v /var/lib/cni:/var/lib/cni \
    -v /var/lib/etcd:/var/lib/etcd \
    -v /var/lib/kubelet:/var/lib/kubelet \
    -v /etc/kubernetes:/etc/kubernetes \
    --entrypoint=/go/kube-down \
    cdxvirt/k8sup:latest
```

Remove k8s from node on CoreOS:
```
$ docker run \
    --privileged \
    --net=host \
    --pid=host \
    --rm=true \
    -v /run/torcx/bin/docker:/bin/docker:ro \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v /run/torcx/unpack/docker/lib:/host/lib:ro \
    -v /lib/modules:/lib/modules:ro \
    -v /usr/sbin/modprobe:/usr/sbin/modprobe:ro \
    -v /opt/bin:/opt/bin:rw \
    -v /etc/cni:/etc/cni \
    -v /var/lib/cni:/var/lib/cni \
    -v /var/lib/etcd:/var/lib/etcd \
    -v /var/lib/kubelet:/var/lib/kubelet \
    -v /etc/kubernetes:/etc/kubernetes \
    --entrypoint=/go/kube-down \
    cdxvirt/k8sup:latest \
    --remove
```

Show k8sup log and Cluster ID:
```
$ docker logs k8sup
```

If you want to delete etcd data:
```
$ sudo rm -rf /var/lib/etcd/*
```

To access the dashboard:
```
Browse https://<your-master-node-ip>:6443/ui
user:     admin
password: admin
```

NOTE:

1. If you want to use Ceph RBD mapping with k8sup, make sure that the 'rbd.ko' kernel object file, the 'modprobe' command file, and either the 'rbd' command file or the host path '/opt/bin' are mounted to the k8sup container as volumes.

2. k8sup ships with a default ntp service to synchronize system time of whole cluster. If a node is running other NTP client already, k8sup will not synchronize system time for this node, so you need to ensure all cluster nodes have the same system time by yourself.

3. Running k8sup on Ubuntu 16.04.2 <br /> https://gist.github.com/hsfeng/7fa5b57b68a62d7f14f3a10fc7db46cf <br />
