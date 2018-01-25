# http://rudijs.github.io/2015-10/docker-elk-quickstart/
# http://rudijs.github.io/2015-12/docker-elk-v2-quickstart/
# Create directory for ELK data
c:
cd \
mkdir Docker
cd Docker

# remove ELK
docker stop logstash kibana elasticsearch
docker container rm logstash kibana elasticsearch
docker image rm logstash kibana elasticsearch
# pull ELK
docker pull elasticsearch
docker pull kibana 
docker pull logstash

# run elasticsearch
rmdir ESData
mkdir ESData

# -v full_path_to/custom_elasticsearch.yml:/usr/share/elasticsearch/config/elasticsearch.yml
#docker run -d --name elasticsearch -v c:/Docker/ESData:/usr/share/elasticsearch/data -p 9200:9200 -p 9300:9300 elasticsearch 
docker run -d --name elasticsearch -p 9200:9200 -p 9300:9300 elasticsearch 

# test container
docker ps
docker logs elasticsearch
http://localhost:9200

# run Kibana
#docker run -d --name kibana -p 5601:5601 -e ELASTICSEARCH_URL=http://localhost:9200 --net host kibana
docker run --name kibana --link elasticsearch:elasticsearch -p 5601:5601 -d kibana

# run Logstash
rmdir Logstash
mkdir -p Logstash/config

# Create an input logstash configuration file 
$input_config = @"
input {
    file {
        type => "Attachments"
        path => ["/host/Attachments/*.*"]
		start_position => "beginning"
    }
}

output {
  elasticsearch { hosts => ["localhost:9200"] }
}

"@
Set-Content -Path "Logstash/config/logstash.conf" -Value $input_config -Force

# create directory for logs
mkdir -p Attachments
docker run -d --name logstash -v c:/Docker/logstash/config:/config-dir:ro -v c:/Docker/Attachments:/host/Attachments:ro --net host logstash logstash -f /config-dir/logstash.conf --debug


# test container
docker logs -f logstash
echo 101 > Attachments/test1.log
echo 202 > Attachments/test2.log
echo 303 > Attachments/test3.log
curl localhost:9200/logstash-*/_search?pretty=true


