import json
import os
import pymongo

def read_config(filename=None):
    if filename is None:
        filename = "~/.owl/mongolog.json"
    fd = open(os.path.expanduser(filename), 'r')
    config = json.load(fd)
    return config['mongolog']

def db_connect(config):
    hostname = "localhost:41803"
    if 'host' in config:
        hostname = config['host']
    database = "barnowl"
    if 'database' in config:
        database = config['database']
    username = None
    if 'username' in config:
        username = config['username']
    password = None
    if 'password' in config:
        password = config['password']

    connection = pymongo.Connection(hostname)
    database = connection[database]
    if username is not None and password is not None:
        database.authenticate(username, password)
    return database

