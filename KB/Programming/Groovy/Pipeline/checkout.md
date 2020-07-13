# checkout

## General SCM



```groovy
checkout([$class: 'GitSCM',
           branches: [[name: revision]],
           credentialsId: cid,
           userRemoteConfigs: [[url: repo]]])
```

