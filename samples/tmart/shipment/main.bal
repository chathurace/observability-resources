import ballerina/log;
import ballerina/http;
import ballerinax/jaeger as _;

type Shipment record {|
    string orderId;
    string address;
|};

public function main() {
    log:printInfo("Starting the shipment service...");
}

service /logistics on new http:Listener(9101) {
    
    resource function get shipments() returns string[] {
        return ["Shipment 1", "Shipment 2", "Shipment 3"];
    }

    resource function post shipments(Shipment shipmentData) returns string|error {
        log:printInfo("Creating shipment for order: " + shipmentData.orderId);
        if shipmentData.orderId == "PE" {
            log:printError("Error creating shipment for order: " + shipmentData.orderId);
            return error("Error creating shipment for order: " + shipmentData.orderId);
        }
        return "Created shipment with data: " + shipmentData.orderId;
    }
}
