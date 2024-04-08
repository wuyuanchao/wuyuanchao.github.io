---
title: "Spring Transaction Propagation"
weight: 1
# bookFlatSection: false
# bookToc: true
# bookHidden: false
# bookCollapseSection: false
# bookComments: false
# bookSearchExclude: false
---

https://docs.spring.io/spring-framework/docs/current/reference/html/data-access.html#tx-propagation-required

#### PROPAGATION_REQUIRED
如果inner transaction scope 标记了回滚，那么就会影响到全局。

> When the propagation setting is PROPAGATION_REQUIRED, a logical transaction scope is created for each method upon which the setting is applied. Each such logical transaction scope can determine rollback-only status individually, with an outer transaction scope being logically independent from the inner transaction scope. In the case of standard PROPAGATION_REQUIRED behavior, all these scopes are mapped to the same physical transaction. So a rollback-only marker set in the inner transaction scope does affect the outer transaction’s chance to actually commit.

#### PROPAGATION_REQUIRES_NEW
每个事务范围都对应一个独立的物理事务。
> PROPAGATION_REQUIRES_NEW, in contrast to PROPAGATION_REQUIRED, always uses an independent physical transaction for each affected transaction scope, never participating in an existing transaction for an outer scope. In such an arrangement, the underlying resource transactions are different and, hence, can commit or roll back independently, with an outer transaction not affected by an inner transaction’s rollback status and with an inner transaction’s locks released immediately after its completion.

#### PROPAGATION_NESTED
使用具有多个可以回滚的保存点(savepoint)的单个物理事务。
> PROPAGATION_NESTED uses a single physical transaction with multiple savepoints that it can roll back to. Such partial rollbacks let an inner transaction scope trigger a rollback for its scope, with the outer transaction being able to continue the physical transaction despite some operations having been rolled back. This setting is typically mapped onto JDBC savepoints, so it works only with JDBC resource transactions. 


