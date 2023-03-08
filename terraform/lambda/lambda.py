import os
import json
from neo4j import GraphDatabase
import boto3

# Values here are created as environment variables in the terraform deployment
ENDPOINT = os.environ.get("GRAPH_URI")
# "this should look something like: bolt://<db-name>.cluster-<code>.<region>.neptune.amazonaws.com:8182"
GRAPH_URI = f"bolt://{ENDPOINT}"

EVENT_BUS_NAME = os.environ.get("EVENT_BUS_NAME")
EVENT_SCHEMA = os.environ.get("EVENT_SCHEMA")
ALGORITHM = os.environ.get("ALGORITHM")


# lambda entrypoint
def lambda_handler(event, context):
    """
    lambda_handler is the entrypoint for the AWS Lambda function

    :param event: the SQSEvent that triggered the lambda
    """
    print("----------------================ BEGIN ================----------------")

    driver = GraphDatabase.driver(GRAPH_URI, auth=("ignored", "ignored"), encrypted=True)
    session = driver.session()

    # populate the database if there's nothing in it
    if not session.execute_read(check_graph_exists, "Service A"):
        print("Service A Not Found")
        populate_graph(session)

    # get the source information from the sqs event
    body = json.loads(event["Records"][0]["body"])
    source_service = body["sourceService"]
    souerce_resource = body["sourceResource"]
    print(f"Event ({source_service}, {souerce_resource})")

    # interrogate the graph
    services = session.execute_read(get_affected_services, souerce_resource)

    if not any(services):
        print("No affected services found")
        print("----------------================ COMPLETED ================----------------")
        return {"statusCode": 200}

    print("Affected Services = ", json.dumps(services))

    # construct the notification and put it to eventbridge for routing to queue(s)
    notification = {
        "sourceService": source_service,
        "sourceResource": souerce_resource,
        "notifyServices": services
    }
    put_notification(notification)

    print("----------------================ COMPLETED ================----------------")
    return {"statusCode": 200}


def check_graph_exists(transaction, service_id) -> bool:
    """
    check_graph_exists queries the graph for a given Service Id and returns a boolean indicating whether or not it was found

    :param transaction: transaction
    :param service_id: the id of the service to look for
    """

    query = f"MATCH (s:Service) WHERE s.serviceId = \"{service_id}\" RETURN s.serviceId"
    result = transaction.run(query)

    return any(result)


def populate_graph(session) -> None:
    """
    populate_graph creates the initial set of services and resources in the graph, as well as their relationships

    :param session: db session
    """

    print("Clearing DB...")
    session.execute_write(clear_data)

    print("Creating Services...")
    session.execute_write(create_service, "Service A")
    session.execute_write(create_service, "Service B")
    session.execute_write(create_service, "Service C")
    session.execute_write(create_service, "Service D")
    session.execute_write(create_service, "Service E")

    print("Creating Resources...")
    session.execute_write(create_resource, "Service A", "Resource 1")
    session.execute_write(create_resource, "Service B", "Resource 2")
    session.execute_write(create_resource, "Service C", "Resource 3")
    session.execute_write(create_resource, "Service D", "Resource 4")
    session.execute_write(create_resource, "Service E", "Resource 5")

    print("Creating Relationships...")
    session.execute_write(create_relationship, "Resource 1", "Resource 2")
    session.execute_write(create_relationship, "Resource 2", "Resource 3")
    session.execute_write(create_relationship, "Resource 2", "Resource 4")
    session.execute_write(create_relationship, "Resource 3", "Resource 5")

    print("Creation Completed")


def clear_data(transaction) -> None:
    """
    clear_data removes all data from the database

    :param transaction: transaction
    """

    transaction.run("MATCH (n) DETACH DELETE n")


def create_service(transaction, service_id) -> None:
    """
    create_service creates a node in the database of type Service

    :param transaction: transaction
    """

    transaction.run(f"CREATE (s:Service {{ serviceId:\"{service_id}\" }})")


