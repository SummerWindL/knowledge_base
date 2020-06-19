### UniPush集成了个推服务 实现手机APP端推送
以下提供安装方案：

**推荐使用第一种方案**

#### 方案一：
下载官方提供的Jar 该文档已经提供
本地安装 依赖 执行如下命令 （注意检查 jar 所在路径，例子中为： D:\lib\ ）

```
mvn install:install-file -Dfile=D:\lib\gexin-rp-sdk-http-4.1.1.3.jar -DgroupId=com.gexin.platform -DartifactId=gexin-rp-sdk-http -Dversion=4.1.1.3 -Dpackaging=jar
```

```
mvn install:install-file -Dfile=D:\lib\gexin-rp-fastjson-1.0.0.6.jar -DgroupId=com.gexin.platform -DartifactId=gexin-rp-fastjson -Dversion=1.0.0.6 -Dpackaging=jar
```

```
mvn install:install-file -Dfile=D:\lib\gexin-rp-sdk-base-4.0.0.36.jar -DgroupId=com.gexin.platform -DartifactId=gexin-rp-sdk-base -Dversion=4.0.0.36 -Dpackaging=jar
```

```
mvn install:install-file -Dfile=D:\lib\gexin-rp-sdk-template-4.0.0.28.jar -DgroupId=com.gexin.platform -DartifactId=gexin-rp-sdk-template -Dversion=4.0.0.28 -Dpackaging=jar
```

```
mvn install:install-file -Dfile=D:\lib\protobuf-java-2.5.0.jar -DgroupId=com.google.protobuf -DartifactId=protobuf-java -Dversion=2.5.0 -Dpackaging=jar
```

替换jar文件名 安装到本地开发的maven仓库

将下边依赖放到maven项目 pom.xml中

```xml

<dependency>
    <groupId>com.gexin.platform</groupId>
    <artifactId>gexin-rp-sdk-http</artifactId>
    <version>4.1.1.3</version>
    <!--<systemPath>${basedir}/src/lib/gexin-rp-sdk-http-4.1.1.3.jar</systemPath>
    <scope>system</scope>-->
</dependency>
<dependency>
    <groupId>com.gexin.platform</groupId>
    <artifactId>gexin-rp-fastjson</artifactId>
    <version>1.0.0.6</version>
    <!--<scope>system</scope>
    <systemPath>${basedir}/src/lib/gexin-rp-fastjson-1.0.0.6.jar</systemPath>-->
</dependency>
<dependency>
    <groupId>com.gexin.platform</groupId>
    <artifactId>gexin-rp-sdk-base</artifactId>
    <version>4.0.0.36</version>
    <!--<scope>system</scope>
    <systemPath>${basedir}/src/lib/gexin-rp-sdk-base-4.0.0.36.jar</systemPath>-->
</dependency>
<dependency>
    <groupId>com.gexin.platform</groupId>
    <artifactId>gexin-rp-sdk-template</artifactId>
    <version>4.0.0.28</version>
    <!--<scope>system</scope>
    <systemPath>${basedir}/src/lib/gexin-rp-sdk-template-4.0.0.28.jar</systemPath>-->
</dependency>
<!-- https://mvnrepository.com/artifact/com.google.protobuf/protobuf-java -->
<dependency>
    <groupId>com.google.protobuf</groupId>
    <artifactId>protobuf-java</artifactId>
    <version>2.5.0</version>
    <!--<scope>system</scope>
    <systemPath>${basedir}/src/lib/protobuf-java-2.5.0.jar</systemPath>-->
</dependency>
```




### 方案二：
maven方式安装
将下边的依赖放到maven项目的 pom.xml 中：
```
<dependency>
    <groupId>com.gexin.platform</groupId>
    <artifactId>gexin-rp-sdk-http</artifactId>
    <version>4.1.1.3</version>
</dependency>
```
然后再增加一个repository到 pom.xml 中：

```
<repositories>
    <repository>
        <id>getui-nexus</id>
        <url>http://mvn.gt.igexin.com/nexus/content/repositories/releases/</url>
    </repository>
 </repositories>
```
