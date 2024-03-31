---
title: "Basic Concepts"
weight: 2
# bookFlatSection: false
# bookToc: true
# bookHidden: false
# bookCollapseSection: false
# bookComments: false
# bookSearchExclude: false
---

### 基础概念
#### node.js
> Node.js® 是一个基于 Chrome V8 引擎 的 JavaScript 运行时环境。

做个不是很严谨的类比：node.js 之于 JavaScript 如同 jre 之于 java。

javascript一开始是作为web页面的脚本语言而诞生的，运行在浏览器中，如果离开浏览器，就没有运行时环境，没有办法执行。Node.js 是一个让 JavaScript 运行在浏览器之外的平台，让javascript脱离浏览器，可以运行在装有node.js的服务器上。

```
$ node -v
v16.6.1
$ cat <<EOF >hello.js
> console.log('hello world');
> EOF
$ node hello.js 
hello world
```

#### nvm
既然node.js是个运行时环境，那么node.js开发的应用，就会因为运行时环境不同，遇到一些版本兼容问题。就如同我们使用不同的jdk版本进行开发时，有时也会遇到些jdk版本兼容问题一样。为了克服版本兼容问题，建议使用nvm进行node.js的安装和版本管理。

> nvm is a version manager for node.js, designed to be installed per-user, and invoked per-shell. 

nvm(Node Version Manager)，顾名思义，是一个node.js的版本管理器，可以非常方便地安装和切换各种版本的node.js。
```
$ nvm install node
Downloading and installing node v16.6.1...
Downloading https://nodejs.org/dist/v16.6.1/node-v16.6.1-darwin-x64.tar.xz...
############################################################################################################################################### 100.0%
Computing checksum with shasum -a 256
Checksums matched!
Now using node v16.6.1 (npm v7.20.3)
Creating default alias: default -> node (-> v16.6.1)
$ nvm install 14
Downloading and installing node v14.17.4...
...
Now using node v14.17.4 (npm v6.14.14)
$ node -v
v14.17.4
$ nvm use 16
Now using node v16.6.1 (npm v7.20.3)
$ node -v
v16.6.1
$ nvm list
       v14.17.4
->      v16.6.1
...
```

#### npm
没有在官网找到npm的全称是啥的资料，但是猜测应该是Node Package Manager,即node.js的包管理器。有点类似java世界里的maven。
> npm is the world's largest software registry. Open source developers from every continent use npm to share and borrow packages, and many organizations use npm to manage private development as well.

npm可以用install命令安装一个包，所谓安装就是下载到本地。然后可以在工程中，使用require语句引用这个包。
```
$ npm install lodash
added 1 package, and audited 2 packages in 3s
found 0 vulnerabilities
$ ls node_modules/
lodash
$ cat <<EOF >index.js
> var lodash = require('lodash');
> var output = lodash.without([1,2,3,4], 2);
> console.log(output);
> EOF
$ node index.js 
[ 1, 3, 4 ]
```

当然，最佳的方式是使用package.json声明当前工程依赖哪些包。
> The best way to manage locally installed npm packages is to create a package.json file.

package.json非常类似maven里的pom.xml，除了依赖，package.json还有很多配置选项，其中必须配置的选项是当前工程的名称(name)和版本号(version).
```
{
  "name": "my-awesome-package",
  "version": "1.0.0"
}
```

声明依赖的两个选项为：
- "dependencies": These packages are required by your application in production.
- "devDependencies": These packages are only needed for development and testing.

dependencies是运行时依赖包，devDependencies是开发测试依赖包（如同maven中scope为test的依赖）

#### webpack

教程：
https://webpack.js.org/guides/getting-started/

> At its core, webpack is a static module bundler for modern JavaScript applications. When webpack processes your application, it internally builds a dependency graph which maps every module your project needs and generates one or more bundles.

webpack的作用是通过定义的entry（默认为src/index.js）和output（默认为dist/main.js）,将entry中的依赖生成一个图，并将这些依赖打包，输出到output。从这个角度看，webpack有点像ant，webpack.config.js则像ant的build.xml配置文件。如果类比到maven中，它承担执行mvn package时的角色，类似package插件。

```
$ cat webpack.config.js 
const path = require('path');
const HtmlWebpackPlugin = require('html-webpack-plugin');

module.exports = {
  mode: 'development',
  /*
    代码分离可以用于获取更小的 bundle，以及控制资源加载优先级，如果使用合理，会极大影响加载时间。
    wenpack通过配置多个entry point，手动分离代码
    使用dependOn选项，防止重复

    另一种方式重复的方式是使用SplitChunksPlugin插件
    配置方式：optimization: { splitChunks: { chunks: 'all' }}
  */
  entry: {
    index: {import: './src/index.js', dependOn: 'shared'},
    another: {import: './src/another.js', dependOn: 'shared'},
    shared: 'lodash'
  },
  //source-map可以将编译后的代码映射回原始源代码,如果发生错误，控制太会显示发生错误的文件和行号的引用
  devtool: 'inline-source-map',
  /*
    web server 将在编译代码后自动重新加载,避免每次编译代码时，手动运行 npm run build，并刷新浏览器
    安装：npm install --save-dev webpack-dev-server
    运行：webpack serve --open
  */
  devServer: {
    contentBase: './dist',
  },
  output: {
    filename: '[name].bundle.js',
    path: path.resolve(__dirname, 'dist'),
    //每次构建前清理 /dist 文件夹
    clean: true
  },
  module: {
    rules: [
      /*
        除了 JavaScript，通过 loader 或内置的 Asset Modules 可以引入任何其他类型的文件。
        为了在 JavaScript 模块中 import 一个 CSS 文件，需要安装 style-loader 和 css-loader，
        并在 module 配置 中添加这些 loader
      */
      {test: /\.css$/i, use: ['style-loader', 'css-loader']},
      {test: /\.(png|svg|jpg|jpeg|gif)$/i, type: 'asset/resource' }
    ]
  },
  plugins: [
    /*
      HtmlWebpackPlugin 创建了一个全新的index.html文件，所有的 bundle 会自动添加到 html 中
      安装：npm install --save-dev html-webpack-plugin
    */
    new HtmlWebpackPlugin({title: 'webpack demo'})
  ],
  /*
    一个 HTML 页面上使用多个入口时，需设置 optimization.runtimeChunk: 'single'
  */
  optimization: {
    runtimeChunk: 'single',
  }
}
```
