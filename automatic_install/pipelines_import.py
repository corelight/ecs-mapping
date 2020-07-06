import requests
from urllib3.exceptions import InsecureRequestWarning
import sys
import glob
import time
#template
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

max_install_attempts=5
successful_install_amount=0
failed_install_amount=0
failed_files=()
user = ""
password = ""
ipHost = ""
port = ""
auth = ""
checkCert = ""
secure = ""

    

def testConnection():
    testUri = "/_cat/indices?v&pretty"
    uri = secure + "://" + ipHost + ":" + port + testUri
    requests.packages.urllib3.disable_warnings(category=InsecureRequestWarning)
    
    if ((checkCert.lower() == 'y') and (auth.lower() =='y')):
        try:
            response = requests.get(uri, verify=False, headers={'Content-Type': 'application/json'}, auth=(user, password))
        except requests.exceptions.ConnectionError:
            print ("Can not connect to the HOST/IP")
            sys.exit()
        except requests.exceptions.Timeout:
            print "Request Timeout"
            sys.exit()
        checkRequest(response, 0, "")
    if ((checkCert.lower() == 'n') and (auth.lower() =='y')):
        try:
            response = requests.get(uri, verify=False, headers={'Content-Type': 'application/json'}, auth=(user, password))
        except requests.exceptions.ConnectionError:
            print ("Can not connect to the HOST/IP")
            sys.exit()
        except requests.exceptions.Timeout:
            print "Request Timeout"
            sys.exit()
        checkRequest(response, 0, "",)
    if ((checkCert.lower() == 'y') and (auth.lower() =='n')):
        try:
            response = requests.get(uri, verify=False, headers={'Content-Type': 'application/json'})
        except requests.exceptions.ConnectionError:
            print ("Can not connect to the HOST/IP")
            sys.exit()
        except requests.exceptions.Timeout:
            print "Request Timeout"
            sys.exit()
        checkRequest(response, 0, "")
    if ((checkCert.lower() == 'n') and (auth.lower() =='n')):
        try:
            response = requests.get(uri, headers={'Content-Type': 'application/json'})
        except requests.exceptions.ConnectionError:
            print ("Can not connect to the HOST/IP")
            sys.exit()
        except requests.exceptions.Timeout:
            print "Request Timeout"
            sys.exit()
        checkRequest(response, 0, "")

def checkRequest(responseObj, retry, pipeline):
    if (responseObj.status_code == 200):
        return 200
        
    if (responseObj.status_code == 409):
        print responseObj.json()
        time.sleep(5)
        return 409
    if (responseObj.status_code == 400):
        print responseObj.json()
        time.sleep(5)
        return 400


def exportToElastic(pipeline, retry):
    print "Trying to upload pipeline: %s" % pipeline
    if (pipeline != "zeek-enrichment-conn-policy/_execute"):
        f = open(pipeline)
        postData = f.read()
        f.close()
    else:
        postData = ""
    response = ""
    run = 1
    uri = secure + "://" + ipHost + ":" + port + "/_ingest/pipeline/"  + pipeline
    if ("template" in pipeline):
        uri = secure + "://" + ipHost + ":" + port + "/_template/" + pipeline
    if (pipeline == "zeek-enrichment-conn-dictionary"):
        uri = secure +  "://" + ipHost + ":" + port + "/" +pipeline + "/_bulk"
    if ((pipeline == "zeek-enrichment-conn-policy") or (pipeline == "zeek-enrichment-conn-policy/_execute")):
        uri = secure + "://" + ipHost + ":" + port + "/_enrich/policy/" + pipeline
        print "URI = %s" %uri
    # print "Uploading data to: %s" %uri    
    requests.packages.urllib3.disable_warnings(category=InsecureRequestWarning)
    while ((run <= retry) and (response != 200)):
        run = run + 1
        if ((checkCert.lower() == 'y') and (auth.lower() =='y')):
            try:
                response = requests.put(uri, verify=False, headers={'Content-Type': 'application/json'}, auth=(user, password), data=postData)
                print response
            except requests.exceptions.ConnectionError:
                print ("Can not connect to the HOST/IP: %s") %requests.exceptions.ConnectionError
                sys.exit()
            except requests.exceptions.Timeout:
                print "Request Timeout"
                sys.exit()
        if ((checkCert.lower() == 'n') and (auth.lower() =='y')):
            try:
                response = requests.put(uri, verify=True, headers={'Content-Type': 'application/json'}, auth=(user, password), data=postData)
            except requests.exceptions.ConnectionError:
                print ("Can not connect to the HOST/IP")
                sys.exit()
            except requests.exceptions.Timeout:
                print "Request Timeout"
                sys.exit()
        if ((checkCert.lower() == 'y') and (auth.lower() =='n')):
            try:
                response = requests.put(uri, verify=False, headers={'Content-Type': 'application/json'}, data=postData)
            except requests.exceptions.ConnectionError:
                print ("Can not connect to the HOST/IP")
                sys.exit()
            except requests.exceptions.Timeout:
                print "Request Timeout"
                sys.exit()
        if ((checkCert.lower() == 'n') and (auth.lower() =='n')):
            try:
                response = requests.put(uri, headers={'Content-Type': 'application/json'}, data=postData)
            except requests.exceptions.ConnectionError:
                print ("Can not connect to the HOST/IP")
                sys.exit()
            except requests.exceptions.Timeout:
                print "Request Timeout"
                sys.exit()
        response = checkRequest(response, retry, pipeline)
        if response == 400:
            if (pipeline == "zeek-enrichment-conn-policy"):
                response = elasticDel("corelight_conn_pipeline", retry)
                print response
                response = elasticDel(pipeline, retry)
                response = elasticDel(pipeline, retry)
                print response
    
    if response == 200:
        return 
    else:
        print "Error uploading %s status code %s" %(pipeline, response)
        sys.exit()


