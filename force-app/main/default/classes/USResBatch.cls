global class USResBatch implements Database.Batchable<sObject>, Database.AllowsCallouts {
    public USResBatch() {
    }
  
    global Database.QueryLocator start(Database.BatchableContext BC) {
        String queryString = 'SELECT Id FROM Appraisal__c';
    
        queryString += ' WHERE Appraisal_Firm_Transaction_ID__c != null AND Vendor_Ordered_From__c = \'US RES\'';
        queryString += ' AND CreatedDate = LAST_N_DAYS:30 AND Property__c != null';
        queryString += ' AND Status__c != \'Complete-Delivered\' AND Status__c != \'Cancelled\' AND Prevent_Auto_Refresh__c = false';
    
        return Database.getQueryLocator(queryString);
      }
    
      global void execute(Database.BatchableContext BC, List<sObject> scope) {
        List<Id> refreshIdList = new List<Id>();
        for (sobject s : scope) {
          refreshIdList.add((Id) s.get('Id'));
          AppraisalMergeController.refreshBatch((Id) s.get('Id'));
        }
        // if(!refreshIdList.isEmpty()) {
        //   AppraisalMergeController.refreshAppraisalStatus(refreshIdList);
        // }
      }
    
      global void finish(Database.BatchableContext BC) {
      }
    }