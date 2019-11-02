#!/usr/bin/env python3
# -*- coding: utf-8 -*-
#
# Copyright 2019 Tobias Küchel <devel@zukuul.de>
# This piece of software is licensed under:
# SPDX-License-Identifier: GPL-3.0-or-later

import sys,os
import re
import argparse
import gender_guesser.detector as gender
from unidecode import unidecode
#import unicodedata

regex= r"[0-9]+"
d = gender.Detector(case_sensitive=False)

parser = argparse.ArgumentParser(description="Create logins for the Informatik Biber with usernames and passwords, using a given prefix")
parser.add_argument('-d', '--dont-ask-gender', help='Skip asking questions about the gender, results in anonym for all unknown gender types', required=False, action="store_true")
parser.add_argument('prefix', metavar='prefix', help='Prefix for all usernames')
args = parser.parse_args()
prefix = args.prefix

with open("add.csv") as f:
    lines = f.readlines()

collected_classes = {}
for line in lines:
    data = line.split(";")
    if not data[0] in collected_classes:
        ## find number in classname
        restufe = re.search(regex, data[0])
        if not restufe:
            guess = None
        else:
            if restufe.group() == "2":
                guess = "13"
            elif restufe.group() == "1":
                guess = "12"
            else:
                guess = restufe.group()
        print("%s => %s : ok? oder andere Stufe eingeben. (Enter, 0-13)" % ( data[0], guess), end='')
        classname = input()
        if classname != "":
            collected_classes[data[0]] = classname
        else:
            collected_classes[data[0]] = guess
print(collected_classes)

final = []
for line in lines:
    data = line.split(";")
    klasse = data[0]
    surname = data[1]
    firstname = data[2]
    username = data[3]
    if not data[0] in collected_classes:
        print("Problem: Klassenstufenbezeichnung %s gefunden und keine Klasse dazu bekannt. Kann eigentlich nicht sein. Exiting.")
        sys.exit()
    else:
        stufe = collected_classes[data[0]]
    if not stufe:
        print("Ignoriere %s" % data)
        continue

    g = d.get_gender(firstname)
    if g in ["unknown", "andy", "mostly_male", "mostly_female"]:
        g = "anonym"
        if not args.dont_ask_gender:
            print(klasse, stufe, firstname, surname, g)
            getg = input("Give gender on commandline m or f or d: ")
            if getg == "m":
                g = "male"
            elif getg == "f": 
                g = "female"
            elif getg == "d":
                g = "divers"

    prefixed_username = prefix + unidecode(username).lower()  
    passwd = unidecode(username).lower()  # + "-" + data[4].split(".")[0] - if there was a birthdate in the dataset, this could be the day of birth
    final.append(",".join([klasse,stufe,firstname,surname,prefixed_username,passwd,g]))

with open("schueler.biber.csv", "w") as f:
    f.writelines("%s\n" % l for l in final)

