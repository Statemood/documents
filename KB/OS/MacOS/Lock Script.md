```shell
#! /bin/bash

Lock(){
    /System/Library/CoreServices/Menu\ Extras/User.menu/Contents/Resources/CGSession -suspend
}

echo -e "`date +'%F %T'` \033[1mScreen locked by \033[1;34m$USER\033[0m"

Lock
```

