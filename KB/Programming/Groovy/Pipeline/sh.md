# sh

## Shell Script



```groovy
sh 'whoami'

sh("whoami")
```



#### Return Stdout

```groovy
sh(script: "whoami", returnStdout: true)
```



#### Return Status

```groovy
sh(script: "whoami", returnStatus: true)
```

