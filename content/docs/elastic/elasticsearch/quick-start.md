---
title: "Elasticsearch Quick Start"
weight: 1
# bookFlatSection: false
# bookToc: true
# bookHidden: false
# bookCollapseSection: false
# bookComments: false
# bookSearchExclude: false
---

## 基础概念

Elasticsearch 是一个开源的实时的分布式搜索分析引擎，建立在一个全文搜索引擎库 Apache Lucene™ 基础之上。它被用作全文检索、结构化搜索、分析以及这三个功能的组合。

一个 Elasticsearch 集群可以 包含多个 索引 ，相应的每个索引可以包含多个 类型 。 这些不同的类型存储着多个 文档 ，每个文档又有 多个 属性 。

一个 索引 类似于传统关系数据库中的一个 数据库。索引实际上是指向一个或者多个物理 分片 的 逻辑命名空间。应用程序是直接与索引而不是与分片进行交互。一个分片是一个 Lucene 的实例，文档被存储和索引到分片内，分片又被分配到集群内的各个节点里。

*从ES 6开始,每个索引只有一个类型将成为标准。本笔记的原始资料来源的文章基于Elasticsearch 2.x 版本，有些内容可能已经过时。
参考：https://www.elastic.co/guide/en/elasticsearch/reference/current/removal-of-types.html*

## 文档
一个文档不仅仅包含它的数据 ，也包含 元数据。文档的唯一性由 _index, _type, 和 routing values （通常默认是该文档的 _id ）的组合来确定。这三个必须的元数据元素:
- _index
文档在哪存放 一个 索引 应该是因共同的特性被分组到一起的文档集合。
- _type
文档表示的对象类别
- _id
文档唯一标识 ID 是一个字符串，当它和 _index 以及 _type 组合就可以唯一确定 Elasticsearch 中的一个文档。 当你创建一个新的文档，要么提供自己的 _id ，要么让 Elasticsearch 帮你生成。

这表示我们确切的知道集群中哪个分片含有此文档。

索引一个文档的操作如下：
```
curl -X PUT "localhost:9200/website/blog/123?pretty" -H 'Content-Type: application/json' -d'
{
  "title": "My first blog entry",
  "text":  "Just trying this out...",
  "date":  "2014/01/01"
}
'
```
Elasticsearch的响应体如下：
```
{
   "_index":    "website",
   "_type":     "blog",
   "_id":       "123",
   "_version":  1,
   "created":   true
}
```
website是索引；blog是类型；123是文档唯一标识ID；title、text和date是文档的属性。

#### 分布式文档存储
索引在默认情况下会被分配5个主分片。创建索引的时候就确定好主分片的数量 并且永远不会改变这个数量。

一个 分片 是一个底层的 工作单元 ，它仅保存了全部数据中的一部分。分片是数据的容器，文档保存在分片内。

索引内任意一个文档都归属于一个主分片，主分片的数目决定着索引能够保存的最大数据量。技术上来说，一个主分片最大能够存储 Integer.MAX_VALUE - 128 个文档。

当索引一个文档的时候，文档会被存储到一个主分片中。Elasticsearch通过分片路由公式决定将文档分配到哪个主分片：
```
shard = hash(routing) % number_of_primary_shards
```
其中，routing 是一个可变值，默认是文档的 _id

一个副本分片只是一个主分片的拷贝。副本分片作为硬件故障时保护数据不丢失的冗余备份，并为搜索和返回文档等读操作提供服务。副本分片数可以随时修改。在同一个节点上既保存原始数据又保存副本是没有意义的，因为一旦失去了那个节点，我们也将丢失该节点上的所有副本数据。

所有新近被索引的文档都将会保存在主分片上，然后被并行的复制到对应的副本分片上。这就保证了我们既可以从主分片又可以从副本分片上获得文档。

当我们丢失一个节点的同时，我们可能也失去了某几个主分片，缺失主分片的时候索引也不能正常工作。幸运的是，在其它节点上存在着这丢失的主分片的完整副本，此时对应的副本分片会提升为主分片。

## 批量操作

ElasticSearch批量操作：
在批量请求中引用的每个文档可能属于不同的主分片， 每个文档可能被分配给集群中的任何节点。这意味着批量请求 bulk 中的每个 操作 都需要被转发到正确节点上的正确分片。

如果单个请求被包装在 JSON 数组中，那就意味着我们需要执行以下操作：

将 JSON 解析为数组（包括文档数据，可以非常大）
查看每个请求以确定应该去哪个分片
为每个分片创建一个请求数组
将这些数组序列化为内部传输格式
将请求发送到每个分片
这是可行的，但需要大量的 RAM 来存储原本相同的数据的副本，并将创建更多的数据结构，Java虚拟机（JVM）将不得不花费时间进行垃圾回收。

相反，Elasticsearch可以直接读取被网络缓冲区接收的原始数据。 它使用换行符字符来识别和解析小的 action/metadata 行来决定哪个分片应该处理每个请求。

