# https://blog.sstorie.com/importing-iis-logs-into-elasticsearch-with-logstash/
# http://robwillis.info/2017/05/elk-5-setting-up-a-grok-filter-for-iis-logs/
# Create directory for ELK data
c:
cd \
mkdir Docker
cd Docker

# remove ELK
#docker stop logstash kibana elasticsearch
#docker container rm logstash kibana elasticsearch
#docker image rm logstash kibana elasticsearch
# pull ELK
#docker pull elasticsearch
#docker pull kibana 
#docker pull logstash

# run elasticsearch
#rmdir ESData
#mkdir ESData
#docker run -d --name elasticsearch -v c:/Docker/ESData:/usr/share/elasticsearch/data -p 9200:9200 -p 9300:9300 elasticsearch 
docker run -d --name elasticsearch -p 9200:9200 -p 9300:9300 elasticsearch 

# test container
#docker ps
#docker logs elasticsearch
#http://localhost:9200

# run Kibana
#docker run -d --name kibana -p 5601:5601 -e ELASTICSEARCH_URL=http://localhost:9200 --net host kibana
docker run --name kibana --link elasticsearch:elasticsearch -p 5601:5601 -d kibana

# run Logstash
rmdir Logstash
mkdir -p Logstash/config

# Create an input logstash configuration file 
# IIS logging all fields
$input_config = @"
input {
file {
type => "IISLog"
path => "/LogFiles/W3SVC*/*.log"
start_position => "beginning"
}
}

filter {  
  ## Ignore the comments that IIS will add to the start of the W3C logs
  #
  if [message] =~ "^#" {
    drop {}
  }
  
  grok {
    ## Very helpful site for building these statements:
    #   http://grokdebug.herokuapp.com/
    #
    # This is configured to parse out every field of IIS's W3C format when
    #   every field is included in the logs
    #
    match => { "message" => [
	"%{TIMESTAMP_ISO8601:log_timestamp} %{IPORHOST:site} %{WORD:method} %{URIPATH:page} %{NOTSPACE:querystring} %{NUMBER:port} %{NOTSPACE:username} %{IPORHOST:clienthost} %{NOTSPACE:useragent} %{NOTSPACE:referer} %{NUMBER:response} %{NUMBER:subresponse} %{NUMBER:scstatus} %{NUMBER:timetaken:int}",
	"%{TIMESTAMP_ISO8601:log_timestamp} %{WORD:iisSite} %{NOTSPACE:computername} %{IPORHOST:site} %{WORD:method} %{URIPATH:page} %{NOTSPACE:querystring} %{NUMBER:port} %{NOTSPACE:username} %{IPORHOST:clienthost} %{NOTSPACE:protocol} %{NOTSPACE:useragent} %{NOTSPACE:referer} %{IPORHOST:cshost} %{NUMBER:response} %{NUMBER:subresponse} %{NUMBER:scstatus} %{NUMBER:bytessent:int} %{NUMBER:bytesrecvd:int} %{NUMBER:timetaken:int}",
    "%{TIMESTAMP_ISO8601:log_timestamp} %{WORD:S-SiteName} %{NOTSPACE:S-ComputerName} %{IPORHOST:S-IP} %{WORD:CS-Method} %{URIPATH:CS-URI-Stem} (?:-|\"%{URIPATH:CS-URI-Query}\") %{NUMBER:S-Port} %{NOTSPACE:CS-Username} %{IPORHOST:C-IP} %{NOTSPACE:CS-Version} %{NOTSPACE:CS-UserAgent} %{NOTSPACE:CS-Cookie} %{NOTSPACE:CS-Referer} %{NOTSPACE:CS-Host} %{NUMBER:SC-Status} %{NUMBER:SC-SubStatus} %{NUMBER:SC-Win32-Status} %{NUMBER:SC-Bytes} %{NUMBER:CS-Bytes} %{NUMBER:Time-Taken}",
    "%{TIMESTAMP_ISO8601:log_timestamp} %{WORD:serviceName} %{WORD:serverName} %{IP:serverIP} %{WORD:method} %{URIPATH:uriStem} %{NOTSPACE:uriQuery} %{NUMBER:port} %{NOTSPACE:username} %{IPORHOST:clientIP} %{NOTSPACE:protocolVersion} %{NOTSPACE:userAgent} %{NOTSPACE:cookie} %{NOTSPACE:referer} %{NOTSPACE:requestHost} %{NUMBER:response} %{NUMBER:subresponse} %{NUMBER:win32response} %{NUMBER:bytesSent} %{NUMBER:bytesReceived} %{NUMBER:timetaken}",
    "%{DATESTAMP:log_timestamp} %{WORD:sitename} %{HOSTNAME:computername} %{IP:hostip} %{URIPROTO:method} %{URIPATH:request} (?:%{NOTSPACE:queryparam}|-) %{NUMBER:port} (?:%{WORD:username}|-) %{IP:clientip} %{NOTSPACE:httpversion} %{NOTSPACE:user-agent} (?:%{NOTSPACE:cookie}|-) (?:%{NOTSPACE:referer}|-) (?:%{HOSTNAME:host}|-) %{NUMBER:status} %{NUMBER:sub-status} %{NUMBER:win32-status} %{NUMBER:bytes-received} %{NUMBER:bytes-sent} %{NUMBER:time-taken}"
    
    ] }
   
  }

  ## Set the Event Timesteamp from the log
  #
  date {
    match => [ "log_timestamp", "YYYY-MM-dd HH:mm:ss" ]
      timezone => "Etc/UTC"
  }
  
  ## Perform some mutations on the records to prep them for Elastic
  #
  mutate {
    ## Finally remove the original log_timestamp field since the event will
    #   have the proper date on it
    #
    remove_field => [ "log_timestamp"]
  }

  ## Parse out the user agent
  #
    useragent {
        source=> "useragent"
        prefix=> "browser"
    }

}

# output logs to console and to elasticsearch
output {
  elasticsearch { hosts => ["localhost:9200"] }
}

"@
Set-Content -Path "Logstash/config/logstash.conf" -Value $input_config -Force

# create directory for logs
docker run -d --name logstash -v c:/Docker/logstash/config:/config-dir:ro -v C:/inetpub/logs/LogFiles/:/LogFiles/:ro --net host logstash logstash -f /config-dir/logstash.conf --debug 


# test container
# docker logs -f logstash
# curl localhost:9200/logstash-*/_search?pretty=true


