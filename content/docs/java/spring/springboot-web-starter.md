---
title: "Springboot Web Starter"
# bookFlatSection: false
# bookToc: true
# bookHidden: false
# bookCollapseSection: false
# bookComments: false
# bookSearchExclude: false
---

## Springboot Web启动

#### 1. new SpringApplicatin().
构造的时候，确定 WebApplicationType
```
/**
* The application should not run as a web application and should not start an
* embedded web server.
*/
NONE,

/**
* The application should run as a servlet-based web application and should start an
* embedded servlet web server.
*/
SERVLET,

/**
* The application should run as a reactive web application and should start an
* embedded reactive web server.
*/
REACTIVE;
```

通过SpringFactoriesLoader初始化两个集合：
List<ApplicationContextInitializer<?>> initializers;
List<ApplicationListener<?>> listeners;

#### 2. SpringApplication.run()
ApplicationContextFactory通过不同的WebApplicationType创建不同的ApplicationContext
```
AnnotationConfigApplicationContext
AnnotationConfigReactiveWebServerApplicationContext
AnnotationConfigServletWebServerApplicationContext
```

#### 3. prepareContext
在prepareContext方法中，会构建 BeanDefinitionLoader 
