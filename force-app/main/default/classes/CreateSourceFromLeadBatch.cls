public class CreateSourceFromLeadBatch implements Database.Batchable<sObject> {
    public Database.QueryLocator start(Database.BatchableContext bc) {
        system.debug('start:::');
        string leadQuery = 'SELECT id,FirstName,LastName,Email,Phone,MobilePhone,Company,Loan_Product_s__c,Introduction_Source__c,Introduction_Subsource__c,Account_Converted_Into__c,Contact_Converted_Into__c,Deal_Converted_Into__c,Status,Conference_Year__c,Requested_Loan_Size__c,first_Touch_checkbox__c,last_Touch_checkbox__c,True_source__c,Contact_Notes__c,Existing_Contact__c,utm_Campaign_Content__c,utm_Campaign_Medium__c,utm_Campaign_Name__c,utm_Campaign_Source__c,utm_Campaign_Term__c from lead where id NOT IN (select Lead__c from Source__c) LIMIT 1';
        system.debug('leadQuery:::'+leadQuery);
        return  Database.getQueryLocator(leadQuery);
    }
    public void execute(Database.BatchableContext bc, List<lead> leadList){
        system.debug('leadList:::'+leadList);
        if(leadList != null && leadList.size() > 0){
            lead_Helper.CreateSource(leadList);
        }
    }
    public void finish(Database.BatchableContext bc){
        // execute any post-processing operations
        system.debug('createSourceFromLeadBatch:::finish:::');
    }
}