#!/usr/bin/env python3

import requests
from urllib3.exceptions import InsecureRequestWarning
import glob
import time
import sys

def input_bool(question, default=None):

    prompt = " [yn]"

    if default is not None:
        prompt = " [Yn]:" if default else " [yN]:"

    while True:
        val = input(question + prompt)
        val = val.lower()
        if val  == '' and default is not None:
            return default
        if val in ('y', 'n'):
            return val == 'y'
        print("Invalid response")

def input_int(question):
    while True:
        val = input(question + ": ")
        try:
            return int(val)
        except ValueError as e:
            print("Invalid response", e)

def testConnection(session, baseURI):
    testUri = "/_cat/indices?v&pretty"
    uri = baseURI + testUri
    response = session.get(uri, timeout=5)
    checkRequest(response)
    response.raise_for_status()

def checkRequest(responseObj, debug=False):
    code = responseObj.status_code
    if code == 200:
        return 200

    if 400 <= code <= 500:
        if debug:
            print(responseObj.json())
        time.sleep(5)
        return code
    return code

def exportToElastic(session, baseURI, pipeline, debug=False, retry=4):
    if debug:
        print("Trying to upload pipeline: %s" % pipeline)
    if pipeline != "zeek-enrichment-conn-policy/_execute":
        with open(pipeline) as f:
            postData = f.read()
    else:
        postData = ""
    run = 1
    uri = baseURI + "/_ingest/pipeline/"  + pipeline
    if "template" in pipeline:
        uri = baseURI + "/_template/" + pipeline
    if pipeline == "zeek-enrichment-conn-dictionary":
        uri = baseURI + "/" + pipeline + "/_bulk"
    if pipeline.endswith(("policy", "policy/_execute")):
        uri = baseURI +  "/_enrich/policy/" + pipeline 
    
    if debug:
        print("URI = %s" % uri)
    # print "Uploading data to: %s" %uri    
    response = 0
    while run <= retry and response != 200:
        run = run + 1
        response = session.put(uri, data=postData, timeout=10)
        response = checkRequest(response)
        if response == 400 or response == 409:
            if pipeline == "zeek-enrichment-conn-policy":
                # Delete the pipeline that calls the enrich policy before we can delete the enrich policy itself. https://www.elastic.co/guide/en/elasticsearch/reference/master/enrich-setup.html#update-enrich-policies
                response = elasticDel(session, baseURI, "xpack-corelight_conn_pipeline", retry, debug) # Keep to delete old one, can ignore these errors
                response = elasticDel(session, baseURI, "xpack-corelight_additional_pipeline", retry, debug)
                response = elasticDel(session, baseURI, "xpack-corelight_conn_enrich_pipeline", retry, debug)
                response = elasticDel(session, baseURI, "zeek-enrichment-conn-policy", retry, debug)
                if debug:
                    print(response)
                response = elasticDel(session, baseURI, pipeline, retry)
                if debug:
                    print(response)
                time.sleep(5)
                response = 500

    if response == 200:
        return 
    else:
        print("Error uploading %s status code %s" %(pipeline, response),file=sys.stderr)
        sys.exit(1)


def elasticDel(session, baseURI, pipeline, retry, debug=False):

    uri = baseURI + "/_ingest/pipeline/"  + pipeline
    if pipeline.endswith("-policy"):
        uri = baseURI + "/_enrich/policy/" + pipeline

    if debug:
        print("deleting uri = %s" % uri)
    response = session.delete(uri, timeout=5)
    result = checkRequest(response)
    return result

def get_config():
    """Return a baseURI and session"""

    s = requests.Session()
    s.headers={'Content-Type': 'application/json'}

    print("\nEnter the information to connect to your Elasticsearch cluster.\n")
    ipHost = input("Hostname or IP: ")
    port = input_int("Port")
    auth = input_bool("Use user and password authentication?", default=True)

    if auth:
        user = input("User: ")
        password = input("Password: ")
        s.auth = (user, password)
    secure = input_bool("Use https?")
    ignoreCertErrors = False
    if secure:
        ignoreCertErrors = input_bool("Would you like to ignore certificate errors?", default=False)
    s.verify = not ignoreCertErrors

    print("You have entered the following parameters to connect to your cluster: \n - Host/IP: %s \n - Port: %s \n - HTTP/HTTPS: %s" %(ipHost, port, secure))
    if auth:
        print(" -User: %s \n -Password: %s" %(user, password))
    if secure:
        print(" - Ignore Certificate Errors: %s" % ignoreCertErrors)

    proto = "https" if secure else "http"
    baseURI = proto + "://" + ipHost + ":" + str(port)
    return baseURI, s

def main():
    debug = False
    if len(sys.argv) >1 :
        if (sys.argv[1] == "-d") or (sys.argv[1] == "--d"):
            debug = True
    
    requests.packages.urllib3.disable_warnings(category=InsecureRequestWarning)

    requiredTemplate = ["template_corelight", "template_corelight_temporary_log_holdings", "template_corelight_base_settings", "template_corelight_parse_failures"]
    xpackTemplate = ["xpack-corelight_additional_pipeline","xpack-corelight_conn_enrich_pipeline","xpack-template_corelight"]
    nonxpackTemplate = ["non-xpack-template_corelight"]

    print("\nList of pipelines to be installed to Elasticsearch:\n")
    for f in glob.glob("*corelight*"):
        print(f)
    print("\nUse this script to import Corelight pipeline configurations to your Elasticsearch cluster.\n\n")
        
    baseURI, session = get_config()
    print("Uploading schemas to", baseURI)

    testConnection(session, baseURI)
    # Prompt to skip loading ingest pipelines #ie: if using logstash to do all the parsing
    load_ingest_pipelines = input_bool("Use ingest pipelines? (if you are using Logstash to perform ECS and normalization then select no)", default=True)
    if load_ingest_pipelines :
        xpack = input_bool("Will X-Pack be enabled? Disabling this will disable Enrich tables and Geolocation", default=True)
        if xpack:
            exportToElastic(session, baseURI, "zeek-enrichment-conn-dictionary",debug, retry=1)
            exportToElastic(session, baseURI, "zeek-enrichment-conn-policy", debug)
            exportToElastic(session, baseURI, "zeek-enrichment-conn-policy/_execute", debug)
            #exportToElastic(session, baseURI, "xpack-corelight_additional_pipeline")
            #exportToElastic(session, baseURI, "xpack-corelight_conn_enrich_pipeline")
            for template in xpackTemplate:
                exportToElastic(session, baseURI, template, debug)
        else:
            for template in nonxpackTemplate:
                exportToElastic(session, baseURI, template, debug)
    else:
        pass

    for template in requiredTemplate:
                exportToElastic(session, baseURI, template, debug)

    #for f in glob.glob("template_corelight*"):
    #    if f != "template_corelight_metrics_and_stats":
    #        exportToElastic(session, baseURI, f)
    if load_ingest_pipelines:
        for f in glob.glob("corelight*"):
            exportToElastic(session, baseURI, f, debug)
    #if xpack:
    #    exportToElastic(session, baseURI, "xpack-template_corelight")
    #else:
    #    exportToElastic(session, baseURI, "non-xpack-template_corelight")
if __name__ == "__main__":
    main()
