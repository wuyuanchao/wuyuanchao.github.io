---
title: "Mysql Beats"
weight: 1
# bookFlatSection: false
# bookToc: true
# bookHidden: false
# bookCollapseSection: false
# bookComments: false
# bookSearchExclude: false
---

### mysqlbeat

Fully customizable Beat for MySQL server - this beat will ship the results of any query defined in the config file to Elasticsearch.

<https://github.com/adibendahan/mysqlbeat>

#### Usage

Just run `mysqlbeat -c mysqlbeat.yml`

```yml
mysqlbeat:
  # Defines how often an event is sent to the output
  #period: 10s

  # Defines the mysql hostname that the beat will connect to
  hostname: "127.0.0.1"

  # Defines the mysql port
  port: "3306"

  # MAKE SURE THE USER ONLY HAS PERMISSIONS TO RUN THE QUERY DESIRED AND NOTHING ELSE.
  # Defines the mysql user to use
  username: "wuyc"

  # Defines the mysql password to use - option #1 - plain text
  password: "123456"

  # Defines the mysql password to use - option #2 - AES encryption (see github.com/adibendahan/mysqlbeat-password-encrypter)
  #encryptedpassword: "7c29839cbbed0f8d51a92fe5c3fc"

  # Defines the queries that will run  - the query below is an example
  queries: ["select * from wuyc.test;"]
  querytypes: ["two-columns",
               "show-slave-delay"]
  deltawildcard: "__DELTA"
output:
  pretty: true
```

