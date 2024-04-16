---
title: "Aspectj"
weight: 1
# bookFlatSection: false
# bookToc: true
# bookHidden: false
# bookCollapseSection: false
# bookComments: false
# bookSearchExclude: false
---

### AspectJ
官网文档：
https://www.eclipse.org/aspectj/doc/released/progguide/index.html

#### 安装与运行
aspectj 可以用 `.aj` 文件进行定义。使用 `ajc` 编译成jvm可加载的class文件。运行时需要 aspectjrt.jar 运行时环境。

下载aspectj，官网地址：https://www.eclipse.org/aspectj/downloads.php
```
% wget https://ftp.yz.yamagata-u.ac.jp/pub/eclipse//tools/aspectj/aspectj-1.9.6.jar
```

下载完成后，运行jar进行安装
```
java -jar aspectj-1.9.6.jar
```

安装完以后，将aspectj的bin添加到path，ajc 命令就可用了。
```
% ajc -version
AspectJ Compiler 1.9.6 - Built: Wednesday Jul 22, 2020 at 12:34:23 PDT - Eclipse Compiler 48c3f7668a46f2 (22Apr2020) - Java14
```

#### 概念
面向方面编程是切面模块化思想的一种实践，就好像面向对象编程是通用模块化思想的一种实践一样。AspectJ是java的面向方面编程的实现。

AspectJ 为 java 引入了一种新的概念 join point（和 AOP联盟的 joinpoint 一样）。并增加了一些新的结构体： pointcuts, advice, inter-type declarations and aspects。

> A **join point** is a well-defined point in the program flow. A **pointcut** picks out certain join points and values at those points. A piece of **advice** is code that is executed when a join point is reached. These are the dynamic parts of AspectJ.

定义一个pointcut，通过列举出所有方法的声明并将他们用 “或” 连接，并命名为 `move()` :
```
pointcut move():
    call(void FigureElement.setXY(int,int)) ||
    call(void Point.setX(int))              ||
    call(void Point.setY(int))              ||
    call(void Line.setP1(Point))            ||
    call(void Line.setP2(Point));
```

定义一个advice，应用在上述定义的名为 move() 的 pointcut 上，在 pointcut 声明的 joinpoints 触发前(before)触发这个advice:
```
before(): move() {
    System.out.println("about to move");
}
```

将joinpoint的上下文暴露给advice:
```
pointcut setXY(FigureElement fe, int x, int y):
    call(void FigureElement.setXY(int, int))
    && target(fe)
    && args(x, y);

after(FigureElement fe, int x, int y) returning: setXY(fe, x, y) {
    System.out.println(fe + " moved to (" + x + ", " + y + ").");
}
```

Inter-type declarations：
定义一个observers向量,在changes发生后触发向量中的screen进行更新显示。
```
aspect PointObserving {
    private Vector Point.observers = new Vector();

    public static void addObserver(Point p, Screen s) {
        p.observers.add(s);
    }
    public static void removeObserver(Point p, Screen s) {
        p.observers.remove(s);
    }

    pointcut changes(Point p): target(p) && call(void Point.set*(int));

    after(Point p): changes(p) {
        Iterator iter = p.observers.iterator();
        while ( iter.hasNext() ) {
            updateObserver(p, (Screen)iter.next());
        }
    }

    static void updateObserver(Point p, Screen s) {
        s.display(p);
    }
}
```

Aspects 将 pointcuts, advice, and inter-type declarations 包装在一起，就想一个class。Aspects的实例化由AspectJ控制，不能使用java的new操作生成一个新的实例。默认情况下，Aspect 都是单例的。

> Aspects wrap up pointcuts, advice, and inter-type declarations in a a modular unit of crosscutting implementation. It is defined very much like a class, and can have methods, fields, and initializers in addition to the crosscutting members. 
> By default, each aspect is a singleton, so one aspect instance is created. 

#### Aspects在测试上的应用
1. 跟踪，在方法调用前打印 `thisJoinPoint`。这是一个特殊变量，表示当前的 `join point`。
```
aspect SimpleTracing {
    pointcut tracedCall():
        call(void FigureElement.draw(GraphicsContext));

    before(): tracedCall() {
        System.out.println("Entering: " + thisJoinPoint);
    }
}
```

