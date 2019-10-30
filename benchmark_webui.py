#!/usr/bin/env python3
# -*- coding: utf-8 -*-
#
# Copyright 2019 Tobias Küchel <devel@zukuul.de>
# This piece of software is licensed under:
# SPDX-License-Identifier: GPL-3.0-or-later


import requests, json, argparse

formatpretty=True
try:
    from pygments import highlight, lexers, formatters # optional pretty printing
except ImportError:
    formatpretty=False

URLBase="https://server"

parser = argparse.ArgumentParser(description="Test the login process of the WebUI. Login, retrieve identity, retrieve quota, measure time.")
parser.add_argument('-s','--serverurl', help='Server URL to use, defaults to "https://server"', required=False)
parser.add_argument('-v','--verbose', help='Show the output of Identity and Quota retrieval"', required=False, action="store_true")
parser.add_argument('-u','--user', help='Username to use for login', required=True)
parser.add_argument('-p','--password', help='Password to use for login', required=True)
args = parser.parse_args()
if args.serverurl != None:
    URLBase=args.serverurl
print("Login into ", URLBase)
    
s = requests.Session()
payload = {'username': args.user, 'mode': 'normal', 'password': args.password }
l = s.post(URLBase+"/api/core/auth", json=payload, verify=False)
print("Login ", end='')
if (l.status_code == requests.status_codes.codes.ok):
    if "success" in l.json():
        if l.json()["success"]:
            print(" ok    ", end='')
        else:
            print(" failed", end='')
    else:
        print(" returned unexpected content", end='')
else:
    print(" failed", end='')
print(", ", l.elapsed.total_seconds(), " seconds.")

n = s.get(URLBase+"/api/core/identity", verify=False)
print("Profile", end='')
if (n.status_code == 200):
    if "identity" in n.json() and "profile" in n.json()["identity"]:
        if n.json()["identity"]['profile']:
            print(" ok   ", end='')
        else:
            print(" empty", end='')
    if args.verbose:
        obj = json.dumps(n.json(), indent=2)
        if formatpretty:
            colorful_json = highlight(obj, lexers.JsonLexer(), formatters.TerminalFormatter())
            obj = colorful_json
        print(obj)
else:
    print(" failed", end='')
print(", ", n.elapsed.total_seconds(), " seconds.")



o = s.post(URLBase+"/api/lmn/quota/", verify=False)
print("Quota ", end='')
if (o.status_code == 200):
    print(" ok    ", end='')
    if args.verbose:
        obj = json.dumps(o.json(), indent=2)
        if formatpretty:
            colorful_json = highlight(obj, lexers.JsonLexer(), formatters.TerminalFormatter())
            obj = colorful_json
        print(obj)
else:
    print(" failed", end='')
print(", ", o.elapsed.total_seconds(), " seconds.")
