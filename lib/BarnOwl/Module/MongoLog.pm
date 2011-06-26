use local::lib;
use warnings;
use strict;

package BarnOwl::Module::MongoLog;
our $VERSION = 0.1;

use BarnOwl;
use BarnOwl::Hooks;

use boolean;
use DateTime;
use MongoDB;

use JSON;

our $messages = undef;

our $conffile = BarnOwl::get_config_dir() . "/mongolog.json";

sub fail {
    my $msg = shift;
    $messages = undef;
    BarnOwl::admin_message('MongoLog Error', $msg);
    die("MongoLog Error: $msg\n");
}

sub read_config {
    my $conffile = shift;
    my $cfg = {};
    if (open(my $fh, "<", "$conffile")) {
        my $raw_cfg = do {local $/; <$fh>};
        close($fh);

        eval { $cfg = from_json($raw_cfg); };
        if ($@) { BarnOwl::admin_message('ReadConfig', "Unable to parse $conffile: $@"); }
    } else {
        BarnOwl::message("Config file $conffile could not be opened.");
    }
    return $cfg;
}

sub load_config {
    my $prefix = shift;
    my $cfg = read_config($conffile);
    my $appconf = $cfg->{$prefix};
    my ($key, $value);
    while (($key, $value) = each(%$appconf))
    {
        BarnOwl::set($prefix . ":" . $key, $value);
    }
}

sub initialize {
    BarnOwl::new_variable_bool("mongolog:enable", {
        default => 0,
        summary => "turn MongoDB logging on or off",
        description => "If this is set, messages are logged to MongoDB " .
            "(with the MongoDB instance determined by the mongolog:host, " .
            "mongolog:database, mongolog:username, and mongolog:password " .
            "settings)."
    });

    BarnOwl::new_variable_string("mongolog:host", {
        default => "localhost:41803",
        summary => "Host (and port) to connect to MongoDB on"
    });

    BarnOwl::new_variable_string("mongolog:database", {
        default => "barnowl",
        summary => "Database name to attempt to connect to MongoDB with"
    });

    BarnOwl::new_variable_string("mongolog:username", {
        default => undef,
        summary => "Username to attempt to connect to MongoDB with"
    });

    BarnOwl::new_variable_string("mongolog:password", {
        default => undef,
        summary => "Password to attempt to connect to MongoDB with"
    });

    BarnOwl::new_command("mongolog:connect" => \&mongolog_connect, {
        summary => "Connect to MongoDB for logging",
        usage => "mongolog:connect"
    });

    load_config("mongolog");
}

sub mongolog_connect {
    my $quiet = shift;
    my ($conn, $db);
    my $host = BarnOwl::getvar("mongolog:host");
    my $username = BarnOwl::getvar("mongolog:username");
    my $password = BarnOwl::getvar("mongolog:password");
    my $database = BarnOwl::getvar("mongolog:database");
    eval {
        if(!$quiet)
        {
            BarnOwl::admin_message('MongoLog', "Attempting to connect to $host/$database/$username");
        }
        $conn = MongoDB::Connection->new(
            'host' => $host,
            username => $username,
            password => $password,
            db_name => $database,
        );
    };
    if ($@) {
        if(!$quiet)
        {
            fail("Unable to connect: $@");
        }
    }

    $db = $conn->get_database($database);
    $messages = $db->messages;
}

sub to_boolean {
    return not(defined $_[0]) ? false :
        "$_[0]" ? true : false;
}

sub handle_message {
    my $m = shift;
    if (BarnOwl::getvar("mongolog:enable") eq "off") {
        return;
    }
    if (!$messages) {
        # Try to connect
        mongolog_connect(1);
    }
    if (!$messages) {
        # If we still aren't connected, report that
        BarnOwl::message("MongoLog: not connected");
        return;
    }

    $m = {%{$m}};

    delete $m->{'id'};
    delete $m->{'deleted'};
    delete $m->{'zwriteline'};
    delete $m->{'isprivate'};
    delete $m->{'isauto'};
    if (exists($m->{'unix_time'})) {
        $m->{'time'} = DateTime->from_epoch(epoch => $m->{'unix_time'});
        delete $m->{'unix_time'};
    }

    foreach (qw/should_wordwrap private/) {
        if (exists($m->{$_})) {
            $m->{$_} = to_boolean($m->{$_});
        }
    }

    # I don't care about ZAUTH_FAILED vs. ZAUTH_NO, so I'm just going
    # to collapse them
    if (exists($m->{'auth'})) {
        $m->{'auth'} = to_boolean($m->{'auth'} eq 'YES');
    }

    if ($m->{'login'} eq 'none') {
        delete $m->{'login'};
    }

    if ($m->{'opcode'} eq '') {
        delete $m->{'opcode'};
    }

    $messages->insert($m);
}

initialize;

eval {
    $BarnOwl::Hooks::receiveMessage->add('BarnOwl::Module::MongoLog::handle_message');
};
if ($@) {
    $BarnOwl::Hooks::receiveMessage->add(\&handle_message);
}

1;
