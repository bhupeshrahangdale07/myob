public with sharing class Batch_MultipleProductsDynamic implements Database.Batchable<MYOB_ProductResponse.cls_Items>, Database.AllowsCallouts {

    private List<MYOB_ProductResponse.cls_Items> lstProductsToSync;

    // Constructor to accept the list of products to sync
    public Batch_MultipleProductsDynamic(List<MYOB_ProductResponse.cls_Items> lstProductsToSync) {
        this.lstProductsToSync = lstProductsToSync;
    }

    // Start method: Returns the custom iterable
    public Iterable<MYOB_ProductResponse.cls_Items> start(Database.BatchableContext BC) {
        return lstProductsToSync;
    }

    // Execute method: Processes each batch of records
    public void execute(Database.BatchableContext BC, List<MYOB_ProductResponse.cls_Items> scope) {
        try {
            // Perform your processing logic here
            for (MYOB_ProductResponse.cls_Items product : scope) {
                // Example: Create or update records in Salesforce
                System.debug('Processing product: ' + product.Name);
                // Add your logic here (e.g., callouts, DML operations)
            }
        } catch (Exception e) {
            // Handle exceptions (e.g., log errors)
            System.debug('Error processing products: ' + e.getMessage());
        }
    }

    // Finish method: Post-processing logic
    public void finish(Database.BatchableContext BC) {
        // Example: Send an email notification or log the results
        System.debug('Batch processing completed successfully!');
    }
}