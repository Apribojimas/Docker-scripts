# !!! ON ERROR. "FsCrawler.ps1 cannot be loaded because run ning scripts is disabled on this system. For more information, see about_Execution_Policies at" fix in next line
# Set-ExecutionPolicy remoteSigned


# https://github.com/shadiakiki1986/docker-fscrawler
# Create directory for fscrawler data
c:
cd \
mkdir Docker
cd Docker

# run elasticsearch
#mkdir -p elasticsearch\data
#docker run -d --name elasticsearch -v c:/Docker/elasticsearch/data/:/usr/share/elasticsearch/data -p 9200:9200 -p 9300:9300 elasticsearch 
docker run -d --name elasticsearch -p 9200:9200 -p 9300:9300 elasticsearch 

# test container
#docker ps
#docker logs elasticsearch
#http://localhost:9200

# run Kibana
#docker run -d --name kibana -p 5601:5601 -e ELASTICSEARCH_URL=http://localhost:9200 --net host kibana
docker run --name kibana --link elasticsearch:elasticsearch -p 5601:5601 -d kibana

# run fscrawler 

#rmdir fscrawler
# configuration directory for DLX job
mkdir -p fscrawler/config/dlx
# indexing directory
$index_documents_path = "C:/Docker/FsCrawler/Documents/"
mkdir -p $index_documents_path


# Create an input fscrawler job DLX configuration file 
$input_config = @"
{
  "name" : "dlx",
  "fs" : {
    "url" : "/usr/share/fscrawler/data/",
    "update_rate" : "5m",
    "json_support" : false,
    "filename_as_id" : true,
    "add_filesize" : true,
    "remove_deleted" : true,
    "add_as_inner_object" : false,
    "store_source" : false,
    "index_content" : true,
    "indexed_chars" : "10000.0",
    "attributes_support" : false,
    "raw_metadata" : true,
    "xml_support" : false,
    "index_folders" : true,
    "lang_detect" : false,
    "continue_on_error" : false,
    "pdf_ocr" : true,
    "ocr" : {
      "language" : "eng"
    }    
  }  
}
"@
Set-Content -Path "fscrawler/config/dlx/_settings.json" -Value $input_config -Force


#test data fscrawler
echo 101 202 303 > $index_documents_path/test.txt

# install container
docker run -d --net="host" --name fscrawler -v $index_documents_path/:/usr/share/fscrawler/data/:ro -v c:/Docker/fscrawler/config/dlx:/usr/share/fscrawler/config-mount/dlx:ro shadiakiki1986/fscrawler --config_dir /usr/share/fscrawler/config dlx --restart --rest

