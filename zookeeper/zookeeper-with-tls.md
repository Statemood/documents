

# Zookeeper with TLS



## Certificate

#### Set Variables

```shell
NAME=zookeeper
PASS=confidential
```



#### Create Root CA

```shell
openssl req -new -x509 -days 1825 -keyout ca.key -out ca.pem -nodes \
			-subj "/C=CN/ST=Shanghai/L=Shanghai/O=Services/CN=Services Security Authority"
```



#### Import Root CA to keystore

```shell
keytool -keystore truststore.p12 -deststoretype pkcs12 -storepass $PASS \
		-import -alias ca-root -file ca.pem -noprompt
```



#### Create a new key-pair and certificate for *zookeeper*

```shell
keytool -keystore $NAME.p12 -storepass $PASS -alias $NAME -validity 1825 \
		-genkey -keyalg RSA -keysize 2048 -keypass $PASS -deststoretype pkcs12 \
		-dname "C=CN/ST=Shanghai/L=Shanghai/O=Services/CN=$NAME"
```



#### Generate a certificate-signing-request for that certificate

```shell
keytool -keystore $NAME.p12 -storepass $PASS -alias $NAME -certreq -file $NAME-cert-file
```



#### Sign the request with the key of private CA and also add a SAN-extension, so that the signed certificate is also valid for IP address

```shell
openssl x509 -req -CA ca.pem -CAkey ca.key -in $NAME-cert-file -out $NAME.pem -days 1825 \
		-CAcreateserial -extensions SAN \
		-extfile <(printf "\n[SAN]\nsubjectAltName=DNS:*.zk-svc,IP:10.10.20.151,IP:10.10.20.152,IP:10.10.20.153")
```



#### Import the root-certificate of the private CA into the keystore `zookeeper.jks`

```shell
keytool -keystore $NAME.p12 -deststoretype pkcs12 -storepass $PASS -import -alias ca-root -file ca.pem -noprompt
```



#### Import the signed certificate for `zookeeper` into the keystore `zookeeper.jks`

```shell
keytool -keystore $NAME.p12 -deststoretype pkcs12 -storepass $PASS -import -alias $NAME -file $NAME.pem
```



## Configure And Start ZooKeeper

#### Set `SERVER_JVMFLAGS` in *zkServer.sh*

```shell
export SERVER_JVMFLAGS="
	-Dzookeeper.serverCnxnFactory=org.apache.zookeeper.server.NettyServerCnxnFactory
	-Dzookeeper.ssl.keyStore.location=/opt/zookeeper/conf/zookeeper.p12
	-Dzookeeper.ssl.keyStore.password=confidential
	-Dzookeeper.ssl.trustStore.location=/opt/zookeeper/conf/zookeeper.p12
	-Dzookeeper.ssl.trustStore.password=confidential"
```

- The Java-Environmentvariable **`zookeeper.serverCnxnFactory`** switches the connection-factory to use the Netty-Framework.



#### Set `CLIENT_JVMFLAGS` in *zkCli.sh*

```shell
export CLIENT_JVMFLAGS="
	-Dzookeeper.clientCnxnSocket=org.apache.zookeeper.ClientCnxnSocketNetty
	-Dzookeeper.client.secure=true
	-Dzookeeper.ssl.keyStore.location=/opt/zookeeper/conf/zookeeper.p12
	-Dzookeeper.ssl.keyStore.password=confidential
	-Dzookeeper.ssl.trustStore.location=/opt/zookeeper/conf/truststore.p12
	-Dzookeeper.ssl.trustStore.password=confidential"
```



#### File zoo.cfg

```shell
dataDir=/data/zk
secureClientPort=2182
syncLimit=5
initLimit=10
tickTime=2000
maxClientCnxns=500
standaloneEnabled=false
autopurge.purgeInterval=24
autopurge.snapRetainCount=7
admin.enableServer=false
reconfigEnabled=true

4lw.commands.whitelist=ruok, cons, stat, mntr
metricsProvider.httpPort=7000
metricsProvider.exportJvmInfo=true
metricsProvider.className=org.apache.zookeeper.metrics.prometheus.PrometheusMetricsProvider
authProvider.1=org.apache.zookeeper.server.auth.X509AuthenticationProvider
ssl.quorum.keyStore.location=/opt/zookeeper/conf/zookeeper.p12
ssl.quorum.keyStore.password=confidential
ssl.quorum.trustStore.location=/opt/zookeeper/conf/truststore.p12
ssl.quorum.trustStore.password=confidential
```

- **`secureClientPort`**: We only allow encrypted connections!
  (If we want to allow unencrypted connections too, we can just specify `clientPort` additionally.)
- **`authProvider.1`**: Selects authentification through client certificates
- **`ssl.quorum.keyStore.*`**: Specifies the path to and password of the keystore, with the `zookeeper`-certificate
- **`ssl.quorum.trustStore.*`**: Specifies the path to and password of the common truststore with the root-certificate of our private CA



