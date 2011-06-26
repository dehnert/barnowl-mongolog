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
add ``scripts`` to your path, or symlink ``scripts/filter-log`` and
``scripts/format-log`` into a directory in your path.

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


If you wish to use ``scripts/filter-log``, you will need to create ``~/.owl/mongolog.json``.
