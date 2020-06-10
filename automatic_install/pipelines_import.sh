#!/bin/bash
RED='\033[0;31m'
CYAN='\033[0;36m'
WAR='\033[1;33m'
STD='\033[0m'

pipelines_path='.'
# templates
corelight_es_template_main="template_corelight"
corelight_es_template_base_settings="template_corelight_base_settings"
corelight_es_template_parse_failures="template_corelight_parse_failures"
corelight_es_template_metrics_and_stats="template_corelight_metrics_and_stats"
corelight_es_template_temporary_logs="template_corelight_temporary_log_holdings"
# cluster settings
corelight_es_cluster_settings="settings_cluster"
# pipelines
corelight_main_pipeline="corelight_main_pipeline"
corelight_general_pipeline="corelight_general_pipeline"
pipelines_list=$(ls ${pipelines_path} | grep -E '^.*_pipeline$' |grep -v ${corelight_general_pipeline} |grep -v ${corelight_main_pipeline})
pipelines_list_amount=$(echo "$pipelines_list" |wc -l)
max_install_attempts=5
successful_install_amount=0
failed_install_amount=0
failed_files=()

tls_bypass='yes'
tls_ca_location=''
curl_cert_params=''
curl_user_auth_params=''
http_or_tls='http'


UploadTemplates() {
    local file=${1}
    local template_name=${2}


		import_status=$(curl -s "$curl_cert_params" "${curl_user_auth_params}" -XPUT "${elasticsearch_url}/_template/$template_name" --data-binary @"$pipelines_path/$file" -H 'Content-Type: application/json')
		i="1"
		while ! echo "${import_status}" | grep -q '"acknowledged":true' && [[ ${i} -le ${max_install_attempts} ]];do
			{
				echo "Retrying install, attempt $i of $max_install_attempts"
				import_status=$(curl -s "$curl_cert_params" "${curl_user_auth_params}" -XPUT "${elasticsearch_url}/_template/$template_name" --data-binary @"$pipelines_path/$file" -H 'Content-Type: application/json')
				i=$[$i+1]
				sleep 3
			}
		done
		if ! echo "${import_status}" | grep -q '"acknowledged":true';then
    {
      echo -e "${RED}${import_status}"
      echo -e "${RED}Failed to install '$file'"
      echo -e "${STD}Exiting script because of the necessity of this template."
      echo -e "${STD}Retry the script. If the error persists then please open a github issue.\n"
      exit 0
    }
		else
    {
      echo "success, $file"
    }
		fi
    echo -e "${STD}"
    sleep .55

}

