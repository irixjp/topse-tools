#!/usr/bin/env python

import os
import os_client_config
import sys


def sessions():
    return os_client_config.make_client(
        'compute',
        auth_url=os.environ['OS_AUTH_URL'],
        username=os.environ['OS_USERNAME'],
        password=os.environ['OS_PASSWORD'],
        project_name=os.environ['OS_TENANT_NAME'],
        region_name=os.environ['OS_REGION_NAME'],)


def list_servers_without_console(session):
    return [i for i in session.servers.list() if i.name != "console"]


def delete_servers(servers, session):
    for s in servers:
        session.servers.delete(s)


def main():
    s = sessions()
    a = list_servers_without_console(s)
    if a:
        delete_servers(a, s)
        sys.exit()
    else:
        print("There is only consle instance.")
        sys.exit()


if __name__ == '__main__':
    main()
