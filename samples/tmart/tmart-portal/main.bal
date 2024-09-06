import ballerina/log;
import ballerina/http;
import ballerinax/jaeger as _;

type POrder record {
    string orderId;
    string customerId;
    string productId;
    int quantity;
};

configurable string shipmentHost = "localhost";
configurable string inventoryHost = "localhost";
configurable string crmHost = "localhost";

public function main() {
    log:printInfo("Starting the TMART portal...");
}

service /tmart on new http:Listener(9100){
    resource function post orders(POrder porder) returns string|error {
        log:printInfo("Order received: " + porder.orderId);
        do {
            http:Client customers = check new("http://" + crmHost + ":9102/customers");
            string address = check customers->/customers/[porder.customerId]/address;

            http:Client inventory = check new("http://" + inventoryHost + ":9103/inventory");
            string status = check inventory->/allocations.post({orderId:porder.orderId, itemId: porder.productId, quantity: porder.quantity});

            http:Client shipments = check new("http://" + shipmentHost + ":9101/logistics");
            string shipmentStatus = check shipments->/shipments.post({orderId: porder.orderId, address: address});
            return string `Order placed successfully - status: ${status}, shipment status: ${shipmentStatus}`;
        } on fail error e {
            log:printError("Error while placing the order: " + porder.orderId, e);
            return "Error while placing the order: " + porder.orderId;
        }
    }
}