2. 分析，可以在aspect中定义变量，用来记录方法的调用次数
```
aspect SetsInRotateCounting {
    int rotateCount = 0;
    int setCount = 0;

    before(): call(void Line.rotate(double)) {
        rotateCount++;
    }

    before(): call(void Point.set*(int))
              && cflow(call(void Line.rotate(double))) {
        setCount++;
    }
}
```

3. 错误检测，使用 `declare error` 和 `withincode`，将`Registry.register` 方法的调用限制在 `FigureElement.make*` 方法里。否则将产生编译错误。
```
aspect RegistrationProtection {

    pointcut register(): call(void Registry.register(FigureElement));
    pointcut canRegister(): withincode(static * FigureElement.make*(..));

    declare error: register() && !canRegister(): "Illegal call"
}
```


#### point cut
1. when a particular method body executes
`execution(void Point.setX(int))`

2. when a method is called
`call(void Point.setX(int))`

3. when an exception handler executes
`handler(ArrayOutOfBoundsException)`

4. when the object currently executing (i.e. this) is of type SomeType
`this(SomeType)`

5. when the target object is of type SomeType
`target(SomeType)`

6. when the executing code belongs to class MyClass
`within(MyClass)`

7. when the join point is in the control flow of a call to a Test's no-argument main method
`cflow(call(void Test.main()))`

笔记：execution 和 call 的区别是， execution 指的是方法执行本身，call 指的是方法的调用。所以在aspectj织入时，execution只织入到方法里（只织入一次），而call织入到方法调用的地方（如果织入范围内方法调用10次，那么织入10个地方）
> When methods and constructors run, there are two interesting times associated with them. That is when they are called, and when they actually execute.


cflow可以想象成从call开始的调用栈。
https://stackoverflow.com/questions/5205916/aspect-oriented-programming-what-is-cflow


#### Advice
1. This `before advice` runs just before the join points picked out by the (anonymous) pointcut
```
before(Point p, int x): target(p) && args(x) && call(void setX(int)) {
      if (!p.assertX(x)) return;
  }
```

2. This `after advice` runs just after each join point picked out by the (anonymous) pointcut, regardless of whether it returns normally or throws an exception:
```
after(Point p, int x): target(p) && args(x) && call(void setX(int)) {
      if (!p.assertX(x)) throw new PostConditionViolation();
  }
```

3. This `after returning advice` runs just after each join point picked out by the (anonymous) pointcut, but only if it returns normally. The return value can be accessed, and is named x here. After the advice runs, the return value is returned:
```
after(Point p) returning(int x): target(p) && call(int getX()) {
      System.out.println("Returning int value " + x + " for p = " + p);
  }
```

4. This `after throwing advice` runs just after each join point picked out by the (anonymous) pointcut, but only when it throws an exception of type Exception. Here the exception value can be accessed with the name e. The advice re-raises the exception after it's done:
```
after() throwing(Exception e): target(Point) && call(void setX(int)) {
      System.out.println(e);
  }
```

5. This `around advice` traps the execution of the join point; it runs instead of the join point. The original action associated with the join point can be invoked through the special `proceed` call:

```
void around(Point p, int x): target(p)
                          && args(x)
                          && call(void setX(int)) {
    if (p.assertX(x)) proceed(p, x);
    p.releaseResources();
}
```

#### Inter-type declarations
```
private boolean Server.disabled = false;
```
如上定义的私有变量，只在当前aspect可见，如果Server或者其他aspect也定义了disabled变量，也不会冲突。

#### thisJoinPoint
thisJoinPoint包含 joinpoint 的静态和动态部分。
```
//获取参数
thisJoinPoint.getArgs()
//获取函数签名等静态信息
thisJoinPoint.getStaticPart()
```

可以是用 `thisJoinPointStaticPart` 直接访问joinpoint的静态部分。

#### AspectjObject.aspectOf()
如果想获取Aspect对象，可以使用 `.aspectOf()`。
比如在billing中获取Timing在Connection中织入的timer。
```
long time = Timing.aspectOf().getTimer(conn).getTime();
```

#### precedence
定义优先级
```
// precedence required to get advice on endtiming in the right order
    declare precedence: Billing, Timing;
```

### Basic Techniques
the two fundamental ways of capturing crosscutting concerns：
1. with dynamic join points and advice. Advice changes an application's behavior.

2. with static introduction.  Introduction changes both an application's behavior and its structure.

### 注意事项
If the advice calls back to the objects, there is always the possibility of recursion. Keep that in mind!


