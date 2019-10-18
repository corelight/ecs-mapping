#/bin/bash

pipelines_path='.'
pipelines_list=$(ls $pipelines_path | grep -E '^corelight.*_pipeline$')



echo -e "\n"
echo "Use this script for import Corelight pipeline configurations to Elasticsearch using API."
echo -e "\n"
read -r -p "(Please 'y' for start the process or 'n' for exit) " response
if [[ $response =~ ^([yY][eE][sS]|[yY])$ ]]; then
{
if [ "$(echo "$pipelines_list" | grep -v 'corelight_main_pipeline'| wc -l)" -gt '1'  ];then
	{
	echo "List of pipelines to be installed to Elasticsearch:"
	echo "$pipelines_list"
	echo -e "\n"
	echo "Please enter API credentials to one of your Elasticsearch nodes."
	echo "Elasticsearch node hostname:"
	read -r -p "Node hostname or IP: " host
	read -r -p "Node API port: " port
        read -r -p "API User: " api_user
        read -r -s -p "API Password: " api_pass
	timeout 1 bash -c 'cat < /dev/null > /dev/tcp/'$host'/'$port
	connection_status=$(echo $?)
	echo -e "\n"
		if [ "$connection_status" -ne '0' ];then
			{
			echo "Connection to $host:$port is not established. Please check network connection."
			exit 0
			}
		fi
	cred_status=$(curl -s -k -X GET "https://$host:$port/_cat/indices?v&pretty" -H 'Content-Type: application/json' --user "${api_user}:${api_pass}" | grep 'green')
		if [ -z "$cred_status" ];then
			{
			echo "User $api_user is not authenticated. Please check credentials."
			exit 0
			}
		fi
	echo -e "\n"
	echo "Import process..."

		for line in $(echo "$pipelines_list");do
	       		{
			echo "Installing $line pipeline"
			import_status=$(curl -s -k -XPUT "https://$host:$port/_ingest/pipeline/$line" --data-binary @"$pipelines_path/$line" --user "${api_user}:${api_pass}" -H 'Content-Type: application/json' | grep '"acknowledged":true')
			i="1"
				while [ -z "$import_status" ] && [ $i -lt 10 ];do
					{
					echo "Installing $line pipeline. Attempt $i"
					import_status=$(curl -s -k -XPUT "https://$host:$port/_ingest/pipeline/$line" --data-binary @"$pipelines_path/$line" --user "${api_user}:${api_pass}" -H 'Content-Type: application/json' | grep '"acknowledged":true')
					i=$[$i+1]
					sleep 3
					echo -e "\n"
					}
				done
			if [ -z "$import_status" ];then
				{
				echo "Installing $line pipeline failed"
				}
				else
				{
				echo "Pipeline $line successfuly installed."
				}
			fi
			echo -e "\n"
       			sleep 1
       			}
		done
		#############corelight_main_pipeline
		echo "Installing corelight_main_pipeline pipeline"
		import_status=$(curl -s -k -XPUT "https://$host:$port/_ingest/pipeline/corelight_main_pipeline" --data-binary @"$pipelines_path/corelight_main_pipeline" --user "${api_user}:${api_pass}" -H 'Content-Type: application/json' | grep '"acknowledged":true')
                 i="1"
                                while [ -z "$import_status" ] && [ $i -lt 10 ];do
                                        {
                                        echo "Installing corelight_main_pipeline pipeline. Attempt $i"
                                        import_status=$(curl -s -k -XPUT "https://$host:$port/_ingest/pipeline/corelight_main_pipeline" --data-binary @"$pipelines_path/corelight_main_pipeline" --user "${api_user}:${api_pass}" -H 'Content-Type: application/json' | grep '"acknowledged":true')
                                        i=$[$i+1]
                                        sleep 3
                                        echo -e "\n"
                                        }
                                done
                        if [ -z "$import_status" ];then
                                {
                                echo "Installing corelight_main_pipeline pipeline failed"
                                }
                                else
                                {
                                echo "Pipeline corelight_main_pipeline successfuly installed."
                                }
                        fi
		##############corelight_template
		echo "Installing Corelight template"
		import_status=$(curl -s -k -XPUT "https://$host:$port/_template/corelight" --data-binary @"$pipelines_path/template_corelight" --user "${api_user}:${api_pass}" -H 'Content-Type: application/json' | grep '"acknowledged":true')
                 i="1"
                                while [ -z "$import_status" ] && [ $i -lt 10 ];do
                                        {
                                        echo "Installing corelight_main_pipeline pipeline. Attempt $i"
                                        import_status=$(curl -s -k -XPUT "https://$host:$port/_template/corelight" --data-binary @"$pipelines_path/template_corelight" --user "${api_user}:${api_pass}" -H 'Content-Type: application/json' | grep '"acknowledged":true')
                                        i=$[$i+1]
                                        sleep 3
                                        echo -e "\n"
                                        }
                                done
                        if [ -z "$import_status" ];then
                                {
                                echo "Installing Corelight template failed"
                                }
                                else
                                {
                                echo "Corelight template successfuly installed."
                                }
                        fi

		#########################

	}
	else
	{
	echo "Pipelines list is empty. Please check pipelines path variable."
	echo "Exit..."
	exit 0
	}
	fi
}
else
{
echo "Exit..."
exit 0
}
fi