def elasticDel(pipeline,  retry):
    uri = secure + "://" + ipHost + ":" + port + "/_ingest/pipeline/"  + pipeline
    requests.packages.urllib3.disable_warnings(category=InsecureRequestWarning)
    if (pipeline == "zeek-enrichment-conn-policy"):
        uri = secure + "://" + ipHost + ":" + port + "/_enrich/policy/" + pipeline
    if ((checkCert.lower() == 'y') and (auth.lower() =='y')):
        print "deleting uri = %s" %uri
        try:
            response = requests.delete(uri, verify=False, headers={'Content-Type': 'application/json'}, auth=(user, password))
        except requests.exceptions.ConnectionError:
            print ("Can not connect to the HOST/IP")
            sys.exit()
        except requests.exceptions.Timeout:
            print "Request Timeout"
            sys.exit()   
    if ((checkCert.lower() == 'n') and (auth.lower() =='y')):
        try:
            response = requests.delete(uri, verify=True, headers={'Content-Type': 'application/json'}, auth=(user, password))
        except requests.exceptions.ConnectionError:
            print ("Can not connect to the HOST/IP")
            sys.exit()
        except requests.exceptions.Timeout:
            print "Request Timeout"
            sys.exit()   
    if ((checkCert.lower() == 'y') and (auth.lower() =='n')):
        try:
            response = requests.delete(uri, verify=False, headers={'Content-Type': 'application/json'}, auth=(user, password))
        except requests.exceptions.ConnectionError:
            print ("Can not connect to the HOST/IP")
            sys.exit()
        except requests.exceptions.Timeout:
            print "Request Timeout"
            sys.exit()  
    if ((checkCert.lower() == 'n') and (auth.lower() =='n')):
        try:
            response = requests.delete(uri, verify=False, headers={'Content-Type': 'application/json'}, auth=(user, password))
        except requests.exceptions.ConnectionError:
            print ("Can not connect to the HOST/IP")
            sys.exit()
        except requests.exceptions.Timeout:
            print "Request Timeout"
            sys.exit()   
    result = checkRequest(response, retry, pipeline)
    return result

print "\nUse this script to import Corelight pipeline configurations to your Elasticsearch cluster.\n\n"
conn = raw_input("('y' to start the process or 'n' to exit): ")
if (conn.lower() !='y'):
        sys.exit()
print "\nList of pipelines to be installed to Elasticsearch:\n"
for file in glob.glob("*corelight*"):
    print file
    
print "\nEnter the information to connect to your Elasticsearch cluster.\n"
ipHost = raw_input("Hostname or IP: ")
port = raw_input("Port: ")
auth = raw_input("Use user and password authentication? [y/n]: ")
if (auth.lower() == 'y'):
    user = raw_input("User: ")
    password = raw_input("Password: ")
secure = raw_input("Use http or https [http/https]: ")
if (secure.lower() == 'https'):
    checkCert = raw_input("Enter 'y' unless you have HTTPS certificate authorties (CA) for your machine to trust the cluster's certificate or the CA file\nWould you like to ignore certificate errors [y/n]: ")
print "You have entered the following parameters to connect to your cluster: \n - Host/IP: %s \n - Port: %s \n - HTTP/HTTPS: %s" %(ipHost, port, secure)
if (auth.lower() == 'y'):
    print " -User: %s \n -Passowrd: %s" %(user, password)
if (secure.lower() == 'https'):
    print " - Ignore Certificate Errors: %s" % checkCert

testConnection()
exportToElastic("zeek-enrichment-conn-dictionary", 1)
exportToElastic("zeek-enrichment-conn-policy", 8 )
exportToElastic("zeek-enrichment-conn-policy/_execute", 8 )
exportToElastic("corelight_conn_pipeline",  8)
for file in glob.glob("template_corelight*"):
    if (file != "template_corelight_metrics_and_stats"):
        exportToElastic(file,8)
for file in glob.glob("corelight*"):
    exportToElastic(file,8)