这些原始请求会被直接转发到正确的分片。没有冗余的数据复制，没有浪费的数据结构。整个请求尽可能在最小的内存中处理。

## 搜索
当索引一个文档的时候，Elasticsearch 取出所有字段的值拼接成一个大的字符串，作为 _all 字段进行索引。这就好似增加了一个名叫 _all 的额外字段。

一个倒排索引由文档中所有不重复词的列表构成，对于其中每个词，有一个包含它的文档列表。

组合查询example:
```
% curl -X GET "localhost:9200/_search?pretty" -H 'Content-Type: application/json' -d'
{
    "query": {
    "bool": {
        "must":     { "match": { "title": "how to make millions" }},
        "must_not": { "match": { "tag":   "spam" }},
        "should": [
            { "match": { "tag": "starred" }}
        ],
        "filter": {
          "bool": { 
              "must": [
                  { "range": { "date": { "gte": "2014-01-01" }}},
                  { "range": { "price": { "lte": 29.99 }}}
              ],
              "must_not": [
                  { "term": { "category": "ebooks" }}
              ]
          }
        }
    }
}
}
'
```

Elasticsearch 的相似度算法被定义为检索词频率/反向文档频率， TF/IDF ，包括以下内容：

- 检索词频率
检索词在该字段出现的频率？出现频率越高，相关性也越高。 字段中出现过 5 次要比只出现过 1 次的相关性高。
- 反向文档频率
每个检索词在索引中出现的频率？频率越高，相关性越低。检索词出现在多数文档中会比出现在少数文档中的权重更低。
- 字段长度准则
字段的长度是多少？长度越长，相关性越低。 检索词出现在一个短的 title 要比同样的词出现在一个长的 content 字段权重更大。
单个查询可以联合使用 TF/IDF 和其他方式，比如短语查询中检索词的距离或模糊查询里的检索词相似度。

#### 分布式检索
搜索被执行成一个两阶段过程，我们称之为 query then fetch 。
##### 查询阶段 
当一个搜索请求被发送到某个节点时，这个节点就变成了协调节点。 这个节点的任务是广播查询请求到所有相关分片并将它们的响应整合成全局排序后的结果集合，这个结果集合会返回给客户端。 
1. 创建一个大小为 from + size 的空优先队列。
2. 广播请求到索引中每一个节点的分片拷贝。
3. 每个分片在本地执行查询并添加结果到大小为 from + size 的本地有序优先队列中。
4.  分片返回一个轻量级的结果列表到协调节点，它仅包含文档 ID 集合以及任何排序需要用到的值，例如 _score。
5. 协调节点将这些分片级的结果合并到自己的有序优先队列里，它代表了全局排序结果集合。

##### 取回阶段
查询阶段标识哪些文档满足搜索请求，但是我们仍然需要取回这些文档。
1. 协调节点辨别出哪些文档需要被取回并向相关的分片提交多个 GET 请求。
2. 每个分片加载并 丰富 文档，如果有需要的话，接着返回文档给协调节点。
3. 一旦所有的文档都被取回了，协调节点返回结果给客户端。

> #### 深分页（Deep Pagination）
> 先查后取的过程支持用 from 和 size 参数分页，但是这是 有限制的 。 要记住需要传递信息给协调节点的每个分片必须先创建一个 from + size 长度的队列，协调节点需要根据 number_of_shards * (from + size) 排序文档，来找到被包含在 size 里的文档。
> 取决于你的文档的大小，分片的数量和你使用的硬件，给 10,000 到 50,000 的结果文档深分页（ 1,000 到 5,000 页）是完全可行的。但是使用足够大的 from 值，排序过程可能会变得非常沉重，使用大量的CPU、内存和带宽。因为这个原因，我们强烈建议你不要使用深分页。
> 实际上， “深分页” 很少符合人的行为。当2到3页过去以后，人会停止翻页，并且改变搜索标准。会不知疲倦地一页一页的获取网页直到你的服务崩溃的罪魁祸首一般是机器人或者web spider。

## 手动创建索引
默认的配置，新的字段通过动态映射的方式被添加到类型映射。如果需要对这个建立索引的过程做更多的控制：想要确保这个索引有数量适中的主分片，并且在索引任何数据之前，分析器和映射已经被建立好，需要手动创建索引。

查看所有索引
```
curl -X GET "localhost:9200/*?pretty" 
```

删除所有索引
```
curl -X DELETE "localhost:9200/*"
```

创建索引
```
curl -X PUT "localhost:9200/my_index" -H 'Content-Type: application/json' -d'
{
   "settings" : {
      "number_of_shards" : 3,
      "number_of_replicas" : 1
   }
}
'
```

查看创建的索引
```
curl -X GET "localhost:9200/my_index?pretty" 
```

索引一个文档：
```
curl -X PUT "localhost:9200/my_index/blog/123?pretty" -H 'Content-Type: application/json' -d'
{
  "title": "My first blog entry",
  "text":  "Just trying this out...",
  "date":  "2014/01/01",
  "user_id": 1
}
'
```