def create_resource(transaction, service_id, resource_name) -> None:
    """
    create_resource creates a resource owned by a given service

    :param transaction: transaction
    :param service_id: the id of the existing service that will own the resource
    :param resource_name: the name of the resource
    """

    transaction.run(f"CREATE (r:Resource {{ name:\"{resource_name}\" }})")
    transaction.run(f"MATCH (s:Service), (r:Resource) WHERE s.serviceId = \"{service_id}\" AND r.name = \"{resource_name}\" CREATE (s)-[:OWNS]->(r)")


def create_relationship(transaction, resource_source_name, resource_target_name) -> None:
    """
    create_relationship creates a directed affects relationship between 2 resources

    :param transaction: transaction
    :param resource_source_name: the name of the source resource of the affects relationship
    :param resource_target_name: the name of the target resource of the affects relationship
    """

    transaction.run(f"MATCH (rs:Resource {{ name:\"{resource_source_name}\" }}), (rt:Resource {{ name:\"{resource_target_name}\" }}) CREATE (rs)-[:AFFECTS]->(rt)")


def get_affected_services(transaction, resource_source_name):
    """
    get_affected_services interrogates the graph to find which services will be affected according to the algorithm used

    :param transaction: transaction
    :param resource_source_name: name of the source resource
    :return: a list of tuples containing (target service Id, target resource name)
    """
    print("Getting affected services")

    records = []
    query = get_query(resource_source_name)
    result = transaction.run(query, resourceSourceName=resource_source_name)
    for record in result:
        records.append(record["st.serviceId"])

    return records


def get_query(resource_source_name) -> str:
    """
    get_query creates the graph query given the ALGORITHM passed as an environment variable. Defaults to downstream_all

    :param resource_source_name: the name of the resource that experienced the event and the start of the search path
    """
    print(f"Requested algorithm: {ALGORITHM}")

    if ALGORITHM == "downstream_all":
        print("Using algorithm: downstream_all")
        # Note the variable-length path indicated by the asterisk in [:AFFECTS*]
        return f"""MATCH (r:Resource)-[:AFFECTS*]->(rt:Resource)<-[:OWNS]-(st:Service) 
              WHERE r.name = \"{resource_source_name}\"
              RETURN DISTINCT st.serviceId, rt.name"""
    if ALGORITHM == "downstream_adjacent":
        print("Using algorithm: downstream_adjacent")
        # Note the single path length indicated by the lack of an asterisk in [:AFFECTS]
        return f"""MATCH (r:Resource)-[:AFFECTS]->(rt:Resource)<-[:OWNS]-(st:Service) 
              WHERE r.name = \"{resource_source_name}\" 
              RETURN DISTINCT st.serviceId, rt.name"""
    if ALGORITHM == "downstream_leaves":
        print("Using algorithm: downstream_leaves")
        # Note the clause that limits the path to select resource target (rt) nodes that do NOT have an AFFECTS relationship to another node
        return f"""MATCH (r:Resource)-[:AFFECTS*]->(rt:Resource)<-[:OWNS]-(st:Service) 
              WHERE r.name = \"{resource_source_name}\" AND not(rt)-[:AFFECTS]->() 
              RETURN DISTINCT st.serviceId, rt.name"""
    if ALGORITHM == "upstream_all":
        print("Using algorithm: upstream_all")
        return f"""MATCH (st:>Service)-[:OWNS]->(rt:Resource)-[:AFFECTS*]->(r:Resource) 
              WHERE r.name = \"{resource_source_name}\" 
              RETURN DISTINCT st.serviceId, rt.name"""

    print("Using algorithm: downstream_all")
    return f"""MATCH (r:Resource)-[:AFFECTS*]->(rt:Resource)<-[:OWNS]-(st:Service) 
            WHERE r.name = \"{resource_source_name}\" 
            RETURN DISTINCT st.serviceId, rt.name"""


def put_notification(detail) -> None:
    """
    put_notification puts an event to Amazon EventBridge with the detail given

    :param detail: The detail to include in the event
    """

    print("Publishing notification(s)")
    client = boto3.client("events")
    client.put_events(
        Entries=[
            {
                "Source": "Lambda",
                "EventBusName": EVENT_BUS_NAME,
                "DetailType": EVENT_SCHEMA,
                "Detail": json.dumps(detail)
            }
        ]
    )
