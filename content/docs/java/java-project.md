---
title: "Simple Java Project"
weight: 1
# bookFlatSection: false
# bookToc: true
# bookHidden: false
# bookCollapseSection: false
# bookComments: false
# bookSearchExclude: false
---

## 纯手工构建java项目
```shell
echo 'make source dir'
mkdir -p src/main/java

echo 'create package'
mkdir -p src/main/java/com/example

echo 'code'
cat <<  EOF > src/main/java/com/example/Main.java
package com.example;
public class Main {
    public static void main(String[] args) {
        System.out.println("Hello World");
    }
}
EOF

echo 'clean'
rm -rf target/classes && mkdir -p target/classes

echo 'compile'
javac -d target/classes -sourcepath src/java $(find src/main/java -name "*.java")

echo 'package'
jar -cf target/helloworld.jar -C target/classes .

echo 'run'
java -cp target/*.jar com.example.Main
```