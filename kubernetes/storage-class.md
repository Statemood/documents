
- storage-class.yaml

      apiVersion: storage.k8s.io/v1
      kind: StorageClass
      metadata:
        name: data
      provisioner: kubernetes.io/rbd
      parameters:
        monitors: your-ceph-monitor-servers
        adminId: admin
        adminSecretName: ceph-secret
        adminSecretNamespace: kube-system
        pool: data
        userId: kube
        userSecretName: ceph-secret-kube


- pvc.yaml

      kind: PersistentVolumeClaim
      apiVersion: v1
      metadata:
        name: data-mysql
        namespace: mysql
        annotations:
          volume.beta.kubernetes.io/storage-class: data
      spec:
        accessModes:
          - ReadWriteOnce
        resources:
          requests:
            storage: 50Gi