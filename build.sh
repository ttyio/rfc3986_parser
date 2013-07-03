#!/bin/bash
flex parser_3986.y
g++ -o parser_3986 lex.yy.c
