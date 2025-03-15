# 

Fix permission issue I had with kubectl:

```
sudo chown -R $USER:$USER /etc/rancher/k3s/k3s.yaml
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
echo 'export KUBECONFIG=/etc/rancher/k3s/k3s.yaml' >> ~/.bashrc
source ~/.bashrc
```

Fix for Cilium looking at 10. address for the API:
```
API_SERVER_IP=<IP>
API_SERVER_PORT=6443
cilium install \
  --set k8sServiceHost=${API_SERVER_IP} \
  --set k8sServicePort=${API_SERVER_PORT} \
  --set kubeProxyReplacement=true
```
BGP did not work from the gui, needed to ssh into the UDM SE:

```
sed -i 's/bgpd=no/bgpd=yes/g' /etc/frr/daemons
systemctl enable frr.service && service frr start
vi /etc/frr/frr.conf

log file stdout
hostname UDMSE
router bgp 64513
 bgp router-id 192.168.1.1
 bgp bestpath as-path multipath-relax
 no bgp ebgp-requires-policy
 neighbor 192.168.10.21 remote-as 64512
 neighbor 192.168.10.23 remote-as 64512
 neighbor 192.168.10.30 remote-as 64512
 neighbor 192.168.10.31 remote-as 64512
```
To apply the v2alpha CRD (this was all that worked for me):
```
kubectl apply -f https://raw.githubusercontent.com/cilium/cilium/main/pkg/k8s/apis/cilium.io/client/crds/v2alpha1/ciliumbgppeeringpolicies.yaml
```
To test from UDM:
```
vtysh -c "show ip bgp"
```
and
```
vtysh -c "show bgp summary"
```
The key to this was that I thought 'Active' meant it was talking but it does not, it needed to say Established before it was actually working. The issue was sort of bizzare, I originally set localASN: 64512 (K3s) and peerASN: 64513 (UDM SE) correctly in the file. Noticed in the log they both showed 64512, I reapplied the config and still it was wrong, except when I reapplied the config it was actually wrong in the file after. Once I changed it, they were no longer on the same ASN and that was when it ended up finally working.

To check from Cilium side run:
```
cilium bgp peers
```
To apply storage configs:
```
kubectl apply -f persistent-volumes.yaml
kubectl apply -f persistent-volume-claims.yaml
```
This is how it should look:
```
josh@k3s-master1:~/plexyandyouknowit/k3s-manifests/storage$ kubectl get pv
kubectl get pvc
kubectl get storageclass
kubectl describe pvc k3s-scratch-pvc-k3s1
kubectl describe pvc k3s-scratch-pvc-k3s2
kubectl describe pvc k3s-scratch-pvc-k3s3

NAME                  CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM                          STORAGECLASS    VOLUMEATTRIBUTESCLASS   REASON   AGE
k3s-configs-pv        500Gi      RWX            Retain           Bound    default/k3s-configs-pvc                        <unset>                          12m
k3s-data-pv           30Ti       RWX            Retain           Bound    default/k3s-data-pvc                           <unset>                          12m
k3s-scratch-pv-k3s1   100Gi      RWO            Delete           Bound    default/k3s-scratch-pvc-k3s1   local-storage   <unset>                          40s
k3s-scratch-pv-k3s2   100Gi      RWO            Delete           Bound    default/k3s-scratch-pvc-k3s2   local-storage   <unset>                          40s
k3s-scratch-pv-k3s3   100Gi      RWO            Delete           Bound    default/k3s-scratch-pvc-k3s3   local-storage   <unset>                          40s
NAME                   STATUS   VOLUME                CAPACITY   ACCESS MODES   STORAGECLASS    VOLUMEATTRIBUTESCLASS   AGE
k3s-configs-pvc        Bound    k3s-configs-pv        500Gi      RWX                            <unset>                 12m
k3s-data-pvc           Bound    k3s-data-pv           30Ti       RWX                            <unset>                 12m
k3s-scratch-pvc-k3s1   Bound    k3s-scratch-pv-k3s1   100Gi      RWO            local-storage   <unset>                 36s
k3s-scratch-pvc-k3s2   Bound    k3s-scratch-pv-k3s2   100Gi      RWO            local-storage   <unset>                 36s
k3s-scratch-pvc-k3s3   Bound    k3s-scratch-pv-k3s3   100Gi      RWO            local-storage   <unset>                 36s
NAME                   PROVISIONER             RECLAIMPOLICY   VOLUMEBINDINGMODE      ALLOWVOLUMEEXPANSION   AGE
local-path (default)   rancher.io/local-path   Delete          WaitForFirstConsumer   false                  15h
Name:          k3s-scratch-pvc-k3s1
Namespace:     default
StorageClass:  local-storage
Status:        Bound
Volume:        k3s-scratch-pv-k3s1
Labels:        <none>
Annotations:   pv.kubernetes.io/bind-completed: yes
Finalizers:    [kubernetes.io/pvc-protection]
Capacity:      100Gi
Access Modes:  RWO
VolumeMode:    Filesystem
Used By:       <none>
Events:        <none>
Name:          k3s-scratch-pvc-k3s2
Namespace:     default
StorageClass:  local-storage
Status:        Bound
Volume:        k3s-scratch-pv-k3s2
Labels:        <none>
Annotations:   pv.kubernetes.io/bind-completed: yes
Finalizers:    [kubernetes.io/pvc-protection]
Capacity:      100Gi
Access Modes:  RWO
VolumeMode:    Filesystem
Used By:       <none>
Events:        <none>
Name:          k3s-scratch-pvc-k3s3
Namespace:     default
StorageClass:  local-storage
Status:        Bound
Volume:        k3s-scratch-pv-k3s3
Labels:        <none>
Annotations:   pv.kubernetes.io/bind-completed: yes
Finalizers:    [kubernetes.io/pvc-protection]
Capacity:      100Gi
Access Modes:  RWO
VolumeMode:    Filesystem
Used By:       <none>
Events:        <none>
```