## Start Zookeeper

```shell
zookeeper/bin/zkServer.sh start
```



## Verification

### Verify in the logs that your ensemble is running on TLS

```
INFO  [main:ServerCnxnFactory@169] - Using org.apache.zookeeper.server.NettyServerCnxnFactory as server connection factory
...
...
INFO  [main:QuorumPeer@1999] - Using TLS encrypted quorum communication
...
...
INFO  [ListenerHandler...:3888:QuorumCnxManager$Listener$ListenerHandler@1127] - Creating TLS-only quorum server socket
```



### Connect to Zookeeper

```shell
./bin/zkCli.sh -server 10.10.20.161:2281
```



#### If OK, you will see the following logs



##### On Client side:

```
2020-06-01 14:43:57,462 [myid:] - INFO  [main:X509Util@77] - Setting -D jdk.tls.rejectClientInitiatedRenegotiation=true to disable client-initiated TLS renegotiation
2020-06-01 14:43:57,572 [myid:] - INFO  [main:ClientCnxnSocket@239] - jute.maxbuffer value is 1048575 Bytes
2020-06-01 14:43:57,578 [myid:] - INFO  [main:ClientCnxn@1703] - zookeeper.request.timeout value is 0. feature enabled=false
Welcome to ZooKeeper!
2020-06-01 14:43:57,584 [myid:10.10.20.161:2281] - INFO  [main-SendThread(10.10.20.161:2281):ClientCnxn$SendThread@1154] - Opening socket connection to server mq-1/10.10.20.161:2281.
2020-06-01 14:43:57,584 [myid:10.10.20.161:2281] - INFO  [main-SendThread(10.10.20.161:2281):ClientCnxn$SendThread@1156] - SASL config status: Will not attempt to authenticate using SASL (unknown error)
JLine support is enabled
[zk: 10.10.20.161:2281(CONNECTING) 0] 2020-06-01 14:43:57,961 [myid:10.10.20.161:2281] - INFO  [nioEventLoopGroup-2-1:ClientCnxnSocketNetty$ZKClientPipelineFactory@454] - SSL handler added for channel: [id: 0x68fd6785]
2020-06-01 14:43:57,966 [myid:10.10.20.161:2281] - INFO  [nioEventLoopGroup-2-1:ClientCnxn$SendThread@986] - Socket connection established, initiating session, client: /10.10.20.161:32640, server: mq-1/10.10.20.161:2281
2020-06-01 14:43:57,967 [myid:10.10.20.161:2281] - INFO  [nioEventLoopGroup-2-1:ClientCnxnSocketNetty$1@184] - channel is connected: [id: 0x68fd6785, L:/10.10.20.161:32640 - R:mq-1/10.10.20.161:2281]
2020-06-01 14:43:58,781 [myid:10.10.20.161:2281] - INFO  [nioEventLoopGroup-2-1:ClientCnxn$SendThread@1420] - Session establishment complete on server mq-1/10.10.20.161:2281, session id = 0xb33bfd10000, negotiated timeout = 30000

WATCHER::

WatchedEvent state:SyncConnected type:None path:null

[zk: 10.10.20.161:2281(CONNECTED) 0]
```



##### On Server side:

```
2020-06-01 14:43:58,739 [myid:0] - INFO  [nioEventLoopGroup-7-1:X509AuthenticationProvider@166] - Authenticated Id 'C=CN/ST\=Shanghai/L\=Shanghai/O\=Services/CN\=zookeeper' for Scheme 'x509'
2020-06-01 14:43:58,757 [myid:0] - WARN  [QuorumPeer[myid=0](plain=0.0.0.0:2181)(secure=0.0.0.0:2281):Follower@170] - Got zxid 0x300000001 expected 0x1
2020-06-01 14:43:58,757 [myid:0] - INFO  [SyncThread:0:FileTxnLog@284] - Creating new log file: log.300000001
2020-06-01 14:43:58,764 [myid:0] - INFO  [CommitProcessor:0:LearnerSessionTracker@116] - Committing global session 0xb33bfd10000
```



## Troubleshooting

### Errors

#### Error Message: *Caused by: javax.net.ssl.SSLHandshakeException: no cipher suites in common*

- Using too height version of java, such as *OpenJDK 14*

- OR Incorrect parameters set in *zkServer.sh*



#### Error Message: *DerInputStream.getLength(): lengthTag=109, too big*

- Use  `-deststoretype pkcs12` for *keytool*



## References

[1]. [Encrypt Communication Between Kafka And ZooKeeper With TLS](https://juplo.de/encrypt-communication-between-kafka-and-zookeeper-with-tls/)

[2]. [ZooKeeper SSL User Guide](https://cwiki.apache.org/confluence/display/ZOOKEEPER/ZooKeeper+SSL+User+Guide)

[3.] [ZooKeeper Administrator's Guide](https://zookeeper.apache.org/doc/r3.6.1/zookeeperAdmin.html#Quorum+TLS)