#### Mysqlbeat Configuration Example
```yml
################### Mysqlbeat Configuration Example #########################

############################# Mysqlbeat ######################################

mysqlbeat:
  # Defines how often an event is sent to the output
  #period: 10s

  # Defines the mysql hostname that the beat will connect to
  #hostname: "127.0.0.1"

  # Defines the mysql port
  #port: "3306"

  # MAKE SURE THE USER ONLY HAS PERMISSIONS TO RUN THE QUERY DESIRED AND NOTHING ELSE.
  # Defines the mysql user to use
  #username: "mysqlbeat_user"

  # Defines the mysql password to use - option #1 - plain text
  #password: "mysqlbeat_pass"

  # Defines the mysql password to use - option #2 - AES encryption (see github.com/adibendahan/mysqlbeat-password-encrypter)
  #encryptedpassword: "2321f38819cf693951e88f00cd82"

  # Defines the queries that will run  - the query below is an example
  # LIMITATIONS: Query must start with SELECT/SHOW and cannot contain the character ; (for security reasons)
  queries: [ "SELECT  CONCAT(VARIABLE_NAME, '__DELTA') AS VARIABLE_NAME, VARIABLE_VALUE 
              FROM    information_schema.GLOBAL_STATUS 
              WHERE   VARIABLE_NAME IN ('ABORTED_CONNECTS', 'CONNECTION_ERRORS_INTERNAL', 'CONNECTION_ERRORS_MAX_CONNECTIONS', 'CREATED_TMP_DISK_TABLES', 'CREATED_TMP_FILES', 
                                         'CREATED_TMP_TABLES', 'HANDLER_COMMIT', 'HANDLER_ROLLBACK', 'HANDLER_SAVEPOINT', 'HANDLER_SAVEPOINT_ROLLBACK', 'INNODB_DATA_FSYNCS', 
                                         'INNODB_DATA_READS', 'INNODB_DATA_WRITES', 'INNODB_LOG_WRITES', 'INNODB_OS_LOG_FSYNCS', 'INNODB_PAGES_CREATED', 'INNODB_PAGES_READ', 
                                         'INNODB_PAGES_WRITTEN', 'INNODB_ROWS_DELETED', 'INNODB_ROWS_INSERTED', 'INNODB_ROWS_READ', 'INNODB_ROWS_UPDATED', 'INNODB_ROW_LOCK_TIME', 
                                         'KEY_READS', 'KEY_READ_REQUESTS', 'KEY_WRITES', 'KEY_WRITE_REQUESTS', 'OPENED_TABLES', 'QCACHE_HITS', 'QCACHE_INSERTS', 'QCACHE_LOWMEM_PRUNES', 
                                         'QCACHE_NOT_CACHED', 'SELECT_FULL_JOIN', 'SELECT_FULL_RANGE_JOIN', 'SELECT_RANGE', 'SELECT_RANGE_CHECK', 'SELECT_SCAN', 'SLOW_QUERIES', 
                                         'SORT_MERGE_PASSES', 'SORT_RANGE', 'SORT_ROWS', 'SORT_SCAN', 'TABLE_LOCKS_IMMEDIATE', 'TABLE_LOCKS_WAITED', 'INNODB_ROW_LOCK_WAITS')
              UNION
              SELECT  VARIABLE_NAME, VARIABLE_VALUE 
              FROM    information_schema.GLOBAL_VARIABLES 
              WHERE   VARIABLE_NAME IN ('MAX_CONNECTIONS', 'TABLE_OPEN_CACHE')
              UNION
              SELECT  VARIABLE_NAME, VARIABLE_VALUE 
              FROM    information_schema.GLOBAL_STATUS 
              WHERE   VARIABLE_NAME IN ('INNODB_BUFFER_POOL_PAGES_DATA', 'INNODB_BUFFER_POOL_PAGES_FREE', 'INNODB_BUFFER_POOL_PAGES_TOTAL', 'OPEN_FILES', 'OPEN_TABLES', 
                                        'QCACHE_QUERIES_IN_CACHE', 'THREADS_CONNECTED', 'THREADS_RUNNING', 'INNODB_PAGE_SIZE')
              UNION
              SELECT  'INNODB_BUFFER_POOL_HIT_RATIO' AS VARIABLE_NAME, 
                      INNODB_BUFFER_POOL_READ_REQUESTS.VARIABLE_VALUE  / (INNODB_BUFFER_POOL_READ_REQUESTS.VARIABLE_VALUE  + INNODB_BUFFER_POOL_READS.VARIABLE_VALUE) * 100 AS VARIABLE_VALUE 
              FROM    information_schema.GLOBAL_STATUS INNODB_BUFFER_POOL_READS, information_schema.GLOBAL_STATUS INNODB_BUFFER_POOL_READ_REQUESTS 
              WHERE   INNODB_BUFFER_POOL_READS.variable_name ='INNODB_BUFFER_POOL_READS' AND 
                      INNODB_BUFFER_POOL_READ_REQUESTS.variable_name ='INNODB_BUFFER_POOL_READ_REQUESTS'
              UNION
              SELECT  'CONST_100' AS VARIABLE_NAME, 100 AS VARIABLE_VALUE",
             "SHOW SLAVE STATUS"]

  # Defines the queries result types
  # 'single-row' will be translated as columnname:value
  # 'two-columns' will be translated as value-column1:value-column2 for each row
  # 'multiple-rows' each row will be a document (with columnname:value)
  # 'show-slave-delay' will only send the `Seconds_Behind_Master` column from SHOW SLAVE STATUS
  querytypes: ["two-columns",
               "show-slave-delay"]

  # Colums that end with the following wild card will report only delta in seconds ((neval - oldval)/timediff.Seconds())
  deltawildcard: "__DELTA"

  # In a multiple-rows event, each row must have a unique key so that calculations could be saved for every column.
  # IMPORTANT: make sure that the combination of all DeltaKey columns in a row create a UNIQUE value per row in the query
  deltakeywildcard: "__DELTAKEY"  

###############################################################################
############################# Libbeat Config ##################################
# Base config file used by all other beats for using libbeat features

############################# Output ##########################################

# Configure what outputs to use when sending the data collected by the beat.
# Multiple outputs may be used.
output:

  ### Elasticsearch as output
  elasticsearch:
    # Array of hosts to connect to.
    # Scheme and port can be left out and will be set to the default (http and 9200)
    # In case you specify and additional path, the scheme is required: http://localhost:9200/path
    # IPv6 addresses should always be defined as: https://[2001:db8::1]:9200
    #hosts: ["127.0.0.1:9200"]

    # Optional protocol and basic auth credentials.
    #protocol: "https"
    #username: "admin"
    #password: "s3cr3t"

    # Dictionary of HTTP parameters to pass within the url with index operations.
    #parameters:
      #param1: value1
      #param2: value2

    # Number of workers per Elasticsearch host.
    #worker: 1

    # Optional index name. The default is "mysqlbeat" and generates
    # [mysqlbeat-]YYYY.MM.DD keys.
    #index: "mysqlbeat"

    # A template is used to set the mapping in Elasticsearch
    # By default template loading is disabled and no template is loaded.
    # These settings can be adjusted to load your own template or overwrite existing ones
    #template:

      # Template name. By default the template name is mysqlbeat.
      #name: "mysqlbeat"

      # Path to template file
      #path: "mysqlbeat.template.json"

      # Overwrite existing template
      #overwrite: false

    # Optional HTTP Path
    #path: "/elasticsearch"

    # Proxy server url
    #proxy_url: http://proxy:3128

    # The number of times a particular Elasticsearch index operation is attempted. If
    # the indexing operation doesn't succeed after this many retries, the events are
    # dropped. The default is 3.
    #max_retries: 3

    # The maximum number of events to bulk in a single Elasticsearch bulk API index request.
    # The default is 50.
    bulk_max_size: 50

    # Configure http request timeout before failing an request to Elasticsearch.
    #timeout: 90

    # The number of seconds to wait for new events between two bulk API index requests.
    # If `bulk_max_size` is reached before this interval expires, addition bulk index
    # requests are made.
    #flush_interval: 1

    # Boolean that sets if the topology is kept in Elasticsearch. The default is
    # false. This option makes sense only for Packetbeat.
    #save_topology: false

    # The time to live in seconds for the topology information that is stored in
    # Elasticsearch. The default is 15 seconds.
    #topology_expire: 15

    # tls configuration. By default is off.
    #tls:
      # List of root certificates for HTTPS server verifications
      #certificate_authorities: ["/etc/pki/root/ca.pem"]

      # Certificate for TLS client authentication
      #certificate: "/etc/pki/client/cert.pem"

      # Client Certificate Key
      #certificate_key: "/etc/pki/client/cert.key"

      # Controls whether the client verifies server certificates and host name.
      # If insecure is set to true, all server host names and certificates will be
      # accepted. In this mode TLS based connections are susceptible to
      # man-in-the-middle attacks. Use only for testing.
      #insecure: true

      # Configure cipher suites to be used for TLS connections
      #cipher_suites: []

      # Configure curve types for ECDHE based cipher suites
      #curve_types: []

      # Configure minimum TLS version allowed for connection to logstash
      #min_version: 1.0

      # Configure maximum TLS version allowed for connection to logstash
      #max_version: 1.2


  ### Logstash as output
  #logstash:
    # The Logstash hosts
    #hosts: ["localhost:5044"]

    # Number of workers per Logstash host.
    #worker: 1

    # Set gzip compression level.
    #compression_level: 3

    # Optional load balance the events between the Logstash hosts
    #loadbalance: true

    # Optional index name. The default index name is set to name of the beat
    # in all lowercase.
    #index: mysqlbeat

    # SOCKS5 proxy server URL
    #proxy_url: socks5://user:password@socks5-server:2233

    # Resolve names locally when using a proxy server. Defaults to false.
    #proxy_use_local_resolver: false

    # Optional TLS. By default is off.
    #tls:
      # List of root certificates for HTTPS server verifications
      #certificate_authorities: ["/etc/pki/root/ca.pem"]

      # Certificate for TLS client authentication
      #certificate: "/etc/pki/client/cert.pem"

      # Client Certificate Key
      #certificate_key: "/etc/pki/client/cert.key"

      # Controls whether the client verifies server certificates and host name.
      # If insecure is set to true, all server host names and certificates will be
      # accepted. In this mode TLS based connections are susceptible to
      # man-in-the-middle attacks. Use only for testing.
      #insecure: true

      # Configure cipher suites to be used for TLS connections
      #cipher_suites: []

      # Configure curve types for ECDHE based cipher suites
      #curve_types: []


  ### File as output
  #file:
    # Path to the directory where to save the generated files. The option is mandatory.
    #path: "/tmp/mysqlbeat"

    # Name of the generated files. The default is `mysqlbeat` and it generates files: `mysqlbeat`, `mysqlbeat.1`, `mysqlbeat.2`, etc.
    #filename: mysqlbeat

    # Maximum size in kilobytes of each file. When this size is reached, the files are
    # rotated. The default value is 10240 kB.
    #rotate_every_kb: 10000

    # Maximum number of files under path. When this number of files is reached, the
    # oldest file is deleted and the rest are shifted from last to first. The default
    # is 7 files.
    #number_of_files: 7


  ### Console output
  # console:
    # Pretty print json event
    #pretty: false


############################# Shipper #########################################

shipper:
  # The name of the shipper that publishes the network data. It can be used to group
  # all the transactions sent by a single shipper in the web interface.
  # If this options is not defined, the hostname is used.
  #name:

  # The tags of the shipper are included in their own field with each
  # transaction published. Tags make it easy to group servers by different
  # logical properties.
  #tags: ["service-X", "web-tier"]

  # Optional fields that you can specify to add additional information to the
  # output. Fields can be scalar values, arrays, dictionaries, or any nested
  # combination of these.
  #fields:
  #  env: staging

  # If this option is set to true, the custom fields are stored as top-level
  # fields in the output document instead of being grouped under a fields
  # sub-dictionary. Default is false.
  #fields_under_root: false

  # Uncomment the following if you want to ignore transactions created
  # by the server on which the shipper is installed. This option is useful
  # to remove duplicates if shippers are installed on multiple servers.
  #ignore_outgoing: true

  # How often (in seconds) shippers are publishing their IPs to the topology map.
  # The default is 10 seconds.
  #refresh_topology_freq: 10

  # Expiration time (in seconds) of the IPs published by a shipper to the topology map.
  # All the IPs will be deleted afterwards. Note, that the value must be higher than
  # refresh_topology_freq. The default is 15 seconds.
  #topology_expire: 15

  # Internal queue size for single events in processing pipeline
  #queue_size: 1000

  # Sets the maximum number of CPUs that can be executing simultaneously. The
  # default is the number of logical CPUs available in the system.
  #max_procs:

  # Configure local GeoIP database support.
  # If no paths are not configured geoip is disabled.
  #geoip:
    #paths:
    #  - "/usr/share/GeoIP/GeoLiteCity.dat"
    #  - "/usr/local/var/GeoIP/GeoLiteCity.dat"


############################# Logging #########################################

# There are three options for the log output: syslog, file, stderr.
# Under Windows systems, the log files are per default sent to the file output,
# under all other system per default to syslog.
logging:

  # Send all logging output to syslog. On Windows default is false, otherwise
  # default is true.
  #to_syslog: true

  # Write all logging output to files. Beats automatically rotate files if rotateeverybytes
  # limit is reached.
  #to_files: false

  # To enable logging to files, to_files option has to be set to true
  #files:
    # The directory where the log files will written to.
    #path: /var/log/mysqlbeat

    # The name of the files where the logs are written to.
    #name: mysqlbeat

    # Configure log file size limit. If limit is reached, log file will be
    # automatically rotated
    #rotateeverybytes: 10485760 # = 10MB

    # Number of rotated log files to keep. Oldest files will be deleted first.
    #keepfiles: 7

  # Enable debug output for selected components. To enable all selectors use ["*"]
  # Other available selectors are beat, publish, service
  # Multiple selectors can be chained.
  #selectors: [ ]

  # Sets log level. The default log level is error.
  # Available log levels are: critical, error, warning, info, debug
  #level: error
```

