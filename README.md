# plexyandyouknowit

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
BGP did not work from the gui, ssh into the UDM SE:

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
To apply the v2alpha CRD (this was all that worked for me)
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
The key to this was that I thought 'Active' meant it was talking but it does not, it needed to say Established before it was actually working.

To check from Cilium side run
```
cilium bgp peers
```

