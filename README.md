# Klocate
Klocate is a command-line tool used to locate files on a filesystem.
It is composed of two executables, `kudb` and `kl`.
It is written in Assembly, does not depend on any library, and is an imitation of the `plocate` tool.
## Usage
Build the two executables using the provided `build.sh` shell script.
Create the database at `[db]`, recursively from `[root]`:
```sh
$ kudb [root] [db]
```
The root defaults to `/` and the database location defaults to `/var/lib/klocate/db`.
Then locate files matching the `[query]` from the database at `[db]`:
```sh
$ kl [query] [db]
```
If no query is provided, it just lists the files recorded in the database, and the database location defaults to the same as with `kudb`.
## How it works
The filesystem is recursively explored by walker threads, each writing to their own temporary file (`memfd`), dynamically dispatching and executing work. Then the last thread to stop working 'untangles' the work of each thread, writing the results to the database (using `io_uring`).
It does not keep meta information about each file, neither does it update only the parts of the filesystem that have changed, like the `plocate` tool does.
## Intended command line arguments interface (future)
- `kudb` and `kudb [root]` will work
- `kudb` will accept arguments to control the output database location, the amount of threads used and the visibility it has on hidden files
- `kl` and `kl [query]` will work
- `kl` will accept arguments to control the query mode (regular expression, scope: filename / on the whole path, ...), the input database location, the amount of threads used and certain filtering options
- The `KLOCATE_DB_PATH` environment variable will be used to indicate (when present) the default location for the database)
## TODO
### `kudb`:
- add max directory recursion depth option
- add option to ignore hidden files and folders
- add option to filter certain directories that are irrelevant (`.git/`, build folders, ...)
- properly parse command line arguments and environment variables
### `kl`:
- implement query
- add max directory recursion depth option
- properly parse command line arguments and environment variables

