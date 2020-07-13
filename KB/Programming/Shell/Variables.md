# Variables



### 变量提示

```shell
file="${1:?missing file}"
 key="${2:?missing key}"
```



### 默认变量

A如果没有定义，则表达式返回默认值，否则返回A的值

```shell
string="${A-text}"
```



A没有定义或者为空字符串，则表达式返回默认值，否则返回A的值

```shell
string="${A:-text}"
```



