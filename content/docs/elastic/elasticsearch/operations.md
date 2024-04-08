---
title: "Operations"
weight: 1
# bookFlatSection: false
# bookToc: true
# bookHidden: false
# bookCollapseSection: false
# bookComments: false
# bookSearchExclude: false
---

## 准备工作
elasticsearch的安装和启动非常简单。

官网下载地址：
https://www.elastic.co/cn/downloads/elasticsearch

选择一个适合自己操作系统平台的版本下载，解压以后执行以下命令（以elasticsearch-7.15.2的macOs版本为例）：
```
cd elasticsearch-7.15.2
./bin/elasticsearch
```

## 集群操作
#### 查看集群信息
查看集群的名称及版本信息，包括lucene版本
```
curl 'http://localhost:9200/?pretty'
```
*pretty参数表示美化打印信息*

#### 查看集群健康情况
查看集群的状态、节点数量、主分片数量等
```
curl -X GET "localhost:9200/_cluster/health?pretty"
```

#### 查看集群内所有索引
使用`/*`查看所有索引的信息，包括索引名称，mappings，settings等信息。
```
curl -X GET "localhost:9200/*?pretty" 
```
如果是个空集群，将返回`{}`

#### 删除所有索引
```
curl -X DELETE "localhost:9200/*"
```
`/*`全删是非常危险的操作，如果是生成环境，建议在elasticsearch.yml中配置开启`action.destructive_requires_name: true`，使删除只限于特定名称指向的数据, 而不允许通过指定 `_all` 或通配符来删除指定索引库。

## 索引操作
#### 创建索引
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
> Indices created in 6.x only allow a single-type per index. 

elasticsearch 6以后，一个索引只能有一个类型，并且建议使用 `_doc` 作为type名称。

