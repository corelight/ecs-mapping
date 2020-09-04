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

def checkRequest(responseObj):
    code = responseObj.status_code
    if code == 200:
        return 200

    if 400 <= code <= 500:
        print(responseObj.json())
        time.sleep(5)
        return code
    return code

def exportToElastic(session, baseURI, pipeline, retry=4):
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

    print("URI = %s" % uri)
    # print "Uploading data to: %s" %uri    
    response = 0
    while run <= retry and response != 200:
        run = run + 1
        response = session.put(uri, data=postData, timeout=10)
        response = checkRequest(response)
        if response == 400:
            if (pipeline == "zeek-enrichment-conn-policy"):
                response = elasticDel(session, baseURI, "corelight_conn_pipeline", retry)
                print(response)
                response = elasticDel(session, baseURI, pipeline, retry)
                print(response)
                time.sleep(5)
                response = 500

    if response == 200:
        return 
    else:
        print("Error uploading %s status code %s" %(pipeline, response),file=sys.stderr)
        sys.exit(1)


def elasticDel(session, baseURI, pipeline,  retry):

    uri = baseURI + "/_ingest/pipeline/"  + pipeline
    if pipeline.endswith("-policy"):
        uri = baseURI + "/_enrich/policy/" + pipeline

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
        print(" -User: %s \n -Passowrd: %s" %(user, password))
    if secure:
        print(" - Ignore Certificate Errors: %s" % ignoreCertErrors)

    proto = "https" if secure else "http"
    baseURI = proto + "://" + ipHost + ":" + str(port)
    return baseURI, s

def main():
    requests.packages.urllib3.disable_warnings(category=InsecureRequestWarning)

    print("\nList of pipelines to be installed to Elasticsearch:\n")
    for f in glob.glob("*corelight*"):
        print(f)
    print("\nUse this script to import Corelight pipeline configurations to your Elasticsearch cluster.\n\n")
        
    baseURI, session = get_config()
    print("Uploading schemas to", baseURI)

    testConnection(session, baseURI)
    xpack = input_bool("Will X-Pack be enabled?Disableing this will disable Enrich tables and Geolocation", default=True)
    if xpack:
        exportToElastic(session, baseURI, "zeek-enrichment-conn-dictionary", retry=1)
        exportToElastic(session, baseURI, "zeek-enrichment-conn-policy")
        exportToElastic(session, baseURI, "zeek-enrichment-conn-policy/_execute")
        exportToElastic(session, baseURI, "corelight_conn_pipeline")
    else:
        exportToElastic(session, baseURI, "non-xpack-corelight_conn_pipeline")
    for f in glob.glob("template_corelight*"):
        if f != "template_corelight_metrics_and_stats":
            exportToElastic(session, baseURI, f)
    if xpack:
        for f in glob.glob("corelight*"):
            exportToElastic(session, baseURI, f)
    else:
        for f in glob.glob("corelight*"):
            exportToElastic(session, baseURI, f)
        response = elasticDel(session, baseURI, "corelight_conn_pipeline", 1)
        print(response)
        exportToElastic(session, baseURI, "non-xpack-corelight_general_pipeline")
if __name__ == "__main__":
    main()
