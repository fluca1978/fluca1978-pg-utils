PostgreSQL 11 Server Side Programming - Quick Start Guide
---

<br/>
<br/>
<center>
<a href="https://www.packtpub.com/big-data-and-business-intelligence/postgresql-11-server-side-programming-quick-start-guide" >
<img src="https://dz13w8afd47il.cloudfront.net/sites/default/files/imagecache/ppv4_main_book_cover/B11208.png" alt="PostgreSQL 11 Server Side Programming Book" />
</a>
</center>
<br/>
<br/>

Following a consolidated tradition, Packt is producing more and more books on PostgreSQL and related technologies, and this is the first one that covers aspects about the freshly released *PostgreSQL 11* version.

Nevertheless, this does not mean that the book is *only* for PostgreSQL 11 users and administrators: it covers topics, concepts and provide examples that can be use as-is or ported to older versions of PostgreSQL, as well as probably to newer ones. In fact, while the book code examples have been tested against a PostgreSQL 11 cluster, only the examples related to the new object `PROCEDURE`, introduced by PostgreSQL 11, are strongly tied to such a version.

This book is a *Quick Start Guide*, and therefore it has a very practical approach to a limited scope, and only that. Therefore the book assumes you are able to install, manage and run a PostgreSQL 11 cluster, that you know how to connect and how to handle basic SQL statements. A basic knowledge in general programming is also required.

Questo libro è una *Quick Start Guide*, ovvero un libro conciso e specifico su un insieme limitato di argomenti. Il libro si riferisce a PostgreSQL 11, rilasciato a fine 2018, tuttavia molti degli esempi e dei concetti sono applicabili a qualunque versione precedente e/o successiva di questo potente database.

Il libro consiste di 10 capitoli che illustrano, passo passo, sulla programmazione all'interno di un database PostgreSQL. Il linguaggio principale utilizzato è `PL/pgSQL`, il default nel mondo PostgreSQL per l'implementazione di funzioni, procedure e conseguentemente trigger e altre funzionalità. Tuttavia vengono mostrati anche linguaggi esterni, come ad esempio `Perl 5` e `Java` al fine di mostrare la potenza e flessibilità di PostgreSQL, che accetta anche linguaggi di programmazione differenti, nonché la differenza a livello di deployment di tali linguaggi esterni.

Gli esempi del libro si articolano su un database di *digital assesment* minimale e il codice sorgente degli esempi è disponibile sul [repository GitHub ufficiale](https://github.com/PacktPublishing/PostgreSQL-11-Quick-Start-Guide).

Segue un elenco dettagliato del contenuto di ogni capitolo:

- *Capitolo 1*, **Introduction to Server Side Programming** introduce il lettore ai concetti base circa la programmazione lato server, cosa questo significhi e come PostgreSQL renda possibile eseguire programmi "localmente" ai dati memorizzati.

- *Capitolo 2*, **Query Tricks** mostra alcuni "trucchi" che PostgreSQL mette a disposizione degli utenti per svolgere compiti comuni, come ad esempio ottenere valori generati dinamicamente da una query, combinare query fra loro e percorrere strutture dati ricorsive.

- *Capitolo 3*, **The PL/pgSQL Language** introduce il linguaggio procedurale di default per l'implementazione di blocchi di codice iterativi all'interno di PostgreSQL. Si utilizza il costrutto `DO` per l'esecuzione immediata del codice, vengono mostrate le variabili, gli ambiti di visibilità delle stesse, le eccezioni, le iterazioni e altre caratteristiche generali del linguaggio.


- *Capitolo 4*, **Stored Procedures** mostra come utilizzare il linguaggio `PL/pgSQL` per realizzare funzioni, ovvero blocchi di codice richiamabili da una query o da altri blocchi di codice. Vengono mostrate le classiche `FUNCTION` e le nuove `PROCEDURE` le quali permettono di controllare la transazione corrente.

- *Capitolo 5*, **PL/Perl and PL/Java** introduce i due linguaggi esterni e mostra come utilizzarli direttamente all'interno di PostgreSQL per implementare funzioni (sia `FUNCTION` che `PROCEDURE`).

- *Capitolo 6*, **Triggers** illustra come utilizzare il codice contenuto in una `FUNCTION` per "reagire" ad eventi di modifica dei dati o delle strutture (es. tabelle). Gli esempi mostrati includono codice scritto in linguaggio `PL/pgSQL`, `PL/Perl` e `PL/Java`.

- *Capitolo 7*, **Rules and the Query Rewriting System** introduce il lettore alla possibilità di "intercettare" le query e modificarle al volo per trasformarle, entro certi limiti, in query combinate o query totalmente differenti.

- *Capitolo 8*, **Extensions** presenta i concetti generali di una estensione, l'unità minima di pacchetizzazione di un software installabile all'interno del server PostgreSQL. Viene mostrato un esempio di costruzione di estensione da zero, nonché i metodi di utilizzo delle estensioni presenti nell'ecosistema.


- *Capitolo 9*, **Intra-Process Communications** spiega come interagire con i processi PostgreSQL, sia dal punto di vista della comunicazione fra sessioni distinte che l'implementazione di processi ausiliari soggetti al ciclo di vita del cluster.

- *Capitolo 10*, **Custom Data Types** illustra come estendere i tipi di dato già presenti in PostgreSQL e come crearne di nuovi, con relativi operatori di confronto.


