import ballerina/log;
import ballerina/http;
import ballerinax/jaeger as _;

type Allocation record {|
    string orderId;
    string itemId;
    int quantity;
|};

map<int> inventoryMap = {
    "P100": 100,
    "P200": 0,
    "P300": 300
};

configurable string shipmentHost = "localhost";

public function main() {
    log:printInfo("Starting the inventory service...");
}

service /inventory on new http:Listener(9103) {
    resource function get inventory() returns string[] {
        return inventoryMap.keys();
    }

    resource function post allocations(Allocation allocation) returns json|error {
        log:printInfo(string `Allocating items: ${allocation.itemId} - ${allocation.quantity}`);
        int? availableQuantity = inventoryMap[allocation.itemId];
        if (availableQuantity == ()) {
            log:printError("Invalid item Id: " + allocation.itemId);
            return error("Invalid item Id: " + allocation.itemId);
        } else if (availableQuantity < allocation.quantity) {
            log:printInfo("Insufficient quantity in the inventory. Creating a warehouse order for item: " + allocation.itemId);
            do {
                http:Client shipments = check new("http://" + shipmentHost + ":9101/logistics");
                json message = check shipments->/shipments.post({orderId: allocation.orderId, address: "WH1"});
            } on fail error e {
                log:printError("Error while creating a warehouse order for " + allocation.itemId, e);
                return error("Error while creating a warehouse order for " + allocation.itemId);
            }
        }
        return {orderId: allocation.orderId, status: "Allocated successfully"};
    }
}
