1. pre-requirements
   Linux OS, gcc, flex
      > gcc --version
        cc (GCC) 4.1.2 20080704 (Red Hat 4.1.2-51)
           Copyright (C) 2006 Free Software Foundation, Inc.
           This is free software; see the source for copying conditions.  There is NO
           warranty; not even for MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
      > flex --version
        flex version 2.5.4


2. build
   > cd <dir>/rfc3986_parser
   > ./build.sh

3. run
   3.1 input from file
   I have put one sample data in file <dir>/rfc3986_parser/input
      > ./parser_3986 < input
        ----------------------
        Error: invalid string "d/rfc/rfc2396.txt#intro" in line 3.
        Total 1 error(s).
        ----------------------
        (1/8)
        scheme: ftp
        host: ftp.is.co.za
        path: /rfc/rfc1808.txt

        (2/8)
        scheme: http
        user: vincenth
        host: www.ietf.org
        path: /rfc/rfc2396.txt
        fragment: intro

        (3/8)
        scheme: ldap
        host: [2001:db8::7]
        path: /c=GB
        query: objectClass?one

        (4/8)
        scheme: mailto
        path: John.Doe@example.com

        (5/8)
        scheme: news
        path: comp.infosystems.www.servers.unix

        (6/8)
        scheme: tel
        path: +1-816-555-1212

        (7/8)
        scheme: telnet
        host: 192.0.2.16
        port: 80
        path: /

        (8/8)
        scheme: urn
        path: oasis:names:specification:docbook:dtd:xml:4.1.2

        Total 8 URI(s) found.
        ----------------------

   3.2 input from console
       > ./parser_3986
        ----------------------
        http://vincenth@local:80/readme.txt#intro
        http://80
        Error: incomplete uri in line 3.
        Total 1 error(s).
        ----------------------
        (1/1)
        scheme: http
        user: vincenth
        host: local
        port: 80
        path: /readme.txt
        fragment: intro

        Total 1 URI(s) found.
        ----------------------