echo -e ""
echo "Use this script to import Corelight pipeline configurations to your Elasticsearch cluster."
echo -e ""
read -r -p "('y' to start the process or 'n' to exit) " response
if [[ ${response} =~ ^([yY][eE][sS]|[yY])$ ]]; then
{
	if [[ "${pipelines_list_amount}" -gt '1'  ]];then
	{
		echo "List of pipelines to be installed to Elasticsearch:"
		echo "$pipelines_list"
		echo -e "\n"
		# Basic cluster connection information
		echo "Enter the information to connect to your Elasticsearch cluster."
		read -r -p "Hostname or IP: " -e -i '127.0.0.1' host
		read -r -p "Port: " -e -i "9200" port
		# User/Pass
		echo "Determine if your cluster is using user & password to authenticate (ie: security/x-pack)"
		read -r -p "Use user and password authentication? [y/n]: " -e -i 'n' response
		if [[ ${response} =~ ^([yY][eE][sS]|[yY])$ ]]; then
			read -r -p "User: " -e -i 'elastic' api_user
			read -r -s -p "Password: " api_pass
			echo ""
		fi
		# HTTP or HTTPS(TLS)
		read -r -p "Use HTTP or HTTPS [http/https]: " -e -i "$http_or_tls" response
		if [[ "${response,,}" == "http" ]]; then
			echo ""
		elif [[ "${response,,}" == "https" ]]; then
			http_or_tls='https'
			echo ""
			echo "Enter 'y' unless you have HTTPS certificate authorties (CA) for your machine to trust the cluster's certificate or the CA file"
      read -r -p "Would you like to ignore certificate errors [y/n]: " -e -i "y" response
      if [[ "${response,,}" =~ ^y|yes$ ]]; then
        echo "Ignoring HTTPS certificate errors.."
      elif [[ "${response,,}" =~ ^n|no$ ]]; then
        echo ""
        tls_bypass='no'
        echo "To use the CA's already loaded in your machine enter 'y'"
        echo "To specify the location of a CA file enter 'n'"
        read -r -p "[y/n]: " -e -i "y" response
        if [[ "${response,,}" =~ ^y|yes$ ]]; then
          echo ""
        elif [[ "${response,,}" =~ ^n|no$ ]]; then
          read -r -p "Specify the full path to your CA file: " response
          tls_ca_location="${response}"
        fi
      else
        echo "Ignoring HTTPS certificate errors.."
      fi
		else
		  echo "Using HTTP.."
		fi

    # Set and confirm parameters, before continuing
    echo -e "You have entered the following parameters to connect to your cluster:"
    echo "  - Host/IP: ${host}"
    echo "  - Port: ${port}"
    echo "  - HTTP/HTTPS: ${http_or_tls}"
    elasticsearch_url="${http_or_tls}://${host}:${port}"
    if [[ -n "$api_user" ]]; then
      echo "  - User: ${api_user}"
      curl_user_auth_params=" --user "${api_user}:${api_pass}""
    fi
    if [[ ${http_or_tls} == "https" ]]; then
      echo "  - Ignore Certificate Errors: $tls_bypass"
      if [[ ${tls_bypass} == "no" ]]; then
        if [[ -z "$tls_ca_location" ]]; then
          echo "  - Certificate Validation: Builtin"
        else
          echo "  - Certificate Validation: '$tls_ca_location'"
          curl_cert_params=" --cacert ${tls_ca_location}"
        fi
      else
        curl_cert_params=' -k'
      fi
    fi
    echo ""
    read -r -p "Would you like to continue with these parameters? [y/n]: " -e -i 'y' response
    if [[ "${response,,}" == "y" ]]; then
      echo ""
    elif [[ "${response}" == "n" ]]; then
      echo "Please restart the script to enter your new parameters"
      echo "Exit..."
      exit 0
    fi

    # Check network before continuing
		timeout 1 bash -c "cat < /dev/null > /dev/tcp/${host}/${port}"
		connection_status=$(echo $?)
		echo ""
    if [[ "$connection_status" -ne '0' ]];then
    {
      echo -e "${RED}Connection to $host:$port is not established.${STD}\nPlease check network connection and try again."
      exit 0
    }
    fi
    # Check access and, if applicable, authentication before continuing
    cred_status=$(curl -s "$curl_cert_params" "${curl_user_auth_params}" -X GET "${elasticsearch_url}/_cat/indices?v&pretty" -H 'Content-Type: application/json' | grep 'green')
    if [[ -z "$cred_status" ]];then
    {
      echo -e "${RED}User $api_user is not able to authenticate. Verify the credentials and try again.${STD}"
      exit 0
    }
    fi

		############# Corelight Main Pipeline
		echo "Installing the main Corelight pipeline file '$corelight_main_pipeline'..."
		import_status=$(curl -s "$curl_cert_params" "${curl_user_auth_params}" -XPUT "${elasticsearch_url}/_ingest/pipeline/$corelight_main_pipeline" --data-binary @"$pipelines_path/$corelight_main_pipeline" -H 'Content-Type: application/json')
		i="1"
		while ! echo "${import_status}" | grep -q '"acknowledged":true' && [[ ${i} -le ${max_install_attempts} ]];do
    {
      echo "Retrying install, attempt $i of $max_install_attempts"
      import_status=$(curl -s "$curl_cert_params" "${curl_user_auth_params}" -XPUT "${elasticsearch_url}/_ingest/pipeline/$corelight_main_pipeline" --data-binary @"$pipelines_path/$corelight_main_pipeline" -H 'Content-Type: application/json')
      i=$[$i+1]
      sleep 3
    }
		done
		if ! echo "${import_status}" | grep -q '"acknowledged":true';then
    {
        echo -e "${RED}${import_status}"
        echo -e "${RED}Failed to install '$corelight_main_pipeline'"
        echo -e "${STD}Exiting script because of the necessity of this pipeline file."
        echo -e "${STD}Please retry the script. If the error persists then please open a github issue.\n"
        exit 0
    }
		else
    {
      echo "success"
    }
		fi
    echo -e "${STD}"
    sleep .55
    
		############# Corelight General Pipeline
		echo "Installing the main Corelight pipeline file '$corelight_general_pipeline'..."
		import_status=$(curl -s "$curl_cert_params" "${curl_user_auth_params}" -XPUT "${elasticsearch_url}/_ingest/pipeline/$corelight_general_pipeline" --data-binary @"$pipelines_path/$corelight_general_pipeline" -H 'Content-Type: application/json')
		i="1"
		while ! echo "${import_status}" | grep -q '"acknowledged":true' && [[ ${i} -le ${max_install_attempts} ]];do
    {
      echo "Retrying install, attempt $i of $max_install_attempts"
      import_status=$(curl -s "$curl_cert_params" "${curl_user_auth_params}" -XPUT "${elasticsearch_url}/_ingest/pipeline/$corelight_general_pipeline" --data-binary @"$pipelines_path/$corelight_general_pipeline" -H 'Content-Type: application/json')
      i=$[$i+1]
      sleep 3
    }
		done
		if ! echo "${import_status}" | grep -q '"acknowledged":true';then
    {
        echo -e "${RED}${import_status}"
        echo -e "${RED}Failed to install '$corelight_general_pipeline'"
        echo -e "${STD}Exiting script because of the necessity of this pipeline file."
        echo -e "${STD}Please retry the script. If the error persists then please open a github issue.\n"
        exit 0
    }
		else
    {
      echo "success,"
    }
		fi
    echo -e "${STD}"
    sleep .55

		############## Corelight Elasticsearch (Mapping and Settings) Template
    UploadTemplates ${corelight_es_template_main} "corelight" 
    UploadTemplates ${corelight_es_template_base_settings} "corelight_base_settings" 
    UploadTemplates ${corelight_es_template_parse_failures} "corelight_parse_failures"
    UploadTemplates ${corelight_es_template_temporary_logs} "corelight_temporary_log_holdings"

		############## Corelight Cluster Settings
		echo "Installing the Corelight cluster settings for Elasticsearch..."
		import_status=$(curl -s "$curl_cert_params" "${curl_user_auth_params}" -XPUT "${elasticsearch_url}/_cluster/settings" --data-binary @"$pipelines_path/$corelight_es_cluster_settings" -H 'Content-Type: application/json')
		i="1"
		while ! echo "${import_status}" | grep -q '"acknowledged":true' && [[ ${i} -le ${max_install_attempts} ]];do
			{
				echo "Retrying install, attempt $i of $max_install_attempts"
				import_status=$(curl -s "$curl_cert_params" "${curl_user_auth_params}" -XPUT "${elasticsearch_url}/_cluster/settings" --data-binary @"$pipelines_path/$corelight_es_cluster_settings" -H 'Content-Type: application/json')
				i=$[$i+1]
				sleep 3
			}
		done
		if ! echo "${import_status}" | grep -q '"acknowledged":true';then
    {
      echo -e "${RED}${import_status}"
      echo -e "${RED}Failed to install '$corelight_es_cluster_settings'"
      echo -e "${STD}Exiting script because of the necessity of these settings."
      echo -e "${STD}Retry the script. If the error persists then please open a github issue.\n"
      exit 0
    }
		else
    {
      echo "success"
    }
		fi
    echo -e "${STD}"
    sleep .55

		############## Corelight Enrichments
		echo "Installing a few Corelight enrichments for efficiency..."
		# Dictionary Data for Conn first
		conn_dictionary_file_name="zeek-enrichment-conn-dictionary"
		import_status=$(curl -s "$curl_cert_params" "${curl_user_auth_params}" -XPOST "${elasticsearch_url}/$conn_dictionary_file_name/_bulk" --data-binary @"$pipelines_path/$conn_dictionary_file_name" -H 'Content-Type: application/json')
		i="1"
		while ! echo "${import_status}" | grep -q '"errors":false' && [[ ${i} -le ${max_install_attempts} ]];do
			{
				echo "Retrying install, attempt $i of $max_install_attempts"
				import_status=$(curl -s "$curl_cert_params" "${curl_user_auth_params}" -XPUT "${elasticsearch_url}/$conn_dictionary_file_name/_bulk" --data-binary @"$pipelines_path/$conn_dictionary_file_name" -H 'Content-Type: application/json')
				i=$[$i+1]
				sleep 1.25
			}
		done
		if ! echo "${import_status}" | grep -q '"errors":false';then
    {
      echo -e "${RED}${import_status}"
      echo -e "${RED}Failed to install '$conn_dictionary_file_name'"
      echo -e "${STD}Exiting script because of the necessity of this."
      echo -e "${STD}Retry the script. If the error persists then please open a github issue.\n"
      exit 0
    }
		else
    {
      echo "success"
    }
		fi
    echo -e "${STD}"
    sleep .55
		# Enrichment Policy for Conn next
		conn_enrichment_policy_file_name="zeek-enrichment-conn-policy"
		import_status=$(curl -s "$curl_cert_params" "${curl_user_auth_params}" -XPUT "${elasticsearch_url}/_enrich/policy/$conn_enrichment_policy_file_name" --data-binary @"$pipelines_path/$conn_enrichment_policy_file_name" -H 'Content-Type: application/json')
		i="1"
		while ! echo "${import_status}" | grep -q '"acknowledged":true' && [[ ${i} -le ${max_install_attempts} ]];do
			{
				echo "Retrying install, attempt $i of $max_install_attempts"
				if echo "${import_status}" | grep -q 'already exists';then
				  echo "already exists"
				  echo "removing old enrichment policy and its corresponding pipeline in order to update them"
				  sleep 1
				  # Delete pipeline that calls the enrich policy before we can delete the enrich policy itself. https://www.elastic.co/guide/en/elasticsearch/reference/master/enrich-setup.html#update-enrich-policies
				  curl -s "$curl_cert_params" "${curl_user_auth_params}" -XDELETE "${elasticsearch_url}/_ingest/pipeline/corelight_conn_pipeline"
				  # Delete the enrich policy now
				  curl -s "$curl_cert_params" "${curl_user_auth_params}" -XDELETE "${elasticsearch_url}/_enrich/policy/$conn_enrichment_policy_file_name"
        fi
        import_status=$(curl -s "$curl_cert_params" "${curl_user_auth_params}" -XPUT "${elasticsearch_url}/_enrich/policy/$conn_enrichment_policy_file_name" --data-binary @"$pipelines_path/$conn_enrichment_policy_file_name" -H 'Content-Type: application/json')
        curl "$curl_cert_params" "${curl_user_auth_params}" -XPUT "${elasticsearch_url}/_enrich/policy/$conn_enrichment_policy_file_name/_execute"
        i=$[$i+1]
        sleep 1.25
			}
		done
		if ! echo "${import_status}" | grep -q '"acknowledged":true';then
    {
      echo -e "${RED}${import_status}"
      echo -e "${RED}Failed to install '$conn_enrichment_policy_file_name'"
      echo -e "${STD}Exiting script because of the necessity of this."
      echo -e "${STD}Retry the script. If the error persists then please open a github issue.\n"
      exit 0
    }
		else
    {
      curl "$curl_cert_params" "${curl_user_auth_params}" -XPUT "${elasticsearch_url}/_enrich/policy/$conn_enrichment_policy_file_name/_execute"
      echo "success"
    }
		fi
    echo -e "${STD}"
    sleep .55

		#########################
		echo -e "\n${STD}Installing the rest of the Corelight pipeline...\n"
		############# Corelight (the rest of the) Pipeline
		for pipeline_file in ${pipelines_list};do
		{
			echo "Installing '$pipeline_file'"
			import_status=$(curl -s "$curl_cert_params" "${curl_user_auth_params}" -XPUT "${elasticsearch_url}/_ingest/pipeline/$pipeline_file" --data-binary @"$pipelines_path/$pipeline_file" -H 'Content-Type: application/json')
			i="1"
			while ! echo "${import_status}" | grep -q '"acknowledged":true' && [[ ${i} -le ${max_install_attempts} ]];do
      {
        echo "Retrying install, attempt $i of $max_install_attempts"
        import_status=$(curl -s "$curl_cert_params" "${curl_user_auth_params}" -XPUT "${elasticsearch_url}/_ingest/pipeline/$pipeline_file" --data-binary @"$pipelines_path/$pipeline_file" -H 'Content-Type: application/json')
        i=$[$i+1]
        sleep 1.25
      }
			done
      if ! echo "${import_status}" | grep -q '"acknowledged":true';then
      {
        failed_install_amount=$((failed_install_amount+1))
        echo -e "${RED}${import_status}"
        echo -e "${RED}Failed to install '$pipeline_file'"
        failed_files+=("${pipeline_file}")
      }
			else
      {
        successful_install_amount=$((successful_install_amount+1))
        echo "success"
      }
			fi
			echo -e "${STD}"
			sleep .55
		}
		done
		if [[ ${failed_install_amount} -ge 1 ]]; then
		  echo -e "${WAR}Failed to install $failed_install_amount pipeline(s)"
		  echo -e "${WAR}Failed to install the following pipeline(s):\n${failed_files[@]}\n"
    fi
		echo -e "${CYAN}Successfully installed $successful_install_amount of $pipelines_list_amount pipelines${STD}\n"
	}
	else
  {
    echo -e "${RED}Pipelines list is empty."
    echo "Please make sure you are in the same directory as the pipelines you are trying to install."
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
