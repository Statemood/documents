# build

## Build an existing job



```groovy
build job: 'test-pipeline-1'
```



```groovy
build job: 'test-pipeline-2', 
  		parameters: [[$class: 'StringParameteValue', name: 'who', value: 'World']]
```

