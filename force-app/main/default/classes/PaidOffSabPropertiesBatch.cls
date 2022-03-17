public without sharing class PaidOffSabPropertiesBatch implements Database.Batchable<sObject> {
  public Database.QueryLocator start(Database.BatchableContext bc) {
    String queryString = 'SELECT Deal__r.Payoff_Date__c, Id, Status__c, Deal__c, Inactive_Date__c ';
    queryString += 'FROM Property__c WHERE ';
    queryString += 'Deal__r.Record_Type_Name__c = \'Single_Asset_Bridge_Loan\' AND ';
    queryString += 'Deal__r.StageName = \'Paid Off\' AND ';
    queryString += 'Deal__r.LOC_Loan_Type__c =\'Single Asset (1-4 Unit)\' AND ';
    queryString += 'Status__c != \'Paid Off\' ';
    queryString += 'FOR UPDATE';
    return Database.getQueryLocator(queryString);
  }
  public void execute(
    Database.BatchableContext bc,
    List<Property__c> properties
  ) {
    if (properties != null && properties.size() > 0) {
      for (Property__c p : properties) {
        p.Status__c = 'Paid Off';
        p.Inactive_Date__c = p.Deal__r.Payoff_Date__c;
      }

      update properties;
    }
  }
  public void finish(Database.BatchableContext bc) {
  }
}
