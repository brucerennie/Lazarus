{-------------------------------------------------------------------------------
The contents of this file are subject to the Mozilla Public License
Version 1.1 (the "License"); you may not use this file except in compliance
with the License. You may obtain a copy of the License at
http://www.mozilla.org/MPL/

Software distributed under the License is distributed on an "AS IS" basis,
WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License for
the specific language governing rights and limitations under the License.

The Original Code is: SynHighlighterSQL.pas, released 2000-04-21.
The Original Code is based on the wmSQLSyn.pas and wmSybaseSyn.pas files from
the mwEdit component suite by Martin Waldenburg and other developers, the
Initial Author of these files is Willo van der Merwe. Initial Author of
SynHighlighterSQL.pas is Michael Hieke.
Portions created by Willo van der Merwe are Copyright 1999 Willo van der Merwe.
Portions created by Michael Hieke are Copyright 2000 Michael Hieke.
All Rights Reserved.

Contributors to the SynEdit and mwEdit projects are listed in the
Contributors.txt file.

Alternatively, the contents of this file may be used under the terms of the
GNU General Public License Version 2 or later (the "GPL"), in which case
the provisions of the GPL are applicable instead of those above.
If you wish to allow use of your version of this file only under the terms
of the GPL and not to allow others to use your version of this file
under the MPL, indicate your decision by deleting the provisions above and
replace them with the notice and other provisions required by the GPL.
If you do not delete the provisions above, a recipient may use your version
of this file under either the MPL or the GPL.

$Id$

You may retrieve the latest version of this file at the SynEdit home page,
located at http://SynEdit.SourceForge.net

Known Issues:
-------------------------------------------------------------------------------}
{
@abstract(SQL highlighter for SynEdit with support for different dialects.)
@author(Michael Hieke)
@created(2000-04-21)
@lastmod(2000-11-16)
The SynHighlighterSQL implements a highlighter for SQL for the SynEdit projects.
Different SQL dialects can be selected via the Dialect property.
}
unit SynHighlighterSQL;

{$I SynEdit.inc}

interface

uses
  SysUtils, Classes,
  LCLIntf, LCLType,
  Controls, Graphics,
  SynEditTypes, SynEditHighlighter, SynEditStrConst,
  SynHighlighterHashEntries;

type
  TtkTokenKind = (tkComment, tkDatatype, tkDefaultPackage, tkException,         // DJLP 2000-08-11
    tkFunction, tkIdentifier, tkKey, tkNull, tkNumber, tkSpace, tkPLSQL,        // DJLP 2000-08-11
    tkSQLPlus, tkString, tkSymbol, tkTableName, tkUnknown, tkVariable);         // DJLP 2000-08-11

  TRangeState = (rsUnknown, rsComment, rsString);

  TProcTableProc = procedure of object;

  TSQLDialect = (sqlStandard, sqlInterbase6, sqlMSSQL7, sqlMySQL, sqlOracle,
    sqlSybase, sqlIngres, sqlMSSQL2K, sqlPostgres, sqlSQLite,                                           // JJV 2000-11-16
    sqlFirebird25, sqlFirebird30, sqlFirebird40, sqlMSSQL2022);

type
  PIdentifierTable = ^TIdentifierTable;
  TIdentifierTable = array[Char] of ByteBool;

  PHashTable = ^THashTable;
  THashTable = array[Char] of Integer;

