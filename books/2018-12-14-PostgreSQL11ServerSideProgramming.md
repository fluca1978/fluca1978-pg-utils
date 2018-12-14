PostgreSQL 11 Server Side Programming - Quick Start Guide
---

Near the end of November, Packt published the book **[PostgreSQL 11 Server Side Programming Quick Start Guide](https://www.packtpub.com/big-data-and-business-intelligence/postgresql-11-server-side-programming-quick-start-guide)**, authored by [Luca Ferrari (fluca1978)](https://fluca1978.github.io).

<br/>
<br/>
<center>
<a href="https://www.packtpub.com/big-data-and-business-intelligence/postgresql-11-server-side-programming-quick-start-guide" >
<img src="https://dz13w8afd47il.cloudfront.net/sites/default/files/imagecache/ppv4_main_book_cover/B11208.png" alt="PostgreSQL 11 Server Side Programming Book" />
</center>
<br/>
<br/>

Following a consolidated tradition, Packt is producing more and more books on PostgreSQL and related technologies, and this is the first one that covers aspects about the freshly released *PostgreSQL 11* version.

Nevertheless, this does not mean that the book is *only* for PostgreSQL 11 users and administrators: it covers topics, concepts and provide examples that can be use as-is or ported to older versions of PostgreSQL, as well as probably to newer ones. In fact, while the book code examples have been tested against a PostgreSQL 11 cluster, only the examples related to the new object `PROCEDURE`, introduced by PostgreSQL 11, are strongly tied to such a version.

This book is a *Quick Start Guide*, and therefore it has a very practical approach to a limited scope, and only that. Therefore the book assumes you are able to install, manage and run a PostgreSQL 11 cluster, that you know how to connect and how to handle basic SQL statements. A basic knowledge in general programming is also required.

The book consists of 10 chapters, each focusing on a particular aspect of developing and deploying code within a PostgreSQL cluster. The main programming language used in the book is **`PL/pgSQL`**, the default procedural language for PostgreSQL; however several examples are rewritten using **`Perl 5`** and **`Java`** in order to demonstrate how it is possible to use also other "foreign" languages. In fact, one of the cool features of PostgreSQL since a lot is to be able to run code written in other non-SQL based languages directly within the cluster. But not all languages are equal: some of them require a deployment workflow, while others begin script-based allows you to directly *inject* the code into the cluster as you type it. Here the choice of using `PL/Java` to show how a deployable language works, as opposite to `PL/Perl` that being script-based can be typed directly within a database connection.

More in details, the book chapters are the followings:

- *Chapter 1*, **Introduction to Server Side Programming** presents the basic concepts behind the server-side programming, what it means with regard to PostgreSQL, how this great database support the paradigm and shows the example database used along the whole book.

- *Chapter 2*, **Query Tricks** provides you hints about advanced SQL statements that can help you solve day-by-day tasks without requiring a stand-alone program. As an example, discovering auto-assigned keys or computed fields (e.g., dates or timestamps) and performing recursion on a dataset.

- *Chapter 3*, **The PL/pgSQL Language** details the syntax and workflow of a piece of `PL/pgSQL` language, the default language in PostgreSQL to write SQL-like statements, iterations, conditionals and manage variables, exceptions and other programming stuff. The chapter takes you directly to the language usage via the `DO` statement, that allows you to execute code on a database connection directly.

- *Chapter 4*, **Stored Procedures** tells you how to *store* the code in the database for later execution and reuse. The chapter details both main type of stored procedures: `FUNCTION`s, the old well known objects, and `PROCEDURE`s, the new PostgreSQL 11 objects able to interact with a transaction. 

- *Chapter 5*, **PL/Perl and PL/Java** shows how to implement stored procedures (both `FUNCTION`s and `PROCEDURE`s) using either Perl 5 or Java. As already stated, the concepts are general enough to apply the implementation to other foreign languages.



- *Chapter 6*, **Triggers** shows you how to use `FUNCTION`s to react to data events, like changes against a table. Both Data Manipulation Triggers (DML Triggers) and Data Definition Triggers (DDL Triggers) are detailed and examples are shown in all the three book languages (`PL/pgSQL`, `PL/Perl`, `PL/Java`).

- *Chapter 7*, **Rules and the Query Rewriting System** provides hint about the path of a statement and the way it is possible to alter it on the fly to perform statement manipulation even before a trigger fires.

- *Chapter 8*, **Extensions** tells you how to organize your code in a way PostgreSQL can easily handle, from installation to ugprade. A glance at the PostgreSQL Extension Network (PGXN) and the search infrastructure (PGXS) is provided, as well as some practical examples about how to write an extension from scratch or use an already existing extension.

- *Chapter 9*, **Intra-Process Communications** tells you about how PostgreSQL can make two different *backend* process communicate via `LISTEN` and `NOTIFY`, providing examples on how even external application (and processes) can be notified of events. The chapter then continues showing a skeleton implementation of the *Background Workers*, custom processes that can be plugged into a cluster and run as part of it.


- *Chapter 10*, **Custom Data Types** shows you how to extend the PostgreSQL already rich data types and create your own, from adding SQL enumerations to implementing a whole custom data type.

