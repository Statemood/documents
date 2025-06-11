#! /bin/bash 

test -f ./config.sh && . ./config.sh || exit 1

test -d $etcd_sign_ssl_dir || mkdir -p $etcd_sign_ssl_dir
cd $etcd_sign_ssl_dir

msg ETCD "Gen Certs"
cat << ECAEOF > etcd-ca.cnf
[ req ]
req_extensions     = v3_req
distinguished_name = req_distinguished_name

[req_distinguished_name]

[ v3_req ]
keyUsage           = critical, keyCertSign, digitalSignature, keyEncipherment
basicConstraints   = critical, CA:true
ECAEOF

n=0
cat << ECSEOF > etcd-server.cnf
[ req ]
req_extensions      = v3_req
distinguished_name  = req_distinguished_name
[req_distinguished_name]
[ v3_req ]
basicConstraints    = CA:FALSE
extendedKeyUsage    = clientAuth, serverAuth
keyUsage            = nonRepudiation, digitalSignature, keyEncipherment
subjectAltName      = @alt_names
[alt_names]
`for k in ${!etcd_server[@]}; do echo IP.$((n++)) = ${etcd_server[$k]}; done`
ECSEOF

n=0
cat << ECPEOF > etcd-peer.cnf
[ req ]
req_extensions     = v3_req
distinguished_name = req_distinguished_name

[req_distinguished_name]

[ v3_req ]
extendedKeyUsage   = clientAuth, serverAuth
keyUsage           = critical, digitalSignature, keyEncipherment
subjectAltName     = @alt_names

[alt_names]
`for k in ${!etcd_server[@]}; do echo IP.$((n++)) = ${etcd_server[$k]}; done`
ECPEOF

n=0
cat << ECCEOF > etcd-client.cnf
[ req ]
req_extensions     = v3_req
distinguished_name = req_distinguished_name

[req_distinguished_name]

[ v3_req ]
extendedKeyUsage   = clientAuth
keyUsage           = critical, digitalSignature, keyEncipherment
subjectAltName     = @alt_names

[alt_names]
`for k in ${!etcd_server[@]}; do echo IP.$((n++)) = ${etcd_server[$k]}; done`
`test -z "$etcd_client" || for k in ${!etcd_client[@]}; do echo IP.$((n++)) = ${etcd_client[$k]}; done`
ECCEOF

openssl genrsa -out etcd-ca.key $etcd_ssl_size
openssl req -x509 -new -nodes -key etcd-ca.key -days $etcd_ssl_days -out etcd-ca.pem \
        -subj "/C=CN/ST=Shanghai/L=Shanghai/O=k8s/CN=etcd-ca" \
        -config etcd-ca.cnf -extensions v3_req

openssl genrsa -out etcd-server.key $etcd_ssl_size

openssl req -new -key etcd-server.key -out etcd-server.csr \
        -subj "/C=CN/ST=Shanghai/L=Shanghai/O=k8s/CN=etcd-server" \
        -config etcd-server.cnf

openssl x509 -req -in etcd-server.csr -CA etcd-ca.pem \
        -CAkey etcd-ca.key -CAcreateserial \
        -out etcd-server.pem -days $etcd_ssl_days \
        -extfile etcd-server.cnf -extensions v3_req

openssl genrsa -out etcd-peer.key $etcd_ssl_size

openssl req -new -key etcd-peer.key -out etcd-peer.csr \
        -subj "/C=CN/ST=Shanghai/L=Shanghai/O=k8s/CN=etcd-peer" \
        -config etcd-peer.cnf

openssl x509 -req -in etcd-peer.csr \
        -CA etcd-ca.pem -CAkey etcd-ca.key -CAcreateserial \
        -out etcd-peer.pem -days $etcd_ssl_days \
        -extfile etcd-peer.cnf -extensions v3_req

openssl genrsa -out etcd-client.key $etcd_ssl_size

openssl req -new -key etcd-client.key -out etcd-client.csr \
        -subj "/C=CN/ST=Shanghai/L=Shanghai/O=system:masters/CN=etcd-client" \
        -config etcd-client.cnf

openssl x509 -req -in etcd-client.csr \
        -CA etcd-ca.pem -CAkey etcd-ca.key -CAcreateserial \
        -out etcd-client.pem -days $etcd_ssl_days \
        -extfile etcd-client.cnf -extensions v3_req

for k in ${!etcd_server[@]}
do
    i=${etcd_server[$k]}
    msg ETCD "Send certificates to server $i"
    pki=/etc/etcd/pki
    ssh $i "mkdir -m 755 -p $pki"
    scp etcd-*.pem etcd-*.key $i:$pki
    ssh $i "chcon -R -u system_u -t cert_t $pki"

    ssh $i "mkdir -m 700 -p $etcd_data_dir"
    ssh $i "chcon -u system_u -t var_lib_t $etcd_data_dir"

    for b in etcd etcdctl etcdutl
    do 
        f=/usr/bin/$b 
        ssh $i "curl -o $f $etcd_downurl/$b"
        ssh $i "chcon -u system_u -t bin_t $f"
        ssh $i "chmod 755 $f"
    done

    msg ETCD "Send unit file to $i"
    suf=/usr/lib/systemd/system/etcd.service
    ssh $i "curl -o $suf $etcd_downurl/etcd.service"
    ssh $i "chcon -u system_u -t systemd_unit_file_t $suf"
    ssh $i "chmod 644 $suf"

    msg ETCD "Set firewall $i"
    ssh $i "firewall-cmd --zone=public --add-port=2379-2380/tcp --permanent"
    ssh $i "firewall-cmd --reload"

cat << EEOF > etcd.conf.$i
[member]
ETCD_NAME=$k
ETCD_DATA_DIR="$etcd_data_dir"
ETCD_LISTEN_PEER_URLS="https://$i:2380"
ETCD_LISTEN_CLIENT_URLS="https://$i:2379"
[cluster]
ETCD_INITIAL_ADVERTISE_PEER_URLS="https://$i:2380"
ETCD_INITIAL_CLUSTER="$etcd_cluster"
ETCD_INITIAL_CLUSTER_STATE="new"
ETCD_INITIAL_CLUSTER_TOKEN="etcd-cluster"
ETCD_ADVERTISE_CLIENT_URLS="https://$i:2379"
[security]
ETCD_CERT_FILE="/etc/etcd/pki/etcd-server.pem"
ETCD_KEY_FILE="/etc/etcd/pki/etcd-server.key"
ETCD_CLIENT_CERT_AUTH="true"
ETCD_TRUSTED_CA_FILE="/etc/etcd/pki/etcd-ca.pem"
ETCD_AUTO_TLS="true"
ETCD_PEER_CERT_FILE="/etc/etcd/pki/etcd-peer.pem"
ETCD_PEER_KEY_FILE="/etc/etcd/pki/etcd-peer.key"
ETCD_PEER_CLIENT_CERT_AUTH="true"
ETCD_PEER_TRUSTED_CA_FILE="/etc/etcd/pki/etcd-ca.pem"
ETCD_PEER_AUTO_TLS="true"
EEOF

    f=/etc/etcd/etcd.conf
    scp etcd.conf.$i $i:$f
    ssh $i "chcon -u system_u -t etc_t $f"
done

for k in ${!k8s_master[@]}
do
    i="${k8s_master[$k]}"

    msg ETCD "Send etcd client cert to $k"
    ssh $i "mkdir -p "
    scp 