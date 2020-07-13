# tool

## Install a tool



```groovy
def mvn_home = tool name: 'M3'

sh("$mvn_home/bin/mvn -B verify")

tool name: 'jgit', type: 'hudson.plugins.git.GitTool'
```

