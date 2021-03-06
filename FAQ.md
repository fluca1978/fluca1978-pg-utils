# What are these scripts?

This is a list of scripts I used to teach and explain some PostgreSQL related concepts.
The main idea is to allow users to reproduce on their own installation the explained 
concept without having to copy and paste each command line by line.

# On which operating system can I run the scripts?

All the scripts have been written as much portable as possible. Almost every script
has been written to be run in a Bourne Shell; some scripts rely on Perl to execute.
All the scripts have been tested on a FreeBSD system 8.2-RELEASE.

# On which PostgreSQL can I run the scripts?

All the examples, demos, scripts have been run against PostgreSQL 9.1.2 on i386-portbld-freebsd8.2, compiled by cc (GCC) 4.2.1 20070719  [FreeBSD], 32-bit, or higher.
Most notably, all the `examples` subdirectory has been tested against 9.6 and 10 versions.


# Why are some scripts numbered?

The number of each script is tied to the logical sequence I introduce arguments.
Sometime the execution of a script is related to the previous execution of the
minor number script(s). For instance, in order to execute the demo 01-, 02, etc. you
have at least to execute the setup scripts 00-*.

# Why are these scripts so simple?

They are here for didactic purposes, not for professional usage. Think they are 
a starting point for you to produce your solid-as-rock derivates.

# Why many scripts reproduce the same stuff? Is not better to use functions and
  chain scripts to avoid code duplication?

This is not a scripting contest! The idea is that each script must be self contained
and that has to clearly show to the user which commands and statements must be run
in order to produce the final result. Moreover I want scripts to be copy-and-paste
ready to exactly see what is going on without having to open another file or
inspect a function.