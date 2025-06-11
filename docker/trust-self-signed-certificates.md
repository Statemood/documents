# Trust self signed certificates

*以下操作在所有节点上执行。*

1. 安装 ca-certificates

   ```shell
   yum install -y ca-certificates
   ```

2. 复制 CA 证书

   ```shell
   cp my-ca.pem /etc/pki/ca-trust/source/anchors/
   ```
   

3. 启用 CA 证书动态更新

   ```shell
   update-ca-trust
   ```

   

4. 重启 Docker 服务

   ```shell
   systemctl restart docker
   ```