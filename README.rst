Dependencies
------------

MongoLog itself depends on MongoDB (of course) and the Perl bindings. The
scripts to filter and format logs are in Python and thus depend on the Python
bindings.

MongoDB (package: mongodb) is in Ubuntu as of Lucid. The Python
bindings (python-pymongo) are available as of Maverick. The Perl bindings
(libmongodb-perl) will be available starting in Oneiric. If you are running an
insufficiently new version of Ubuntu,
http://www.mongodb.org/display/DOCS/Ubuntu+and+Debian+packages or
http://web.onassar.com/blog/2011/01/19/installing-mongodb-on-ubuntu-10-10/ may
be useful if you want packages to install.


Installing
----------

To install the module, you need to symlink the reposity in to
``~/.owl/modules/MongoLog/`` (so the path to the module source file will be
``~/.owl/modules/MongoLog/lib/BarnOwl/Module/MongoLog.pm``). You may also want
symlink ``scripts/mongolog`` into your path. ``mongolog foo`` calls the
appropriate ``mongolog-foo`` command in the ``scripts`` directory, similarly
to how ``git`` operates. To add new ``mongolog`` subcommands, you can either
add to the ``scripts`` directory or place them anywhere in your path.

Configuring
-----------

To configure MongoLog in BarnOwl, you can set the ``mongolog:enable`` (default:
off), ``mongolog:host`` (default: ``localhost:41803``), ``mongolog:database`` (default:
``barnowl``), ``mongolog:username`` (default: none), or ``mongolog:password`` (default:
none) variables.

Alternatively, if you create a file called ``~/.owl/mongolog.json``, the
BarnOwl module will automatically load any parameters specified there. (In
particular, it will copy them to the corresponding BarnOwl variables on
startup. You can override them per-session with the ``:set`` command as usual.)

For example, one valid ``~/.owl/mongolog.json`` would be::

    {
        "mongolog" : {
            "host" : "localhost",
            "database" : "barnowl",
            "username" : "foo",
            "password" : "bar"
        }
    }


If you wish to use ``scripts/mongolog-filter``, you will need to create ``~/.owl/mongolog.json``.

``mongolog`` subcommands
------------------------

``filter``
  ``filter`` retrieves log entries from the database and dumps them as JSON to
  ``stdout``. It takes various options to limit what gets displayed.
``format``
  ``format`` takes JSON documents on ``stdin``, and formats them according to
  one of two predefined formats --- ``log``, which looks like a normal BarnOwl
  log entry; and ``style:default``, which looks somewhat similar to the default
  BarnOwl style. To select which style, either pass it as the first argument on
  the commandline, or define the ``default_format`` key in your
  ``~/.owl/mongolog.json``.
``latest``
  ``latest`` just pipes ``filter`` into ``format`` for you. ``filter`` is run
  with ``--limit 20`` and any arguments that you provide on the commandline of
  ``latest``. ``format`` will be run with no arguments. If you prefer
  ``style:default``, this means you may want to set your ``default_format``.

Tuning
------

You may find that running ``mongolog filter`` is a bit slow. I found adding
indices to improve matters substantially::

    db.messages.ensureIndex({"time": 1})
    db.messages.ensureIndex({"class": 1})

Even after, it was a little on the slow side, but the indices made it better
--- times dropped from about two seconds to about 3/4 second in my highly
unscientific test.