搜索指定类型下的所有文档
```
curl -X GET "localhost:9200/my_index/blog/_search?pretty"
```

获取一个文档
```
 curl -X GET "localhost:9200/my_index/blog/123?pretty"
```

获取多个文档
```
curl -X GET "localhost:9200/my_index/my_type/_mget?pretty" -H 'Content-Type: application/json' -d'{"ids":["1","2"]}'
```

多个索引中获取多个文档
```
curl -X GET "localhost:9200/_mget?pretty" -H 'Content-Type: application/json' -d'
{
   "docs" : [
      {
         "_index" : "my_index",
         "_type" :  "my_type",
         "_id" :    2
      },
      {
         "_index" : "my_index_01",
         "_type" :  "blog",
         "_id" :    123,
         "_source": "text"
      }
   ]
}
'
```

删除索引
```
curl -X DELETE "localhost:9200/my_index"
```

创建索引并定义类型/映射(无法执行)
```
curl -X PUT "localhost:9200/my_index?pretty" -H 'Content-Type: application/json' -d'
{
   "settings" : {
      "number_of_shards" : 3,
      "number_of_replicas" : 1
   },
  "mappings": {
    "blog":{
      "properties" : {
        "title" : {
          "type" :    "text",
          "analyzer": "english"
        },
        "date" : {
          "type" :   "date",
          "format" : "yyyy/MM/dd HH:mm:ss||yyyy/MM/dd||epoch_millis"
        },
        "text" : {
          "type" :   "text"
        },
        "user_id" : {
          "type" :   "long"
        }
      }
    }  
  }
}
'
```


#### 配置分析器
一个 分析器 就是在一个包里面组合了三种函数的一个包装器
1. 字符过滤器 char_filter
    字符过滤器 用来 整理 一个尚未被分词的字符串。一个分析器可能有0个或者多个字符过滤器。
2. 分词器 tokenizer
    分词器把字符串分解成单个词条或者词汇单元。一个分析器 必须 有一个唯一的分词器。
3. 词单元过滤器 filter
    词单元过滤器可以修改、添加或者移除词单元。

定义分析器
```
curl -X PUT "localhost:9200/my_index" -H 'Content-Type: application/json' -d'
{
  "settings": {
    "number_of_shards" : 3,
    "number_of_replicas" : 1,
    "analysis": {
      "analyzer": {
        "my_custom_analyzer": {
          "type": "custom",
          "char_filter": [
            "emoticons" 
          ],
          "tokenizer": "punctuation", 
          "filter": [
            "lowercase",
            "english_stop" 
          ]
        }
      },
      "tokenizer": {
        "punctuation": { 
          "type": "pattern",
          "pattern": "[ .,!?]"
        }
      },
      "char_filter": {
        "emoticons": { 
          "type": "mapping",
          "mappings": [
            ":) => _happy_",
            ":( => _sad_"
          ]
        }
      },
      "filter": {
        "english_stop": { 
          "type": "stop",
          "stopwords": "_english_"
        }
      }
    }
  }
}
'
```
应用自定义分析器
```
curl -X PUT "localhost:9200/my_index/_mapping/blog?pretty" -H 'Content-Type: application/json' -d'
{
    "properties": {
        "title": {
            "type":      "text",
            "analyzer":  "my_custom_analyzer"
        }
    }
}
'
```

#### 属性
文档字段三个最重要的属性：
- type
字段的数据类型，例如 string 或 date。它是最重要的属性。对于不是 string 的域，你一般只需要设置 type。
- index
字段是否应当被当成全文来搜索（ analyzed ），或被当成一个准确的值（ not_analyzed ），还是完全不可被搜索（ no ）。
- analyzer
确定在索引和搜索时全文字段使用的 analyzer

## 搜索

#### 批量索引文档
```
curl -X POST "localhost:9200/my_store/products/_bulk?pretty" -H 'Content-Type: application/json' -d'
{ "index": { "_id": 1 }}
{ "price" : 10, "productID" : "XHDK-A-1293-#fJ3" }
{ "index": { "_id": 2 }}
{ "price" : 20, "productID" : "KDKE-B-9947-#kL5" }
{ "index": { "_id": 3 }}
{ "price" : 30, "productID" : "JODL-X-1937-#pV7" }
{ "index": { "_id": 4 }}
{ "price" : 30, "productID" : "QQPX-R-3956-#aD8" }
'
```

#### 过滤查询
```
curl -X GET "localhost:9200/my_store/products/_search?pretty" -H 'Content-Type: application/json' -d'
{
    "query" : {
        "constant_score" : { 
            "filter" : {
                "term" : { 
                    "price" : 20
                }
            }
        }
    }
}
'
```

#### 匹配查询
```
curl -X GET "localhost:9200/my_index/my_type/_search?pretty" -H 'Content-Type: application/json' -d'
{
    "query": {
        "match": {
            "title": "QUICK!"
        }
    }
}
'
```
