# JDK路径
JAVA_HOME=/usr/shopxx/jdk6.0
# Tomcat服务启动用户
TOMCAT_USER=tomcat
# JSVC启动参数
JSVC_OPTS="-jvm server"
# Tomcat内存配置
JAVA_OPTS="-server -Xms128m -Xmx512m"
# APR库路径
LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/shopxx/tomcat6.0/lib
export LD_LIBRARY_PATH