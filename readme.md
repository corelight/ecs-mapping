Corelight Elastic Common Schema Mapping
=======================================


Overview
--------
The Elastic Common Schema (https://github.com/elastic/ecs) is a way to unify field names across multiple data sources in Elastic. This mapping connects either Corelight or Zeek data types to relevant Elastic Common Schema field names, using Elastic's ingest node pipelines. A few notes on how the mapping works:
- Field names are replaced in this operation (i.e. ECS does not support having both the original field name and the ECS field name for the same record).
- Both open source Zeek and Corelight source types are supported.  If you have changed your source type you will need to edit these mapping files to account for that.
- The mapping can be done using either an ElasticSearch ingest node or directly in Kibana, as outlined below.
- Once done, the mapping applies to new data only and should be done using a new index.  This is because (due to how Elastic works) if the ingestion is done in a mixed index it will cause problems with field name conflicts between old and new field names. If this is a particular concern, you can work around it by having two exports to Elastic - one to a new index with the direct Elastic integration (which will have the new ECS field names) and one to the old index using the JSON exporter (which will have the original Zeek field names).
- Using the ECS mapping will increase CPU consumption within Elastic due to the real time field mapping.

This mapping is Version 1, which is current as of ECS 1.0, Zeek 3.0, and Corelight v17. As always, we are looking forward to any suggestions and ideas for improvement you have!


License
-------
The mapping files and automation script are open-source under a BSD license. See ``COPYING``for details.


Installation
------------
There are three main steps for a successful installation: (1) load the Corelight templates into Elasticsearch and (2) configure the Corelight sensor to export to the new index.


1) Import index template

    1.a) Goto the Dev console in Kibana and run the command from the file "template_corelight_base_settings". The index pattern name is "*\*ecs-corelight\**", which you can change if needed.


    1.b) Import the default pipeline with the command from the file "corelight_main_pipeline" (this essentially maps the ECS datasets (groups of field names) to the appropriate Corelight mapping file).

    1.c) Import all other pipelines from the files "corelight_conn_pipeline", "corelight_dce_rpc_pipeline", etc. You can also import all the pipelines automatically with the custom script (below).

    For automatic installation  *NOTE* This is the recommended and supported method - of pipelines on your Elasticsearch instance you can use the script pipelines_import.sh:
    - Use the folder automatic_install. Edit index name (or names) in file 'template_corelight' according to your environment.
    - Copy all files to a Linux host.
    - Run the script using the command # bash pipelines_import.sh or pipelines_import.py (Python3)
    - Using an interactive menu, install all pipelines to your environment.


 In this version both reduced and non reduced logs are in the same pipeline

3) Configure your sensor to send events to the new elasticsearch index. This is documented in the Corelight manual; for Zeek you have likely written your own export mechanism so configure that as appropriate for your environment.
