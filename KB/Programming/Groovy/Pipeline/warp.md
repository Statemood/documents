# warp



```groovy
warp([$class: 'Xvnc', useXauthority: true]) {
  	sh("make selenium-tests")
}
```



```groovy
wrap([$class: 'BuildUser']) { env.BUILD_USER    = BUILD_USER    }
wrap([$class: 'BuildUser']) { env.BUILD_USER_ID = BUILD_USER_ID }
```

