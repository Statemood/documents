# 使用 Ceph S3 为 Harbor 提供后端存储



本文档基于以下版本实现。

| Application | Version  |
| :---------: | :------: |
|    Ceph     |  1.14.2  |
|   Harbor    |  1.9.4   |
|   Docker    | CE 19.03 |



## Ceph



### 安装 radosgw 

```shell
ceph-deploy install --rgw 192.168.0.10 192.168.0.11 192.168.0.12
```



### 创建 radosgw

```shell 
ceph-deploy rgw create 192.168.0.10 192.168.0.11 192.168.0.12
```



测试服务是否正常

```shell
curl -s http://192.168.0.10:7480
```

正常返回如下数据

```xml
<?xml version="1.0" encoding="UTF-8"?>
<ListAllMyBucketsResult xmlns="http://s3.amazonaws.com/doc/2006-03-01/">
  <Owner>
    <ID>anonymous</ID>
    <DisplayName></DisplayName>
  </Owner>
  <Buckets></Buckets>
</ListAllMyBucketsResult>
```



### Create Auth Key

```shell
ceph auth get-or-create client.radosgw.gateway osd 'allow rwx' mon 'allow rwx' -o /etc/ceph/ceph.client.radosgw.keyring
```

分发 */etc/ceph/ceph.client.radosgw.keyring* 到其它 radosgw 节点。





### 防火墙打开端口

```shell
firewall-cmd --zone=public --add-port 7480/tcp --permanent
firewall-cmd --reload
```





### 查看存储池状态

```shell
rados df
```



查看 zonegroup

```shell 
radosgw-admin zonegroup get
```



### 创建对象存储

1. Create  a radosgw user for s3 access

   ```shell
   radosgw-admin user create --uid="harbor" --display-name="Harbor Registry"
   ```

   

2. Create a swift user

   ```shell
   radosgw-admin subuser create --uid=harbor --subuser=harbor:swift --access=full
   ```

   

3. Create Secret Key

   ```shell
   radosgw-admin key create --subuser=harbor:swift --key-type=swift --gen-secret
   ```

- 记住 `keys` 字段中的 `access_key` & `secret_key` 



4. 查看 bucket 状态

   ```shell
   radosgw-admin bucket stats harbor
   ```



## Harbor

### 修改 harbor 配置文件

harbor.yml

```yaml
storage_service:
  s3:
    region: cn-shanghai-1
    regionendpoint: http://192.168.0.10:7480
    bucket: harbor
    secure: false
    accesskey: D1GOBJWCX79LJ469ABAT
    secretkey: LFOcGayBQEP99prsuVEn4H8L0ZQNTWkgshcbh9Sl
```

- `region` 可任意填写
- `regionendpoint` 填写 *Ceph S3* 服务地址
- `bucket` 填写 *bucket* 名称
- `secure` 根据 *regionendpoint* 协议类型(*http: false, https: true*)填写
- `accesskey` *access_key*
- `secretkey` *secret_key*



### 启动 Harbor

启动Harbor即可。

