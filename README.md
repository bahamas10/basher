Basher
======

Configuration Management in Bash

> not complicated enough to attract attention&trade; - [@mikeal](https://twitter.com/mikeal/status/443819733255598080)

`basher` is configuration management without the complication.  It is a single
bash script that is responsible for running other scripts (bash or other)
that do things like install software, start services, create users, etc.

It's just bash, so it should work on any Unix or Unix-like operating system.

- [Quick Start Guide](#quick-start-guide)
- [How It Works](#how-it-works)
- [Examples](#examples)
- [Dependencies](#dependencies)
- [Configuration](#configuration)
- [Plugins](#plugins-1)
- [FAQ / Concerns](#faq--concerns)
- [Contributing / Style](#contributing--style)
- [License](#license)


Quick Start Guide
-----------------

### Install Basher

Run the following commands to install `basher`.  Change the path as appropriate for
your environment.

**Note:** `sudo` or escalated privileges may be required.

    curl https://raw.github.com/bahamas10/basher/master/basher -o /opt/local/bin/basher
    chmod +x /opt/local/bin/basher

...and it's installed.

### Install Plugins

The next step is to clone down the template `basher-repo` (found here
https://github.com/bahamas10/basher-repo) by running the following command below.
This repo contains the plugins (scripts) that are available for use by
`basher`.

**Note:** If you have forked this repo, or have your own repo, substitute your `git`
url into the command below.

    git clone https://github.com/bahamas10/basher-repo /var/basher

The final step is to create a basic configuration file that tells `basher`
that the repo is installed to `/var/basher`.  If you skip this step, you
will need to pass the directory into `basher` with `-d /var/basher`.

    echo 'BASHER_DIR=/var/basher' > /etc/basher.conf

Again, escalated privileges may be required for this step.

Lastly, test out `basher` by running the `test` plugin.

    $ basher -f test
    [2014-03-25T02:18:25-0400] main  INFO: running as dave on bahamas10.local in /var/basher (pid 29426)
    [2014-03-25T02:18:25-0400] main  INFO: 1 plugin - [test]
    [2014-03-25T02:18:25-0400] main  INFO: loading plugin test
    [2014-03-25T02:18:25-0400] main->test->index  INFO: it works!
    [2014-03-25T02:18:25-0400] main  INFO: finished test successfully
    [2014-03-25T02:18:25-0400] main  INFO: run finished in 0 seconds

And from the output we can see that it works!

**Note:** `-f` in the above example tells `basher` to skip lockfile creation at
`/var/run/basher.pid`, so it can be run without escalated privileges.

How It Works
------------

`basher` is a single bash script, that is responsible for running other scripts
called plugins.

### Plugins

Plugins are simply shell scripts (not necessarily bash) or programs that
perform a specific job, such as to install software, create users, manage
services, etc.

For instance, you could have a plugin called `rsyslog` whose job it is to install,
configure, and start `rsyslogd` on a server.

It's also possible to make helper plugins that do nothing when run directly.  For instance,
you could have a plugin called `aptitude` whose job it is to define helper functions
that wrap `apt-get` and add `basher` style logging and error-checking logic. This way
they can then be sourced by other plugins, like the `rsyslog` plugin mentioned above
to allow for code reuse.

Plugins are executed in their own subshell environment, so they can **not** modify
the running environment of the `basher` process, and are free to call `exit` or similar
without killing the entire `basher` process.  In fact, the exit code of your plugin
is used to determine if it was successfully run or not.  A non-successful plugin will
cause the `basher` process to halt execution and terminate.

In the quick start the `basher-repo` was cloned to `/var/basher`.  This repo
contains a `plugins/` directory which contains the plugins that can be used
by `basher`.

---

The command line operands tell `basher` which plugins to run.  For example

    $ basher test

...tells basher to run the `test` plugin, while

    $ basher node rsyslog

...tells basher to run the `node` plugin followed by the `rsyslog` plugin,
halting execution if anything fails.

You can specify plugins to run in the config file, `/etc/basher.conf` to be
run when `bahser` is run without any operands.  For example

    BASHER_PLUGINS=(test node rsyslog)

Will cause `basher` to run `test`, `node`, and `rsyslog`, in that order, when
it is called on the command line with no operands.

Examples
--------

Try running the advanced version of the `test` plugin to make sure some
of the fancier features of `basher` are working.

    $ basher test/all
    [2014-03-25T02:42:54-0400] main  INFO: running as dave on bahamas10.local in /var/basher (pid 30215)
    [2014-03-25T02:42:54-0400] main  INFO: 1 plugin - [test/all]
    [2014-03-25T02:42:54-0400] main  INFO: loading plugin test/all
    [2014-03-25T02:42:54-0400] main->test->all  INFO: loaded test item
    [2014-03-25T02:42:54-0400] main->test->all  INFO: testing log messages
    [2014-03-25T02:42:54-0400] main->test->all ERROR: > some error
    [2014-03-25T02:42:54-0400] main->test->all  WARN: > some warn
    [2014-03-25T02:42:54-0400] main->test->all  INFO: > some info
    [2014-03-25T02:42:54-0400] main->test->all  INFO: > some log
    [2014-03-25T02:42:54-0400] main->test->all  INFO: running in /var/basher/plugins/test as dave
    [2014-03-25T02:42:54-0400] main->test->all  INFO: basher version v0.0.0
    [2014-03-25T02:42:54-0400] main->test->all  INFO: uname Darwin
    [2014-03-25T02:42:54-0400] main->test->all  INFO: finished
    [2014-03-25T02:42:54-0400] main  INFO: finished test/all successfully
    [2014-03-25T02:42:54-0400] main  INFO: run finished in 0 seconds

And the `fs` portion of the `test` plugin can be used to see if `put_file()` and
`put_template()` (`erb` templating) are working.

    $ basher test/fs
    [2014-03-25T02:44:20-0400] main  INFO: running as dave on bahamas10.local in /var/basher (pid 30419)
    [2014-03-25T02:44:20-0400] main  INFO: 1 plugin - [test/fs]
    [2014-03-25T02:44:20-0400] main  INFO: loading plugin test/fs
    [2014-03-25T02:44:20-0400] main->test->fs  INFO: put_file :: files/hello-world1.txt -> /tmp/hello-world1.txt
    diff: /tmp/hello-world1.txt: No such file or directory
    [2014-03-25T02:44:20-0400] main->test->fs  INFO: put_template :: templates/hello-world2.txt.erb -> /tmp/hello-world2.txt
    diff: /tmp/hello-world2.txt: No such file or directory
    [2014-03-25T02:44:20-0400] main->test->fs  INFO: put_template :: templates/hello-world3.txt.erb -> /tmp/hello-world3.txt
    diff: /tmp/hello-world3.txt: No such file or directory
    [2014-03-25T02:44:20-0400] main  INFO: finished test/fs successfully
    [2014-03-25T02:44:20-0400] main  INFO: run finished in 0 seconds

Now, running the plugin again, you can see that no action is taken for the
files that have not changed, and that a diff is printed for template that has
changed.

    $ basher test/fs
    [2014-03-25T02:44:21-0400] main  INFO: running as dave on bahamas10.local in /var/basher (pid 30491)
    [2014-03-25T02:44:21-0400] main  INFO: 1 plugin - [test/fs]
    [2014-03-25T02:44:21-0400] main  INFO: loading plugin test/fs
    [2014-03-25T02:44:21-0400] main->test->fs  INFO: put_file :: files/hello-world1.txt -> /tmp/hello-world1.txt
    [2014-03-25T02:44:21-0400] main->test->fs  INFO: put_template :: templates/hello-world2.txt.erb -> /tmp/hello-world2.txt
    [2014-03-25T02:44:21-0400] main->test->fs  INFO: put_template :: templates/hello-world3.txt.erb -> /tmp/hello-world3.txt
    --- /tmp/hello-world3.txt   2014-03-25 02:44:20.000000000 -0400
    +++ /tmp/basher-30491-2UCOkm    2014-03-25 02:44:21.000000000 -0400
    @@ -1,2 +1,2 @@
     Hello bahamas10.local!
    -The time is 2014-03-25 02:44:20 -0400
    +The time is 2014-03-25 02:44:21 -0400
    [2014-03-25T02:44:21-0400] main  INFO: finished test/fs successfully
    [2014-03-25T02:44:21-0400] main  INFO: run finished in 0 seconds

Dependencies
------------

Any posix compliant system **will** have the necessary tools installed to run this
software.  However, some optional dependencies are required for builtin convenience
functions like `put_template`, `git_repository`, etc. to work.

### required

- `bash` v3 or higher.
- `date(1)` - posix tool, required for all logging functions if bash is < v4

### posix tools used

- `cp(1)` - required for `put_file`
- `chmod(1)` - optionally needed for `put_file` and `put_template`
- `chown(1)` - optionally needed for `put_file` and `put_template`
- `diff(1)` - required for `put_file` and `put_template`
- `erb(1)` - ruby templating tool, required for `put_template`
- `mv(1)` - required for `put_template`

### optional

- `git(1)` - source control tool, required for `git_repository`
- `tput(1)` - used for colorizing output, will fail gracefully if not present

**Note:** `basher` doesn't attempt to check the version of bash running it.  Because
of this, if you attempt to run `basher` on any version less than the minimum
supported, it may or may not work.

Configuration
-------------

The config file is optional, see the [Example Config](example-basher.conf) for
more information.

The file should be located at `/etc/basher.conf`, and is simply a bash script that
will be sourced by `basher` when it is executed.

#### `BASHER_PLUGINS`

An array of plugins to run when `basher` is invoked.  These plugins will only
be executed if `basher` is run without any command line operands.

#### `BASHER_DATE_FORMAT`

The date string in `strftime(3)` format to be passed to `date(1)` or `printf`
for all logging functions.  The default is ISO 8601 format.

#### `BASHER_DIR`

The basher repo directory in which to run.  This directory should,
at the very least, have a `plugins/` directory.  This defaults to
`$PWD`, and can be overridden at runtime with `-d dir`.

In default installations, this should be set to `/var/basher`

#### `BASHER_LOCKFILE`

The lockfile to use when not run with `-f`.

Plugins
-------

Plugins without a name explicitly defined are assumed to be called `index`, much
like `index.html` for the web, or `index.js` for node.  For example:

    basher test test/all test/fs

Executes, in order:

    $BASHER_DIR/plugins/test/index
    $BASHER_DIR/plugins/test/all
    $BASHER_DIR/plugins/test/fs

Plugins are executed in their plugin directory, so for example the `rsyslog` plugin
will be executed in `$BASHER_DIR/plugins/rsyslog`, where it can access files,
templates, script, etc.  by using relative paths.

For example:

    basher foo

Will execute `cd "$BAHSER_DIR/plugins/foo && . index`.

### Logging

`basher` has log levels that are inspired by https://github.com/trentm/node-bunyan#levels.
See the [Functions](#functions) section below for more information and usage.

### Variables and Functions

#### Environmental Variables

These variables have been exported so they are available to all executing plugins,
and any scripts they `exec`.  Modifying these variables will not affect the running
`basher` process.

- `BASHER_DATE_FORMAT` - the date format in `strftime` format to be passed to `date(1)` or `printf` for logging
- `BASHER_DIR` - the basher directory where plugins are stored
- `BASHER_LOCKFILE` - the lockfile to use if `-f` is **not** supplied, defaults to `/var/run/basher.pid`
- `BASHER_VERBOSITY` - an integer representing the verbosity `basher` was started with
- `BASHER_VERSION` - the version of `basher` installed

#### Global Variables

These variables will be available to your plugins, but are not exported, so
they will not be available as environmental variables to executed scripts.

- `COLOR_RESET` - output of `tput sgr0`
- `COLOR_BOLD` - output of `tput bold`
- `COLOR_INVERSE` - output of `tput rev`
- `COLOR_BLACK` - output of `tput setaf 0`
- `COLOR_RED` - output of `tput setaf 1`
- `COLOR_GREEN` - output of `tput setaf 2`
- `COLOR_YELLOW` - output of `tput setaf 3`
- `COLOR_BLUE` - output of `tput setaf 4`
- `COLOR_MAGENTA` - output of `tput setaf 5`
- `COLOR_CYAN` - output of `tput setaf 6`
- `COLOR_WHITE` - output of `tput setaf 7`

**Note:** these variables will be empty if the terminal doesn't support colors

#### Functions

The following functions are available for logging purposes

- `fatal()`
- `error()`
- `warn()`
- `info()`
- `debug()`
- `trace()`
- `log()`

All logging functions have usage similar to `echo`.

- `log()` is an alias for `info()`
- `fatal()` will generate a log message and also force the process to exit with a code of 1.

---

- `color_diff()`

This function is a simple wrapper around `diff` that adds color around the output.
It has the same usage as `diff`, and produces the same exit codes.  Arguments
are passed to `diff` like:

    diff -u "$@"

---

- `put_file()`

This function has similar usage to `cp` or `mv`, except it only works with 2
options.  It `cp`'s `$1` to `$2`, only if there was a difference found between
the 2 files.

This function will fatal if the `cp` operation fails, return 0 if the files
differ and the new file was moved into place, and return 1 if the files were
the same.  This allows for code like:

``` bash
if put_file files/sshd_config /etc/ssh/sshd_config; then
     # files were different
     restart ssh
fi
```

`put_file()` will also show the output of `diff` to the terminal, so you can
see how the files differed if they did.

arguments

- `$1` - source file
- `$2` - destination file
- `$3` - [optional] mode to set file, passed to `chmod`
- `$4` - [optional] owner to set file, passed to `chown`

returns

- 0 - file was updated
- 1 - files were the same; nothing done

---

- `put_template()`

This function is almost identical to `put_file`, except it takes an
`erb` template as the first argument and automatically renders it.

This function will fatal if `erb` is not found

```
if put_template templates/sshd_config.erb /etc/ssh/sshd_config; then
    # files were different
    restart ssh
fi
```

arguments

- `$1` - erb template
- `$2` - destination file
- `$3` - [optional] mode to set file, passed to `chmod`
- `$4` - [optional] owner to set file, passed to `chown`

returns

- 0 - file was updated
- 1 - files were the same; nothing done

---

- `git_repository()`

Synchronize a git repository to the local filesystem.  This function
ensures the directory is created, and kept up-to-date against a specific
branch or tag (defaults to `master`).

    usage: git_repository <repo> <dir> [tag|branch]

`git_repository` will `fatal` if **anything** goes wrong.

``` bash
# ensure my dotfiles are in up-to-date in my home directory
git_repository git://github.com/bahamas10/dotfiles.git /home/dave/.dotfiles

# checkout the node.js source code to `/var/tmp` and compile it
git_repository git://github.com/joyent/node.git /var/tmp/node v0.10.10
(cd /var/tmp/node && ./configure --with-dtrace --prefix=/opt/local && make && make install) || fatal 'something failed'
```

2 line node.js install, ftw.

arguments

- `$1` - git url
- `$2` - destination directory (can be empty or an existing git directory)
- `$3` - [optional] branch|tag|commit to pass to `git checkout`

returns

- 0 - the repo was updated or created
- 1 - no update or `git pull` was needed on the repo; nothing changed

### Other Languages

It is possible to write your plugins in other languages, fairly easily.  Let's make
an example plugin called `polyglot`.

```
mkdir plugin/polyglot
cd plugins/polyglot
```

You can now create an `index` script that looks simply like this

`index`

```
exec node ./my_script.js
```

...and then `my_script.js` will be run as your plugin, allowing you to signify failure or success
by calling `process.exit()` with the appropriate return code.

FAQ / Concerns
--------------

#### I want to run `basher` as a limited user but it says Permission Denied when trying to create the lockfile

Short Answer: use `-f` to skip the lockfile logic in `basher`.

Long Answer: Change `BASHER_LOCKFILE` in the config to a path where the limited
user has read/write access.

#### Is there an easy way to test a single plugin I'm currently working on?

Yes.

You can use the `-t` option to specify a single (bash) script to execute
in the CWD.  For example:

    $ vim index
    ... edit ... edit ... edit ... <esc>:wq
    $ basher -t index

... this will execute `index` in the current directory for testing.  Note that lockfile
checking/creation will be skipped when `basher` is executed with `-t`.

#### I want to test my plugin without loading `/etc/basher.conf`, can this be done?

Yes.

Run `basher` like this:

    basher -c /dev/null

#### I want to use a fancy new bash feature that is not guaranteed to be available for bash v3

The best way to do this is to use feature detection rather than version snooping.  For
instance, if you want to use associate arrays, you can do something like this:

``` bash
if declare -A foo; then
    debug 'associative array created'
else
    fatal 'failed to create associative array'
fi
```

This way, your plugin will fail and halt execution of `basher` if the declaration
of the associative array fails.

#### How do I determine the path where my plugin is located?

`$PWD`.

A plugin is guaranteed, by `basher`, to be run out of its directory.  Also,
you can use `$BASHER_DIR`, which will point the directory out of which the `basher`
process is running.

#### Do I have to use `debug`, `log`, `put_file`, etc.? I just want to use scripts

Of course not.

Any bash script is already a valid `basher` plugin.  The logging functions automatically
add things like the date, log level, executing plugin name, and line number and filename
if `-vvvv` is supplied.

All functions provided by `bahser` are meant for nothing more than convenience.

#### I want certain plugins run on certain nodes based on X? Is that possible?

Yes.

Because `/etc/basher.conf` is just a bash script, you are free to load it up
with however much logic you want.  `basher` blocks until the entire config file
has been sourced.

For example, imagine this `/etc/basher.conf` file:

``` bash
# every node gets node.js
BASHER_PLUGINS=(node)

# only prod nodes get ssl certificates
re='^prod-'
if [[ $HOSTNAME =~ $re ]]; then
    BASHER_PLUGINS+=(ssl-certs)
fi

# on Saturday nodes get the party plugin!
dow=$(date +%w)
if ((dow == 6)); then
    BASHER_PLUGINS+=(party)
fi
```

You can even get really fancy, and retrieve a nodes plugin list from some database.

**Note:** Some error checking steps skipped for brevity

``` bash
# assume data like => {"plugins":["node","rsyslog"]}
BASHER_PLUGINS=( $(curl -sS "http://machinedatabase.com/nodes/$HOSTNAME" | json plugins | json -a) )
if (($? != 0)); then
    fatal 'failed to retrieve remote plugins list'
fi
```

All functions available to plugins are also available when the config is sourced.

#### Can I use `put_file`, `put_template`, etc. without exiting if they fail?

Yes.

These functions explicitly call `fatal`, which calls `exit`, which then causes
your plugin to terminate immediately, and finally `basher` to terminate shortly
after.  You can turn the `exit` call into, effectively, a `return` call by
wrapping it in a subshell.  Think of it like a try/catch block.

``` bash
# if `put_file` fails and fatals, the plugin will still continue executing
(put_file foo bar)

log 'we make it here no matter what!'
```

Contributing / Style
--------------------

Pull requests and creating issues are welcomed and encouraged.  However, I try to maintain
a style with bash that makes it safe and predictable.  The style guide is based on this wiki,
specifically this page.

http://mywiki.wooledge.org/BashGuide/Practices

If anything is not mentioned explicitly in this readme, it defaults to matching whatever
is outlined in the wiki.

Any pull request to the core `basher` script should adhere to this guide.

**Note:** Some of this style guide is based on personal aesthetic preference, and as
such, is happily up for debate.

### Quoting

Use double quotes for strings that require variable or command substitution
interpolation, and single quotes for all others.

``` bash
# right
foo='Hello World'
bar="You are $USER"

# wrong
foo="hello world"

# possibly wrong, depending on intent
bar='You are $USER'
```

All variables that will undergo word-splitting *must* be quoted (1).  If no splitting
will happen, the variable may remain unquoted.

``` bash
foo='hello world'

if [[ -n $foo ]]; then   # no quotes needed - [[ ... ]] won't word-split variable expansions
    echo "$foo"          # quotes needed
fi

bar=$foo  # no quotes needed - variable assignment doesn't word-split
```

1. The only exception to this rule is if the code or bash controls the variable for the
duration of its lifetime.  For instance, `basher` has code like:

``` bash
printf_date_supported=false
if printf '%()T' &>/dev/null; then
    printf_date_supported=true
fi

if $printf_date_supported; then
    ...
fi
```

Even though `$printf_date_supported` undergoes word-splitting in that example, we don't
use quotes because we control the contents of the variable.

Also, variables like `$$`, `$?`, `$#`, etc. don't required quotes because they will
never contain spaces, tabs, or newlines.

When in doubt, [quote all expansions](http://mywiki.wooledge.org/Quotes).

### Functions

Don't use the `function` keyword.  All variables created in a function must be made local.

``` bash
# wrong
function foo {
    i=foo # this is now global, wrong
}

# right
foo() {
    local i=foo # this is local, preferred
}
```

### Command Substitution

Use `$(...)` for command substitution.

``` bash
foo=`date`  # wrong
foo=$(date) # right
```

### Math / Integer Manipulation

Use `((...))` and `$((...))`.

``` bash
a=5
b=4

# wrong
if [[ $a -gt $b ]]; then
    ...
fi

# right
if ((a > b)); then
    ...
fi
```

Do **not** use the `let` command.

### Variable Declaration

Avoid uppercase variable names unless there's a good reason to use them.
Don't use `let` or `readonly` to create variables.  `declare` should *only*
be used for associative arrays.  `local` should *always* be used in functions.

```
# wrong
declare -i foo=5
let foo++
readonly bar='something'

# right
i=5
((i++))
bar='something'
```

### Block Statements

`then` should be on the same line as `if`, and `do` should be on the same line
as `while`.

``` bash
# wrong
if true
then
    ...
fi

# also wrong, though admittedly it looks kinda cool
true && {
    ...
}

# right
if true; then
    ...
fi
```

### Sequences

Use bash builtins for generating sequences

``` bash
n=10

# wrong
for f in $(seq 1 5); do
    ...
done

for f in $(seq 1 "$n"); do
    ...
done

# right
for f in {1..5}; do
    ...
done

for ((i = 0; i < n; i++)); do
    ...
done
```

### eval

Never.

### Miscellaneous

None of the things listed in the link below will be accepted in this code base.

http://mywiki.wooledge.org/BashPitfalls

This reference has examples on how to fix these issues.

License
-------

MIT License
