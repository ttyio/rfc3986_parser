%option noyywrap yylineno
%x S_HIER S_AUTH S_ERR

sub_delims  (!|$|&|'|\(|\)|\*|\+|,|;|=)
alpha       [a-zA-Z]
digit       [0-9]
unreserved  {alpha}|{digit}|-|\.|_|~

dec_octet   {digit}|([1-9]{digit})|(1{digit}{2})|(2[0-4]{digit})|(25[0-5])

scheme      ({alpha})+({alpha}|{digit}|\+|-|\.)*

IPv4address {dec_octet}\.{dec_octet}\.{dec_octet}\.{dec_octet}
hexdig       [a-fA-F0-9]
pct_encoded  %{hexdig}{2}
userinfo     ({unreserved}|{pct_encoded}|{sub_delims}|":")*
port         {digit}*
reg_name      ({unreserved}|{pct_encoded}|{sub_delims})+

h16         {hexdig}{1,4}
ls32        ({h16}:{h16})|{IPv4address}

IPv6address (({h16}:){6}{ls32})|(::({h16}:){5}{ls32})|({h16}?::({h16}:){4}{ls32})|((({h16}:)?::({h16}:){3}{ls32})|((({h16}:){0,2}{h16})?::({h16}:){2}{ls32})|((({h16}:){0,3}{h16})?::({h16}:){ls32})|((({h16}:){0,4}{h16})?::{ls32})|((({h16}:){0,5}{h16})?::{h16})|((({h16}:){0,6})+{h16})?::)

IPvFuture     v({hexdig})+\.({unreserved}|{sub_delims}|:)+
IP_literal    (\[)({IPv6address}|{IPvFuture})(\])
host         ({IP_literal}|{IPv4address}|{reg_name})

pchar        {unreserved}|{pct_encoded}|{sub_delims}|:|@

fragment     ({pchar}|\/|\?)*
segment        {pchar}*
segment_nz     {pchar}+

path_abempty   ("/"{segment})*
path_absolute  "/"({segment_nz}("/"{segment})*)?
path_rootless  {segment_nz}("/"{segment})*

%{
#include <string.h>

// invalid port
#define INVALID_UINT            (unsigned int)-1

// Print information only in DEBUG enviroment
#ifdef _DEBUG
    #define DEBUG_INFO2(_FMT, _VAR1)            \
        printf(_FMT, _VAR1);
#else
    #define DEBUG_INFO2(_FMT, _VAR1)
#endif


// trim right most char(s) in the string
#define STRING_TRIM_RIGHT(_STR,_N)              \
    if (strlen(_STR)-_N >= 0){                  \
        (_STR)[strlen(_STR)-_N] = '\0';         \
    }

#define YY_UNPUT_CHARS()                        \
        for (int i=0;i<yyleng;i++){             \
            yyunput( yytext[i], yytext_ptr);    \
        }

// structure to store the URI
struct CUriInfo{
    char* scheme;
    char* user;
    char* host;
    unsigned int port;
    char* path;
    char* query;
    char* fragment;

    CUriInfo();
    ~CUriInfo();
}* uriInfo;

// error count during parse
unsigned int errCount = 0;

// push current uri to the list, return true if succeed, else false.
bool pushUri(CUriInfo*& pInfo);

// free all resource in URI
void resetUri(CUriInfo* pInfo);
%}

%%

{alpha}+({alpha}|{digit}|\+|-|\.)*":"   {
    uriInfo->scheme = strdup(yytext);
    STRING_TRIM_RIGHT(uriInfo->scheme, 1);
    DEBUG_INFO2("DEBUG: Find scheme \"%s\".\n", uriInfo->scheme);
    BEGIN   S_HIER;
}

[ \t\n]*    {
    pushUri(uriInfo);
}

.      {
    if (!pushUri(uriInfo)){
        DEBUG_INFO2("DEBUG: failed to push uri in \"%s\".\n", ".");
        yyunput( yytext[0], yytext_ptr);
        BEGIN S_ERR;
    } else {
        BEGIN INITIAL;
    }
}

<S_ERR>[^ \t\n]*    {
    resetUri(uriInfo);
    printf("Error: invalid string \"%s\" in line %d.\n", yytext, yylineno);
    ++errCount;
    BEGIN INITIAL;
}

<S_ERR>.|\n    {
    resetUri(uriInfo);
    printf("Error: incomplete uri in line %d.\n", yylineno-1);
    ++errCount;
    BEGIN INITIAL;
}


<S_HIER>"//"    {
    DEBUG_INFO2("DEBUG: Find \"%s\", next search authority.\n", yytext);
    BEGIN S_AUTH;
}

<S_HIER>{path_absolute}|{path_rootless}    {
    if (uriInfo->path != NULL){
        YY_UNPUT_CHARS();
        BEGIN S_ERR;
    } else {
        uriInfo->path = strdup(yytext);
        DEBUG_INFO2("DEBUG: Find path \"%s\".\n", uriInfo->path);
    }
}

<S_HIER>"?"{fragment}    {
    if (uriInfo->query != NULL){
        YY_UNPUT_CHARS();
        BEGIN S_ERR;
    } else {
        uriInfo->query = strdup(yytext+1);
        DEBUG_INFO2("DEBUG: Find query \"%s\".\n", uriInfo->query);
    }
}

<S_HIER>"#"{fragment}    {
    if (uriInfo->fragment != NULL){
        YY_UNPUT_CHARS();
        BEGIN S_ERR;
    } else {
        uriInfo->fragment = strdup(yytext+1);
        DEBUG_INFO2("DEBUG: Find fragment \"%s\".\n", uriInfo->fragment);
        BEGIN   S_HIER;
    }
}

<S_HIER>.|\n      {
    if (!pushUri(uriInfo)){
        DEBUG_INFO2("DEBUG: failed to push uri in \"%s\".\n", "<S_HIER>.|\\n");
        if (yytext[0] == '\n'){
            printf("Error: incomplete uri in line %d.\n", yylineno);
            ++errCount;
            BEGIN INITIAL;
        } else {
            YY_UNPUT_CHARS();
            BEGIN S_ERR;
        }
    } else {
        BEGIN INITIAL;
    }
}

<S_AUTH>{userinfo}"@"   {
    if (uriInfo->user != NULL){
        YY_UNPUT_CHARS();
        BEGIN S_ERR;
    } else {
        uriInfo->user = strdup(yytext);
        STRING_TRIM_RIGHT(uriInfo->user, 1);
        DEBUG_INFO2("DEBUG: Find userInfo \"%s\".\n", uriInfo->user);
    }
}

<S_AUTH>{host}  {
    if (uriInfo->host != NULL){
        YY_UNPUT_CHARS();
        BEGIN S_ERR;
    } else {
        uriInfo->host = strdup(yytext);
        DEBUG_INFO2("DEBUG: Find host \"%s\".\n", uriInfo->host);
    }
}

<S_AUTH>":"{port}  {
    if (uriInfo->port != INVALID_UINT){
        YY_UNPUT_CHARS();
        BEGIN S_ERR;
    } else {
        uriInfo->port = atoi(yytext+1);
        DEBUG_INFO2("DEBUG: Find port \"%u\".\n", uriInfo->port);
    }
}

<S_AUTH>{path_abempty}    {
    if (uriInfo->path != NULL){
        YY_UNPUT_CHARS();
        BEGIN S_ERR;
    } else {
        uriInfo->path = strdup(yytext);
        DEBUG_INFO2("DEBUG: Find path \"%s\".\n", uriInfo->path);
        BEGIN S_HIER;
    }
}

<S_AUTH>.|\n      {
    if (!pushUri(uriInfo)){
        DEBUG_INFO2("DEBUG: failed to push uri in \"%s\".\n", "<S_AUTH>.|\\n");
        if (yytext[0] == '\n'){
            printf("Error: incomplete uri in line %d.\n", yylineno);
            ++errCount;
            BEGIN INITIAL;
        } else {
            yyunput( yytext[0], yytext_ptr);
            BEGIN S_ERR;
        }
    }else{
        BEGIN INITIAL;
    }
}

<<EOF>>     {
    printf("Total %lld error(s).\n", (long long)errCount);
    printf("----------------------\n");
    yyterminate();
}

%%

#include <vector>


// check NULL or empty string
#define IS_EMPTY_STRING(_STR)                               \
        ((_STR)==NULL || strlen(_STR)==0)

// print structure field which is non-empty string 
#define PRINT_STR_FIELD(_VAL, _KEY)                         \
        if (!IS_EMPTY_STRING((_VAL)->_KEY)){                \
            printf("%s: %s\n", #_KEY, (_VAL)->_KEY);        \
        }

// print structure field which is valid uint
#define PRINT_UINT_FIELD(_VAL, _KEY)                        \
        if ((_VAL)->_KEY != INVALID_UINT){                  \
            printf("%s: %u\n", #_KEY, (_VAL)->_KEY);        \
        }

// free not NULL string
#define FREE_STRING(_STR)                                   \
        if (_STR != NULL){                                  \
            free(_STR);                                     \
            _STR = NULL;                                    \
        }

// global var to store URI list
std::vector<CUriInfo*> uriList;

// validate the URI, return true if pass validation, else return false
bool isValidUri(CUriInfo* pInfo);
// print URI
void printUri(CUriInfo* pInfo);
// print URI list
void printUriList();
// free URI list
void freeUriList();
// init all the resources
void initResource();
// free all the resources
void freeResource();

CUriInfo::CUriInfo()
    :scheme(NULL),
     user(NULL),
     host(NULL),
     port(INVALID_UINT),
     path(NULL),
     query(NULL),
     fragment(NULL)
{
}

CUriInfo::~CUriInfo()
{
    resetUri(this);
}

void resetUri(CUriInfo* pInfo)
{
    // free and reset all fields to default
    FREE_STRING(pInfo->scheme);
    FREE_STRING(pInfo->user);
    FREE_STRING(pInfo->host);
    FREE_STRING(pInfo->path);
    FREE_STRING(pInfo->query);
    FREE_STRING(pInfo->fragment);
    pInfo->port = INVALID_UINT;
}

bool isValidUri(CUriInfo* pInfo)
{
    // check scheme not empty
    if (IS_EMPTY_STRING(pInfo->scheme)){
        return false;
    }
    // check path not empty
    if (IS_EMPTY_STRING(pInfo->path)){
        return false;
    }
    return true;
}

void printUri(CUriInfo* pInfo)
{
    // print all fields
    PRINT_STR_FIELD(pInfo, scheme);
    PRINT_STR_FIELD(pInfo, user);
    PRINT_STR_FIELD(pInfo, host);
    PRINT_UINT_FIELD(pInfo, port);
    PRINT_STR_FIELD(pInfo, path);
    PRINT_STR_FIELD(pInfo, query);
    PRINT_STR_FIELD(pInfo, fragment);
    printf("\n");
}


bool pushUri(CUriInfo*& pInfo)
{
    // valiattion for URI
    if (!isValidUri(pInfo)){
        resetUri(pInfo);
        return false;
    }

    // push current and create new
    uriList.push_back(pInfo);
    pInfo = new CUriInfo;
    return true;
}

void printUriList()
{
    // print URI list
    size_t uriCount = uriList.size();
    size_t uriIndex = 1;
    std::vector<CUriInfo*>::iterator iter;
    for (iter=uriList.begin();iter!=uriList.end();iter++){
        printf("(%lld/%lld)\n", (long long)uriIndex++, (long long)uriCount);
        printUri(*iter);
    }
    printf("Total %lld URI(s) found.\n", (long long)uriCount);
    printf("----------------------\n");
}

void freeUriList()
{
    // free URI list
    std::vector<CUriInfo*>::iterator iter;
    for (iter=uriList.begin();iter!=uriList.end();iter++){
        delete *iter;
    }
    uriList.clear();
}

void initResource()
{
    // initialize current uriInfo
    uriInfo = new CUriInfo();
    printf("----------------------\n");
}

void freeResource()
{
    // delete currnet uriInfo
    if (uriInfo){
        delete uriInfo;
        uriInfo = NULL;
    }

    // free URI list
    freeUriList();
}

int main()
{
    // init
    initResource();

    // parser
    yylex();

    // print the result
    printUriList();

    // clean up
    freeResource();
    return 0;
}

