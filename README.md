# k8sup

Using One Docker container to bootstrap a HA Kubernetes cluster with auto service discovery.

Default behavior: If only one cluster is discovered, auto join it. If more than one cluster are discovered, start a new cluster.

You still can join a specified cluster or force to start a new cluster.

<pre>
Options:
-n, --network=NETINFO        SubnetID/Mask or Host IP address or NIC name
                             e. g. "192.168.11.0/24" or "192.168.11.1"
                             or "eth0" (Required option)
-c, --cluster=CLUSTER_ID     Join a specified cluster
    --new                    Force to start a new cluster
    --worker                 Force to run as k8s worker and etcd proxy
-h, --help                   This help text
</pre>

Build k8s:
<pre>
$ docker build -t develop/k8sup:k8s-1.5 .
</pre>

Run k8s:
<pre>
$ sudo docker run -d \
    --privileged \
    --net=host \
    --pid=host \
    --restart=always \
    -v $(which docker):/bin/docker:ro \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v /usr/lib/:/host/lib:ro \
    -v /usr/sbin:/usr/sbin:ro \
    -v /opt/bin:/opt/bin:ro \
    -v /lib/modules:/lib/modules:ro \
    -v /var/lib/kubelet:/var/lib/kubelet \
    -v /etc/kubernetes:/etc/kubernetes \
    -v var-cni:/var/lib/cni \
    -v etc-cni:/etc/cni \
    -v etcd:/var/lib/etcd \
    --name=k8sup \
    develop/k8sup:k8s-1.5 \
    --cluster={cluster-id} \
    --network={your-subnet-id/mask}
</pre>

Stop k8s:
<pre>
$ sudo docker exec k8sup /go/kube-down
</pre>

Show k8sup log and Cluster ID:
<pre>
$ sudo docker logs k8sup
</pre>

If you want to delete etcd data:
<pre>
$ sudo rm -rf /var/lib/etcd/*
</pre>

NOTE: If you want to use Ceph RBD mounting with k8sup, make sure that the rbd, modprobe command binary files and the rbd.ko kernel object file are mounted to the k8sup container as volume.
