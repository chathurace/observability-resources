import ballerina/http;
import ballerina/log;
import ballerinax/jaeger as _;

map<string> customersMap = {
    "Peter": "5, Park Street, Brisbane",
    "Ann": "10, Park Street, Brisbane",
    "Ben": "15, Park Street, Brisbane"
};

public function main() {
    log:printInfo("Starting the customer service...");
}

service /customers on new http:Listener(9102) {
    
    resource function get customers() returns string[] {
        return customersMap.keys();
    }

    resource function get customers/[string customerId]/address() returns string|error {
        log:printInfo("Retrieving address for customer: " + customerId);
        string? address = customersMap[customerId];
        if (address == ()) {
            log:printError("Address not found for customer: " + customerId);
            return error("Address not found for customer: " + customerId);
        }
        return address;
    }
}
