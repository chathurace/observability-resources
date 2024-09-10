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
configurable string bookParkHost = "localhost";

public function main() {
    log:printInfo("Starting the TMART portal...");
}

service /tmart on new http:Listener(9100){
    resource function post orders(POrder porder) returns json|error {
        log:printInfo("Order received: " + porder.orderId);
        do {
            http:Client customers = check new("http://" + crmHost + ":9102/customers");
            string address = check customers->/customers/[porder.customerId]/address;

            http:Client inventory = check new("http://" + inventoryHost + ":9103/inventory");
            json inventoryResponse = check inventory->/allocations.post(
                {orderId:porder.orderId, itemId: porder.productId, quantity: porder.quantity});

            http:Client shipments = check new("http://" + shipmentHost + ":9101/logistics");
            json shipmentResult = check shipments->/shipments.post({orderId: porder.orderId, address: address});
            return {orderId: porder.orderId, orderStatus: "Order placed successfully", 
                inventoryStatus: check inventoryResponse.status, shipmentStatus: check shipmentResult.status};
        } on fail error e {
            log:printError("Error while placing the order: " + porder.orderId, e);
            return {orderId: porder.orderId, status: "Error while placing the order"};
        }
    }

    resource function post bookOrders(POrder porder) returns json|error {
        log:printInfo("Book order received: " + porder.orderId);
        do {
            http:Client bookOrders = check new("http://" + bookParkHost + ":8290/store");
            return bookOrders->/orders.post({"order": porder.orderId, customer: porder.customerId, bookId: porder.productId});
        } on fail error e {
            log:printError("Error while placing the order: " + porder.orderId, e);
            return {orderId: porder.orderId, status: "Error while placing the order"};
        }
    }
}