《removal-of-types》这篇文章里面详细阐述了这么做的原因：
[https://www.elastic.co/guide/en/elasticsearch/reference/current/removal-of-types.html](https://www.elastic.co/guide/en/elasticsearch/reference/current/removal-of-types.html)

#### 查看创建的索引
指定索引名查看索引信息，上例中我们创建了索引my_index
```
curl -X GET "localhost:9200/my_index?pretty" 
```

#### 索引一个文档：
通过put索引一个指定id的文档，本例中id为123。
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
通过post索引一个没有指定id的文档，由 Elasticsearch 按FlakeID 模式自动生成长度为20个字符的 GUID 字符串作为id。
```
curl -X POST "localhost:9200/my_index/blog/?pretty" -H 'Content-Type: application/json' -d'
{
  "title": "My second blog entry",
  "text":  "Still trying this out...",
  "date":  "2014/01/01"
}
'
```

#### 获取文档
```
 curl -X GET "localhost:9200/my_index/blog/123?pretty"
```

#### 更新文档
在 Elasticsearch 中文档是 不可改变 的，不能修改它们。想要更新现有的文档，需要 重建索引 然后进行替换。在内部，Elasticsearch 将旧文档标记为已删除，并增加一个全新的文档。
```
curl -X PUT "localhost:9200/my_index/blog/123?pretty" -H 'Content-Type: application/json' -d'
{
  "title": "My first blog entry",
  "text":  "I am starting to get the hang of this...",
  "date":  "2014/01/02"
}
'
```
虽然Elasticsearch 的 update API 似乎对文档直接进行了修改，但实际上 Elasticsearch 按上述完全相同方式执行以下过程：
- 从旧文档构建 JSON
- 更改该 JSON
- 删除旧文档
- 索引一个新文档

#### 删除索引
```
curl -X DELETE "localhost:9200/my_index"
```

## 批量操作
#### 使用 `_mget` 获取多个文档
同时获取多个文档，需要通过docs数组告知Elasticsearch这些文档的三个基本元数据(index,type,id)，还可以通过_source指定字段。
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

，如果所有文档的 `_index` 和 `_type` 都是相同的，可以只传一个 ids 数组，而不是整个 docs 数组。
```
curl -X GET "localhost:9200/my_index/blog/_mget?pretty" -H 'Content-Type: application/json' -d'{"ids":["123","OVeeNn0Bv21y_VBnsUDR"]}'
```

#### 使用 `_bulk` 进行批量操作
批量索引一组文档
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

Elasticsearch 提供bulk API 允许在单个步骤中进行多次 create 、 index 、 update 或 delete 请求。请求体格式类似一个有效的单行 JSON 文档 流 ，它通过换行符(\n)连接到一起。具体API详见文档：
https://www.elastic.co/guide/cn/elasticsearch/guide/current/bulk.html#bulk

需要注意的是 bulk 请求不是原子的，不能用它来实现事务控制。每个请求是单独处理的，因此一个请求的成功或失败不会影响其他的请求。

## 搜索
#### 空搜索
不指定任何查询，简单地返回集群中所有索引下的所有文档，默认返回查询结果的前十个文档。
```
curl -X GET "localhost:9200/_search?pretty"
```

搜索指定类型下的所有文档
```
curl -X GET "localhost:9200/my_index/blog/_search?pretty"
```

进行分页
```
curl -X GET "localhost:9200/_search?size=5&from=5&pretty"
```
size 和 from 可以指定也可以不指定。其中size表示期望返回的结果数量，默认是10；from表示跳过的初始结果数量，默认是 0。

> #### 在分布式系统中深度分页
> 理解为什么深度分页是有问题的，我们可以假设在一个有 5 个主分片的索引中搜索。 当我们请求结果的第一页（结果从 1 到 10 ），每一个分片产生前 10 的结果，并且返回给 协调节点 ，协调节点对 50 个结果排序得到全部结果的前 10 个。
现在假设我们请求第 1000 页 — 结果从 10001 到 10010 。所有都以相同的方式工作除了每个分片不得不产生前10010个结果以外。 然后协调节点对全部 50050 个结果排序最后丢弃掉这些结果中的 50040 个结果。
可以看到，在分布式系统中，对结果排序的成本随分页的深度成指数上升。这就是 web 搜索引擎对任何查询都不要返回超过 1000 个结果的原因。

> #### 深分页（Deep Pagination）
> 先查后取的过程支持用 from 和 size 参数分页，但是这是 有限制的 。 要记住需要传递信息给协调节点的每个分片必须先创建一个 from + size 长度的队列，协调节点需要根据 number_of_shards * (from + size) 排序文档，来找到被包含在 size 里的文档。
取决于你的文档的大小，分片的数量和你使用的硬件，给 10,000 到 50,000 的结果文档深分页（ 1,000 到 5,000 页）是完全可行的。但是使用足够大的 from 值，排序过程可能会变得非常沉重，使用大量的CPU、内存和带宽。因为这个原因，我们强烈建议你不要使用深分页。
实际上， “深分页” 很少符合人的行为。当2到3页过去以后，人会停止翻页，并且改变搜索标准。会不知疲倦地一页一页的获取网页直到你的服务崩溃的罪魁祸首一般是机器人或者web spider。

#### 游标查询 
scroll查询可以用来对 Elasticsearch 有效地执行大批量的文档查询，而又不用付出深度分页那种代价。
使用游标查询需要分两步：
1. 启用游标查询
```
curl -X GET "localhost:9200/my_store/_search?scroll=1m&pretty" -H 'Content-Type: application/json' -d'{
  "size": 2
}'
```
*这个查询的返回结果包括一个字段 `_scroll_id`， 它是一个base64编码的长字符串。*

2. 传递字段 `_scroll_id` 到 `_search/scroll `查询接口获取下一批结果
```
curl -X GET "localhost:9200/_search/scroll?pretty" -H 'Content-Type: application/json' -d'{
    "scroll": "1m",
    "scroll_id" : "FGluY2x1ZGVfY29udGV4dF91dWlkDXF1ZXJ5QW5kRmV0Y2gBFlZEcWhQNWlRVENDVzRMNXl2c3RNX1EAAAAAAAAAhhZHMHVJT195N1FieTNmVUtpRWhBMGF3"
}
'
```

*具体操作参见手册：https://www.elastic.co/guide/cn/elasticsearch/guide/current/scroll.html#scroll*

#### 精确值查找
在my_store索引下查找price为20的products
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
constant_score 表示以非评分模式执行
filter 表示使用过滤器

组合过滤 bool （布尔）过滤器是个 复合过滤器（compound filter） ，它可以接受多个其他过滤器作为参数，并将这些过滤器结合成各式各样的布尔（逻辑）组合。一个 bool 过滤器由三部分组成：
- must
所有的语句都 必须（must） 匹配，与 AND 等价。
- must_not
所有的语句都 不能（must not） 匹配，与 NOT 等价。
- should
至少有一个语句要匹配，与 OR 等价。

bool 过滤器本身仍然还只是一个过滤器。 这意味着我们可以将一个 bool 过滤器置于其他 bool 过滤器内部。
```
curl -X GET "localhost:9200/my_index/blog/_search?pretty" -H 'Content-Type: application/json' -d'
{
   "query" : {
      "constant_score" : {
         "filter" : {
            "bool" : {
              "should" : [
                { "term" : {"title" : "My second blog entry"}}, 
                { "bool" : { 
                  "must" : [
                    { "term" : {"date" : "2014/01/01"}}, 
                    { "term" : {"user_id" : 1}} 
                  ]
                }}
              ]
           }
         }
      }
   }
}
'
```

#### 自定义映射
在上述的查询过程中，由于自动映射中productID为text类型，es将其进行了分词，所以我们用 term 查询查找精确值 XHDK-A-1293-#fJ3 的时候，找不到任何文档。显然这种对 ID 码或其他任何精确值的处理方式并不是我们想要的。es7提供了一种数据类型 keyword 专门处理这种需求。
> `keyword`, which is used for structured content such as IDs, email addresses, hostnames, status codes, zip codes, or tags.

因此我们需要删除原来索引，重新创建一个自定义映射的索引：
```
curl -X DELETE "localhost:9200/my_store?pretty"
curl -X PUT "localhost:9200/my_store?pretty" -H 'Content-Type: application/json' -d'
{
    "mappings" : {
        "properties" : {
            "productID" : {
                "type" : "keyword"
            }
        }
    }
}
'
```
es7以后，默认的tyep使用 `_doc`，所以索引文档时我们需要使用 `_doc` 代替以前type的位置：
```
curl -X POST "localhost:9200/my_store/_doc/_bulk?pretty" -H 'Content-Type: application/json' -d'
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
最后进行查询就能通过productID匹配了。
```
curl -X GET "localhost:9200/my_store/_doc/_search?pretty" -H 'Content-Type: application/json' -d'
{
   "query" : {
      "constant_score" : {
         "filter" : {
            "bool" : {
              "should" : [
                { "term" : {"price" : 30}}, 
                { "bool" : { 
                  "must" : [
                    { "term" : {"productID" : "XHDK-A-1293-#fJ3"}}, 
                    { "term" : {"price" : 20}} 
                  ]
                }}
              ]
           }
         }
      }
   }
}
'
```

#### 多值匹配
当匹配多个精确值时，es提供了terms用以简化请求。同时一定要了解 term 和 terms 是 包含（contains） 操作，而非 等值（equals） （判断）。下列查询会得到价格为20或30的商品。
```
curl -X GET "localhost:9200/my_store/products/_search?pretty" -H 'Content-Type: application/json' -d'
{
    "query" : {
        "constant_score" : {
            "filter" : {
                "terms" : { 
                    "price" : [20, 30]
                }
            }
        }
    }
}
'
```

#### 全文检索
```
curl -X GET "localhost:9200/my_index/my_type/_search?pretty" -H 'Content-Type: application/json' -d'
{
    "query": {
        "match": {
            "title": "BROWN DOG!"
        }
    }
}
'
```
使用 operator 控制精度
```
curl -X GET "localhost:9200/my_index/my_type/_search?pretty" -H 'Content-Type: application/json' -d'
{
    "query": {
        "match": {
            "title": {      
                "query":    "BROWN DOG!",
                "operator": "and"
            }
        }
    }
}
'
```
使用minimum_should_match参数控制精度：
```
curl -X GET "localhost:9200/my_index/my_type/_search?pretty" -H 'Content-Type: application/json' -d'
{
  "query": {
    "match": {
      "title": {
        "query":                "quick brown dog",
        "minimum_should_match": "75%"
      }
    }
  }
}
'
```

#### 组合查询
组合查询和组合过滤器功能类似，只有一个重要区别。组合查询的 should 语句不必包含所有词项，但是如果包含，会得到更高的评分。并且可以通过minimum_should_match参数控制精度，它既可以是一个绝对的数字，又可以是个百分比。
```
curl -X GET "localhost:9200/my_index/my_type/_search?pretty" -H 'Content-Type: application/json' -d'
{
  "query": {
    "bool": {
      "should": [
        { "match": { "title": "brown" }},
        { "match": { "title": "fox"   }},
        { "match": { "title": "dog"   }}
      ],
      "minimum_should_match": 2 
    }
  }
}
'
```

#### 控制权重
通过指定 boost 来控制任何查询语句的相对的权重， boost 的默认值为 1 ，大于 1 会提升一个语句的相对权重。
```
curl -X GET "localhost:9200/_search?pretty" -H 'Content-Type: application/json' -d'
{
    "query": {
        "bool": {
            "must": {
                "match": {  
                    "content": {
                        "query":    "full text search",
                        "operator": "and"
                    }
                }
            },
            "should": [
                { "match": {
                    "content": {
                        "query": "Elasticsearch",
                        "boost": 3 
                    }
                }},
                { "match": {
                    "content": {
                        "query": "Lucene",
                        "boost": 2 
                    }
                }}
            ]
        }
    }
}
'
```
#### 最佳匹配
使用 dis_max 即分离 最大化查询（Disjunction Max Query）。将任何与任一查询匹配的文档作为结果返回，但只将最佳匹配的评分作为查询的评分结果返回。tie_breaker参数则提供一种 dis_max 和 bool 之间的折中选择，将其他匹配语句的评分也考虑其中。可以是 0 到 1 之间的浮点数，其中 0 代表使用 dis_max 最佳匹配语句的普通逻辑， 1 表示所有匹配语句同等重要。
```
curl -X GET "localhost:9200/my_index/my_type/_search?pretty" -H 'Content-Type: application/json' -d'
{
  "query": {
    "dis_max": {
      "queries": [
        { "match": { "title": "brown fox" }},
        { "match": { "body": "brown fox"   }}
      ],
      "tie_breaker": 0.3
    }
  }
}
'
```

#### 多字段
所有的 `_core_field` 类型 (strings, numbers, Booleans, dates) 接收一个 fields 参数，该参数允许你转化一个简单的映射。

#### 自动补全
completion suggester
https://www.elastic.co/guide/en/elasticsearch/reference/5.6/search-suggesters-completion.html

#### n-gram 与 shingles（瓦片词）

特殊名词：
- unigram 一元语言模型(n=1)
- bigram 二元语言模型(n=2)
- trigram 三元语言模型(n=3)