type
  TSynSQLSyn = class(TSynCustomHighlighter)
  private
    fRange: TRangeState;
    fLine: PChar;
    fLineNumber: Integer;
    fProcTable: array[#0..#255] of TProcTableProc;
    Run: LongInt;
    fStringLen: Integer;
    fToIdent: PChar;
    fTokenPos: Integer;
    fTokenID: TtkTokenKind;
    fKeywords: TSynHashEntryList;
    fTableNames: TStrings;
    fDialect: TSQLDialect;
    fCommentAttri: TSynHighlighterAttributes;
    fDataTypeAttri: TSynHighlighterAttributes;
    fDefaultPackageAttri: TSynHighlighterAttributes;                            // DJLP 2000-08-11
    fExceptionAttri: TSynHighlighterAttributes;
    fFunctionAttri: TSynHighlighterAttributes;
    fIdentifierAttri: TSynHighlighterAttributes;
    fKeyAttri: TSynHighlighterAttributes;
    fNumberAttri: TSynHighlighterAttributes;
    fPLSQLAttri: TSynHighlighterAttributes;                                     // DJLP 2000-08-11
    fSpaceAttri: TSynHighlighterAttributes;
    fSQLPlusAttri: TSynHighlighterAttributes;                                   // DJLP 2000-09-05
    fStringAttri: TSynHighlighterAttributes;
    fSymbolAttri: TSynHighlighterAttributes;
    fTableNameAttri: TSynHighlighterAttributes;
    fVariableAttri: TSynHighlighterAttributes;
    fIdentifiersPtr: PIdentifierTable;
    fmHashTablePtr: PHashTable;
    function KeyHash(ToHash: PChar): Integer;
    function KeyComp(const aKey: string): Boolean;
    procedure AndSymbolProc;
    procedure AsciiCharProc;
    procedure CRProc;
    procedure EqualProc;
    procedure GreaterProc;
    procedure IdentProc;
    procedure LFProc;
    procedure LowerProc;
    procedure MinusProc;
    procedure NullProc;
    procedure NumberProc;
    procedure OrSymbolProc;
    procedure PlusProc;
    procedure SlashProc;
    procedure SpaceProc;
    procedure StringProc;
    procedure SymbolProc;
    procedure SymbolAssignProc;
    procedure VariableProc;
    procedure UnknownProc;
    function IdentKind(MayBe: PChar): TtkTokenKind;
    procedure MakeMethodTables;
    procedure AnsiCProc;
    procedure DoAddKeyword(AKeyword: string; AKind: integer);
    procedure SetDialect(Value: TSQLDialect);
    procedure SetTableNames(const Value: TStrings);
    procedure TableNamesChanged(Sender: TObject);
    procedure InitializeKeywordLists;
    procedure PutTableNamesInKeywordList;
  protected
    function GetIdentChars: TSynIdentChars; override;
    function GetSampleSource : String; override;
  public
    class function GetLanguageName: string; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Assign(Source: TPersistent); override;
    function GetDefaultAttribute(Index: integer): TSynHighlighterAttributes;
      override;
    function GetEol: Boolean; override;
    function GetRange: Pointer; override;
    function GetToken: string; override;
    procedure GetTokenEx(out TokenStart: PChar; out TokenLength: integer); override;

    function GetTokenAttribute: TSynHighlighterAttributes; override;
    function GetTokenID: TtkTokenKind;
    function GetTokenKind: integer; override;
    function GetTokenPos: Integer; override;
    function IsKeyword(const AKeyword: string): boolean; override;              // DJLP 2000-08-09
    procedure Next; override;
    procedure ResetRange; override;
    procedure SetLine(const NewValue: string; LineNumber: Integer); override;
    procedure SetRange(Value: Pointer); override;
  published
    property CommentAttri: TSynHighlighterAttributes read fCommentAttri
      write fCommentAttri;
    property DataTypeAttri: TSynHighlighterAttributes read fDataTypeAttri
      write fDataTypeAttri;
    property DefaultPackageAttri: TSynHighlighterAttributes                     // DJLP 2000-08-11
      read fDefaultPackageAttri write fDefaultPackageAttri;
    property ExceptionAttri: TSynHighlighterAttributes read fExceptionAttri
      write fExceptionAttri;
    property FunctionAttri: TSynHighlighterAttributes read fFunctionAttri
      write fFunctionAttri;
    property IdentifierAttri: TSynHighlighterAttributes read fIdentifierAttri
      write fIdentifierAttri;
    property KeyAttri: TSynHighlighterAttributes read fKeyAttri write fKeyAttri;
    property NumberAttri: TSynHighlighterAttributes read fNumberAttri
      write fNumberAttri;
    property PLSQLAttri: TSynHighlighterAttributes read fPLSQLAttri             // DJLP 2000-08-11
      write fPLSQLAttri;
    property SpaceAttri: TSynHighlighterAttributes read fSpaceAttri
      write fSpaceAttri;
    property SQLPlusAttri: TSynHighlighterAttributes read fSQLPlusAttri         // DJLP 2000-09-05
      write fSQLPlusAttri;
    property StringAttri: TSynHighlighterAttributes read fStringAttri
      write fStringAttri;
    property SymbolAttri: TSynHighlighterAttributes read fSymbolAttri
      write fSymbolAttri;
    property TableNameAttri: TSynHighlighterAttributes read fTableNameAttri
      write fTableNameAttri;
    property TableNames: TStrings read fTableNames write SetTableNames;
    property VariableAttri: TSynHighlighterAttributes read fVariableAttri
      write fVariableAttri;
    property SQLDialect: TSQLDialect read fDialect write SetDialect;
  end;

implementation

var
  Identifiers: TIdentifierTable;
  mHashTable: THashTable;

  IdentifiersMSSQL7: TIdentifierTable;
  mHashTableMSSQL7: THashTable;

const
  //---SQLite keywords------------------------------------------------------------
  SQLiteKW: string =
    'abort,action,add,after,all,alter,analyze,and,as,asc,attach,autoincrement,' +
    'before,begin,between,by,cascade,case,cast,check,collate,column,' +
    'commit,conflict,constraint,create,cross,current_date,current_time,' +
    'current_timestamp,database,default,deferrable,deferred,delete,desc,' +
    'detach,distinct,drop,each,else,end,escape,except,exclusive,exists,explain,' +
    'fail,for,foreign,from,full,glob,group,having,if,ignore,immediate,in,index,indexed,' +
    'initially,inner,insert,instead,intersect,into,is,isnull,join,key,left,like,limit,' +
    'match,natural,no,not,notnull,null,of,offset,on,or,order,outer,plan,pragma,' +
    'primary,query,replace,raise,references,regexp,reindex,release,rename,restrict,right,' +
    'rollback,row,savepoint,select,set,table,temp,temporary,then,to,transaction,' +
    'trigger,union,unique,update,using,vacuum,values,view,virtual,when,where';

  SQLiteTypes: string =
    'int,integer,tinyint,smallint,mediumint,bigint,int2,int8,character,varchar,' +
    'nchar,,nvarchar,text,clob,blob,real,double,float,numeric,decimal,boolean,' +
    'date,datetime';

  SQLiteFunctions: string =
    'abs,avg,changes,char,coalesce,concat,concat_ws,count,format,group_concat,' +
    'hex,ifnull,iif,instr,julianday,last_insert_rowid,json,json_array,' +
    'json_array_length,json_each,json_error_position,json_extract,json_group_array,' +
    'json_group_object,json_insert,json_object,json_patch,json_quote,json_remove,' +
    'json_replace,json_set,json_tree,json_type,json_valid,jsonb,jsonb_array,' +
    'jsonb_insert,jsonb_extract,jsonb_group_array,jsonb_group_object,jsonb_object,' +
    'jsonb_patch,jsonb_remove,jsonb_replace,jsonb_set,length,likelihood,likely,' +
    'load_extension,lower,ltrim,max,min,nullif,octet_length,printf,quote,random,' +
    'randomblob,round,rtrim,sign,soundex,sqlite_compileoption_get,' +
    'sqlite_compileoption_used,sqlite_offset,sqlite_source_id,sqlite_version,' +
    'strftim,substr,substring,sum,time,total,total_changes,trim,typeof,unhex,' +
    'unicode,unlikely,upper,zeroblob';

//---"Standard" (ANSI SQL keywords (Version 1, 2 and 3) (www.sql.org)---------
  StandardKW: string =
    'absolute,action,active,actor,add,after,alias,all,allocate,alter,' +
    'and,any,are,as,asc,ascending,assertion,async,at,attributes,auto,' +
    'base_name,before,begin,between,bit,bit_length,boolean,both,breadth,by,' +
    'cache,call,cascade,cascaded,case,cast,catalog,char_length,' +
    'character_length,check,coalesce,collate,collation,column,commit,' +
    'committed,completion,computed,conditional,connect,connection,constraint,' +
    'constraints,containing,convert,corresponding,count,create,cross,current,' +
    'current_date,current_path,current_time,current_timestamp,current_user,' +
    'cursor,cycle,data,database,date,day,deallocate,debug,declare,default,' +
    'deferrable,deferred,delete,depth,desc,descending,describe,descriptor,' +
    'destroy,diagnostics,dictionary,disconnect,distinct,do,domain,' +
    'drop,each,element,else,elseif,end,end-exec,entry_point,equals,escape,' +
    'except,exception,execute,exists,exit,external,extract,factor,false,' +
    'filter,first,for,foreign,from,full,function,general,generator,get,' +
    'global,grant,group,having,hold,hour,identity,if,ignore,immediate,in,' +
    'inactive,index,initially,inner,input,insensitive,insert,instead,' +
    'intersect,interval,into,is,isolation,join,key,last,leading,leave,left,' +
    'less,level,like,limit,list,local,loop,lower,match,merge,minute,modify,' +
    'month,names,national,natural,nchar,new,new_table,next,no,none,not,null,' +
    'nullif,object,octet_length,of,off,old,old_table,on,only,operation,' +
    'operator,operators,or,order,others,outer,output,overlaps,pad,' +
    'parameter,parameters,partial,password,path,pendant,plan,position,' +
    'postfix,prefix,preorder,prepare,preserve,primary,prior,private,' +
    'privileges,procedure,protected,read,recursive,ref,referencing,relative,' +
    'replace,resignal,restrict,retain,return,returns,revoke,right,role,' +
    'rollback,routine,row,rows,savepoint,schema,scroll,search,second,select,' +
    'sensitive,sequence,session,session_user,set,shadow,shared,signal,' +
    'similar,size,snapshot,some,space,sqlexception,sqlstate,sqlwarning,start,' +
    'state,structure,substring,suspend,symbol,system_user,table,temporary,' +
    'term,test,then,there,time,timestamp,timezone_hour,timezone_minute,to,' +
    'trailing,transaction,translate,translation,trigger,trim,true,tuple,type,' +
    'uncommitted,under,union,unique,unknown,update,upper,usage,user,using,' +
    'value,varchar,variable,varying,view,virtual,visible,wait,when,where,' +
    'while,with,without,work,write,year,zone';

//---Sybase keywords------------------------------------------------------------
  SybaseKW: string =
    'absolute,action,add,after,alias,all,allocate,alter,and,any,are,' +
    'arith_overflow,as,asc,assertion,async,at,authorization,avg,before,begin,' +
    'between,bit,bit_length,boolean,both,breadth,break,browse,bulk,by,call,' +
    'cascade,cascaded,case,cast,catalog,char,char_convert,char_length,' +
    'character,character_length,check,checkpoint,close,clustered,coalesce,' +
    'collate,collation,column,commit,completion,compute,confirm,' +
    'connect,connection,constraint,constraints,continue,controlrow,convert,' +
    'corresponding,count,create,cross,current,current_date,current_time,' +
    'current_timestamp,current_user,cursor,cycle,data,database,date,day,dbcc,' +
    'deallocate,dec,decimal,declare,default,deferrable,deferred,delete,depth,' +
    'desc,describe,descriptor,diagnostics,dictionary,dis,disconnect,distinct,' +
    'domain,double,drop,dummy,dump,each,else,elseif,en,end,endtran,equals,' +
    'errlvl,errordata,errorexit,escape,except,exception,exclusive,exec,' +
    'execute,exists,exit,exp_row_size,external,extract,false,fetch,' +
    'fillfactor,first,float,for,foreign,found,from,full,general,get,global,' +
    'go,goto,grant,group,having,holdlock,hour,identity,identity_gap,' +
    'identity_insert,identity_start,if,ignore,immediate,in,index,indicator,' +
    'initially,inner,input,insensitive,insert,install,int,integer,intersect,' +
    'interval,into,is,isolation,jar,join,key,kill,language,last,leading,' +
    'leave,left,less,level,like,limit,lineno,load,local,lock,loop,lower,' +
    'match,max,max_rows_per_page,min,minute,mirror,mirrorexit,modify,module,' +
    'month,names,national,natural,nchar,new,next,no,noholdlock,nonclustered,' +
    'none,not,null,nullif,numeric,numeric_truncation,object,' +
    'octet_length,of,off,offsets,oid,old,on,once,online,only,open,operation,' +
    'operators,option,or,order,others,outer,output,over,overlaps,pad,' +
    'parameters,partial,partition,pendant,perm,permanent,plan,position,' +
    'precision,preorder,prepare,preserve,primary,print,prior,private,' +
    'privileges,proc,procedure,processexit,protected,proxy_table,public,' +
    'quiesce,raiserror,read,readpast,readtext,real,reconfigure,recursive,' +
    'ref,reference,referencing,relative,remove,reorg,replace,replication,' +
    'reservepagegap,resignal,restrict,return,returns,revoke,right,role,' +
    'rollback,routine,row,rowcount,rows,rule,save,savepoint,schema,scroll,' +
    'search,second,section,select,sensitive,sequence,session_user,set,' +
    'setuser,shared,shutdown,signal,similar,size,smallint,some,space,sql,' +
    'sqlcode,sqlerror,sqlexception,sqlstate,statistics,stripe,structure,' +
    'substring,sum,syb_identity,syb_restree,system_user,table,temp,temporary,' +
    'test,textsize,then,there,time,timestamp,timezone_hour,timezone_minute,' +
    'to,trailing,tran,transaction,translate,translation,trigger,trim,true,' +
    'truncate,tsequal,type,under,union,unique,unknown,unpartition,update,' +
    'upper,usage,use,user,user_option,using,value,values,varchar,variable,' +
    'varying,view,virtual,visible,wait,waitfor,when,whenever,where,while,' +
    'with,without,work,write,writetext,year,zone';

//---Oracle---------------------------------------------------------------------
  // Oracle SQL keywords
  OracleKW: string =
    'ACCESS,ACCESSED,ACCOUNT,ACTIVATE,ACTIVE_INSTANCE_COUNT,ADD,ADMIN,ADVISE,' +
    'AGENT,ALL,ALLOCATE,ALTER,ANALYZE,ANCILLARY,AND,ANY,AQ_TM_PROCESSES,' +
    'ARCHIVE_LAG_TARGET,ARCHIVELOG,AS,ASC,ASSOCIATE,ATTRIBUTES,AUDIT,' +
    'AUDIT_FILE_DEST,AUDIT_SYS_OPERATIONS,AUDIT_TRAIL,AUTHENTICATED,AUTHID,' +
    'AUTOALLOCATE,AUTOEXTEND,AUTOMATIC,BACKGROUND_CORE_DUMP,' +
    'BACKGROUND_DUMP_DEST,BACKUP,BACKUP_TAPE_IO_SLAVES,BECOME,BEFORE,' +
    'BEHALF,BETWEEN,BINDING,BITMAP,BITMAP_MERGE_AREA_SIZE,BLANK_TRIMMING,' +
    'BLOCK,BLOCKSIZE,BUFFER_POOL,BUFFER_POOL_KEEP,BUFFER_POOL_RECYCLE,BY,' +
    'CACHE,CANCEL,CASCADE,CAST,CATEGORY,CHAINED,CHANGE,CHARACTER,CHECK,' +
    'CHECKPOINT,CHILD,CHUNK,CIRCUITS,CLASS,CLONE,CLUSTER,CLUSTER_DATABASE,' +
    'CLUSTER_DATABASE_INSTANCES,CLUSTER_INTERCONNECTS,COALESCE,COBOL,' +
    'COLUMN,COLUMNS,COMMENT,COMMIT_POINT_STRENGTH,COMPATIBLE,COMPILE,' +
    'COMPLETE,COMPOSITE_LIMIT,COMPRESS,COMPUTE,CONNECT,' +
    'CONNECT_TIME,CONSIDER,CONSTRAINT,CONSTRAINTS,CONTENTS,CONTEXT,CONTINUE,' +
    'CONTROL,CONTROL_FILE_RECORD_KEEP_TIME,CONTROL_FILES,CONTROLFILE,' +
    'CORE_DUMP_DEST,COST,CPU_COUNT,CPU_PER_CALL,CPU_PER_SESSION,CREATE,' +
    'CREATE_BITMAP_AREA_SIZE,CREATE_STORED_OUTLINES,CURRENT,CURRENT_USER,' +
    'CURSOR_SHARING,CURSOR_SPACE_FOR_TIME,CYCLE,DANGLING,DATAFILE,' +
    'DB_BLOCK_BUFFERS,DB_BLOCK_CHECKING,DB_BLOCK_CHECKSUM,DB_BLOCK_SIZE,' +
    'DB_CACHE_ADVICE,DB_CACHE_SIZE,DB_CREATE_FILE_DEST,DB_DOMAIN,' +
    'DB_FILE_MULTIBLOCK_READ_COUNT,DB_FILE_NAME_CONVERT,DB_FILES,' +
    'DB_KEEP_CACHE_SIZE,DB_NAME,DB_RECYCLE_CACHE_SIZE,DB_WRITER_PROCESSES,' +
    'DBLINK_ENCRYPT_LOGIN,DBWR_IO_SLAVES,DEALLOCATE,DEBUG,DEFAULT,DEFERRED,' +
    'DEFINER,DELETE,DEMAND,DETERMINES,DG_BROKER_START,DICTIONARY,DIMENSION,' +
    'DIRECTORY,DISABLE,DISASSOCIATE,DISK_ASYNCH_IO,DISMOUNT,DISPATCHERS,' +
    'DISTINCT,DISTRIBUTED,DISTRIBUTED_LOCK_TIMEOUT,DML,DML_LOCKS,DOCUMENT,' +
    'DROP,DRS_START,ELSE,ENABLE,ENQUEUE_RESOURCES,ESCAPE,ESTIMATE,EVENT,' +
    'EVENTS,EXCEPT,EXCEPTIONS,EXCHANGE,EXCLUDING,EXCLUSIVE,EXISTS,EXPIRE,' +
    'EXPLAIN,EXTENT,EXTERNALLY,FAILED_LOGIN_ATTEMPTS,FAL_CLIENT,FAL_SERVER,' +
    'FAST,FAST_START_IO_TARGET,FAST_START_MTTR_TARGET,' +
    'FAST_START_PARALLEL_ROLLBACK,FILE,FILE_MAPPING,FILESYSTEMIO_OPTIONS,' +
    'FIXED_DATE,FLUSH,FOR,FORCE,FOREIGN,FORTRAN,FREELIST,FREELISTS,FRESH,' +
    'FROM,FROM_TZ,FUNCTIONS,GC_FILES_TO_LOCKS,GENERATED,GLOBAL,' +
    'GLOBAL_CONTEXT_POOL_SIZE,GLOBAL_NAME,GLOBAL_NAMES,GLOBALLY,GO,GRANT,' +
    'GROUP,GROUPS,HASH,HASH_AREA_SIZE,HASH_JOIN_ENABLED,HASHKEYS,HAVING,HEAP,' +
    'HI_SHARED_MEMORY_ADDRESS,HIERARCHY,HS_AUTOREGISTER,IDENTIFIED,IDLE_TIME,' +
    'IFILE,IMMEDIATE,IN,INCLUDING,INCREMENT,INDEX,INDEXTYPE,INDEXTYPES,' +
    'INFILE,INITIAL,INITIALIZED,INITIALLY,INITRANS,INSERT,INSTANCE,' +
    'INSTANCE_GROUPS,INSTANCE_NAME,INSTANCE_NUMBER,INT,INTERSECT,INTO,' +
    'INVALIDATE,IS,ISOLATION,JAVA,JAVA_MAX_SESSIONSPACE_SIZE,JAVA_POOL_SIZE,' +
    'JAVA_SOFT_SESSIONSPACE_LIMIT,JOB_QUEUE_PROCESSES,JOIN,KEEP,KEY,KILL,' +
    'LARGE_POOL_SIZE,LAYERLISTS,LEVEL,LIBRARY,LICENSE_MAX_SESSIONS,' +
    'LICENSE_MAX_USERS,LICENSE_SESSIONS_WARNING,LIKE,LIMIT,LINK,LIST,LOB,' +
    'LOCAL,LOCAL_LISTENER,LOCATOR,LOCK,LOCK_NAME_SPACE,LOCK_SGA,' +
    'LOG_ARCHIVE_DEST,LOG_ARCHIVE_DUPLEX_DEST,LOG_ARCHIVE_FORMAT,' +
    'LOG_ARCHIVE_MAX_PROCESSES,LOG_ARCHIVE_MIN_SUCCEED_DEST,' +
    'LOG_ARCHIVE_START,LOG_ARCHIVE_TRACE,LOG_BUFFER,LOG_CHECKPOINT_INTERVAL,' +
    'LOG_CHECKPOINT_TIMEOUT,LOG_CHECKPOINTS_TO_ALERT,LOG_FILE_NAME_CONVERT,' +
    'LOG_PARALLELISM,LOGFILE,LOGGING,LOGICAL_READS_PER_CALL,' +
    'LOGICAL_READS_PER_SESSION,LOGMNR_MAX_PERSISTENT_SESSIONS,MANAGE,MANAGED,' +
    'MANUAL,MAP,MASTER,MATCHED,MATERIALIZED,MAX_COMMIT_PROPAGATION_DELAY,' +
    'MAX_DISPATCHERS,MAX_DUMP_FILE_SIZE,MAX_ENABLED_ROLES,' +
    'MAX_ROLLBACK_SEGMENTS,MAX_SHARED_SERVERS,MAXDATAFILES,MAXEXTENTS,' +
    'MAXINSTANCES,MAXLOGFILES,MAXLOGHISTORY,MAXLOGMEMBERS,MAXSIZE,MAXTRANS,' +
    'MAXVALUE,MEMBER,MINEXTENTS,MINIMIZE,MINIMUM,MINUS,MINVALUE,MODE,MODIFY,' +
    'MODULE,MONITORING,MOUNT,MOVE,MOVEMENT,MULTISET,NAMED,NATIONAL,NESTED,' +
    'NEVER,NEXT,NLS_CALENDAR,NLS_COMP,NLS_CURRENCY,NLS_DATE_FORMAT,' +
    'NLS_DATE_LANGUAGE,NLS_DUAL_CURRENCY,NLS_ISO_CURRENCY,NLS_LANGUAGE,' +
    'NLS_LENGTH_SEMANTICS,NLS_NCHAR_CONV_EXCP,NLS_NUMERIC_CHARACTERS,' +
    'NLS_TERRITORY,NLS_TIMESTAMP_FORMAT,NLS_TIMESTAMP_TZ_FORMAT,NO,' +
    'NOARCHIVELOG,NOAUDIT,NOCACHE,NOCOMPRESS,NOCOPY,NOCYCLE,NOFORCE,' +
    'NOLOGGING,NOMAXVALUE,NOMINIMIZE,NOMINVALUE,NOMONITORING,NONE,' +
    'NOORDER,NORELY,NORESETLOGS,NOREVERSE,NORMAL,NOROWDEPENDENCIES,NOSORT,' +
    'NOT,NOTHING,NOVALIDATE,NOWAIT,NULL,O7_DICTIONARY_ACCESSIBILITY,' +
    'OBJECT_CACHE_MAX_SIZE_PERCENT,OBJECT_CACHE_OPTIMAL_SIZE,OF,OFFLINE,OID,' +
    'OLAP_PAGE_POOL_SIZE,ON,ONLINE,ONLY,OPEN_CURSORS,OPEN_LINKS,' +
    'OPEN_LINKS_PER_INSTANCE,OPERATOR,OPTIMAL,OPTIMIZER_DYNAMIC_SAMPLING,' +
    'OPTIMIZER_FEATURES_ENABLE,OPTIMIZER_INDEX_CACHING,' +
    'OPTIMIZER_INDEX_COST_ADJ,OPTIMIZER_MAX_PERMUTATIONS,OPTIMIZER_MODE,' +
    'OPTION,OR,ORACLE_TRACE_COLLECTION_NAME,ORACLE_TRACE_COLLECTION_PATH,' +
    'ORACLE_TRACE_COLLECTION_SIZE,ORACLE_TRACE_ENABLE,' +
    'ORACLE_TRACE_FACILITY_NAME,ORACLE_TRACE_FACILITY_PATH,ORDER,' +
    'OS_AUTHENT_PREFIX,OS_ROLES,OUTLINE,OVERFLOW,OWN,PACKAGES,PARALLEL,' +
    'PARALLEL_ADAPTIVE_MULTI_USER,PARALLEL_AUTOMATIC_TUNING,' +
    'PARALLEL_EXECUTION_MESSAGE_SIZE,PARALLEL_INSTANCE_GROUP,' +
    'PARALLEL_MAX_SERVERS,PARALLEL_MIN_PERCENT,PARALLEL_MIN_SERVERS,' +
    'PARALLEL_THREADS_PER_CPU,PARAMETERS,PARTITION_VIEW_ENABLED,PARTITIONS,' +
    'PASSWORD,PASSWORD_GRACE_TIME,PASSWORD_LIFE_TIME,PASSWORD_LOCK_TIME,' +
    'PASSWORD_REUSE_MAX,PASSWORD_REUSE_TIME,PASSWORD_VERIFY_FUNCTION,' +
    'PCTFREE,PCTINCREASE,PCTTHRESHOLD,PCTUSED,PCTVERSION,PERCENT,PERMANENT,' +
    'PGA_AGGREGATE_TARGET,PIPELINED,PLAN,PLI,PLSQL_COMPILER_FLAGS,' +
    'PLSQL_NATIVE_C_COMPILER,PLSQL_NATIVE_LIBRARY_DIR,' +
    'PLSQL_NATIVE_LIBRARY_SUBDIR_COUNT,PLSQL_NATIVE_LINKER,' +
    'PLSQL_NATIVE_MAKE_FILE_NAME,PLSQL_NATIVE_MAKE_UTILITY,' +
    'PLSQL_V2_COMPATIBILITY,POST_TRANSACTION,PRE_PAGE_SGA,PREBUILD,PRECISION,' +
    'PRIMARY,PRIOR,PRIVATE_SGA,PRIVILEGES,PROCESSES,PROFILE,PUBLIC,QUERY,' +
    'QUERY_REWRITE_ENABLED,QUERY_REWRITE_INTEGRITY,QUIESCE,QUOTA,' +
    'RDBMS_SERVER_DN,READ,READ_ONLY_OPEN_DELAYED,REBUILD,RECORDS_PER_BLOCK,' +
    'RECOVER,RECOVERABLE,RECOVERY,RECOVERY_PARALLELISM,RECYCLE,REDUCED,' +
    'REFERENCES,REFRESH,REGISTER,RELY,REMOTE_ARCHIVE_ENABLE,' +
    'REMOTE_DEPENDENCIES_MODE,REMOTE_LISTENER,REMOTE_LOGIN_PASSWORDFILE,' +
    'REMOTE_OS_AUTHENT,REMOTE_OS_ROLES,RENAME,' +
    'REPLICATION_DEPENDENCY_TRACKING,RESET,RESETLOGS,RESIZE,RESOLVE,RESOLVER,' +
    'RESOURCE,RESOURCE_LIMIT,RESOURCE_MANAGER_PLAN,RESTRICT,RESTRICTED,' +
    'RESUMABLE,RESUME,REUSE,REVOKE,REWRITE,RNDS,RNPS,ROLE,ROLES,' +
    'ROLLBACK_SEGMENTS,ROW,ROW_LOCKING,ROWDEPENDENCIES,ROWLABEL,ROWNUM,' +
    'ROWS,SAMPLE,SCN,SCOPE,SECTION,SEGMENT,SELECT,SELECTIVITY,SEQUENCE,' +
    'SERIAL_REUSE,SERVICE_NAMES,SESSION,SESSION_CACHED_CURSORS,' +
    'SESSION_MAX_OPEN_FILES,SESSIONS,SESSIONS_PER_USER,SGA_MAX_SIZE,' +
    'SHADOW_CORE_DUMP,SHARE,SHARED,SHARED_MEMORY_ADDRESS,SHARED_POOL,' +
    'SHARED_POOL_RESERVED_SIZE,SHARED_POOL_SIZE,SHARED_SERVER_SESSIONS,' +
    'SHARED_SERVERS,SHRINK,SIZE,SNAPSHOT,SOME,SORT,SORT_AREA_RETAINED_SIZE,' +
    'SORT_AREA_SIZE,SOURCE,SPECIFICATION,SPECIFIED,SPFILE,SPLIT,SQL_TRACE,' +
    'SQL92_SECURITY,STANDBY,STANDBY_ARCHIVE_DEST,STANDBY_FILE_MANAGEMENT,' +
    'STAR_TRANSFORMATION_ENABLED,START,START_DATE,STATISTICS,' +
    'STATISTICS_LEVEL,STOP,STORAGE,STRUCTURE,SUBPARTITION,SUBPARTITIONS,' +
    'SUCCESSFUL,SUSPEND,SWITCH,SYNONYM,SYSTEM,TABLE,TABLESPACE,' +
    'TAPE_ASYNCH_IO,TEMPFILE,TEMPORARY,THE,THEN,THREAD,THROUGH,TIME,' +
    'TIMED_OS_STATISTICS,TIMED_STATISTICS,TIMEOUT,TO,TRACE_ENABLED,' +
    'TRACEFILE_IDENTIFIER,TRACING,TRANSACTION,TRANSACTION_AUDITING,' +
    'TRANSACTIONS,TRANSACTIONS_PER_ROLLBACK_SEGMENT,TRIGGER,TRUNCATE,TRUST,' +
    'TYPES,UNARCHIVED,UNDER,UNDO,UNDO_MANAGEMENT,UNDO_RETENTION,' +
    'UNDO_SUPPRESS_ERRORS,UNDO_TABLESPACE,UNIFORM,UNION,UNIQUE,UNLIMITED,' +
    'UNLOCK,UNQUIESCE,UNRECOVERABLE,UNTIL,UNUSABLE,UNUSED,UPDATE,USAGE,' +
    'USE_INDIRECT_DATA_BUFFERS,USER_DUMP_DEST,VALIDATE,VALIDATION,VALUES,' +
    'VARGRAPHIC,VARRAY,VIEW,WHERE,WITH,WITHOUT,WNDS,WNPS,' +
    'WORKAREA_SIZE_POLICY';

  // PLSQL keywords
  OraclePLSQLKW: string =
    'ABORT,ACCEPT,AFTER,ARRAY,ARRAYLEN,ASSERT,ASSIGN,AT,AUTHORIZATION,' +
    'AUTONOMOUS_TRANSACTION,BASE_TABLE,BEGIN,BODY,BULK,BULK_ROWCOUNT,CALL,' +
    'CALLING,CASE,CHAR_BASE,CHARSETFORM,CHARSETID,CLOSE,CLUSTERS,COLAUTH,' +
    'COLLECT,COMMIT,CONNECTION,CONSTANT,COOKIE,COOKIE_TABLE,CRASH,CURRVAL,' +
    'CURSOR,DATA_BASE,DATABASE,DBA,DEBUGOFF,DEBUGON,DECLARE,DEFINITION,' +
    'DELAY,DELTA,DEQUEUE_OPTIONS_T,DETERMINISTIC,DIGITS,DISPOSE,DO,EACH,' +
    'ELSIF,END,ENQUEUE_OPTIONS_T,ENTRY,EXCEPTION,EXCEPTION_INIT,EXIT,' +
    'EXTERNAL,FALSE,FETCH,FIXED,FORALL,FORM,FOUND,FUNCTION,GENERIC,GOTO,IF,' +
    'INDEXES,INDICATOR,INSTEAD,INTERFACE,ISOPEN,LANGUAGE,LCR$_DDL_RECORD,' +
    'LCR$_ROW_LIST,LCR$_ROW_RECORD,LCR$_ROW_UNIT,LIMITED,LOOP,MAXLEN,' +
    'MESSAGE_PROPERTIES_T,MGW_BASIC_MSG_T,MGW_MQSERIES_PROPERTIES,' +
    'MGW_NAME_TYPE_ARRAY_T,MGW_NAME_VALUE_T,MGW_PROPERTIES,MGW_PROPERTY,' +
    'MGW_RAW_VALUE_T,MGW_TEXT_VALUE_T,NAME,NEW,NEXTVAL,NOTFOUND,' +
    'NUMBER_BASE,OLD,OPEN,OUT,PACKAGE,PARALLEL_ENABLE,PARTITION,PASCAL,' +
    'PRAGMA,PRIVATE,PROCEDURE,RAISE,RANGE,RE$ATTRIBUTE_VALUE,' +
    'RE$ATTRIBUTE_VALUE_LIST,RE$COLUMN_VALUE,RE$COLUMN_VALUE_LIST,' +
    'RE$NAME_ARRAY,RE$NV_ARRAY,RE$NV_LIST,RE$NV_NODE,RE$RULE_HIT,' +
    'RE$RULE_HIT_LIST,RE$TABLE_ALIAS,RE$TABLE_ALIAS_LIST,' +
    'RE$TABLE_VALUE,RE$TABLE_VALUE_LIST,RE$VARIABLE_TYPE,' +
    'RE$VARIABLE_TYPE_LIST,RE$VARIABLE_VALUE,RE$VARIABLE_VALUE_LIST,RECORD,' +
    'REF,REFERENCING,RELEASE,REMR,REQ,RESP,RESTRICT_REFERENCES,RETURN,' +
    'REVERSE,ROLLBACK,ROWCOUNT,ROWTYPE,RUNTIME_INFO,SAVEPOINT,SCHEMA,' +
    'SELF,SEPARATE,SERIALLY_REUSABLE,SPACE,SQL,SQLERROR,STATEMENT,STRUCT,' +
    'SUBTYPE,TABAUTH,TABLES,TASK,TDO,TERMINATE,TRUE,TYPE,USE,VARYING,VIEWS,' +
    'WHEN,WHILE,WORK,WRITE,XOR';

  // Oracle data types
  OracleTypes: string =
    'ANYDATA,ANYDATASET,ANYTYPE,BFILE,BINARY_INTEGER,BLOB,BOOLEAN,CHAR,CLOB,' +
    'DATE,DAY,DBURIType,DEC,DECIMAL,DOUBLE,FLOAT,HTTPURIType,INTEGER,LONG,' +
    'MLSLABEL,MONTH,NATURAL,NATURALN,NCHAR,NCLOB,NUMBER,NUMERIC,' +
    'NVARCHAR2,PLS_INTEGER,POSITIVE,POSITIVEN,RAW,REAL,ROWID,SECOND,SMALLINT,' +
    'TIMESTAMP,URIType,UROWID,VARCHAR,VARCHAR2,XDBURIType,XMLDATA,XMLType,' +
    'YEAR,ZONE';

  // Oracle built in exceptions
  OracleExceptions: string =
    'ACCESS_INTO_NULL,COLLECTION_IS_NULL,CURSOR_ALREADY_OPEN,' +
    'DUP_VAL_ON_INDEX,INVALID_CURSOR,INVALID_NUMBER,LOGIN_DENIED,' +
    'NO_DATA_FOUND,NOT_LOGGED_ON,OTHERS,PROGRAM_ERROR,ROWTYPE_MISMATCH,' +
    'STORAGE_ERROR,SUBSCRIPT_BEYOND_COUNT,SUBSCRIPT_OUTSIDE_LIMIT,' +
    'SYS_INVALID_ROWID,TIMEOUT_ON_RESOURCE,TOO_MANY_ROWS,VALUE_ERROR,' +
    'ZERO_DIVIDE';

  // Oracle built in functions
  OracleFunctions: string =
    'ABS,ACOS,ADD_MONTHS,AGGREGATE,ANALYTIC,ASCII,ASCIISTR,ASIN,ATAN,ATAN2,' +
    'AVERAGE,AVG,BASE64_DECODE,BASE64_ENCODE,BEGIN_REQUEST,BFILENAME,' +
    'BIN_TO_NUM,BIT_AND,BIT_COMPLEMENT,BIT_OR,BIT_XOR,BITAND,' +
    'CAST_FROM_BINARY_INTEGER,CAST_FROM_NUMBER,CAST_TO_BINARY_INTEGER,' +
    'CAST_TO_NUMBER,CAST_TO_RAW,CAST_TO_VARCHAR2,CEIL,CHARTOROWID,CHR,' +
    'COLUMN_PRESENT,COMPARE,COMPARE_TEMPLATES,COMPOSE,CONCAT,CONVERSION,' +
    'CONVERT,CONVERT_ANYDATA_TO_LCR_DDL,CONVERT_ANYDATA_TO_LCR_ROW,' +
    'COPIES,COPY_TEMPLATE,CORR,COS,COSH,COUNT,COVAR_POP,COVAR_SAMP,' +
    'CREATE_OBJECT_FROM_EXISTING,CREATE_PIPE,CREATE_REFRESH_TEMPLATE,' +
    'CREATE_TEMPLATE_OBJECT,CREATE_TEMPLATE_PARM,CREATE_USER_AUTHORIZATION,' +
    'CREATE_USER_PARM_VALUE,CRLF,CUBE,CUME_DIST,CURRENT_DATE,' +
    'CURRENT_INSTANCE,CURRENT_TIMESTAMP,DATA_BLOCK_ADDRESS_BLOCK,' +
    'DATA_BLOCK_ADDRESS_FILE,DBTIMEZONE,DECODE,DECOMPOSE,DELETE_BREAKPOINT,' +
    'DELETE_OER_BREAKPOINT,DENSE_RANK,DEPTH,DEREF,DISABLE_BREAKPOINT,' +
    'DISABLED,DISPLAY,DROP_ALL,DROP_ELEMENT,DROP_FILE,DUMP,' +
    'EMPTY_BLOB,EMPTY_CLOB,ENABLE_BREAKPOINT,EQUALS_PATH,ESTIMATE_CPU_UNITS,' +
    'EXCLUDE_PUSH,EXECUTE_AND_FETCH,EXECUTE_NON_QUERY,EXISTSNODE,EXP,EXTEND,' +
    'EXTRACT,EXTRACTVALUE,FCOPY,FETCH_ROW,FETCH_ROWS,FGETPOS,FILEEXISTS,' +
    'FILEISOPEN,FIRST,FIRST_VALUE,FLOOR,FLUSH_DATA,FOPEN,FOPEN_NCHAR,' +
    'FORMAT_CALL_STACK,FORMAT_ERROR_STACK,FREMOVE,FRENAME,FROM_REMOTE,FSEEK,' +
    'GET_ARG_FORM,GET_ARG_TYPE,GET_COOKIE_COUNT,GET_COOKIES,' +
    'GET_DETAILED_SQLCODE,GET_DETAILED_SQLERRM,GET_ERROR_MESSAGE,' +
    'GET_HASH_VALUE,GET_HEADER_COUNT,GET_INDEXES,GET_INFORMATION,' +
    'GET_OBJECT_NULL_VECTOR_ARG,GET_PARAMETER_VALUE,' +
    'GET_PERSISTENT_CONN_COUNT,GET_RAW,GET_RESPONSE,GET_RUNTIME_INFO,' +
    'GET_RUNTIME_PARM_ID,GET_SESSION_TIMEOUT,GET_SYSTEM_CHANGE_NUMBER,' +
    'GET_TAG,GET_TIME,GET_TIMEOUT,GET_TIMEOUT_BEHAVIOR,GET_VALUE,' +
    'GETCHUNKSIZE,GETLENGTH,GLB,GREATEST,GREATEST_LB,GROUP_ID,GROUPING,' +
    'GROUPING_ID,HEXTORAW,I_AM_A_REFRESH,INITCAP,INITIALIZE,' +
    'INSTANTIATE_OFFLINE,INSTANTIATE_ONLINE,INSTR,INSTRB,' +
    'INTERNAL_VERSION_CHECK,IS_CLUSTER_DATABASE,IS_LOCATOR,IS_OPEN,' +
    'IS_ROLE_ENABLED,IS_SESSION_ALIVE,IS_TRIGGER_FIRE_ONCE,ISTEMPORARY,LAG,' +
    'LAST,LAST_DAY,LAST_ERROR_POSITION,LAST_ROW_COUNT,LAST_ROW_ID,' +
    'LAST_SQL__CODE,LAST_VALUE,LEAD,LEAST,LEAST_LB,LENGTH,LENGTHB,LINEAR,LN,' +
    'LOCAL_TRANSACTION_ID,LOCALTIMESTAMP,LOG,LOWER,LPAD,LTRIM,LUB,' +
    'MAKE_DATA_BLOCK_ADDRESS,MAKE_REF,MAP_ALL,MAP_ELEMENT,MAP_FILE,' +
    'MAP_OBJECT,MAX,MIN,MINE_VALUE,MISCELLANEOUS,MOD,MONTHS_BETWEEN,NCHR,' +
    'NEW_TIME,NEXT_DAY,NEXT_ITEM_TYPE,NLS_CHARSET_DECL_LEN,NLS_CHARSET_ID,' +
    'NLS_CHARSET_NAME,NLS_INITCAP,NLS_LOWER,NLS_SORT,NLS_UPPER,NLSSORT,NTILE,' +
    'NULLIF,NUMTODSINTERVAL,NUMTOYMINTERVAL,NVARRAY_FIND_NAME,' +
    'NVARRAY_FIND_NAME_TYPE,NVARRAY_GET,NVARRAY_GET_BOOLEAN,NVARRAY_GET_BYTE,' +
    'NVARRAY_GET_DATE,NVARRAY_GET_DOUBLE,NVARRAY_GET_FLOAT,' +
    'NVARRAY_GET_INTEGER,NVARRAY_GET_LONG,NVARRAY_GET_RAW,NVARRAY_GET_SHORT,' +
    'NVARRAY_GET_TEXT,NVL,NVL2,OBJECT,OPEN_CURSOR,OVER,OVERLAY,PATH,' +
    'PAUSE_PROFILER,PERCENT_RANK,PERCENTILE_CONT,PERCENTILE_DISC,PMARKER,' +
    'PORT_STRING,POWER,PURGE,PUSH,PUT_RAW,QUOTED_PRINTABLE_DECODE,' +
    'QUOTED_PRINTABLE_ENCODE,RANDOM,RANK,RATIO_TO_REPORT,RATION_TO_REPORT,' +
    'RAWTOHEX,RAWTONHEX,RECEIVE_MESSAGE,REFERENCE,REFTOHEX,REGR_AVGX,' +
    'REGR_AVGY,REGR_COUNT,REGR_INTERCEPT,REGR_R2,REGR_SLOPE,REGR_SXX,' +
    'REGR_SXY,REGR_SYY,REGRESSION,REMOVE_PIPE,REPLACE,REPLICATION_IS_ON,' +
    'REQUEST,REQUEST_PIECES,RESTORE,RESUME_PROFILER,RETURNING,ROLLUP,ROUND,' +
    'ROW_NUMBER,ROWID_BLOCK_NUMBER,ROWID_CREATE,ROWID_OBJECT,' +
    'ROWID_RELATIVE_FNO,ROWID_ROW_NUMBER,ROWID_TO_ABSOLUTE_FNO,' +
    'ROWID_TO_EXTENDED,ROWID_TO_RESTRICTED,ROWID_TYPE,ROWID_VERIFY,' +
    'ROWIDTOCHAR,ROWIDTONCHAR,RPAD,RTRIM,SEND_MESSAGE,SESSIONTIMEZONE,' +
    'SET_BREAKPOINT,SET_OER_BREAKPOINT,SET_TIMEOUT,SET_VALUE,SIGN,SIN,SINH,' +
    'SOUNDEX,SPACE_ERROR_INFO,SQLCODE,SQLERRM,SQRT,START_PROFILER,STDDEV,' +
    'STDDEV_POP,STDDEV_SAMP,STDDEVP,STDDEVS,STEP_ID,STOP_PROFILER,SUBSTR,' +
    'SUBSTRB,SUM,SYNCHRONIZE,SYS_CONNECT_BY_PATH,SYS_CONTEXT,SYS_DBURIGEN,' +
    'SYS_EXTRACT_UTC,SYS_GUID,SYS_TYPEID,SYS_XMLAGG,SYS_XMLGEN,SYSDATE,' +
    'SYSTIMESTAMP,TAN,TANH,TO_CHAR,TO_CLOB,TO_DATE,TO_DSINTERVAL,TO_LABEL,' +
    'TO_LOB,TO_MULTI_BYTE,TO_NCHAR,TO_NCLOB,TO_NUMBER,TO_SINGLE_BYTE,' +
    'TO_TIMESTAMP,TO_TIMESTAMP_TZ,TO_YMINTERVAL,TRANSLATE,TRANSLITERATE,' +
    'TREAT,TRIM,TRUNC,TZ_OFFSET,UID,UNDER_PATH,UNESCAPE,UNIQUE_SESSION_ID,' +
    'UNIQUE_SESSION_NAME,UNISTR,UPDATEXML,UPPER,USER,USERENV,USING,UUDECODE,' +
    'UUENCODE,VALUE,VAR_POP,VAR_SAMP,VARIANCE,VARP,VARS,VSIZE,WIDTH_BUCKET,' +
    'XMLAGG,XMLCOLATTVAL,XMLCONCAT,XMLELEMENT,XMLFOREST,XMLSEQUENCE,' +
    'XMLTRANSFORM,XRANGE';

  OracleDefaultPackages: string =
    'DBMS_ALERT,DBMS_APPLICATION_INFO,DBMS_APPLY_ADM,DBMS_AQ,' +
    'DBMS_AQ_EXP_HISTORY_TABLES,DBMS_AQ_EXP_INDEX_TABLES,' +
    'DBMS_AQ_EXP_QUEUE_TABLES,DBMS_AQ_EXP_QUEUES,' +
    'DBMS_AQ_EXP_SUBSCRIBER_TABLES,DBMS_AQ_EXP_TIMEMGR_TABLES,' +
    'DBMS_AQ_EXP_ZECURITY,DBMS_AQ_IMP_INTERNAL,DBMS_AQ_IMP_ZECURITY,' +
    'DBMS_AQ_IMPORT_INTERNAL,DBMS_AQ_SYS_EXP_ACTIONS,' +
    'DBMS_AQ_SYS_EXP_INTERNAL,DBMS_AQ_SYS_IMP_INTERNAL,DBMS_AQADM,' +
    'DBMS_AQADM_SYS,DBMS_AQADM_SYSCALLS,DBMS_AQELM,DBMS_AQIN,' +
    'DBMS_AQJMS,DBMS_BACKUP_RESTORE,DBMS_CAPTURE_ADM,DBMS_DDL,' +
    'DBMS_DEBUG,DBMS_DEFER,DBMS_DEFER_IMPORT_INTERNAL,DBMS_DEFER_QUERY,' +
    'DBMS_DEFER_SYS,DBMS_DESCRIBE,DBMS_DISTRIBUTED_TRUST_ADMIN,' +
    'DBMS_EXPORT_EXTENSION,DBMS_FGA,DBMS_FLASHBACK,DBMS_HS_PASSTHROUGH,' +
    'DBMS_IJOB,DBMS_INTERNAL_TRIGGER,DBMS_IOT,DBMS_IREFRESH,DBMS_ISNAPSHOT,' +
    'DBMS_JAVA_TEST,DBMS_JOB,DBMS_LDAP,DBMS_LIBCACHE,DBMS_LOB,DBMS_LOCK,' +
    'DBMS_LOGMNR,DBMS_LOGMNR_CDC_PUBLISH,DBMS_LOGMNR_CDC_SUBSCRIBE,' +
    'DBMS_LOGMNR_D,DBMS_LOGSTDBY,DBMS_METADATA,DBMS_MGWADM,' +
    'DBMS_MGWMSG,DBMS_MVIEW,DBMS_OBFUSCATION_TOOLKIT,DBMS_ODCI,' +
    'DBMS_OFFLINE_OG,DBMS_OFFLINE_SNAPSHOT,DBMS_OLAP,' +
    'DBMS_ORACLE_TRACE_AGENT,DBMS_ORACLE_TRACE_USER,DBMS_OUTLN,' +
    'DBMS_OUTLN_EDIT,DBMS_OUTPUT,DBMS_PCLXUTIL,DBMS_PICKLER,DBMS_PIPE,' +
    'DBMS_PITR,DBMS_PLUGTS,DBMS_PROFILER,DBMS_PROPAGATION_ADM,' +
    'DBMS_PRVTAQIM,DBMS_PRVTAQIP,DBMS_PRVTAQIS,DBMS_PRVTRMIE,DBMS_PSP,' +
    'DBMS_PSWMG_IMPORT,DBMS_RANDOM,DBMS_RCVMAN,DBMS_RECTIFIER_DIFF,' +
    'DBMS_REDEFINITION,DBMS_REFRESH,DBMS_REFRESH_EXP_LWM,' +
    'DBMS_REFRESH_EXP_SITES,DBMS_REPAIR,DBMS_REPCAT,DBMS_REPCAT_ADMIN,' +
    'DBMS_REPCAT_AUTH,DBMS_REPCAT_INSTANTIATE,DBMS_REPCAT_RGT,DBMS_REPUTIL,' +
    'DBMS_RESOURCE_MANAGER,DBMS_RESOURCE_MANAGER_PRIVS,DBMS_RESUMABLE,' +
    'DBMS_RLS,DBMS_RMGR_GROUP_EXPORT,DBMS_RMGR_PACT_EXPORT,' +
    'DBMS_RMGR_PLAN_EXPORT,DBMS_RMIN,DBMS_ROWID,DBMS_RULE,DBMS_RULE_ADM,' +
    'DBMS_RULE_EXIMP,DBMS_SESSION,DBMS_SHARED_POOL,DBMS_SNAP_INTERNAL,' +
    'DBMS_SNAP_REPAPI,DBMS_SNAPSHOT,DBMS_SNAPSHOT_UTL,DBMS_SPACE,' +
    'DBMS_SPACE_ADMIN,DBMS_SQL,DBMS_STANDARD,DBMS_STATS,DBMS_STORAGE_MAP,' +
    'DBMS_STREAMS,DBMS_STREAMS_ADM,DBMS_SUMADV,DBMS_SUMMARY,' +
    'DBMS_SUMREF_CHILD,DBMS_SUMREF_PARENT,DBMS_SUMREF_UTIL,' +
    'DBMS_SUMREF_UTIL2,DBMS_SUMVDM,DBMS_SYS_ERROR,DBMS_SYS_SQL,' +
    'DBMS_SYSTEM,DBMS_TRACE,DBMS_TRANSACTION,DBMS_TRANSFORM,DBMS_TTS,' +
    'DBMS_TYPES,DBMS_UTILITY,DBMS_WM,DBMS_XDB,DBMS_XDB_VERSION,DBMS_XDBT,' +
    'DBMS_XMLDOM,DBMS_XMLGEN,DBMS_XMLPARSER,DBMS_XMLQUERY,' +
    'DBMS_XMLSAVE,DBMS_XPLAN,DBMS_XSLPROCESSOR,DBMS_ZHELP,DBMS_ZHELP_IR,' +
    'DBMSZEXP_SYSPKGGRNT,DEBUG_EXTPROC,DIANA,DIUTIL,ODCICONST,OUTLN_PKG,' +
    'PBREAK,PBRPH,PBSDE,PBUTL,PIDL,PLITBLM,SDO_CS,SDO_GEOM,SDO_LRS,' +
    'SDO_MIGRATE,SDO_TUNE,SDO_UTIL,STANDARD,SYS_STUB_FOR_PURITY_ANALYSIS,' +
    'UTL_COLL,UTL_ENCODE,UTL_FILE,UTL_FILE_DIR,UTL_HTTP,UTL_INADDR,UTL_PG,' +
    'UTL_RAW,UTL_REF,UTL_SMTP,UTL_TCP,UTL_URL';

  OracleSQLPlusCommands: string =
    'APP,APPINFO,AQ$_AGENT,AQ$_AGENT_LIST_T,AQ$_DESCRIPTOR,AQ$_POST_INFO,' +
    'AQ$_POST_INFO_LIST,AQ$_RECIPIENT_LIST_T,AQ$_REG_INFO,AQ$_REG_INFO_LIST,' +
    'AQ$_SUBSCRIBER_LIST_T,ARCHIVE,ARRAYSIZE,ATTRIBUTE,AUTOCOMMIT,AUTOP,' +
    'AUTOPRINT,AUTORECOVERY,AUTOT,AUTOTRACE,BLO,BLOCKTERMINATOR,BRE,BREAK,' +
    'BTI,BTITLE,BUFFER,CL,CLEAR,CLOSECURSOR,CMDS,CMDSEP,COL,COLSEP,COM,COMP,' +
    'COMPAT,COMPATIBILITY,CON,CONN,COPY,COPYC,COPYCOMMIT,COPYTYPECHECK,DEF,' +
    'DEFINE,DESC,DESCR,DESCRI,DESCRIB,DESCRIBE,DISC,DISCO,DISCON,DISCONN,' +
    'DISCONNE,DISCONNEC,DISCONNECT,EA,ECHO,EDITF,EDITFILE,EMB,' +
    'EMBEDDED,ESC,EXEC,EXECUTE,FAILURE,FEED,FEEDBACK,FLAGGER,FLU,FULL,GET,' +
    'HEA,HEADING,HEADS,HEADSEP,HELP,HO,HOST,INPUT,INTERMED,INTERMEDIATE,INV,' +
    'INVISIBLE,LIN,LINESIZE,LO,LOBOF,LOBOFFSET,LOGON,LOGSOURCE,LONGC,' +
    'LONGCHUNKSIZE,MARKUP,MAXDATA,MIX,MIXED,NATIVE,NEWP,NEWPAGE,NUM,' +
    'NUMF,NUMFORMAT,NUMWIDTH,OFF,OSERROR,PAGES,PAGESIZE,PASSW,PAU,PAUSE,' +
    'PPRINT,PRI,PRINT,PROMPT,RECSEP,RECSEPCHAR,REPF,REPFOOTER,REPH,REPHEADER,' +
    'RUN,SAVE,SCAN,SERVEROUTPUT,SET,SHIFT,SHIFTINOUT,SHO,SHOW,SHUTDOWN,' +
    'SILENT,SPOOL,SQLBL,SQLBLANKLINES,SQLC,SQLCASE,SQLCO,SQLCONTINUE,SQLN,' +
    'SQLNUMBER,SQLP,SQLPRE,SQLPREFIX,SQLPROMPT,SQLT,SQLTERMINATOR,STA,' +
    'STARTUP,STATEMENT_ID,STORE,SUCCESS,SUF,SUFFIX,TAB,TERM,TERMOUT,TI,TIMI,' +
    'TIMING,TRIMOUT,TRIMS,TRIMSPOOL,TTI,TTITLE,UND,UNDEF,UNDEFINE,' +
    'UNDERLINE,UP,VAR,VARIABLE,VER,VERIFY,VERSION,VIS,VISIBLE,WHENEVER,WR,' +
    'WRA,WRAP,WRAPPED';

  OracleCommentKW: string =
    'REM,REMA,REMAR,REMARK';

  //---Postgresql-----------------------------------------------------------------
  //Postgresql Keywords
  PostgresKW: String =
    'IF,LOOP,ABORT,ABSOLUTE,ACCESS,ACTION,ADA,ADD,ADMIN,AFTER,AGGREGATE,ALIAS' +
    ',ALLOCATE,ALTER,ANALYSE,ANALYZE,AND,ARE,AS,ASC,ASENSITIVE' +
    ',ASSERTION,ASSIGNMENT,ASYMMETRIC,AT,ATOMIC,AUTHORIZATION,BACKWARD' +
    ',BEFORE,BEGIN,BETWEEN' +
    ',BOTH,BREADTH,BY,C,CACHE,CALL,CALLED,CARDINALITY,CASCADE,CASCADED,CASE' +
    ',CAST,CATALOG,CATALOG_NAME,CHAIN,CHARACTERISTICS' +
    ',CHARACTER_SET_CATALOG,CHARACTER_SET_NAME,CHARACTER_SET_SCHEMA' +
    ',CHECK,CHECKED,CHECKPOINT,CLASS,CLASS_ORIGIN,CLOB,CLOSE,CLUSTER,COBOL,COLLATE' +
    ',COLLATION,COLLATION_CATALOG,COLLATION_NAME,COLLATION_SCHEMA,COLUMN,COLUMN_NAME' +
    ',COMMAND_Function,COMMAND_Function_CODE,COMMENT,COMMIT,COMMITTED,COMPLETION' +
    ',CONDITION_NUMBER,CONNECT,CONNECTION,CONNECTION_NAME,CONSTRAINT,CONSTRAINTS' +
    ',CONSTRAINT_CATALOG,CONSTRAINT_NAME,CONSTRAINT_SCHEMA,CONSTRUCTOR,CONTAINS' +
    ',CONTINUE,CONVERSION,COPY,CORRESPONDING,CREATE,CREATEDB,CREATEUSER' +
    ',CROSS,CUBE,CURRENT,CURRENT_PATH,CURRENT_ROLE' +
    ',CURSOR,CURSOR_NAME,CYCLE,DATA,DATABASE,DATETIME_INTERVAL_CODE' +
    ',DATETIME_INTERVAL_PRECISION,DAY,DEALLOCATE,DEC,DECLARE,DEFAULT,DEFERRABLE' +
    ',DEFERRED,DEFINED,DEFINER,DELETE,DELIMITER,DELIMITERS,DEPTH,DEREF,DESC,DESCRIBE' +
    ',DESCRIPTOR,DESTROY,DESTRUCTOR,DETERMINISTIC,DIAGNOSTICS,DICTIONARY,DISCONNECT' +
    ',DISPATCH,DISTINCT,DO,DOMAIN,DROP,DYNAMIC,DYNAMIC_Function,DYNAMIC_Function_CODE' +
    ',EACH,ELSE,ELSIF,ELSEIF,ENCODING,ENCRYPTED,END,EQUALS,ESCAPE,EXCEPT,EXCEPTION' +
    ',EXCLUSIVE,EXEC,EXECUTE,EXISTING,EXPLAIN,EXTERNAL,FALSE,FETCH' +
    ',FINAL,FIRST,FOR,FORCE,FOREIGN,FORTRAN,FORWARD,FOUND,FREE,FREEZE,FROM' +
    ',FULL,Function,G,GENERAL,GENERATED,GET,GLOBAL,GO,GOTO,GRANT,GRANTED,GROUP' +
    ',GROUPING,HANDLER,HAVING,HIERARCHY,HOLD,HOUR,IDENTITY,IGNORE,ILIKE' +
    ',IMMEDIATE,IMMUTABLE,IMPLEMENTATION,IMPLICIT,INCREMENT,INDEX,INDICATOR' +
    ',INFIX,INHERITS,INITIALIZE,INITIALLY,INNER,INOUT,INPUT,INSENSITIVE,INSERT' +
    ',INSTANCE,INSTANTIABLE,INSTEAD,INT,INTERSECT,INTO,INVOKER' +
    ',IS,ISNULL,ISOLATION,ITERATE,JOIN,K,KEY,KEY_MEMBER,KEY_TYPE,LANCOMPILER,LANGUAGE' +
    ',LARGE,LAST,LATERAL,LEADING,LEFT,LESS,LEVEL,LIKE,LIMIT,LISTEN,LOAD,LOCAL' +
    ' LOCATION,LOCATOR,LOCK,M,MAP,MATCH,MAXVALUE,MESSAGE_LENGTH' +
    ',MESSAGE_OCTET_LENGTH,MESSAGE_TEXT,METHOD,MINUTE,MINVALUE,MODE,MODIFIES' +
    ',MODIFY,MODULE,MONTH,MORE,MOVE,MUMPS,NAME,NAMES,NATIONAL,NATURAL,NCHAR,NCLOB' +
    ',NEW,NEXT,NO,NOCREATEDB,NOCREATEUSER,NONE,NOT,NOTHING,NOTIFY,NOTNULL,NULL,NULLABLE' +
    ',NUMBER,OBJECT,OF,OFF,OFFSET,OIDS,OLD,ON,ONLY,OPEN' +
    ',OPERATION,Operator,OPTION,OPTIONS,OR,ORDER,ORDINALITY,OUT,OUTER,OUTPUT,OVERLAPS' +
    ',OVERRIDING,OWNER,PAD,PARAMETER,PARAMETERS,PARAMETER_MODE,PARAMETER_NAME,PARAMETER_ORDINAL_POSITION' +
    ',PARAMETER_SPECIFIC_CATALOG,PARAMETER_SPECIFIC_NAME,PARAMETER_SPECIFIC_SCHEMA,PARTIAL,PASCAL,PASSWORD' +
    ',PENDANT,PLACING,PLI,POSTFIX,PRECISION,PREFIX,PREORDER,PREPARE,PRESERVE,PRIMARY' +
    ',PRIOR,PRIVILEGES,PROCEDURAL,PROCEDURE,PUBLIC,READ,READS,RECHECK,RECURSIVE,REF,REFERENCES' +
    ',REFERENCING,REINDEX,RELATIVE,RENAME ,REPEATABLE,RESET,RESTRICT,RESULT,RETURN,RETURNED_LENGTH' +
    ',RETURNED_OCTET_LENGTH,RETURNED_SQLSTATE,RETURNS,REVOKE,RIGHT,ROLE,ROLLBACK,ROLLUP,ROUTINE,ROUTINE_CATALOG' +
    ',ROUTINE_NAME,ROUTINE_SCHEMA,ROW,ROWS,ROW_COUNT,RULE,SAVEPOINT,SCALE,SCHEMA,SCHEMA_NAME' +
    ',SCOPE,SCROLL,SEARCH,SECOND,SECTION,SECURITY,SELECT,SELF,SENSITIVE,SEQUENCE,SERIALIZABLE,SERVER_NAME' +
    ',SESSION,SET,SETOF,SETS,SHARE,SHOW,SIMILAR,SIMPLE,SIZE,SOURCE,SPACE' +
    ',SPECIFIC,SPECIFICTYPE,SPECIFIC_NAME,SQLCODE,SQLERROR,SQLEXCEPTION,SQLSTATE,SQLWARNING' +
    ',STABLE,START,STATE,STATEMENT,STATIC,STATISTICS,STDIN,STDOUT,STORAGE,STRICT,STRUCTURE' +
    ',STYLE,SUBCLASS_ORIGIN,SUBLIST,SYMMETRIC,SYSID,SYSTEM,SYSTEM_USER,TABLE' +
    ',TABLE_NAME,TEMP,TEMPLATE,TEMPORARY,TERMINATE,THAN,THEN,TIMEZONE_HOUR' +
    ',TIMEZONE_MINUTE,TO,TOAST,TRAILING,TRANSACTION,TRANSACTIONS_COMMITTED,TRANSACTIONS_ROLLED_BACK' +
    ',TRANSACTION_ACTIVE,TRANSFORM,TRANSFORMS,TRANSLATION,TREAT,TRIGGER_CATALOG' +
    ',TRIGGER_NAME,TRIGGER_SCHEMA,TRUE,TRUNCATE,TRUSTED,TYPE,UNCOMMITTED,UNDER,UNENCRYPTED,UNION'+
    ',UNIQUE,UNKNOWN,UNLISTEN,UNNAMED,UNNEST,UNTIL,UPDATE,USAGE,USER_DEFINED_TYPE_CATALOG' +
    ',USER_DEFINED_TYPE_NAME,USER_DEFINED_TYPE_SCHEMA,USING,VACUUM,VALID,VALIDATOR,VALUE,VALUES' +
    ',VARIABLE,VARYING,VERBOSE,VIEW,VOLATILE,WHEN,WHENEVER,WHERE,WITH,WITHOUT,WORK,WRITE,YEAR,ZONE';

  //Postgresql Functions
  PostgresFunctions:String =
    'abs,cbrt,ceil,ceiling,degrees,exp,floor,ln,log,mod,pi,power,radians,random,'+
    'round,setseed,sign,sqrt,trunc,width_bucket,acos,asin,atan,atan2,cos,cot,'+
    'sin,tan,bit_length,char_length,character_length,convert,lower,octet_length,'+
    'overlay,position,substring,trim,upper,ascii,btrim,chr,decode,'+
    'encode,initcap,length,lpad,ltrim,md5,pg_client_encoding,quote_ident,quote_literal,'+
    'replace,rpad,rtrim,split_part,strpos,substr,to_ascii,to_hex,translate,get_byte,'+
    'set_byte,get_bit,set_bit,to_char,to_date,'+
    'to_timestamp,to_number,age,date_part,date_trunc,extract,now,'+
    'timeofday,isfinite,area,box_intersect,center,diameter,height,isclosed,isopen,'+
    'npoints,pclose,popen,radius,width,'+
    'broadcast,'+
    'host,masklen,set_masklen,netmask,hostmask,network,abbrev,family,nextval,'+
    'currval,setval,coalesce,nullif,array_cat ,array_append ,array_prepend ,array_dims,'+
    'array_lower ,array_upper ,array_to_string ,string_to_array ,avg,bit_and,bit_or,bool_and,'+
    'bool_or,count,every,max,min,stddev,sum,variance,exists ,in ,some,'+
    'all ,generate_series,current_database,current_schema,'+
    'current_schemas,,inet_client_addr,inet_client_port,inet_server_addr,inet_server_port,'+
    'version,has_table_privilege,has_database_privilege,'+
    'has_function_privilege,has_language_privilege,'+
    'has_schema_privilege,has_tablespace_privilege,'+
    'pg_table_is_visible,pg_type_is_visible,pg_function_is_visible,pg_operator_is_visible,'+
    'pg_opclass_is_visible,pg_conversion_is_visible,format_type,pg_get_viewdef,'+
    'pg_get_ruledef,pg_get_indexdef,'+
    'pg_get_triggerdef,pg_get_constraintdef,pg_get_expr,'+
    'pg_get_userbyid,pg_get_serial_sequence,pg_tablespace_databases,obj_description,'+
    'col_description,current_setting,set_config,pg_cancel_backend,pg_start_backup,pg_stop_backup,'+
    'current_user,current_date,current_time,current_timestamp,localtime,localtimestamp,session_user,user';

  //Postgresql Types
  PostgresTypes: String =
    'smallint,integer,bigint,decimal,numeric,real,double,serial,bigserial,'+
    'character,varchar,char,text,bytea,timestamp, interval,date,'+
    'time,boolean,point,line,lseg,box,path,polygon,circle,cidr,inet,'+
    'macaddr,BIT,bitvar,ARRAY,oid,regproc,regprocedure,regoper,regoperator,regclass,'+
    'regtype,any,anyarray,anyelement,cstring,internal,language_handler,record,'+
    'trigger,void,opaque,refcursor,binary,blob,int4,int2,int8,float,float4,float8';

  //Postgresql Exceptions
  PostgresExceptions: String =
    '$BODY$,SUCCESSFUL_COMPLETION,WARNING,DYNAMIC_RESULT_SETS_RETURNED,IMPLICIT_ZERO_BIT_PADDING,NULL_VALUE_ELIMINATED_IN_SET_FUNCTION,'+
    'PRIVILEGE_NOT_GRANTED,PRIVILEGE_NOT_REVOKED,STRING_DATA_RIGHT_TRUNCATION,DEPRECATED_FEATURE,NO_DATA,NO_ADDITIONAL_DYNAMIC_RESULT_SETS_RETURNED,'+
    'SQL_STATEMENT_NOT_YET_COMPLETE,CONNECTION_EXCEPTION,CONNECTION_DOES_NOT_EXIST,CONNECTION_FAILURE,SQLCLIENT_UNABLE_TO_ESTABLISH_SQLCONNECTION,'+
    'SQLSERVER_REJECTED_ESTABLISHMENT_OF_SQLCONNECTION,TRANSACTION_RESOLUTION_UNKNOWN,PROTOCOL_VIOLATION,TRIGGERED_ACTION_EXCEPTION,'+
    'FEATURE_NOT_SUPPORTED,INVALID_TRANSACTION_INITIATION,LOCATOR_EXCEPTION,INVALID_LOCATOR_SPECIFICATION,INVALID_GRANTOR,INVALID_GRANT_OPERATION,'+
    'INVALID_ROLE_SPECIFICATION,CARDINALITY_VIOLATION,DATA_EXCEPTION,ARRAY_SUBSCRIPT_ERROR,CHARACTER_NOT_IN_REPERTOIRE,DATETIME_FIELD_OVERFLOW,'+
    'DIVISION_BY_ZERO,ERROR_IN_ASSIGNMENT,ESCAPE_CHARACTER_CONFLICT,INDICATOR_OVERFLOW,INTERVAL_FIELD_OVERFLOW,INVALID_ARGUMENT_FOR_LOGARITHM,'+
    'INVALID_ARGUMENT_FOR_POWER_FUNCTION,INVALID_ARGUMENT_FOR_WIDTH_BUCKET_FUNCTION,INVALID_CHARACTER_VALUE_FOR_CAST,INVALID_DATETIME_FORMAT,'+
    'INVALID_ESCAPE_CHARACTER,INVALID_ESCAPE_OCTET,INVALID_ESCAPE_SEQUENCE,INVALID_INDICATOR_PARAMETER_VALUE,INVALID_LIMIT_VALUE,'+
    'INVALID_PARAMETER_VALUE,INVALID_REGULAR_EXPRESSION,INVALID_TIME_ZONE_DISPLACEMENT_VALUE,INVALID_USE_OF_ESCAPE_CHARACTER,'+
    'MOST_SPECIFIC_TYPE_MISMATCH,NULL_VALUE_NOT_ALLOWED,NULL_VALUE_NO_INDICATOR_PARAMETER,NUMERIC_VALUE_OUT_OF_RANGE,STRING_DATA_LENGTH_MISMATCH,'+
    'SUBSTRING_ERROR,TRIM_ERROR,UNTERMINATED_C_STRING,ZERO_LENGTH_CHARACTER_STRING,FLOATING_POINT_EXCEPTION,'+
    'INVALID_TEXT_REPRESENTATION,INVALID_BINARY_REPRESENTATION,BAD_COPY_FILE_FORMAT,UNTRANSLATABLE_CHARACTER,INTEGRITY_CONSTRAINT_VIOLATION,'+
    'RESTRICT_VIOLATION,NOT_NULL_VIOLATION,FOREIGN_KEY_VIOLATION,UNIQUE_VIOLATION,CHECK_VIOLATION,INVALID_CURSOR_STATE,INVALID_TRANSACTION_STATE,'+
    'ACTIVE_SQL_TRANSACTION,BRANCH_TRANSACTION_ALREADY_ACTIVE,HELD_CURSOR_REQUIRES_SAME_ISOLATION_LEVEL,INAPPROPRIATE_ACCESS_MODE_FOR_BRANCH_TRANSACTION,'+
    'INAPPROPRIATE_ISOLATION_LEVEL_FOR_BRANCH_TRANSACTION,NO_ACTIVE_SQL_TRANSACTION_FOR_BRANCH_TRANSACTION,READ_ONLY_SQL_TRANSACTION,'+
    'SCHEMA_AND_DATA_STATEMENT_MIXING_NOT_SUPPORTED,NO_ACTIVE_SQL_TRANSACTION,IN_FAILED_SQL_TRANSACTION,INVALID_SQL_STATEMENT_NAME,TRIGGERED_DATA_CHANGE_VIOLATION,'+
    'INVALID_AUTHORIZATION_SPECIFICATION,DEPENDENT_PRIVILEGE_DESCRIPTORS_STILL_EXIST,DEPENDENT_OBJECTS_STILL_EXIST,INVALID_TRANSACTION_TERMINATION,'+
    'SQL_ROUTINE_EXCEPTION,FUNCTION_EXECUTED_NO_RETURN_STATEMENT,MODIFYING_SQL_DATA_NOT_PERMITTED,PROHIBITED_SQL_STATEMENT_ATTEMPTED,READING_SQL_DATA_NOT_PERMITTED,'+
    'INVALID_CURSOR_NAME,EXTERNAL_ROUTINE_EXCEPTION,CONTAINING_SQL_NOT_PERMITTED,'+
    'EXTERNAL_ROUTINE_INVOCATION_EXCEPTION,INVALID_SQLSTATE_RETURNED,TRIGGER_PROTOCOL_VIOLATED,'+
    'SRF_PROTOCOL_VIOLATED,SAVEPOINT_EXCEPTION,INVALID_SAVEPOINT_SPECIFICATION,INVALID_CATALOG_NAME,INVALID_SCHEMA_NAME,TRANSACTION_ROLLBACK,'+
    'TRANSACTION_INTEGRITY_CONSTRAINT_VIOLATION,SERIALIZATION_FAILURE,STATEMENT_COMPLETION_UNKNOWN,DEADLOCK_DETECTED,SYNTAX_ERROR_OR_ACCESS_RULE_VIOLATION,'+
    'SYNTAX_ERROR,INSUFFICIENT_PRIVILEGE,CANNOT_COERCE,GROUPING_ERROR,INVALID_FOREIGN_KEY,INVALID_NAME,NAME_TOO_LONG,RESERVED_NAME,DATATYPE_MISMATCH,'+
    'INDETERMINATE_DATATYPE,WRONG_OBJECT_TYPE,UNDEFINED_COLUMN,UNDEFINED_FUNCTION,UNDEFINED_TABLE,UNDEFINED_PARAMETER,UNDEFINED_OBJECT,'+
    'DUPLICATE_COLUMN,DUPLICATE_CURSOR,DUPLICATE_DATABASE,DUPLICATE_FUNCTION,DUPLICATE_PREPARED_STATEMENT,DUPLICATE_SCHEMA,DUPLICATE_TABLE,'+
    'DUPLICATE_ALIAS,DUPLICATE_OBJECT,AMBIGUOUS_COLUMN,AMBIGUOUS_FUNCTION,AMBIGUOUS_PARAMETER,AMBIGUOUS_ALIAS,INVALID_COLUMN_REFERENCE,'+
    'INVALID_COLUMN_DEFINITION,INVALID_CURSOR_DEFINITION,INVALID_DATABASE_DEFINITION,INVALID_FUNCTION_DEFINITION,INVALID_PREPARED_STATEMENT_DEFINITION,'+
    'INVALID_SCHEMA_DEFINITION,INVALID_TABLE_DEFINITION,INVALID_OBJECT_DEFINITION,WITH_CHECK_OPTION_VIOLATION,INSUFFICIENT_RESOURCES,'+
    'DISK_FULL,OUT_OF_MEMORY,TOO_MANY_CONNECTIONS,PROGRAM_LIMIT_EXCEEDED,STATEMENT_TOO_COMPLEX,TOO_MANY_COLUMNS,TOO_MANY_ARGUMENTS,'+
    'OBJECT_NOT_IN_PREREQUISITE_STATE,OBJECT_IN_USE,CANT_CHANGE_RUNTIME_PARAM,LOCK_NOT_AVAILABLE,OPERATOR_INTERVENTION,QUERY_CANCELED,'+
    'ADMIN_SHUTDOWN,CRASH_SHUTDOWN,CANNOT_CONNECT_NOW,IO_ERROR,UNDEFINED_FILE,DUPLICATE_FILE,CONFIG_FILE_ERROR,LOCK_FILE_EXISTS,'+
    'PLPGSQL_ERROR,RAISE_EXCEPTION,INTERNAL_ERROR,DATA_CORRUPTED,INDEX_CORRUPTED';

//---MS-SQL 7-------------------------------------------------------------------
  // keywords
  MSSQL7KW: string =
    'ABSOLUTE,ADD,ALL,ALTER,ANY,AS,ASC,AUTHORIZATION,AVG,BACKUP,BEGIN,' +
    'BETWEEN,BREAK,BROWSE,BULK,BY,CASCADE,CHECK,CHECKPOINT,CLOSE,CLUSTERED,' +
    'COLUMN,COMMIT,COMMITTED,COMPUTE,CONFIRM,CONSTRAINT,CONTAINS,' +
    'CONTAINSTABLE,CONTINUE,CONTROLROW,COUNT,CREATE,CROSS,CURRENT,' +
    'CURRENT_DATE,CURRENT_TIME,CURSOR,DATABASE,DBCC,DEALLOCATE,DECLARE,' +
    'DEFAULT,DELETE,DENY,DESC,DISK,DISTINCT,DISTRIBUTED,DOUBLE,DROP,DUMMY,' +
    'DUMP,ELSE,END,ERRLVL,ERROREXIT,ESCAPE,EXCEPT,EXEC,EXECUTE,EXISTS,EXIT,' +
    'FETCH,FILE,FILLFACTOR,FIRST,FLOPPY,FOR,FOREIGN,FREETEXT,FREETEXTTABLE,' +
    'FROM,FULL,GLOBAL,GOTO,GRANT,GROUP,HAVING,HOLDLOCK,IDENTITY,IDENTITYCOL,' +
    'IDENTITY_INSERT,IF,IN,INDEX,INNER,INSERT,INTERSECT,INTO,IS,ISOLATION,' +
    'JOIN,KEY,KILL,LAST,LEFT,LEVEL,LIKE,LINENO,LOAD,MAX,MIN,MIRROREXIT,' +
    'NATIONAL,NEXT,NOCHECK,NONCLUSTERED,NOT,NULL,OF,OFF,OFFSETS,ON,ONCE,' +
    'ONLY,OPEN,OPENDATASOURCE,OPENQUERY,OPENROWSET,OPTION,OR,ORDER,OUTER,' +
    'OVER,PERCENT,PERM,PERMANENT,PIPE,PLAN,PRECISION,PREPARE,PRIMARY,PRINT,' +
    'PRIOR,PRIVILEGES,PROC,PROCEDURE,PROCESSEXIT,PUBLIC,RAISERROR,READ,' +
    'READTEXT,RECONFIGURE,REFERENCES,RELATIVE,REPEATABLE,REPLICATION,RESTORE,' +
    'RESTRICT,RETURN,REVOKE,RIGHT,ROLLBACK,ROWCOUNT,ROWGUIDCOL,RULE,SAVE,' +
    'SCHEMA,SELECT,SERIALIZABLE,SET,SETUSER,SHUTDOWN,SOME,STATISTICS,SUM,' +
    'TABLE,TAPE,TEMP,TEMPORARY,TEXTSIZE,THEN,TO,TOP,TRAN,TRANSACTION,TRIGGER,' +
    'TRUNCATE,TSEQUAL,UNCOMMITTED,UNION,UNIQUE,UPDATE,UPDATETEXT,USE,USER,' +
    'VALUES,VARYING,VIEW,WAITFOR,WHEN,WHERE,WHILE,WITH,WORK,WRITETEXT';

  // functions
  MSSQL7Functions: string =
    '@@CONNECTIONS,@@CPU_BUSY,@@CURSOR_ROWS,@@DATEFIRST,@@DBTS,@@ERROR,' +
    '@@FETCH_STATUS,@@IDENTITY,@@IDLE,@@IO_BUSY,@@LANGID,@@LANGUAGE,' +
    '@@LOCK_TIMEOUT,@@MAX_CONNECTIONS,@@MAX_PRECISION,@@NESTLEVEL,@@OPTIONS,' +
    '@@PACKET_ERRORS,@@PACK_RECEIVED,@@PACK_SENT,@@PROCID,@@REMSERVER,' +
    '@@ROWCOUNT,@@SERVERNAME,@@SERVICENAME,@@SPID,@@TEXTSIZE,@@TIMETICKS,' +
    '@@TOTAL_ERRORS,@@TOTAL_READ,@@TOTAL_WRITE,@@TRANCOUNT,@@VERSION,ABS,' +
    'ACOS,AND,APP_NAME,ASCII,ASIN,ATAN,ATN2,CASE,CAST,CEILING,CHARINDEX,' +
    'COALESCE,COLUMNPROPERTY,COL_LENGTH,COL_NAME,CONVERT,COS,COT,' +
    'CURRENT_TIMESTAMP,CURRENT_USER,CURSOR_STATUS,DATABASEPROPERTY,' +
    'DATALENGTH,DATEADD,DATEDIFF,DATENAME,DATEPART,DAY,DB_ID,DB_NAME,' +
    'DEGREES,DIFFERENCE,EXP,FILEGROUPPROPERTY,FILEGROUP_ID,FILEGROUP_NAME,' +
    'FILEPROPERTY,FILE_ID,FILE_NAME,FLOOR,FORMATMESSAGE,' +
    'FULLTEXTCATALOGPROPERTY,FULLTEXTSERVICEPROPERTY,GETANSINULL,GETDATE,' +
    'HOST_ID,HOST_NAME,IDENT_INCR,IDENT_SEED,INDEXPROPERTY,INDEX_COL,' +
    'ISDATE,ISNULL,ISNUMERIC,IS_MEMBER,IS_SRVROLEMEMBER,LEN,LOG,LOG10,LOWER,' +
    'LTRIM,MONTH,NEWID,NULLIF,OBJECTPROPERTY,OBJECT_ID,OBJECT_NAME,PARSENAME,' +
    'PATINDEX,PERMISSIONS,PI,POWER,QUOTENAME,RADIANS,RAND,REPLACE,REPLICATE,' +
    'REVERSE,ROUND,RTRIM,SESSION_USER,SIGN,SIN,SOUNDEX,SPACE,SQRT,SQUARE,' +
    'STATS_DATE,STR,STUFF,SUBSTRING,SUSER_ID,SUSER_NAME,SUSER_SID,' +
    'SUSER_SNAME,SYSTEM_USER,TAN,TEXTPTR,TEXTVALID,TYPEPROPERTY,UNICODE,' +
    'UPPER,USER_ID,USER_NAME,YEAR';

  // types
  MSSQL7Types: string =
    'BINARY,BIT,CHAR,DATETIME,DECIMAL,FLOAT,IMAGE,INT,MONEY,NCHAR,NTEXT,' +
    'NUMERIC,NVARCHAR,REAL,SMALLDATETIME,SMALLINT,SMALLMONEY,SYSNAME,TEXT,' +
    'TIMESTAMP,TINYINT,UNIQUEIDENTIFIER,VARBINARY,VARCHAR';

//---MS-SQL2K-------------------------------------------------------------------
  // keywords
  MSSQL2000KW =
    'ADD,ALL,ALTER,AND,ANY,AS,ASC,AUTHORIZATION,BACKUP,' +
    'BEGIN,BETWEEN,BREAK,BROWSE,BULK,BY,CASCADE,CASE,' +
    'CHECK,CHECKPOINT,CLOSE,CLUSTERED,COLLATE,' +
    'COLUMN,COMMIT,COMPUTE,CONSTRAINT,CONTAINS,CONTAINSTABLE,' +
    'CONTINUE,CREATE,CROSS,CURRENT,CURSOR,DATABASE,' +
    'DBCC,DEALLOCATE,DECLARE,DEFAULT,DELETE,DENY,DESC,DISK,' +
    'DISTINCT,DISTRIBUTED,DOUBLE,DROP,DUMMY,DUMP,ELSE,END,' +
    'ERRLVL,ESCAPE,EXCEPT,EXEC,EXECUTE,EXISTS,EXIT,FETCH,FILE,' +
    'FILLFACTOR,FOR,FOREIGN,FORMSOF,FREETEXT,FREETEXTTABLE,FROM,FULL,' +
    'FUNCTION,GOTO,GRANT,GROUP,HAVING,HOLDLOCK,IDENTITY,' +
    'IDENTITYCOL,IDENTITY_INSERT,IF,IN,INFLECTIONAL,INDEX,INNER,INSERT,' +
    'INTERSECT,INTO,IS,ISABOUT,JOIN,KEY,KILL,LEFT,LIKE,LINENO,LOAD,' +
    'NATIONAL,NOCHECK,NONCLUSTERED,NOT,NULL,NULLIF,OF,OFF,' +
    'OFFSETS,ON,OPEN,OPENDATASOURCE,OPENQUERY,OPENROWSET,OPENXML,' +
    'OPTION,OR,ORDER,OUTER,OVER,PERCENT,PLAN,PRECISION,' +
    'PRIMARY,PRINT,PROC,PROCEDURE,PUBLIC,RAISERROR,READ,' +
    'READTEXT,RECONFIGURE,REFERENCES,REPLICATION,RESTORE,' +
    'RESTRICT,RETURN,REVOKE,RIGHT,ROLLBACK,ROWCOUNT,ROWGUIDCOL,' +
    'RULE,SAVE,SCHEMA,SELECT,SESSION_USER,SET,SETUSER,SHUTDOWN,' +
    'SOME,STATISTICS,TABLE,TEXTSIZE,THEN,TO,TOP,TRAN,TRANSACTION,' +
    'TRIGGER,TRUNCATE,TSEQUAL,UNION,UNIQUE,UPDATE,UPDATETEXT,' +
    'USE,USER,VALUES,VARYING,VIEW,WAITFOR,WEIGHT,WHEN,WHERE,WHILE,' +
    'WITH,WRITETEXT';

  // functions
  MSSQL2000Functions =
    '@@CONNECTIONS,@@CPU_BUSY,@@CURSOR_ROWS,@@DATEFIRST,@@DBTS,@@ERROR,' +
    '@@FETCH_STATUS,@@IDENTITY,@@IDLE,@@IO_BUSY,@@LANGID,@@LANGUAGE,' +
    '@@LOCK_TIMEOUT,@@MAX_CONNECTIONS,@@MAX_PRECISION,@@NESTLEVEL,@@OPTIONS,' +
    '@@PACKET_ERRORS,@@PACK_RECEIVED,@@PACK_SENT,@@PROCID,@@REMSERVER,' +
    '@@ROWCOUNT,@@SERVERNAME,@@SERVICENAME,@@SPID,@@TEXTSIZE,@@TIMETICKS,' +
    '@@TOTAL_ERRORS,@@TOTAL_READ,@@TOTAL_WRITE,@@TRANCOUNT,@@VERSION,' +
    'ABS,ACOS,APP_NAME,ASCII,ASIN,ATAN,ATN2,AVG,BINARY_CHECKSUM,CAST,' +
    'CEILING,CHARINDEX,CHECKSUM,CHECKSUM_AGG,COALESCE,COLLATIONPROPERTY,' +
    'COLUMNPROPERTY,COL_LENGTH,COL_NAME,CONVERT,COS,COT,COUNT,' +
    'COUNT_BIG,CURRENT_DATE,CURRENT_TIME,CURRENT_TIMESTAMP,' +
    'CURRENT_USER,CURSOR_STATUS,DATABASEPROPERTY,DATABASEPROPERTYEX,' +
    'DATALENGTH,DATEADD,DATEDIFF,DATENAME,DATEPART,DAY,DB_ID,DB_NAME,DEGREES,' +
    'DIFFERENCE,EXP,FILEGROUPPROPERTY,FILEGROUP_ID,FILEGROUP_NAME,' +
    'FILEPROPERTY,FILE_ID,FILE_NAME,FLOOR,fn_helpcollations,' +
    'fn_listextendedproperty,fn_servershareddrives,fn_trace_geteventinfo,' +
    'fn_trace_getfilterinfo,fn_trace_getinfo,fn_trace_gettable,' +
    'fn_virtualfilestats,FORMATMESSAGE,FULLTEXTCATALOGPROPERTY,' +
    'FULLTEXTSERVICEPROPERTY,GETANSINULL,GETDATE,GETUTCDATE,GROUPING,' +
    'HAS_DBACCESS,HOST_ID,HOST_NAME,IDENT_CURRENT,IDENT_INCR,IDENT_SEED,' +
    'INDEXKEY_PROPERTY,INDEXPROPERTY,INDEX_COL,ISDATE,ISNULL,ISNUMERIC,' +
    'IS_MEMBER,IS_SRVROLEMEMBER,LEN,LOG,LOG10,LOWER,LTRIM,MAX,MIN,MONTH,' +
    'NEWID,OBJECTPROPERTY,OBJECT_ID,OBJECT_NAME,PARSENAME,PATINDEX,' +
    'PERMISSIONS,PI,POWER,QUOTENAME,RADIANS,RAND,REPLACE,REPLICATE,REVERSE,' +
    'ROUND,ROWCOUNT_BIG,RTRIM,SCOPE_IDENTITY,SERVERPROPERTY,SESSIONPROPERTY,' +
    'SIGN,SIN,SOUNDEX,SPACE,SQL_VARIANT_PROPERTY,SQRT,SQUARE,' +
    'STATS_DATE,STDEV,STDEVP,STR,STUFF,SUBSTRING,SUM,SUSER_SID,SUSER_SNAME,' +
    'SYSTEM_USER,TAN,TEXTPTR,TEXTVALID,TYPEPROPERTY,UNICODE,UPPER,' +
    'USER_ID,USER_NAME,VAR,VARP,YEAR';

  // types
  MSSQL2000Types =
    'bigint,binary,bit,char,character,datetime,' +
    'dec,decimal,float,image,int,' +
    'integer,money,nchar,ntext,nvarchar,real,' +
    'rowversion,smalldatetime,smallint,smallmoney,' +
    'sql_variant,sysname,text,timestamp,tinyint,uniqueidentifier,' +
    'varbinary,varchar';

//---MS-SQL---------------------------------------------------------------------
  // keywords
  MSSQLKW =
    'ABSOLUTE,ACTION,ADA,ADD,ALL,ALLOCATE,ALTER,AND,ANY,ARE,AS,ASC,' +
    'ASSERTION,AT,AUTHORIZATION,BACKUP,BEGIN,BETWEEN,BIT_LENGTH,BOTH,' +
    'BREAK,BROWSE,BULK,BY,CASCADE,CASCADED,CASE,CATALOG,CHAR_LENGTH,' +
    'CHARACTER,CHARACTER_LENGTH,CHECK,CHECKPOINT,CLOSE,CLUSTERED,COALESCE,' +
    'COLLATE,COLLATION,COLUMN,COMMIT,COMPUTE,CONNECT,CONNECTION,' +
    'CONSTRAINT,CONSTRAINTS,CONTAINS,CONTINUE,CORRESPONDING,CREATE,CROSS,' +
    'CURRENT,CURRENT_TIME,CURSOR,DATABASE,DBCC,DEALLOCATE,DEC,DECLARE,' +
    'DEFAULT,DEFERRABLE,DEFERRED,DELETE,DENY,DESC,DESCRIBE,DESCRIPTOR,' +
    'DIAGNOSTICS,DISCONNECT,DISK,DISTINCT,DISTRIBUTED,DOMAIN,DOUBLE,DROP,' +
    'DUMP,ELSE,END,ERRLVL,ESCAPE,EXCEPT,EXCEPTION,EXEC,EXECUTE,EXISTS,' +
    'EXIT,EXTERNAL,EXTRACT,FALSE,FETCH,FILE,FILLFACTOR,FIRST,FOR,FOREIGN,' +
    'FORTRAN,FOUND,FREETEXT,FROM,FULL,FUNCTION,GET,GLOBAL,GO,GOTO,GRANT,' +
    'GROUP,HAVING,HOLDLOCK,HOUR,IDENTITY,IDENTITY_INSERT,IDENTITYCOL,IF,' +
    'IMMEDIATE,IN,INCLUDE,INDEX,INDICATOR,INITIALLY,INNER,INPUT,' +
    'INSENSITIVE,INSERT,INTEGER,INTERSECT,INTERVAL,INTO,IS,ISOLATION,JOIN,' +
    'KEY,KILL,LAST,LEADING,LEVEL,LIKE,LINENO,LOAD,LOCAL,MATCH,MERGE,' +
    'MINUTE,MODULE,NAMES,NATIONAL,NATURAL,NEXT,NO,NOCHECK,NONCLUSTERED,' +
    'NONE,NOT,NULL,NULLIF,OCTET_LENGTH,OF,OFF,OFFSETS,ON,ONLY,OPEN,OPTION,' +
    'OR,ORDER,OUTER,OUTPUT,OVER,OVERLAPS,PAD,PARTIAL,PASCAL,PERCENT,PIVOT,' +
    'PLAN,POSITION,PRECISION,PREPARE,PRESERVE,PRIMARY,PRINT,PRIOR,' +
    'PRIVILEGES,PROC,PROCEDURE,PUBLIC,RAISERROR,READ,READTEXT,RECONFIGURE,' +
    'REFERENCES,RELATIVE,REPLICATION,RESTORE,RESTRICT,RETURN,REVERT,' +
    'REVOKE,ROLLBACK,ROWCOUNT,ROWGUIDCOL,ROWS,RULE,SAVE,SCHEMA,SCROLL,' +
    'SECOND,SECTION,SECURITYAUDIT,SELECT,SESSION,SET,SETUSER,SHUTDOWN,' +
    'SIZE,SOME,SQL,SQLCA,SQLCODE,SQLERROR,SQLSTATE,SQLWARNING,STATISTICS,' +
    'TABLE,TABLESAMPLE,TEMPORARY,TEXTSIZE,THEN,TIMEZONE_HOUR,' +
    'TIMEZONE_MINUTE,TO,TOP,TRAILING,TRAN,TRANSACTION,TRANSLATION,TRIGGER,' +
    'TRUE,TRUNCATE,TSEQUAL,UNION,UNIQUE,UNKNOWN,UNPIVOT,UPDATE,UPDATETEXT,' +
    'USAGE,USE,USER,USING,VALUE,VALUES,VARYING,VIEW,WAITFOR,WHEN,WHENEVER,' +
    'WHERE,WHILE,WITH,WORK,WRITE,WRITETEXT,ZONE';

  // functions
  MSSQLFunctions =
    '@@CONNECTIONS,@@CPU_BUSY,@@CURSOR_ROWS,@@DATEFIRST,@@DBTS,@@ERROR,' +
    '@@FETCH_STATUS,@@IDENTITY,@@IDLE,@@IO_BUSY,@@LANGID,@@LANGUAGE,' +
    '@@LOCK_TIMEOUT,@@MAX_CONNECTIONS,@@MAX_PRECISION,@@NESTLEVEL,' +
    '@@OPTIONS,@@PACK_RECEIVED,@@PACK_SENT,@@PACKET_ERRORS,@@PROCID,' +
    '@@REMSERVER,@@ROWCOUNT,@@SERVERNAME,@@SERVICENAME,@@SPID,@@TEXTSIZE,' +
    '@@TIMETICKS,@@TOTAL_ERRORS,@@TOTAL_READ,@@TOTAL_WRITE,@@TRANCOUNT,' +
    '@@VERSION,ABS,ACOS,APP_NAME,APPLOCK_MODE,APPLOCK_TEST,' +
    'APPROX_COUNT_DISTINCT,ASCII,ASIN,ASSEMBLYPROPERTY,ASYMKEY_ID,' +
    'ASYMKEYPROPERTY,ATAN,ATN2,AVG,BINARY_CHECKSUM,BIT_COUNT,CAST,CEILING,' +
    'CERTENCODED,CERTPRIVATEKEY,CHANGE_TRACKING_CURRENT_VERSION,' +
    'CHANGE_TRACKING_IS_COLUMN_IN_MASK,CHANGE_TRACKING_MIN_VALID_VERSION,' +
    'CHANGETABLE,CHARINDEX,CHECKSUM,CHECKSUM_AGG,CHOOSE,COL_LENGTH,' +
    'COL_NAME,COLLATIONPROPERTY,COLUMNPROPERTY,COLUMNS_UPDATED,COMPRESS,' +
    'CONCAT,CONCAT_WS,CONNECTIONPROPERTY,CONTAINSTABLE,CONTEXT_INFO,' +
    'CONVERT,COS,COT,COUNT,COUNT_BIG,CUME_DIST,CURRENT_DATE,' +
    'CURRENT_REQUEST_ID,CURRENT_TIMESTAMP,CURRENT_TRANSACTION_ID,' +
    'CURRENT_USER,CURSOR_STATUS,DATABASE_PRINCIPAL_ID,DATABASEPROPERTYEX,' +
    'DATALENGTH,DATE_BUCKET,DATEADD,DATEDIFF,DATEDIFF_BIG,DATEFIRST,' +
    'DATEFORMAT,DATEFROMPARTS,DATENAME,DATEPART,DATETIME2FROMPARTS,' +
    'DATETIMEFROMPARTS,DATETIMEOFFSETFROMPARTS,DATETRUNC,DAY,DB_ID,' +
    'DB_NAME,DECOMPRESS,DECRYPTBYASYMKEY,DECRYPTBYCERT,DECRYPTBYKEY,' +
    'DECRYPTBYKEYAUTOASYMKEY,DECRYPTBYKEYAUTOCERT,DECRYPTBYPASSPHRASE,' +
    'DEGREES,DENSE_RANK,DIFFERENCE,EDGE_ID_FROM_PARTS,ENCRYPTBYASYMKEY,' +
    'ENCRYPTBYCERT,ENCRYPTBYKEY,ENCRYPTBYPASSPHRASE,EOMONTH,ERROR_LINE,' +
    'ERROR_MESSAGE,ERROR_NUMBER,ERROR_PROCEDURE,ERROR_SEVERITY,' +
    'ERROR_STATE,EVENTDATA,EXP,FILE_ID,FILE_IDEX,FILE_NAME,FILEGROUP_ID,' +
    'FILEGROUP_NAME,FILEGROUPPROPERTY,FILEPROPERTY,FILETABLEROOTPATH,' +
    'FIRST_VALUE,FLOOR,FN_AVAILABLE_BACKUPS,FN_BACKUP_DB_CONFIG,' +
    'FN_BACKUP_INSTANCE_CONFIG,FN_BUILTIN_PERMISSIONS,' +
    'FN_CDC_DECREMENT_LSN,FN_CDC_GET_COLUMN_ORDINAL,FN_CDC_GET_MAX_LSN,' +
    'FN_CDC_GET_MIN_LSN,FN_CDC_HAS_COLUMN_CHANGED,FN_CDC_INCREMENT_LSN,' +
    'FN_CDC_IS_BIT_SET,FN_CDC_MAP_LSN_TO_TIME,FN_CDC_MAP_TIME_TO_LSN,' +
    'FN_CHECK_OBJECT_SIGNATURES,FN_GET_AUDIT_FILE,' +
    'FN_GET_CURRENT_XEVENT_SETTINGS,FN_GET_HEALTH_STATUS,FN_GET_PARAMETER,' +
    'FN_GET_SQL,FN_HADR_BACKUP_IS_PREFERRED_REPLICA,' +
    'FN_HADR_DISTRIBUTED_AG_DATABASE_REPLICA,' +
    'FN_HADR_DISTRIBUTED_AG_REPLICA,FN_HADR_IS_PRIMARY_REPLICA,' +
    'FN_HELPCOLLATIONS,FN_IS_MASTER_SWITCH_ON,FN_LISTEXTENDEDPROPERTY,' +
    'FN_MY_PERMISSIONS,FN_PAGERESCRACKER,FN_SERVERSHAREDDRIVES,' +
    'FN_SYSCOLLECTOR_GET_EXECUTION_DETAILS,' +
    'FN_SYSCOLLECTOR_GET_EXECUTION_STATS,FN_TRACE_GETDATA,' +
    'FN_TRACE_GETEVENTINFO,FN_TRACE_GETFILTERINFO,FN_TRACE_GETINFO,' +
    'FN_TRACE_GETTABLE,FN_TRANSLATE_PERMISSIONS,FN_VIRTUALFILESERVERMODES,' +
    'FN_VIRTUALFILESTATS,FORMAT,FORMATMESSAGE,FREETEXTTABLE,' +
    'FULLTEXTCATALOGPROPERTY,FULLTEXTSERVICEPROPERTY,GET_BIT,' +
    'GET_FILESTREAM_TRANSACTION_CONTEXT,GETANSINULL,GETDATE,' +
    'GETFILENAMESPACEPATH,GETPATHLOCATOR,GETUTCDATE,GRAPH_ID_FROM_EDGE_ID,' +
    'GRAPH_ID_FROM_NODE_ID,GREATEST,GROUPING,GROUPING_ID,' +
    'HAS_PERMS_BY_NAME,HASHBYTES,HOST_ID,HOST_NAME,IDENT_CURRENT,' +
    'IDENT_INCR,IDENT_SEED,IIF,INDEX_COL,INDEXKEY_PROPERTY,INDEXPROPERTY,' +
    'IS_MEMBER,IS_OBJECTSIGNED,IS_ROLEMEMBER,IS_SRVROLEMEMBER,ISDATE,' +
    'ISJSON,ISNULL,ISNUMERIC,JSON_ARRAY,JSON_ARRAYAGG,JSON_MODIFY,' +
    'JSON_OBJECT,JSON_OBJECTAGG,JSON_PATH_EXISTS,JSON_QUERY,JSON_VALUE,' +
    'KEY_GUID,KEY_ID,KEY_NAME,LAG,LANGUAGE,LAST_VALUE,LEAD,LEAST,LEFT,' +
    'LEFT_SHIFT,LEN,LOG,LOG10,LOGINPROPERTY,LOWER,LTRIM,MAX,MIN,' +
    'MIN_ACTIVE_ROWVERSION,MONTH,NEWID,NEWSEQUENTIALID,NODE_ID_FROM_PARTS,' +
    'NTILE,OBJECT_DEFINITION,OBJECT_ID,OBJECT_ID_FROM_EDGE_ID,' +
    'OBJECT_ID_FROM_NODE_ID,OBJECT_NAME,OBJECT_SCHEMA_NAME,OBJECTPROPERTY,' +
    'OBJECTPROPERTYEX,OPENDATASOURCE,OPENJSON,OPENQUERY,OPENROWSET,' +
    'OPENXML,ORIGINAL_DB_NAME,ORIGINAL_LOGIN,PARSE,PARSENAME,PATHNAME,' +
    'PATINDEX,PERCENT_RANK,PERCENTILE_CONT,PERCENTILE_DISC,PERMISSIONS,PI,' +
    'POWER,PUBLISHINGSERVERNAME,PWDCOMPARE,PWDENCRYPT,QUOTENAME,RADIANS,' +
    'RAND,RANK,REPLACE,REPLICATE,REVERSE,RIGHT,RIGHT_SHIFT,ROUND,' +
    'ROW_NUMBER,ROWCOUNT_BIG,RTRIM,SCHEMA_ID,SCHEMA_NAME,SCOPE_IDENTITY,' +
    'SEMANTICKEYPHRASETABLE,SEMANTICSIMILARITYDETAILSTABLE,' +
    'SEMANTICSIMILARITYTABLE,SERVERPROPERTY,SESSION_CONTEXT,SESSION_ID,' +
    'SESSION_USER,SET_BIT,SIGN,SIGNBYASYMKEY,SIGNBYCERT,SIN,' +
    'SMALLDATETIMEFROMPARTS,SOUNDEX,SP_HELPLANGUAGE,SPACE,' +
    'SQL_VARIANT_PROPERTY,SQRT,SQUARE,STATS_DATE,STDEV,STDEVP,STR,' +
    'STRING_AGG,STRING_ESCAPE,STRING_SPLIT,STUFF,SUBSTRING,SUM,SUSER_ID,' +
    'SUSER_NAME,SUSER_SID,SUSER_SNAME,SWITCHOFFSET,SYMKEYPROPERTY,' +
    'SYSDATETIME,SYSDATETIMEOFFSET,SYSTEM_USER,SYSUTCDATETIME,TAN,' +
    'TERTIARY_WEIGHTS,TEXTPTR,TEXTVALID,TIMEFROMPARTS,TODATETIMEOFFSET,' +
    'TRANSLATE,TRIGGER_NESTLEVEL,TRIM,TRY_CAST,TRY_CONVERT,TRY_PARSE,' +
    'TYPE_ID,TYPE_NAME,TYPEPROPERTY,UNICODE,UPPER,USER_ID,USER_NAME,VAR,' +
    'VARP,VERIFYSIGNEDBYASMKEY,VERIFYSIGNEDBYASYMKEY,VERIFYSIGNEDBYCERT,' +
    'VERIGYSIGNEDBYCERT,VERSION,XACT_STATE,YEAR';

  // types
  MSSQLTypes =
    'BIGINT,BINARY,BIT,CHAR,DATE,DATETIME,DATETIME2,DATETIMEOFFSET,' +
    'DECIMAL,FLOAT,GEOGRAPHY,GEOMETRY,HIERARCHYID,IMAGE,INT,MONEY,NCHAR,' +
    'NTEXT,NUMERIC,NVARCHAR,REAL,SMALLDATETIME,SMALLINT,SMALLMONEY,' +
    'SQL_VARIANT,SYSNAME,TEXT,TIME,TIMESTAMP,TINYINT,UNIQUEIDENTIFIER,' +
    'VARBINARY,VARCHAR,XML';

//---Interbase 6----------------------------------------------------------------
  // functions
  Interbase6Functions = 'AVG,CAST,COUNT,GEN_ID,MAX,MIN,SUM,UPPER';

  // keywords
  Interbase6KW: string = 'ACTIVE,ADD,AFTER,ALL,ALTER,AND,ANY,AS,ASC,' +
    'ASCENDING,AT,AUTO,AUTODDL,BASED,BASENAME,BASE_NAME,BEFORE,BEGIN,BETWEEN,' +
    'BLOBEDIT,BUFFER,BY,CACHE,CHARACTER_LENGTH,CHAR_LENGTH,CHECK,' +
    'CHECK_POINT_LEN,CHECK_POINT_LENGTH,COLLATE,COLLATION,COLUMN,COMMIT,' +
    'COMMITED,COMPILETIME,COMPUTED,CLOSE,CONDITIONAL,CONNECT,CONSTRAINT,' +
    'CONTAINING,CONTINUE,CREATE,CURRENT,CURRENT_DATE,CURRENT_TIME,' +
    'CURRENT_TIMESTAMP,CURSOR,DATABASE,DAY,DB_KEY,DEBUG,DEC,DECLARE,DEFAULT,' +
    'DELETE,DESC,DESCENDING,DESCRIBE,DESCRIPTOR,DISCONNECT,DISTINCT,DO,' +
    'DOMAIN,DROP,ECHO,EDIT,ELSE,END,ENTRY_POINT,ESCAPE,EVENT,EXCEPTION,' +
    'EXECUTE,EXISTS,EXIT,EXTERN,EXTERNAL,EXTRACT,FETCH,FILE,FILTER,FOR,' +
    'FOREIGN,FOUND,FROM,FULL,FUNCTION,GDSCODE,GENERATOR,GLOBAL,GOTO,GRANT,' +
    'GROUP,GROUP_COMMIT_WAIT,GROUP_COMMIT_WAIT_TIME,HAVING,HELP,HOUR,IF,' +
    'IMMEDIATE,IN,INACTIVE,INDEX,INDICATOR,INIT,INNER,INPUT,INPUT_TYPE,' +
    'INSERT,INT,INTO,IS,ISOLATION,ISQL,JOIN,KEY,LC_MESSAGES,LC_TYPE,LEFT,' +
    'LENGTH,LEV,LEVEL,LIKE,LOGFILE,LOG_BUFFER_SIZE,LOG_BUF_SIZE,LONG,MANUAL,' +
    'MAXIMUM,MAXIMUM_SEGMENT,MAX_SEGMENT,MERGE,MESSAGE,MINIMUM,MINUTE,' +
    'MODULE_NAME,MONTH,NAMES,NATIONAL,NATURAL,NCHAR,NO,NOAUTO,NOT,NULL,' +
    'NUM_LOG_BUFFS,NUM_LOG_BUFFERS,OCTET_LENGTH,OF,ON,ONLY,OPEN,OPTION,OR,' +
    'ORDER,OUTER,OUTPUT,OUTPUT_TYPE,OVERFLOW,PAGE,PAGELENGTH,PAGES,PAGE_SIZE,' +
    'PARAMETER,PASSWORD,PLAN,POSITION,POST_EVENT,PRECISION,PREPARE,PROCEDURE,' +
    'PROTECTED,PRIMARY,PRIVILEGES,PUBLIC,QUIT,RAW_PARTITIONS,READ,REAL,' +
    'RECORD_VERSION,REFERENCES,RELEASE,RESERV,RESERVING,RETAIN,RETURN,' +
    'RETURNING_VALUES,RETURNS,REVOKE,RIGHT,ROLLBACK,RUNTIME,SCHEMA,SECOND,' +
    'SEGMENT,SELECT,SET,SHADOW,SHARED,SHELL,SHOW,SINGULAR,SIZE,SNAPSHOT,SOME,' +
    'SORT,SQL,SQLCODE,SQLERROR,SQLWARNING,STABILITY,STARTING,STARTS,' +
    'STATEMENT,STATIC,STATISTICS,SUB_TYPE,SUSPEND,TABLE,TERMINATOR,THEN,TO,' +
    'TRANSACTION,TRANSLATE,TRANSLATION,TRIGGER,TRIM,TYPE,UNCOMMITTED,UNION,' +
    'UNIQUE,UPDATE,USER,USING,VALUE,VALUES,VARIABLE,VARYING,VERSION,VIEW,' +
    'WAIT,WEEKDAY,WHEN,WHENEVER,WHERE,WHILE,WITH,WORK,WRITE,YEAR,YEARDAY';

  // types
  Interbase6Types = 'BLOB,CHAR,CHARACTER,DATE,DECIMAL,DOUBLE,FLOAT,INTEGER,' +
    'NUMERIC,SMALLINT,TIME,TIMESTAMP,VARCHAR';

//---MySQL----------------------------------------------------------------------
  // keywords
  MySqlKW: string = 'ACTION,AFTER,AGAINST,AGGREGATE,ALL,ALTER,ANALYZE,AND,AS,' +
    'ASC,AUTO_INCREMENT,AVG_ROW_LENGTH,BACKUP,BEGIN,BENCHMARK,BETWEEN,BINARY,' +
    'BIT,BOOL,BOTH,BY,CASCADE,CHANGE,CHARACTER,CHECK,CHECKSUM,COLLATE,COLUMN,COLUMNS,' +
    'COMMENT,COMMIT,CONSTRAINT,CREATE,CROSS,DATA,DATABASES,DEC,DEFAULT,' +
    'DELAYED,DELAY_KEY_WRITE,DELETE,DESC,DESCRIBE,DISTINCT,DISTINCTROW,DROP,' +
    'ELSE,ENCLOSED,END,ESCAPE,ESCAPED,EXISTS,EXPLAIN,FIELDS,FILE,FIRST,' +
    'FLOAT4,FLOAT8,FLUSH,FOR,FOREIGN,FROM,FULL,FULLTEXT,FUNCTION,GLOBAL,GRANT,' +
    'GRANTS,GROUP,HAVING,HEAP,HIGH_PRIORITY,HOSTS,IDENTIFIED,IGNORE,' +
    'INDEX,INFILE,INNER,INT1,INT2,INT3,INT4,INT8,INTO,IS,ISAM,JOIN,KEY,' +
    'KEYS,KILL,LEADING,LIKE,LIMIT,LINES,LOAD,LOCAL,LOCK,LOGS,LONG,' +
    'LOW_PRIORITY,MATCH,MAX_ROWS,MIDDLEINT,MIN_ROWS,MODIFY,MYISAM,' +
    'NATURAL,NO,NOT,NULL,OPTIMIZE,OPTION,OPTIONALLY,ON,OPEN,OR,ORDER,OUTER,' +
    'OUTFILE,PACK_KEYS,PARTIAL,PRECISION,PRIMARY,PRIVILEGES,PROCEDURE,' +
    'PROCESS,PROCESSLIST,READ,REFERENCES,REGEXP,RELOAD,RENAME,REPAIR,' +
    'RESTRICT,RESTORE,RETURN,RETURNS,REVOKE,RLIKE,ROLLBACK,ROW,ROWS,SELECT,SHOW,' +
    'SHUTDOWN,SONAME,SQL_BIG_RESULT,SQL_BIG_SELECTS,SQL_BIG_TABLES,' +
    'SQL_LOG_OFF,SQL_LOG_UPDATE,SQL_LOW_PRIORITY_UPDATES,SQL_SELECT_LIMIT,' +
    'SQL_SMALL_RESULT,SQL_WARNINGS,STARTING,STATUS,STRAIGHT_JOIN,TABLE,' +
    'TABLES,TEMPORARY,TERMINATED,THEN,TO,TRAILING,TRANSACTION,TYPE,UNION,UNIQUE,' +
    'UNLOCK,UNSIGNED,UPDATE,USAGE,USE,USING,VALUES,VARBINARY,VARCHAR,' +
    'VARIABLES,VARYING,VIEW,WHERE,WITH,WRITE,ZEROFILL';

  // types
  MySqlTypes: string = 'TINYINT,SMALLINT,MEDIUMINT,INT,INTEGER,BIGINT,FLOAT,' +
    'DOUBLE,REAL,DECIMAL,NUMERIC,DATE,DATETIME,TIMESTAMP,TIME,YEAR,CHAR,' +
    'NATIONAL,TINYBLOB,TINYTEXT,TEXT,BLOB,MEDIUMBLOB,MEDIUMTEXT,LONGBLOB,' +
    'LONGTEXT,ENUM,SET,STRING';

  // functions
  MySqlFunctions: string = 'ABS,ACOS,ASCII,ADD,ADDDATE,ASIN,ATAN,ATAN2,AVG,' +
    'BIN,BIT_AND,BIT_COUNT,BIT_OR,CASE,CHARACTER_LENGTH,CEILING,' +
    'CONNECTION_ID,CHAR_LENGTH,COALESCE,CONCAT,CONV,COS,COT,COUNT,' +
    'CURDATE,CURRENT_DATE,CURRENT_TIME,CURRENT_TIMESTAMP,CURTIME,DATABASE,' +
    'DATE_ADD,DATE_FORMAT,DATE_SUB,DAY,DAYNAME,DAYOFMONTH,DAYOFWEEK,' +
    'DAYOFYEAR,DAY_HOUR,DAY_MINUTE,DAY_SECOND,DECODE,DEGREES,ELT,ENCODE,' +
    'ENCRYPT,EXP,EXPORT_SET,FIELD,FIND_IN_SET,FLOOR,FORMAT,FROM_DAYS,' +
    'FROM_UNIXTIME,GET_LOCK,GREATEST,GROUP_CONCAT,HEX,HOUR,HOUR_MINUTE,HOUR_SECOND,IF,' +
    'IFNULL,IN,INET_NTOA,INET_ATON,INSERT,INSERT_ID,INSTR,INTERVAL,ISNULL,' +
    'LAST_INSERT_ID,LCASE,LEAST,LEFT,LENGTH,LOAD_FILE,LOCATE,LOG,LOG10,LOWER,' +
    'LPAD,LTRIM,MAKE_SET,MASTER_POS_WAIT,MAX,MD5,MID,MIN,MINUTE,' +
    'MINUTE_SECOND,MOD,MONTH,MONTHNAME,NOW,NULLIF,OCT,OCTET_LENGTH,ORD,' +
    'PASSWORD,PERIOD_ADD,PERIOD_DIFF,PI,POSITION,POW,POWER,QUARTER,RADIANS,' +
    'RAND,REGEXP_REPLACE,RELEASE_LOCK,REPEAT,REPLACE,REVERSE,RIGHT,ROUND,RPAD,RTRIM,SECOND,' +
    'SEC_TO_TIME,SESSION_USER,SIGN,SIN,SOUNDEX,SPACE,SQRT,STD,STDDEV,STRCMP,' +
    'SUBDATE,SUBSTRING,SUBSTRING_INDEX,SUM,SYSDATE,SYSTEM_USER,TAN,' +
    'TIME_FORMAT,TIME_TO_SEC,TO_DAYS,TRIM,TRUNCATE,UCASE,UNIX_TIMESTAMP,' +
    'UPPER,USER,VERSION,WEEK,WEEKDAY,WHEN,YEARWEEK,YEAR_MONTH';

{begin}                                                                         // JJV 2000-11-16
//---Ingres---------------------------------------------------------------------
  // keywords
  IngresKW: string =
    'ABORT,ACTIVATE,ADD,ADDFORM,AFTER,AGGREGATE,ALL,ALTER,AND,APPEND,ARRAY,' +
    'AS,ASC,AT,AUDIT_LOG,AUTHORIZATION,AUTOCOMMIT,AVGU,BEFORE,BEGIN,BETWEEN,' +
    'BREAKDISPLAY,BY,BYREF,CACHE,CALL,CALLFRAME,CALLPROC,CASCADE,CHECK,CLEAR,' +
    'CLEARROW,CLOSE,COLUMN,COMMAND,COMMENT,COMMIT,CONNECT,CONSTRAINT,' +
    'CONTINUE,COPY,COUNTU,CPUFACTOR,CREATE,CURRENT,CURRENT_USER,CURSOR,DATA,' +
    'DATAHANDLER,DATE_FORMAT,DBEVENT,DDL_CONCURRENCY,DEADLOCK,DECLARE,' +
    'DEFAULT,DEFERRED,DEFINE,DELETE,DELETEROW,DESC,DESCRIBE,DESCRIPTOR,' +
    'DESTROY,DIRECT,DISABLE,DISCONNECT,DISPLAY,DISTINCT,DISTRIBUTE,DO,DOWN,' +
    'DROP,ELSE,ELSEIF,ENABLE,END,ENDDATA,ENDDISPLAY,ENDFORMS,ENDIF,ENDLOOP,' +
    'ENDRETRIEVE,ENDSELECT,ENDWHILE,ERROR,ESCAPE,EXCLUDE,EXCLUDING,EXEC,' +
    'EXECUTE,EXISTS,EXIT,FETCH,FIELD,FINALIZE,FOR,FOREIGN,FORMDATA,FORMINIT,' +
    'FORMS,FROM,FULL,GET,GETFORM,GETOPER,GETROW,GLOBAL,GOTO,GRANT,GRANTED,' +
    'HAVING,HELP,HELP_FORMS,HELP_FRS,HELPFILE,IDENTIFIED,IF,IIMESSAGE,' +
    'IIPRINTF,IIPROMPT,IISTATEMENT,IMMEDIATE,IMPORT,IN,INCLUDE,INDEX,' +
    'INDICATOR,INGRES,INITIALIZE,INITTABLE,INNER,INQUIRE_EQUEL,INQUIRE_FORMS,' +
    'INQUIRE_FRS,INQUIRE_INGRES,INSERT,INSERTROW,INSTALLATION,INTEGRITY,INTO,' +
    'IO_TRACE,IS,J_FREESZ1,J_FREESZ2,J_FREESZ3,J_FREESZ4,J_SORTBUFSZ,' +
    'JCPUFACTOR,JOIN,JOINOP,JOURNALING,KEY,LEVEL,LIKE,LINK,LOADTABLE,LOCAL,' +
    'LOCATION,LOCK_TRACE,LOG_TRACE,LOGDBEVENTS,LOGGING,MAXCOST,MAXCPU,' +
    'MAXPAGE,MENUITEM,MESSAGE,MODE,MODIFY,MODULE,MONEY_FORMAT,MONEY_PREC,' +
    'MOVE,NATURAL,NEXT,NODEADLOCK,NOECHO,NOIO_TRACE,NOJIONOP,NOJOURNALING,' +
    'NOLOCK_TRACE,NOLOG_TRACE,NOLOGDBEVENTS,NOLOGGING,NOMAXCOST,NOMAXCPU,' +
    'NOMAXIO,NOMAXPAGE,NOMAXQUERY,NOMAXROW,NOOPTIMIZEONLY,NOPRINTDBEVENTS,' +
    'NOPRINTQRY,NOPRINTRULES,NOQEP,NORULES,NOSQL,NOSTATISTICS,NOT,NOTRACE,' +
    'NULL,OF,ON,ONLY,OPEN,OPTIMIZEONLY,OPTION,OR,ORDER,OUT,PARAM,PERMIT,' +
    'PREPARE,PRESERVE,PRIMARY,PRINT,PRINTDBEVENTS,PRINTQRY,PRINTSCREEN,' +
    'PRIVILEGES,PROCEDURE,PROMPT,PUBLIC,PUT,PUTFORM,PUTOPER,PUTROW,QBUFSIZE,' +
    'QEP,QRY,QUALIFICATION,QUERY_SIZE,RAISE,RANGE,READONLY,REDISPLAY,' +
    'REFERENCES,REFERENCING,REGISTER,RELOCATE,REMOVE,RENAME,REPEAT,REPEATED,' +
    'REPLACE,REPLICATE,RESTRICT,RESULT_STRUCTURE,RESUME,RET_INTO,RETRIEVE,' +
    'RETURN,RETURNING,REVOKE,ROLLBACK,ROWS,RULE,RUN,SAVE,SAVEPOINT,SCHEMA,' +
    'SCREEN,SCROLL,SCROLLDOWN,SCROLLUP,SECTION,SECURITY_ALARM,SECURITY_AUDIT,' +
    'SELECT,SESSION,SET,SET_4GL,SET_EQUAL,SET_FORMS,SET_FRS,SET_INGRES,' +
    'SET_SQL,SHORT_REMARK,SLEEP,SOME,SORT,SORTBUFSIZE,SQL,STATISTICS,STOP,' +
    'SUBMENU,SUMU,SYNONYM,SYSTEM,TABLE,TABLEDATA,TEWMPORARY,THEN,TO,TRACE,' +
    'TRANSACTION,TYPE,UNION,UNIQUE,UNLOADTABLE,UNTIL,UP,UPDATE,USER,USING,' +
    'VALIDATE,VALIDROW,VALUES,VIEW,WHEN,WHENEVER,WHERE,WHILE,WITH,WORK';

  // types
  IngresTypes: string =
    'BYTE,C,CHAR,CHARACTER,DATE,DECIMAL,FLOAT,FLOAT4,FLOAT8,INTEGER,INTEGER1,' +
    'INTEGER2,INTEGER4,LONG,MONEY,OBJECT_KEY,SECURITY_LABEL,SHORT,SMALLINT,' +
    'TABLE_KEY,TEXT,VARCHAR,VARYING';

  // functions
  IngresFunctions: string =
    '_BINTIM,_CPU_MS,_DATE,_DIO_CNT,_ET_SEC,_PFAULT_CNT,_TIME,_VERSION,ABS,' +
    'ANY,ATAN,AUTOCOMMIT_STATE,AVG,BIOCNT,CHAREXTRACT,COLLATION,CONCAT,' +
    'CONNECT_TIME_LIMIT,COS,COUNT,CREATE_PROCEDURE,CREATE_TABLE,DATABASE,' +
    'DATE_GMT,DATE_PART,DATE_TRUNC,DB_ADMIN,DB_DELIMITED_CASE,DB_NAME_CASE,' +
    'DBA,DBMS_BIO,DBMS_CPU,DBMS_DIO,DBMSINFO,DOW,EXP,FLATTEN_AGGREGATE,' +
    'FLATTEN_NONE,FLATTEN_OPTIMIZE,FLATTEN_SINGLETON,GROUP,HEX,' +
    'IDLE_TIME_LIMIT,IFNULL,INITIAL_USER,INQUIRE_SQL,INT1,INT2,INT4,INTERVAL,' +
    'LANGUAGE,LEFT,LENGTH,LOCATE,LOCKMODE,LOG,LONG_BYTE,LONG_VARCHAR,' +
    'LOWERCASE,MAX,MAXCONNECT,MAXIDLE,MAXIO,MAXQUERY,MAXROW,MIN,MOD,NOTRIM,' +
    'ON_ERROR_STATE,PAD,QUERY_IO_LIMIT,QUERY_LANGUAGE,QUERY_ROW_LIMIT,RIGHT,' +
    'ROLE,SECURITY_AUDIT_LOG,SECURITY_AUDIT_STATE,SECURITY_PRIV,' +
    'SELECT_SYSCAT,SERVER_CLASS,SESSION_ID,SESSION_PRIORITY,' +
    'SESSION_PRIORITY_LIMIT,SESSION_PRIV,SESSION_SECLABEL,SESSION_USER,SHIFT,' +
    'SIN,SIZE,SQRT,SQUEEZE,SUM,SYSTEM_USER,TABLE_STATISTICS,TERMINAL,' +
    'TRANSACTION_STATE,TRIM,UPDATE_ROWCNT,UPDATE_SYSCAT,UPPERCASE,USERNAME,' +
    'VARBYTE';
{end}                                                                           // JJV 2000-11-16

//---Firebird 2.5 keywords------------------------------------------------------
  Firebird25KW: string =
    'ABS,ACCENT,ACOS,ACTION,ACTIVE,ADD,ADMIN,AFTER,ALL,ALTER,ALWAYS,AND,ANY,'+
    'AS,ASC,ASCENDING,ASCII_CHAR,ASCII_VAL,ASIN,AT,ATAN,ATAN2,AUTO,AUTONOMOUS,'+
    'AVG,BACKUP,BEFORE,BEGIN,BETWEEN,BIGINT,BIN_AND,BIN_NOT,BIN_OR,BIN_SHL,'+
    'BIN_SHR,BIN_XOR,BIT_LENGTH,BLOB,BLOCK,BOTH,BREAK,BY,CALLER,CASCADE,CASE,'+
    'CAST,CEIL,CEILING,CHAR,CHAR_LENGTH,CHAR_TO_UUID,CHARACTER,CHARACTER_LENGTH,'+
    'CHECK,CLOSE,COALESCE,COLLATE,COLLATION,COLUMN,COMMENT,COMMIT,COMMITTED,'+
    'COMMON,COMPUTED,CONDITIONAL,CONNECT,CONSTRAINT,CONTAINING,COS,COSH,COT,'+
    'COUNT,CREATE,CROSS,CSTRING,CURRENT,CURRENT_CONNECTION,CURRENT_DATE,'+
    'CURRENT_ROLE,CURRENT_TIME,CURRENT_TIMESTAMP,CURRENT_TRANSACTION,'+
    'CURRENT_USER,CURSOR,DATABASE,DATA,DATE,DATEADD,DATEDIFF,DAY,DEC,DECIMAL,'+
    'DECLARE,DECODE,DEFAULT,DELETE,DELETING,DESC,DESCENDING,DESCRIPTOR,'+
    'DIFFERENCE,DISCONNECT,DISTINCT,DO,DOMAIN,DOUBLE,DROP,ELSE,END,ENTRY_POINT,'+
    'ESCAPE,EXCEPTION,EXECUTE,EXISTS,EXIT,EXP,EXTERNAL,EXTRACT,FETCH,FILE,'+
    'FILTER,FIRST,FIRSTNAME,FLOAT,FLOOR,FOR,FOREIGN,FREE_IT,FROM,FULL,FUNCTION,'+
    'GDSCODE,GENERATED,GENERATOR,GEN_ID,GEN_UUID,GLOBAL,GRANT,GRANTED,GROUP,'+
    'HASH,HAVING,HOUR,IF,IGNORE,IIF,IN,INACTIVE,INDEX,INNER,INPUT_TYPE,'+
    'INSENSITIVE,INSERT,INSERTING,INT,INTEGER,INTO,IS,ISOLATION,JOIN,KEY,LAST,'+
    'LASTNAME,LEADING,LEAVE,LEFT,LENGTH,LEVEL,LIKE,LIMBO,LIST,LN,LOCALTIME,'+
    'LOCALTIMESTAMP,LOCK,LOG,LOG10,LONG,LOWER,LPAD,MANUAL,MAPPING,MATCHED,'+
    'MATCHING,MAX,MAXVALUE,MAXIMUM_SEGMENT,MERGE,MILLISECOND,MIDDLENAME,MIN,'+
    'MINUTE,MINVALUE,MOD,MODULE_NAME,MONTH,NAMES,NATIONAL,NATURAL,NCHAR,NEXT,'+
    'NO,NOT,NULLIF,NULL,NULLS,NUMERIC,OCTET_LENGTH,OF,ON,ONLY,OPEN,OPTION,OR,'+
    'ORDER,OS_NAME,OUTER,OUTPUT_TYPE,OVERFLOW,OVERLAY,PAD,PAGE,PAGES,PAGE_SIZE,'+
    'PARAMETER,PASSWORD,PI,PLACING,PLAN,POSITION,POST_EVENT,POWER,PRECISION,'+
    'PRESERVE,PRIMARY,PRIVILEGES,PROCEDURE,PROTECTED,RAND,RDB$DB_KEY,READ,REAL,'+
    'RECORD_VERSION,RECREATE,RECURSIVE,REFERENCES,RELEASE,REPLACE,REQUESTS,'+
    'RESERV,RESERVING,RESTART,RESTRICT,RETAIN,RETURNING,RETURNING_VALUES,'+
    'RETURNS,REVERSE,REVOKE,RIGHT,ROLE,ROLLBACK,ROUND,ROW_COUNT,ROWS,RPAD,'+
    'SAVEPOINT,SCALAR_ARRAY,SCHEMA,SECOND,SEGMENT,SELECT,SENSITIVE,SEQUENCE,'+
    'SET,SHADOW,SHARED,SIGN,SIMILAR,SIN,SINGULAR,SINH,SIZE,SKIP,SMALLINT,'+
    'SNAPSHOT,SOME,SORT,SOURCE,SPACE,SQLCODE,SQLSTATE,SQRT,STABILITY,START,'+
    'STARTING,STARTS,STATEMENT,STATISTICS,SUBSTRING,SUB_TYPE,SUM,SUSPEND,TABLE,'+
    'TAN,TANH,TEMPORARY,THEN,TIME,TIMESTAMP,TIMEOUT,TO,TRAILING,TRANSACTION,'+
    'TRIGGER,TRIM,TRUNC,TWO_PHASE,TYPE,UNCOMMITTED,UNDO,UNION,UNIQUE,UPDATE,'+
    'UPDATING,UPPER,USER,USING,UUID_TO_CHAR,VALUE,VALUES,VARCHAR,VARIABLE,'+
    'VARYING,VIEW,WAIT,WEEK,WEEKDAY,WHEN,WHERE,WHILE,WITH,WORK,WRITE,YEAR,YEARDAY';

//---Firebird 3.0 keywords------------------------------------------------------
  Firebird30KW: string =
    'ABS,ABSOLUTE,ACCENT,ACOS,ACOSH,ACTION,ACTIVE,ADD,ADMIN,AFTER,ALL,ALTER,'+
    'ALWAYS,AND,ANY,AS,ASC,ASCENDING,ASCII_CHAR,ASCII_VAL,ASIN,ASINH,AT,ATAN,'+
    'ATAN2,ATANH,AUTO,AUTONOMOUS,AVG,BACKUP,BEFORE,BEGIN,BETWEEN,BIGINT,BIN_AND,'+
    'BIN_NOT,BIN_OR,BIN_SHL,BIN_SHR,BIN_XOR,BIT_LENGTH,BLOB,BLOCK,BODY,BOOLEAN,'+
    'BOTH,BREAK,BY,CALLER,CASCADE,CASE,CAST,CEIL,CEILING,CHAR,CHAR_LENGTH,'+
    'CHAR_TO_UUID,CHARACTER,CHARACTER_LENGTH,CHECK,CLOSE,COALESCE,COLLATE,'+
    'COLLATION,COLUMN,COMMENT,COMMIT,COMMITTED,COMMON,COMPUTED,CONDITIONAL,'+
    'CONNECT,CONSTRAINT,CONTAINING,CONTINUE,CORR,COS,COSH,COT,COUNT,COVAR_POP,'+
    'COVAR_SAMP,CREATE,CROSS,CSTRING,CURRENT,CURRENT_CONNECTION,CURRENT_DATE,'+
    'CURRENT_ROLE,CURRENT_TIME,CURRENT_TIMESTAMP,CURRENT_TRANSACTION,'+
    'CURRENT_USER,CURSOR,DATABASE,DATA,DATE,DATEADD,DATEDIFF,DAY,DDL,DEC,'+
    'DECIMAL,DECLARE,DECODE,DECRYPT,DEFAULT,DELETE,DELETING,DENSE_RANK,DESC,'+
    'DESCENDING,DESCRIPTOR,DETERMINISTIC,DIFFERENCE,DISCONNECT,DISTINCT,DO,'+
    'DOMAIN,DOUBLE,DROP,ELSE,ENCRYPT,END,ENGINE,ENTRY_POINT,ESCAPE,EXCEPTION,'+
    'EXECUTE,EXISTS,EXIT,EXP,EXTERNAL,EXTRACT,FALSE,FETCH,FILE,FILTER,FIRST,'+
    'FIRST_VALUE,FIRSTNAME,FLOAT,FLOOR,FOR,FOREIGN,FREE_IT,FROM,FULL,FUNCTION,'+
    'GDSCODE,GENERATED,GENERATOR,GEN_ID,GEN_UUID,GLOBAL,GRANT,GRANTED,GROUP,'+
    'HASH,HAVING,HOUR,IDENTITY,IF,IGNORE,IIF,IN,INACTIVE,INCREMENT,INDEX,INNER,'+
    'INPUT_TYPE,INSENSITIVE,INSERT,INSERTING,INT,INTEGER,INTO,IS,ISOLATION,JOIN,'+
    'KEY,LAG,LAST,LAST_VALUE,LASTNAME,LEAD,LEADING,LEAVE,LEFT,LENGTH,LEVEL,LIKE,'+
    'LIMBO,LINGER,LIST,LN,LOCALTIME,LOCALTIMESTAMP,LOCK,LOG,LOG10,LONG,LOWER,'+
    'LPAD,MANUAL,MAPPING,MATCHED,MATCHING,MAX,MAXVALUE,MERGE,MILLISECOND,'+
    'MIDDLENAME,MIN,MINUTE,MINVALUE,MOD,MODULE_NAME,MONTH,NAME,NAMES,NATIONAL,'+
    'NATURAL,NCHAR,NEXT,NO,NOT,NTH_VALUE,NULLIF,NULL,NULLS,NUMERIC,OCTET_LENGTH,'+
    'OF,OFFSET,ON,ONLY,OPEN,OPTION,OR,ORDER,OS_NAME,OUTER,OUTPUT_TYPE,OVER,'+
    'OVERFLOW,OVERLAY,PACKAGE,PAD,PAGE,PAGES,PAGE_SIZE,PARAMETER,PARTITION,'+
    'PASSWORD,PI,PLACING,PLAN,PLUGIN,POSITION,POST_EVENT,POWER,PRECISION,'+
    'PRESERVE,PRIMARY,PRIOR,PRIVILEGES,PROCEDURE,PROTECTED,RAND,RANK,RDB$DB_KEY,'+
    'RDB$GET_CONTEXT,RDB$RECORD_VERSION,RDB$SET_CONTEXT,READ,REAL,'+
    'RECORD_VERSION,RECREATE,RECURSIVE,REFERENCES,REGR_AVGX,REGR_AVGY,'+
    'REGR_COUNT,REGR_INTERCEPT,REGR_R2,REGR_SLOPE,REGR_SXX,REGR_SXY,REGR_SYY,'+
    'RELATIVE,RELEASE,REPLACE,REQUESTS,RESERV,RESERVING,RESTART,RESTRICT,RETAIN,'+
    'RETURN,RETURNING,RETURNING_VALUES,RETURNS,REVERSE,REVOKE,RIGHT,ROLE,'+
    'ROLLBACK,ROUND,ROW,ROW_COUNT,ROW_NUMBER,ROWS,RPAD,SAVEPOINT,SCALAR_ARRAY,'+
    'SCHEMA,SCROLL,SECOND,SEGMENT,SELECT,SENSITIVE,SEQUENCE,SERVERWIDE,SET,'+
    'SHADOW,SHARED,SIGN,SIMILAR,SIN,SINGULAR,SINH,SIZE,SKIP,SMALLINT,SNAPSHOT,'+
    'SOME,SORT,SOURCE,SPACE,SQLCODE,SQLSTATE,SQRT,STABILITY,START,STARTING,'+
    'STARTS,STATEMENT,STATISTICS,STDDEV_POP,STDDEV_SAMP,SUBSTRING,SUB_TYPE,SUM,'+
    'SUSPEND,TABLE,TAGS,TAN,TANH,TEMPORARY,THEN,TIME,TIMESTAMP,TIMEOUT,TO,'+
    'TRAILING,TRANSACTION,TRIGGER,TRIM,TRUE,TRUNC,TRUSTED,TWO_PHASE,TYPE,'+
    'UNCOMMITTED,UNDO,UNION,UNIQUE,UNKNOWN,UPDATE,UPDATING,UPPER,USAGE,USER,'+
    'USING,UUID_TO_CHAR,VALUE,VALUES,VAR_POP,VAR_SAMP,VARCHAR,VARIABLE,VARYING,'+
    'VIEW,WAIT,WEEK,WEEKDAY,WHEN,WHERE,WHILE,WITH,WORK,WRITE,YEAR,YEARDAY';

//---Firebird 4.0 keywords------------------------------------------------------
  Firebird40KW: string =
    'ABS,ABSOLUTE,ACCENT,ACOS,ACOSH,ACTION,ACTIVE,ADD,ADMIN,AFTER,ALL,ALTER,'+
    'ALWAYS,AND,ANY,AS,ASC,ASCENDING,ASCII_CHAR,ASCII_VAL,ASIN,ASINH,AT,ATAN,'+
    'ATAN2,ATANH,AUTO,AUTONOMOUS,AVG,BACKUP,BASE64_DECODE,BASE64_ENCODE,BEFORE,'+
    'BEGIN,BETWEEN,BIGINT,BIN_AND,BIN_NOT,BIN_OR,BIN_SHL,BIN_SHR,BIN_XOR,BINARY,'+
    'BIND,BIT_LENGTH,BLOB,BLOCK,BODY,BOOLEAN,BOTH,BREAK,BY,CALLER,CASCADE,CASE,'+
    'CAST,CEIL,CEILING,CHAR,CHAR_LENGTH,CHAR_TO_UUID,CHARACTER,CHARACTER_LENGTH,'+
    'CHECK,CLEAR,CLOSE,COALESCE,COLLATE,COLLATION,COLUMN,COMMENT,COMMIT,'+
    'COMMITTED,COMMON,COMPARE_DECFLOAT,COMPUTED,CONDITIONAL,CONNECT,CONNECTIONS,'+
    'CONSISTENCY,CONSTRAINT,CONTAINING,CONTINUE,CORR,COS,COSH,COT,COUNT,COUNTER,'+
    'COVAR_POP,COVAR_SAMP,CREATE,CROSS,CRYPT_HASH,CSTRING,CTR_BIG_ENDIAN,'+
    'CTR_LENGTH,CTR_LITTLE_ENDIAN,CUME_DIST,CURRENT,CURRENT_CONNECTION,'+
    'CURRENT_DATE,CURRENT_ROLE,CURRENT_TIME,CURRENT_TIMESTAMP,'+
    'CURRENT_TRANSACTION,CURRENT_USER,CURSOR,DATABASE,DATA,DATE,DATEADD,'+
    'DATEDIFF,DAY,DDL,DEC,DECFLOAT,DECIMAL,DECLARE,DECODE,DECRYPT,DEFAULT,'+
    'DEFINER,DELETE,DELETING,DENSE_RANK,DESC,DESCENDING,DESCRIPTOR,'+
    'DETERMINISTIC,DIFFERENCE,DISABLE,DISCONNECT,DISTINCT,DO,DOMAIN,DOUBLE,DROP,'+
    'ELSE,ENABLE,ENCRYPT,END,ENGINE,ENTRY_POINT,ESCAPE,EXCEPTION,EXCESS,EXCLUDE,'+
    'EXECUTE,EXISTS,EXIT,EXP,EXTENDED,EXTERNAL,EXTRACT,FALSE,FETCH,FILE,FILTER,'+
    'FIRST,FIRST_DAY,FIRST_VALUE,FIRSTNAME,FLOAT,FLOOR,FOLLOWING,FOR,FOREIGN,'+
    'FREE_IT,FROM,FULL,FUNCTION,GDSCODE,GENERATED,GENERATOR,GEN_ID,GEN_UUID,'+
    'GLOBAL,GRANT,GRANTED,GROUP,HASH,HAVING,HEX_DECODE,HEX_ENCODE,HOUR,IDENTITY,'+
    'IDLE,IF,IGNORE,IIF,IN,INACTIVE,INCLUDE,INCREMENT,INDEX,INNER,INPUT_TYPE,'+
    'INSENSITIVE,INSERT,INSERTING,INT,INT128,INTEGER,INTO,INVOKER,IS,ISOLATION,'+
    'IV,JOIN,KEY,LAG,LAST,LAST_DAY,LAST_VALUE,LASTNAME,LEAD,LEADING,LEAVE,LEFT,'+
    'LEGACY,LENGTH,LEVEL,LIFETIME,LIKE,LIMBO,LINGER,LIST,LN,LATERAL,LOCAL,'+
    'LOCALTIME,LOCALTIMESTAMP,LOCK,LOG,LOG10,LONG,LOWER,LPAD,LPARAM,MAKE_DBKEY,'+
    'MANUAL,MAPPING,MATCHED,MATCHING,MAX,MAXVALUE,MERGE,MESSAGE,MILLISECOND,'+
    'MIDDLENAME,MIN,MINUTE,MINVALUE,MOD,MODE,MODULE_NAME,MONTH,NAME,NAMES,'+
    'NATIONAL,NATIVE,NATURAL,NCHAR,NEXT,NO,NORMALIZE_DECFLOAT,NOT,NTH_VALUE,'+
    'NTILE,NULLIF,NULL,NULLS,NUMBER,NUMERIC,OCTET_LENGTH,OF,OFFSET,OLDEST,ON,'+
    'ONLY,OPEN,OPTION,OR,ORDER,OS_NAME,OTHERS,OUTER,OUTPUT_TYPE,OVER,OVERFLOW,'+
    'OVERLAY,OVERRIDING,PACKAGE,PAD,PAGE,PAGES,PAGE_SIZE,PARAMETER,PARTITION,'+
    'PASSWORD,PERCENT_RANK,PI,PLACING,PLAN,PLUGIN,POOL,POSITION,POST_EVENT,'+
    'POWER,PRECEDING,PRECISION,PRESERVE,PRIMARY,PRIOR,PRIVILEGE,PRIVILEGES,'+
    'PROCEDURE,PROTECTED,PUBLICATION,QUANTIZE,RAND,RANGE,RANK,RDB$DB_KEY,'+
    'RDB$ERROR,RDB$GET_CONTEXT,RDB$GET_TRANSACTION_CN,RDB$RECORD_VERSION,'+
    'RDB$ROLE_IN_USE,RDB$SET_CONTEXT,RDB$SYSTEM_PRIVILEGE,READ,REAL,'+
    'RECORD_VERSION,RECREATE,RECURSIVE,REFERENCES,REGR_AVGX,REGR_AVGY,'+
    'REGR_COUNT,REGR_INTERCEPT,REGR_R2,REGR_SLOPE,REGR_SXX,REGR_SXY,REGR_SYY,'+
    'RELATIVE,RELEASE,REPLACE,REQUESTS,RESERV,RESERVING,RESET,RESETTING,RESTART,'+
    'RESTRICT,RETAIN,RETURN,RETURNING,RETURNING_VALUES,RETURNS,REVERSE,REVOKE,'+
    'RIGHT,ROLE,ROLLBACK,ROUND,ROW,ROW_COUNT,ROW_NUMBER,ROWS,RPAD,RSA_DECRYPT,'+
    'RSA_ENCRYPT,RSA_PRIVATE,RSA_PUBLIC,RSA_SIGN_HASH,RSA_VERIFY_HASH,SALT_LENGTH,'+
    'SAVEPOINT,SCALAR_ARRAY,SCHEMA,SCROLL,SECOND,SECURITY,SEGMENT,SELECT,'+
    'SENSITIVE,SEQUENCE,SERVERWIDE,SESSION,SET,SHADOW,SHARED,SIGN,SIGNATURE,'+
    'SIMILAR,SIN,SINGULAR,SINH,SIZE,SKIP,SMALLINT,SNAPSHOT,SOME,SORT,SOURCE,'+
    'SPACE,SQL,SQLCODE,SQLSTATE,SQRT,STABILITY,START,STARTING,STARTS,STATEMENT,'+
    'STATISTICS,STDDEV_POP,STDDEV_SAMP,SUBSTRING,SUB_TYPE,SUM,SUSPEND,SYSTEM,'+
    'TABLE,TAGS,TAN,TANH,TEMPORARY,THEN,TIES,TIME,TIMESTAMP,TIMEOUT,'+
    'TIMEZONE_HOUR,TIMEZONE_MINUTE,TO,TOTALORDER,TRAILING,TRANSACTION,TRAPS,'+
    'TRIGGER,TRIM,TRUE,TRUNC,TRUSTED,TWO_PHASE,TYPE,UNBOUNDED,UNCOMMITTED,UNDO,'+
    'UNION,UNIQUE,UNKNOWN,UPDATE,UPDATING,UPPER,USAGE,USER,USING,UUID_TO_CHAR,'+
    'VALUE,VALUES,VAR_POP,VAR_SAMP,VARBINARY,VARCHAR,VARIABLE,VARYING,VIEW,WAIT,'+
    'WEEK,WEEKDAY,WHEN,WHERE,WHILE,WINDOW,WITH,WITHOUT,WORK,WRITE,YEAR,YEARDAY,'+
    'ZONE';

procedure MakeIdentTable;
var
  c: char;
begin
  FillChar(Identifiers, SizeOf(Identifiers), 0);
  for c := 'a' to 'z' do
    Identifiers[c] := TRUE;
  for c := 'A' to 'Z' do
    Identifiers[c] := TRUE;
  for c := '0' to '9' do
    Identifiers[c] := TRUE;
  Identifiers['_'] := TRUE;
  Identifiers['#'] := TRUE;                                                     // DJLP 2000-09-05
  Identifiers['$'] := TRUE;                                                     // DJLP 2000-09-05

  FillChar(mHashTable, SizeOf(mHashTable), 0);
  mHashTable['_'] := 1;
  for c := 'a' to 'z' do
    mHashTable[c] := 2 + Ord(c) - Ord('a');
  for c := 'A' to 'Z' do
    mHashTable[c] := 2 + Ord(c) - Ord('A');

  Move(Identifiers, IdentifiersMSSQL7, SizeOf(Identifiers));
  Move(mHashTable, mHashTableMSSQL7, SizeOf(mHashTable));
  IdentifiersMSSQL7['@'] := TRUE;
  mHashTableMSSQL7['@'] := mHashTableMSSQL7['Z'] + 1;
end;

function TSynSQLSyn.KeyHash(ToHash: PChar): Integer;
var
  Start: PChar;
begin
  Result := 0;
  Start := ToHash;
  while fIdentifiersPtr^[ToHash^] do begin
  
    Result := (2 * Result + fmHashTablePtr^[ToHash^]) and $FFFFFF;
    inc(ToHash);
  end;
  Result := Result and $FF; // 255
  fStringLen := ToHash - Start;
end;

function TSynSQLSyn.KeyComp(const aKey: string): Boolean;
var
  i: integer;
  pKey1, pKey2: PChar;
begin
  pKey1 := fToIdent;
  // Note: fStringLen is always > 0 !
  pKey2 := pointer(aKey);
  for i := 1 to fStringLen do
  begin
    if mHashTable[pKey1^] <> mHashTable[pKey2^] then
    begin
      Result := FALSE;
      exit;
    end;
    Inc(pKey1);
    Inc(pKey2);
  end;
  Result := TRUE;
end;

function TSynSQLSyn.IdentKind(MayBe: PChar): TtkTokenKind;
var
  Entry: TSynHashEntry;
begin
  fToIdent := MayBe;
  Entry := fKeywords[KeyHash(MayBe)];
  while Assigned(Entry) do begin
    if Entry.KeywordLen > fStringLen then
      break
    else if Entry.KeywordLen = fStringLen then
      if KeyComp(Entry.Keyword) then begin
        Result := TtkTokenKind(Entry.Kind);
        exit;
      end;
    Entry := Entry.Next;
  end;
  Result := tkIdentifier;
end;

procedure TSynSQLSyn.MakeMethodTables;
var
  I: Char;
begin
  for I := #0 to #255 do
    case I of
       #0: fProcTable[I] := @NullProc;
      #10: fProcTable[I] := @LFProc;
      #13: fProcTable[I] := @CRProc;
      #39: fProcTable[I] := @AsciiCharProc;
      '=': fProcTable[I] := @EqualProc;
      '>': fProcTable[I] := @GreaterProc;
      '<': fProcTable[I] := @LowerProc;
      '-': fProcTable[I] := @MinusProc;
      '|': fProcTable[I] := @OrSymbolProc;
      '+': fProcTable[I] := @PlusProc;
      '/': fProcTable[I] := @SlashProc;
      '&': fProcTable[I] := @AndSymbolProc;
      #34: fProcTable[I] := @StringProc;
      ':', '@':
        fProcTable[I] := @VariableProc;
      'A'..'Z', 'a'..'z', '_':
        fProcTable[I] := @IdentProc;
      '0'..'9':
        fProcTable[I] := @NumberProc;
      #1..#9, #11, #12, #14..#32:
        fProcTable[I] := @SpaceProc;
      '^', '%', '*', '!':
        fProcTable[I] := @SymbolAssignProc;
      '{', '}', '.', ',', ';', '?', '(', ')', '[', ']', '~':
        fProcTable[I] := @SymbolProc;
      else
        fProcTable[I] := @UnknownProc;
    end;
end;

constructor TSynSQLSyn.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  fKeywords := TSynHashEntryList.Create;
  fTableNames := TStringList.Create;
  TStringList(fTableNames).OnChange := @TableNamesChanged;
  fCommentAttri := TSynHighlighterAttributes.Create(@SYNS_AttrComment, SYNS_XML_AttrComment);
  fCommentAttri.Style := [fsItalic];
  AddAttribute(fCommentAttri);
  fDataTypeAttri := TSynHighlighterAttributes.Create(@SYNS_AttrDataType, SYNS_XML_AttrDataType);
  fDataTypeAttri.Style := [fsBold];
  AddAttribute(fDataTypeAttri);
{begin}                                                                         // DJLP 2000-08-11
  fDefaultPackageAttri :=
    TSynHighlighterAttributes.Create(@SYNS_AttrDefaultPackage, SYNS_XML_AttrDefaultPackage);
  fDefaultPackageAttri.Style := [fsBold];
  AddAttribute(fDefaultPackageAttri);
{end}                                                                           // DJLP 2000-08-11
  fExceptionAttri := TSynHighlighterAttributes.Create(@SYNS_AttrException, SYNS_XML_AttrException);
  fExceptionAttri.Style := [fsItalic];
  AddAttribute(fExceptionAttri);
  fFunctionAttri := TSynHighlighterAttributes.Create(@SYNS_AttrFunction, SYNS_XML_AttrFunction);
  fFunctionAttri.Style := [fsBold];
  AddAttribute(fFunctionAttri);
  fIdentifierAttri := TSynHighlighterAttributes.Create(@SYNS_AttrIdentifier, SYNS_XML_AttrIdentifier);
  AddAttribute(fIdentifierAttri);
  fKeyAttri := TSynHighlighterAttributes.Create(@SYNS_AttrReservedWord, SYNS_XML_AttrReservedWord);
  fKeyAttri.Style := [fsBold];
  AddAttribute(fKeyAttri);
  fNumberAttri := TSynHighlighterAttributes.Create(@SYNS_AttrNumber, SYNS_XML_AttrNumber);
  AddAttribute(fNumberAttri);
{begin}                                                                         // DJLP 2000-08-11
  fPLSQLAttri := TSynHighlighterAttributes.Create(@SYNS_AttrPLSQL, SYNS_XML_AttrPLSQL);
  fPLSQLAttri.Style := [fsBold];
  AddAttribute(fPLSQLAttri);
{end}                                                                           // DJLP 2000-08-11
  fSpaceAttri := TSynHighlighterAttributes.Create(@SYNS_AttrSpace, SYNS_XML_AttrSpace);
  AddAttribute(fSpaceAttri);
{begin}                                                                         // DJLP 2000-09-05
  fSQLPlusAttri:=TSynHighlighterAttributes.Create(@SYNS_AttrSQLPlus, SYNS_XML_AttrSQLPlus);
  fSQLPlusAttri.Style := [fsBold];
  AddAttribute(fSQLPlusAttri);
{end}                                                                           // DJLP 2000-09-05
  fStringAttri := TSynHighlighterAttributes.Create(@SYNS_Attrstring, SYNS_XML_Attrstring);
  AddAttribute(fStringAttri);
  fSymbolAttri := TSynHighlighterAttributes.Create(@SYNS_AttrSymbol, SYNS_XML_AttrSymbol);
  AddAttribute(fSymbolAttri);
  fTableNameAttri := TSynHighlighterAttributes.Create(@SYNS_AttrTableName, SYNS_XML_AttrTableName);
  AddAttribute(fTableNameAttri);
  fVariableAttri := TSynHighlighterAttributes.Create(@SYNS_AttrVariable, SYNS_XML_AttrVariable);
  AddAttribute(fVariableAttri);
  SetAttributesOnChange(@DefHighlightChange);
  MakeMethodTables;
  fDefaultFilter := SYNS_FilterSQL;
  fRange := rsUnknown;
  fDialect := sqlStandard;
  SQLDialect := sqlSybase;
end;

destructor TSynSQLSyn.Destroy;
begin
  fKeywords.Free;
  fTableNames.Free;
  inherited Destroy;
end;

procedure TSynSQLSyn.Assign(Source: TPersistent);
begin
  inherited Assign(Source);
  if (Source is TSynSQLSyn) then
    SQLDialect := TSynSQLSyn(Source).SQLDialect;
end;

procedure TSynSQLSyn.SetLine(const NewValue: string; LineNumber: Integer);
begin
  inherited;
  fLine := PChar(NewValue);
  Run := 0;
  fLineNumber := LineNumber;
  Next;
end;

procedure TSynSQLSyn.AndSymbolProc;
begin
  fTokenID := tkSymbol;
  Inc(Run);
  if fLine[Run] in ['=', '&'] then Inc(Run);
end;

procedure TSynSQLSyn.AsciiCharProc;
begin
  // Oracle SQL allows strings to go over multiple lines
  if fLine[Run] = #0 then
    NullProc
  else begin
    fTokenID := tkString;
    if (fRange = rsString) and (fLine[Run] = #39) then begin
      // End of a string after linebreak
      Inc(Run);
      fRange := rsUnknown;
    end
    else
    if SQLDialect <> sqlMySql then begin
      fRange := rsString;
      repeat
        Inc(Run);
      until fLine[Run] in [#0, #10, #13, #39];
      if fLine[Run] = #39 then begin
        Inc(Run);
        fRange := rsUnknown;
      end;
    end
    else begin
      fRange := rsString;
      repeat
        if (fLine[Run] = '\') and (fLine[Run+1] in [#39, '\']) then
          Inc(Run);
        Inc(Run);
      until fLine[Run] in [#0, #10, #13, #39];
      if fLine[Run] = #39 then begin
        Inc(Run);
        fRange := rsUnknown;
      end;
    end;
  end;
end;

procedure TSynSQLSyn.CRProc;
begin
  fTokenID := tkSpace;
  Inc(Run);
  if fLine[Run] = #10 then Inc(Run);
end;

procedure TSynSQLSyn.EqualProc;
begin
  fTokenID := tkSymbol;
  Inc(Run);
  if fLine[Run] in ['=', '>'] then Inc(Run);
end;

procedure TSynSQLSyn.GreaterProc;
begin
  fTokenID := tkSymbol;
  Inc(Run);
  if fLine[Run] in ['=', '>'] then Inc(Run);
end;

procedure TSynSQLSyn.IdentProc;
begin
  fTokenID := IdentKind((fLine + Run));
  inc(Run, fStringLen);
{begin}                                                                         // DJLP 2000-08-11
  if fTokenID = tkComment then begin
    while not (fLine[Run] in [#0, #10, #13]) do
      Inc(Run);
  end else
{end}                                                                           // DJLP 2000-08-11
    while fIdentifiersPtr^[fLine[Run]] do inc(Run);
end;

procedure TSynSQLSyn.LFProc;
begin
  fTokenID := tkSpace;
  inc(Run);
end;

procedure TSynSQLSyn.LowerProc;
begin
  fTokenID := tkSymbol;
  Inc(Run);
  case fLine[Run] of
    '=': Inc(Run);
    '<': begin
           Inc(Run);
           if fLine[Run] = '=' then Inc(Run);
         end;
  end;
end;

procedure TSynSQLSyn.MinusProc;
begin
  Inc(Run);
  if fLine[Run] = '-' then begin
    fTokenID := tkComment;
    repeat
      Inc(Run);
    until fLine[Run] in [#0, #10, #13];
  end else
    fTokenID := tkSymbol;
end;

procedure TSynSQLSyn.NullProc;
begin
  fTokenID := tkNull;
end;

procedure TSynSQLSyn.NumberProc;
begin
  inc(Run);
  fTokenID := tkNumber;
  while FLine[Run] in ['0'..'9'] do inc(Run);
  if (FLine[Run]='.') and not(fLine[Run+1]='.')  then begin
    inc(Run);
    while FLine[Run] in ['0'..'9'] do inc(Run);
  end;
  if (FLine[Run]='e') or (fLine[Run]='E')  then begin
    inc(Run);
    if (FLine[Run]='+') or (fLine[Run]='-')  then inc(Run);
    while FLine[Run] in ['0'..'9'] do inc(Run);
  end;
end;

procedure TSynSQLSyn.OrSymbolProc;
begin
  fTokenID := tkSymbol;
  Inc(Run);
  if fLine[Run] in ['=', '|'] then Inc(Run);
end;

procedure TSynSQLSyn.PlusProc;
begin
  fTokenID := tkSymbol;
  Inc(Run);
  if fLine[Run] in ['=', '+'] then Inc(Run);
end;

procedure TSynSQLSyn.SlashProc;
begin
  Inc(Run);
  case fLine[Run] of
    '*':
      begin
        fRange := rsComment;
        fTokenID := tkComment;
        repeat
          Inc(Run);
          if (fLine[Run] = '*') and (fLine[Run + 1] = '/') then begin
            fRange := rsUnknown;
            Inc(Run, 2);
            break;
          end;
        until fLine[Run] in [#0, #10, #13];
      end;
    '=':
      begin
        Inc(Run);
        fTokenID := tkSymbol;
      end;
    else
      fTokenID := tkSymbol;
  end;
end;

procedure TSynSQLSyn.SpaceProc;
begin
  fTokenID := tkSpace;
  repeat
    Inc(Run);
  until (fLine[Run] > #32) or (fLine[Run] in [#0, #10, #13]);
end;

procedure TSynSQLSyn.StringProc;
begin
  fTokenID := tkString;
  Inc(Run);
  while not (fLine[Run] in [#0, #10, #13]) do begin
    case fLine[Run] of
      '\': if fLine[Run + 1] in [#34, '\'] then
             Inc(Run);
      #34: if fLine[Run + 1] <> #34 then
           begin
             Inc(Run);
             break;
           end;
    end;
    Inc(Run);
  end;
end;

procedure TSynSQLSyn.SymbolProc;
begin
  Inc(Run);
  fTokenID := tkSymbol;
end;

procedure TSynSQLSyn.SymbolAssignProc;
begin
  fTokenID := tkSymbol;
  Inc(Run);
  if fLine[Run] = '=' then Inc(Run);
end;

procedure TSynSQLSyn.VariableProc;
var
  i: integer;
begin
  // MS SQL uses @@ to indicate system functions/variables
  if (fDialect in [sqlMSSQL7, sqlMSSQL2K, sqlMSSQL2022]) and (fLine[Run] = '@') and (fLine[Run + 1] = '@')
  then
    IdentProc
{begin}                                                                         //JDR 2000-25-2000
  else if (SQLDialect in [sqlMySql, sqlOracle]) and (fLine[Run] = '@') then
    SymbolProc
{end}                                                                           //JDR 2000-25-2000
  // Oracle uses the ':' character to indicate bind variables
{begin}                                                                         //JJV 2000-11-16
  // Ingres II also uses the ':' character to indicate variables
  else
    if not (SQLDialect in [sqlOracle, sqlIngres]) and (fLine[Run] = ':') then
{end}                                                                           //JJV 2000-11-16
    SymbolProc
  else begin
    fTokenID := tkVariable;
    i := Run;
    repeat
      Inc(i);
    until not (fIdentifiersPtr^[fLine[i]]);
    Run := i;
  end;
end;

procedure TSynSQLSyn.UnknownProc;
begin
  if (SQLDialect = sqlMySql) and (fLine[Run] = '#') and (Run = 0) then          //DDH Changes from Tonci Grgin for MYSQL
  begin
    fTokenID := tkComment;
    fRange := rsComment;
  end else begin
    {$IFDEF SYN_MBCSSUPPORT}
    if FLine[Run] in LeadBytes then
      Inc(Run,2)
    else
    {$ENDIF}
    inc(Run);
    while (fLine[Run] in [#128..#191]) OR // continued utf8 subcode
     ((fLine[Run]<>#0) and (fProcTable[fLine[Run]] = @UnknownProc)) do inc(Run);
    fTokenID := tkUnknown;
  end;
end;

procedure TSynSQLSyn.AnsiCProc;
begin
  case fLine[Run] of
     #0: NullProc;
    #10: LFProc;
    #13: CRProc;
    else begin
      fTokenID := tkComment;
      if (SQLDialect = sqlMySql) and (fLine[Run] = '#') then begin              //DDH Changes from Tonci Grgin for MYSQL
        repeat
          Inc(Run);
        until fLine[Run] in [#0, #10, #13];
        fRange := rsUnknown;
      end
      else begin

        repeat
          if (fLine[Run] = '*') and (fLine[Run + 1] = '/') then begin
            fRange := rsUnknown;
            Inc(Run, 2);
            break;
          end;
          Inc(Run);
        until fLine[Run] in [#0, #10, #13];
      end;
    end;
  end;
end;

{begin}                                                                         // DJLP 2000-08-09
function TSynSQLSyn.IsKeyword(const AKeyword: string): boolean;
var
  tk: TtkTokenKind;
begin
  tk := IdentKind(PChar(AKeyword));
  Result := tk in [tkDatatype, tkException, tkFunction, tkKey, tkPLSQL,
    tkDefaultPackage];
end;
{end}                                                                           // DJLP 2000-08-09

procedure TSynSQLSyn.Next;
begin
  fTokenPos := Run;
  case fRange of
    rsComment:
      AnsiCProc;
    rsString:
      AsciiCharProc;
  else
    fProcTable[fLine[Run]]();
  end;
end;

function TSynSQLSyn.GetDefaultAttribute(Index: integer):
  TSynHighlighterAttributes;
begin
  case Index of
    SYN_ATTR_COMMENT: Result := fCommentAttri;
    SYN_ATTR_IDENTIFIER: Result := fIdentifierAttri;
    SYN_ATTR_KEYWORD: Result := fKeyAttri;
    SYN_ATTR_STRING: Result := fStringAttri;
    SYN_ATTR_WHITESPACE: Result := fSpaceAttri;
    SYN_ATTR_SYMBOL: Result := fSymbolAttri;
    SYN_ATTR_NUMBER: Result := fNumberAttri;
    SYN_ATTR_VARIABLE: Result := fVariableAttri;
  else
    Result := nil;
  end;
end;

function TSynSQLSyn.GetEol: Boolean;
begin
  Result := fTokenID = tkNull;
end;

function TSynSQLSyn.GetRange: Pointer;
begin
  Result := Pointer(PtrInt(fRange));
end;

function TSynSQLSyn.GetToken: string;
var
  Len: LongInt;
begin
  Result := '';
  Len := Run - fTokenPos;
  Setstring(Result, (FLine + fTokenPos), Len);
end;

procedure TSynSQLSyn.GetTokenEx(out TokenStart: PChar; out TokenLength: integer);
begin
  TokenLength:=Run-fTokenPos;
  TokenStart:=FLine + fTokenPos;
end;

function TSynSQLSyn.GetTokenID: TtkTokenKind;
begin
  Result := fTokenId;
end;

function TSynSQLSyn.GetTokenAttribute: TSynHighlighterAttributes;
begin
  case GetTokenID of
    tkComment: Result := fCommentAttri;
    tkDatatype: Result := fDataTypeAttri;
    tkDefaultPackage: Result := fDefaultPackageAttri;                           // DJLP 2000-08-11
    tkException: Result := fExceptionAttri;
    tkFunction: Result := fFunctionAttri;
    tkIdentifier: Result := fIdentifierAttri;
    tkKey: Result := fKeyAttri;
    tkNumber: Result := fNumberAttri;
    tkPLSQL: Result := fPLSQLAttri;                                             // DJLP 2000-08-11
    tkSpace: Result := fSpaceAttri;
    tkSQLPlus: Result := fSQLPlusAttri;                                         // DJLP 2000-08-11
    tkString: Result := fStringAttri;
    tkSymbol: Result := fSymbolAttri;
    tkTableName: Result := fTableNameAttri;
    tkVariable: Result := fVariableAttri;
    tkUnknown: Result := fIdentifierAttri;
  else
    Result := nil;
  end;
end;

function TSynSQLSyn.GetTokenKind: integer;
begin
  Result := Ord(fTokenId);
end;

function TSynSQLSyn.GetTokenPos: Integer;
begin
  Result := fTokenPos;
end;

procedure TSynSQLSyn.ResetRange;
begin
  fRange := rsUnknown;
end;

procedure TSynSQLSyn.SetRange(Value: Pointer);
begin
  fRange := TRangeState(PtrUInt(Value));
end;

function TSynSQLSyn.GetIdentChars: TSynIdentChars;
begin
  Result := TSynValidStringChars;
  if (fDialect in [sqlMSSQL7, sqlMSSQL2K, sqlMSSQL2022]) then
    Include(Result, '@')
{begin}                                                                         // DJLP 2000-08-11
  else if fDialect = sqlOracle then begin
    Include(Result, '#');
    Include(Result, '$');
  end
{end}                                                                           // DJLP 2000-08-11
  else if (fDialect = sqlFirebird25) or
          (fDialect = sqlFirebird30) or
          (fDialect = sqlFirebird40) then Include(Result, '$');
end;

class function TSynSQLSyn.GetLanguageName: string;
begin
  Result := SYNS_LangSQL;
end;

procedure TSynSQLSyn.DoAddKeyword(AKeyword: string; AKind: integer);
var
  HashValue: integer;
begin
  HashValue := KeyHash(PChar(AKeyword));
  fKeywords[HashValue] := TSynHashEntry.Create(AKeyword, AKind);
end;

procedure TSynSQLSyn.SetTableNames(const Value: TStrings);
begin
  fTableNames.Assign(Value);
end;

procedure TSynSQLSyn.TableNamesChanged(Sender: TObject);
begin
  InitializeKeywordLists;
end;

procedure TSynSQLSyn.PutTableNamesInKeywordList;
var
  i: Integer;
  Entry: TSynHashEntry;
begin
  for i := 0 to (fTableNames.Count - 1) do
  begin
    Entry := fKeywords[KeyHash(PChar(fTableNames[i]))];
    while Assigned(Entry) do
    begin
      if CompareText(Entry.Keyword, fTableNames[i]) = 0 then
        Break;
      Entry := Entry.Next;
    end;
    if not Assigned(Entry) then
      DoAddKeyword(fTableNames[i], Ord(tkTableName));
  end;
end;

procedure TSynSQLSyn.InitializeKeywordLists;
begin
  fKeywords.Clear;
  if (fDialect in [sqlMSSQL7, sqlMSSQL2K, sqlMSSQL2022]) then
  begin
    fIdentifiersPtr := @IdentifiersMSSQL7;
    fmHashTablePtr := @mHashTableMSSQL7;
  end else begin
    fIdentifiersPtr := @Identifiers;
    fmHashTablePtr := @mHashTable;
  end;

  case fDialect of
    sqlPostgres:
      begin
        EnumerateKeywords(Ord(tkKey), PostgresKW, IdentChars, @DoAddKeyword);
        EnumerateKeywords(Ord(tkDatatype), PostgresTypes, IdentChars,
          @DoAddKeyword);
        EnumerateKeywords(Ord(tkFunction), PostgresFunctions, IdentChars,
          @DoAddKeyword);
        EnumerateKeywords(Ord(tkException), PostgresExceptions, IdentChars,
          @DoAddKeyword);
      end;
    sqlSqlite:
      begin
        EnumerateKeywords(Ord(tkDatatype), SQLiteTypes, IdentChars,
          @DoAddKeyword);
        EnumerateKeywords(Ord(tkFunction), SQLiteFunctions, IdentChars,
          @DoAddKeyword);
        EnumerateKeywords(Ord(tkKey), SQLiteKW, IdentChars, @DoAddKeyword);
      end;
    sqlIngres:
      begin
        EnumerateKeywords(Ord(tkDatatype), IngresTypes, IdentChars,
          @DoAddKeyword);
        EnumerateKeywords(Ord(tkKey), IngresKW, IdentChars, @DoAddKeyword);
        EnumerateKeywords(Ord(tkFunction), IngresFunctions, IdentChars,
          @DoAddKeyword);
      end;
    sqlInterbase6:
      begin
        EnumerateKeywords(Ord(tkDatatype), Interbase6Types, IdentChars,
          @DoAddKeyword);
        EnumerateKeywords(Ord(tkFunction), Interbase6Functions, IdentChars,
          @DoAddKeyword);
        EnumerateKeywords(Ord(tkKey), Interbase6KW, IdentChars, @DoAddKeyword);
      end;
    sqlMSSQL7:
      begin
        EnumerateKeywords(Ord(tkKey), MSSQL7KW, IdentChars, @DoAddKeyword);
        EnumerateKeywords(Ord(tkDatatype), MSSQL7Types, IdentChars,
          @DoAddKeyword);
        EnumerateKeywords(Ord(tkFunction), MSSQL7Functions, IdentChars,
          @DoAddKeyword);
      end;
    sqlMSSQL2K:
      begin
        EnumerateKeywords(ord(tkKey), MSSQL2000KW, IdentChars, @DoAddKeyword);
        EnumerateKeywords(ord(tkDataType), MSSQL2000Types, IdentChars, @DoAddKeyword);
        EnumerateKeywords(ord(tkFunction), MSSQL2000Functions, IdentChars, @DoAddKeyword);
      end;
    sqlMSSQL2022:
      begin
        EnumerateKeywords(Ord(tkKey), MSSQLKW, IdentChars, @DoAddKeyword);
        EnumerateKeywords(Ord(tkDatatype), MSSQLTypes, IdentChars, @DoAddKeyword);
        EnumerateKeywords(Ord(tkFunction), MSSQLFunctions, IdentChars, @DoAddKeyword);
      end;
    sqlMySql:
      begin
        EnumerateKeywords(Ord(tkKey), MySqlKW, IdentChars, @DoAddKeyword);
        EnumerateKeywords(Ord(tkDatatype), MySqlTypes, IdentChars,
          @DoAddKeyword);
        EnumerateKeywords(Ord(tkFunction), MySqlFunctions, IdentChars,
          @DoAddKeyword);
      end;
    sqlOracle:
      begin
        EnumerateKeywords(Ord(tkKey), OracleKW, IdentChars, @DoAddKeyword);
        EnumerateKeywords(Ord(tkDatatype), OracleTypes, IdentChars,
          @DoAddKeyword);
        EnumerateKeywords(Ord(tkException), OracleExceptions, IdentChars,
          @DoAddKeyword);
        EnumerateKeywords(Ord(tkFunction), OracleFunctions, IdentChars,
          @DoAddKeyword);
        EnumerateKeywords(Ord(tkComment), OracleCommentKW, IdentChars,
          @DoAddKeyword);
        EnumerateKeywords(Ord(tkDefaultPackage), OracleDefaultPackages,
          IdentChars, @DoAddKeyword);
        EnumerateKeywords(Ord(tkPLSQL), OraclePLSQLKW, IdentChars,
          @DoAddKeyword);
        EnumerateKeywords(Ord(tkSQLPlus), OracleSQLPlusCommands, IdentChars,
          @DoAddKeyword);
      end;
    sqlStandard:
      EnumerateKeywords(Ord(tkKey), StandardKW, IdentChars + ['-'], @DoAddKeyword);
    sqlSybase:
      EnumerateKeywords(Ord(tkKey), SybaseKW, IdentChars, @DoAddKeyword);
    sqlFirebird25:
      EnumerateKeywords(Ord(tkKey), Firebird25KW, IdentChars, @DoAddKeyword);
    sqlFirebird30:
      EnumerateKeywords(Ord(tkKey), Firebird30KW, IdentChars, @DoAddKeyword);
    sqlFirebird40:
      EnumerateKeywords(Ord(tkKey), Firebird40KW, IdentChars, @DoAddKeyword);
  end;
  PutTableNamesInKeywordList;
  DefHighlightChange(Self);
end;

procedure TSynSQLSyn.SetDialect(Value: TSQLDialect);
begin
  if (Value <> fDialect) then
  begin
    fDialect := Value;
    InitializeKeywordLists;
  end;
end;

function TSynSQLSyn.GetSampleSource: String;
begin
  Result:= '';
  case fDialect of
    sqlPostgres:
      Result := '-- PostgreSQL SQL sample source'#13#10 +
        'SELECT datname'#13#10 +
        'FROM pg_database'#13#10 +
        'WHERE datname = ''postgres'';';
    sqlStandard:
      Result := '-- ansi sql sample source'#13#10 +
        'select name , region'#13#10 +
        'from cia'#13#10 +
        'where area < 2000'#13#10 +
        'and gdp > 5000000000';
    sqlInterbase6:
      Result := '/* Interbase sample source */'#13#10 +
        'SET TERM !! ;'#13#10 +
        #13#10 +
        'CREATE PROCEDURE HelloWorld(P_MSG VARCHAR(80)) AS'#13#10 +
        'BEGIN'#13#10 +
        '  EXECUTE PROCEDURE WRITELN(:P_MSG);'#13#10 +
        'END !!'#13#10 +
        #13#10 +
        'SET TERM ; !!';
    sqlMySQL:
      Result := '/* MySQL sample source*/'#13#10 +
        'SET @variable= { 1 }'#13#10 +
        #13#10 +
        'CREATE TABLE sample ('#13#10 +
        '        id INT NOT NULL,'#13#10 +
        '        first_name CHAR(30) NOT NULL,'#13#10 +
        '        PRIMARY KEY (id),'#13#10 +
        '        INDEX name (first_name));'#13#10 +
        #13#10 +
        'SELECT DATE_ADD("1997-12-31 23:59:59",'#13#10 +
        '        INTERVAL 1 SECOND);'#13#10 +
        #13#10 +
        '# End of sample';
    sqlOracle:
      Result := 'PROMPT Oracle sample source'#13#10 +
        'declare'#13#10 +
        '  x varchar2(2000);'#13#10 +
        'begin   -- Show some text here'#13#10 +
        '  select to_char(count(*)) into x'#13#10 +
        '  from tab;'#13#10 +
        #13#10 +
        '  dbms_output.put_line(''Hello World: '' || x);'#13#10 +
        'exception'#13#10 +
        '  when others then'#13#10 +
        '    null;'#13#10 +
        'end;';
    sqlSybase:
      Result := '/* SyBase example source */'#13#10 +
        'declare @Integer        int'#13#10 +
        #13#10 +
        '/* Good for positive numbers only. */'#13#10 +
        'select @Integer = 1000'#13#10 +
        #13#10 +
        'select "Positives Only" ='#13#10 +
        '  right(replicate("0",12) + '#13#10 +
        '    convert(varchar, @Integer),12)'#13#10 +
        #13#10 +
        '/* Good for positive and negative numbers. */'#13#10 +
        'select @Integer = -1000'#13#10 +
        #13#10 +
        'select "Both Signs" ='#13#10 +
        '  substring( "- +", (sign(@Integer) + 2), 1) +'#13#10 +
        '  right(replicate("0",12) + '#13#10 +
        '    convert(varchar, abs(@Integer)),12)'#13#10 +
        #13#10 +
        'select @Integer = 1000'#13#10 +
        #13#10 +
        'select "Both Signs" ='#13#10 +
        '  substring( "- +", (sign(@Integer) + 2), 1) +'#13#10 +
        '  right(replicate("0",12) + '#13#10 +
        '    convert(varchar, abs(@Integer)),12)'#13#10 +
        #13#10 +
        'go';
    sqlIngres:
      Result := '/* Ingres example source */'#13#10 +
        'DELETE'#13#10 +
        'FROM t1'#13#10 +
        'WHERE EXISTS'#13#10 +
        '(SELECT t2.column1, t2.column2'#13#10 +
        'FROM t2'#13#10 +
        'WHERE t1.column1 = t2.column1 and'#13#10 +
        't1.column2 = t2.column2)';
    sqlMSSQL7:
      Result := '/* SQL Server 7 example source */'#13#10 +
        'SET QUOTED_IDENTIFIER OFF'#13#10 +
        'GO'#13#10 +
        'SET ANSI_NULLS OFF'#13#10 +
        'GO'#13#10 +
        #13#10 +
        '/* Object:  Stored Procedure dbo.sp_PPQInsertOrder */'#13#10 +
        'CREATE PROCEDURE sp_PPQInsertOrder'#13#10 +
        '  @Name    varchar(25),'#13#10 +
        '  @Address varchar(255),'#13#10 +
        '  @ZipCode varchar(15)'#13#10 +
        'As'#13#10 +
        '  INSERT INTO PPQOrders(Name, Address, ZipCode, OrderDate)'#13#10 +
        '  VALUES (@Name, @Address, @ZipCode, GetDate())'#13#10 +
        #13#10 +
        '  SELECT SCOPE_IDENTITY()'#13#10 +
        'GO';
    sqlMSSQL2K:
      Result := '/* SQL Server2000 example source */'#13#10 +
        'SET QUOTED_IDENTIFIER OFF'#13#10 +
        'GO'#13#10 +
        'SET ANSI_NULLS OFF'#13#10 +
        'GO'#13#10 +
        #13#10 +
        '/* Object:  Stored Procedure dbo.sp_PPQInsertOrder */'#13#10 +
        'CREATE PROCEDURE sp_PPQInsertOrder'#13#10 +
        '  @Name    varchar(25),'#13#10 +
        '  @Address varchar(255),'#13#10 +
        '  @ZipCode varchar(15)'#13#10 +
        'As'#13#10 +
        '  INSERT INTO PPQOrders(Name, Address, ZipCode, OrderDate)'#13#10 +
        '  VALUES (@Name, @Address, @ZipCode, GetDate())'#13#10 +
        #13#10 +
        '  SELECT SCOPE_IDENTITY()'#13#10 +
        'GO';
    sqlMSSQL2022:
      Result := '/* SQL Server example source */'#13#10 +
        'SET QUOTED_IDENTIFIER OFF'#13#10 +
        'GO'#13#10 +
        'SET ANSI_NULLS OFF'#13#10 +
        'GO'#13#10 +
        #13#10 +
        '/* Object:  Stored Procedure dbo.sp_PPQInsertOrder */'#13#10 +
        'CREATE PROCEDURE sp_PPQInsertOrder'#13#10 +
        '  @Name    varchar(25),'#13#10 +
        '  @Address varchar(255),'#13#10 +
        '  @ZipCode varchar(15)'#13#10 +
        'As'#13#10 +
        '  INSERT INTO PPQOrders(Name, Address, ZipCode, OrderDate)'#13#10 +
        '  VALUES (@Name, @Address, @ZipCode, GetDate())'#13#10 +
        #13#10 +
        '  SELECT SCOPE_IDENTITY()'#13#10 +
        'GO';
  end;
end;

initialization
  MakeIdentTable;
  RegisterPlaceableHighlighter(TSynSQLSyn);

end.
