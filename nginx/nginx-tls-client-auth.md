# Nginx TLS Client Authentication

## 应用场景

一部分开源服务或平台并没有认证系统，因而会引发安全隐患。

针对大部分此类服务都为内部系统，故可以考虑使用预签发的客户端证书来进行安全认证。



## 签发证书

### CA 证书

#### 准备 ca.cnf 配置文件

```
[ req ]
req_extensions = v3_req
distinguished_name = req_distinguished_name
[req_distinguished_name]

[ v3_req ]
keyUsage = critical, cRLSign, keyCertSign, digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth, clientAuth
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid:always,issuer
basicConstraints = critical, CA:true, pathlen:2
```



#### 生成 CA Key

```shell
openssl genrsa -out ca.key 4096
```



#### 签发 CA 证书

```shell
openssl req -x509 -new -nodes -key ca.key -days 1095 -out ca.pem \
        -subj "/CN=Office Security Authority/OU=SA/C=CN/ST=Shanghai/L=Shanghai/O=IT" \
        -config ca.cnf -extensions v3_req
```



### Client 证书

#### 准备 client.cnf 配置文件

```
[ req ]
req_extensions = v3_req
distinguished_name = req_distinguished_name
[req_distinguished_name]
[ v3_req ]
basicConstraints = critical, CA:FALSE
keyUsage = critical, digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth, clientAuth
```



#### 生成 Client Key

```shell
openssl genrsa -out client.key 4096
```



#### 生成证书签名请求

```shell
openssl req -new -key client.key -out client.csr \
        -subj "/CN=Office Security Client/OU=SA/C=CN/ST=Shanghai/L=Shanghai/O=IT" \
        -config client.cnf
```



#### 签发证书

```shell

openssl x509 -req -in client.csr -CA ca.pem -CAkey ca.key -CAcreateserial \
        -out client.pem -days 60 -extfile client.cnf -extensions v3_req
```



#### 导出 PKCS12 格式证书

```shell
openssl pkcs12 -export -in client.pem -inkey client.key -out client.p12 \
        -name "Office Security TLS Client Authentication"
```



### 证书及类型

| 文件       | 类型        | 用途                                    |
| :--------- | :---------- | :-------------------------------------- |
| client.p12 | PKCS #12    | 导入系统供浏览器使用 / 配置到应用中使用 |
| client.key | RSA Key     | 供应用访问使用                          |
| client.pem | Certificate | 供应用访问使用                          |





## 在 Nginx 中使用TLS Client Authentication

在Nginx `server` 字段中增加配置

```nginx
server{				
    listen 443 ssl;
    server_name jenkins.rulin.me;
  	
    ssl_certificate         ssl/jenkins.rulin.me.pem;
    ssl_certificate_key     ssl/jenkins.rulin.me.key;
    ssl_client_certificate  ssl/tls-client-auth-ca.pem;
    ssl_verify_client       on;
 		
    ...
    ...
}
```




## 附录

### 引用

[1]. [Nginx Doc: ssl_verify_client](https://nginx.org/en/docs/http/ngx_http_ssl_module.html#ssl_verify_client)

[2]. [OCSP Validation of Client Certificates](https://docs.nginx.com/nginx/admin-guide/security-controls/terminating-ssl-http/#ocsp-validation-of-client-certificates)

