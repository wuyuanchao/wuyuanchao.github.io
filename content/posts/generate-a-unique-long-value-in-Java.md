---
title: "How do you generate a unique long value in Java?"
date: 2024-07-20T16:03:58+08:00
# bookComments: false
# bookSearchExclude: false
---

The first question you need to think about, is how unique is unique? Unique across multiple threads? Across multiple runs of the program? Across multiple JVMs? Across multiple computers? How frequently will they be needed?

Don’t reinvent the wheel if you can possibly avoid it. Java’s java.util.UUID class can give you a unique ID within that JVM. If you want a long, you can use something like UUID.randomUUID().getMostSignificantBits().

If you’re using any kind of database, it will almost certainly have a method for getting unique IDs which are most often longs. These work by storing a “high water mark” in the database, which is atomically incremented when you ask for the next ID. (Or incremented in blocks, for greater efficiency.) For a client-server database, this will work across multiple JVMs. If you need a unique ID across multiple JVMs, then you’re going to need something that can talk between them in any case; so use a free, lightweight database to do this instead of writing your own implementation from scratch!

That covers most use-cases, but if you’re working with embedded systems, and can’t spare the memory to run a database, but still need a globally unique ID, use the system clock combined with the nanosecond timer; and, if it needs to be unique across many systems, include the motherboard ID.
