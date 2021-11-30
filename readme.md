Corelight Elastic Common Schema Mapping
=======================================


Overview
--------
The Elastic Common Schema (https://github.com/elastic/ecs) is a way to unify field names across multiple data sources in Elastic. This mapping connects either Corelight or Zeek data types to relevant Elastic Common Schema field names, using Elastic's ingest node pipelines. A few notes on how the mapping works:
- Field names are replaced in this operation (i.e. ECS does not support having both the original field name and the ECS field name for the same record).
- Supports both open source Zeek and Corelight
- The ingest pipeline (parsers and mappings) can be uploaded using directly to Elasticsearch (API) or through Kibana (manually)
- Once done, the mapping applies to new data only and should be done using a new index.  This is because (due to how Elastic works) if the ingestion is done in a mixed index it will cause problems with field name conflicts between old and new field names. If this is a particular concern, you can work around it by having two exports to Elastic - one to a new index with the direct Elastic integration (which will have the new ECS field names) and one to the old index using the JSON exporter (which will have the original Zeek field names).
- Using the ECS mapping will increase CPU consumption within Elastic due to the real time field mapping.
- Supports ECS 1.9.0
- Supports Corelight v21
- Supports Zeek 4.x

As always, we are looking forward to any suggestions and ideas for improvement you have!


License
-------
The mapping files and automation script are open-source under a BSD license. See ``COPYING``for details.


Installation
------------
Automatic installation (recommended)
-    1. Clone the Corelight Elastic Common Schema Mapping repository from GitHub to your workstation or jumpbox.
-    2. In ecs_mapping/automatic_install/, locate the template files (template_corelight_*). Edit each file,
       changing the values of the index_patterns field according to your environment.
-    3. Run pipelines_import.py (Python3) from ecs_mapping/automatic_install/.
       Note: CorelightrecommendsusingthePython3scriptforinstallation.Howeverifyoucan’trunPython3 in your environment, there’s also a bash script that executes          the installation (ecs_mapping/automatic_ install/pipelines_import.sh).
-    4. Respond to the configuration prompts to complete the installation.
-    5. Configure your Corelight Sensor to send events to the new Elasticsearch index.

Manual installation
-    1. In the Kibana sidebar, open Dev Tools to access the console.
-    2. In a separate tab, open the manual_install directory in the ecs_mapping repository.
-    3. Copy the contents of zeek-enrichment-conn-dictionary into the Kibana console and click the play button to execute the request. 
       This command imports enriched tables.
-    4. Execute the enriched tables using this command in the Kibana console.
        POST /_enrich/policy/zeek-enrichment-conn-policy/_execute
-    5. In the ecs-mapping repository, locate the template files (template_corelight_*). One at a time, copy the contents of each into the Kibana console. 
       Change the values of the index_patterns fields according to your environment and execute the request.
-    6. Copy the contents of the corelight_general_pipeline file from the ecs-mapping repository into the Kibana console and execute the request. 
       This command maps the ECS datasets to the appropriate Corelight mapping file.
-    7.  One at a time, copy the contents of each pipeline file (corelight_*_pipeline) into the Kibana console and execute the request. 
        These commands install each pipeline to your environment.
-    8. Configure your Corelight Sensor to send events to the new Elasticsearch index.
    
 In this version both reduced and non reduced logs are in the same pipeline

**Note**
You can change the number of shards and the lifecycle policy in template_corelight_ base_settings.

**With the latest update there was a change to matain backward compatibility you will need to do the following**

network.vlan.inner.id should be network.inner.vlan.id use an alias or elastic run time fields for backwards compatibility
