---
title: "Enterprise Java Beans"
weight: 1
# bookFlatSection: false
# bookToc: true
# bookHidden: false
# bookCollapseSection: false
# bookComments: false
# bookSearchExclude: false
---

### Enterprise Java Beans

EJB stands for Enterprise Java Beans.EJB is an essential part of a J2EE platform. 

EJB is primarily divided into three categories：
- Session Bean
Session bean stores data of a particular user for a single session. It can be stateful or stateless. It is less resource intensive as compared to entity bean. Session bean gets destroyed as soon as user session terminates.
- Entity Bean
Entity beans represent persistent data storage. User data can be saved to database via entity beans and later on can be retrieved from the database in the entity bean.
- Message Driven Bean
Message driven beans are used in context of JMS (Java Messaging Service). Message Driven Beans can consumes JMS messages from external entities and act accordingly.
