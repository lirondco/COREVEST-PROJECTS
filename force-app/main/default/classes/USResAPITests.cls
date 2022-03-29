@isTest
public with sharing class USResAPITests {
    @TestSetup
    static void setupTestData() {
      RecordType rt = [
        SELECT Id, DeveloperName
        FROM RecordType
        WHERE DeveloperName = 'Vendor' AND sobjectType = 'Account'
        LIMIT 1
      ];
      insert new Account(Name = 'US RES', RecordTypeId = rt.Id);
  
      Account acc = test_Helper.createAccount();
      Contact cont = test_Helper.createContact(acc);
      Opportunity opp = test_Helper.createOpportunity(acc, cont);
      opp.StageName = 'Submitted to Underwriting';
      opp.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName()
        .get('Bridge Loan')
        .getRecordTypeId();
  
      Property__c prop = new Property__c();
      prop.Property_Type__c = 'SFR';
      prop.Deal__c = opp.Id;
      prop.Calc_AveValue__c = 100000;
      prop.Name = 'test';
      prop.Property_Name__c = 'test Street';
      prop.City__c = 'test';
      prop.State__c = 'test';
      prop.ZipCode__c = '90802';
      prop.Interior_Access_POC__c = 'test person';
      prop.Interior_Access_POC_Email__c = 'test@test.com';
      prop.Interior_Access_POC_Phone__c = '555-555-5555';
      insert prop;
    }
  
    static testMethod void unittest() {
      Property__c p = [SELECT Id FROM Property__c LIMIT 1];
  
      Test.startTest();
      System.enqueueJob(new SmartyStreetsQueueable(new List<Id>{ p.Id }));
  
      Map<String, Object> arguments = new Map<String, Object>();
      arguments.put('appraisalFirm', 'US RES');
      arguments.put('productType', 'Interior Appraisal');
      arguments.put('rushOrder', false);
      // arguments.put('turnTime', '48');
      // arguments.put('dueDate', String.valueOf(System.today().addDays(10)));
      arguments.put('vendorComments', 'adsfa');
      arguments.put('', '');
      AppraisalMergeController.submitOrder(p.Id, arguments);
  
      Appraisal__c app = [SELECT Id FROM Appraisal__c LIMIT 1];
  
      AppraisalMergeController.checkStatus(app.Id);
  
      Database.executeBatch(new AppraisalNationBatch(), 1);
      AppraisalMergeController.retrieveOrderUSRES(app.Id);
  
      Test.stopTest();
    }
  
    static testMethod void unittest2() {
      Property__c p = [SELECT Id FROM Property__c LIMIT 1];
  
      Test.startTest();
      System.enqueueJob(new SmartyStreetsQueueable(new List<Id>{ p.Id }));
  
      Map<String, Object> arguments = new Map<String, Object>();
      arguments.put('appraisalFirm', 'US RES');
      arguments.put('productType', 'Exterior Appraisal');
      arguments.put('rushOrder', false);
      // arguments.put('turnTime', '48');
      // arguments.put('dueDate', String.valueOf(System.today().addDays(10)));
      arguments.put('vendorComments', 'adsfa');
      arguments.put('', '');
      AppraisalMergeController.submitOrder(p.Id, arguments);
  
      Appraisal__c app = [SELECT Id FROM Appraisal__c LIMIT 1];
  
      AppraisalMergeController.checkStatus(app.Id);
  
      // Database.executeBatch(new ClearCapitalBatch(), 1);
      AppraisalMergeController.retrieveOrderUSRES(app.Id);
  
      Test.stopTest();
    }
  
    static testMethod void unittest3() {
      Property__c p = [SELECT Id FROM Property__c LIMIT 1];
  
      Test.startTest();
      System.enqueueJob(new SmartyStreetsQueueable(new List<Id>{ p.Id }));
  
      Map<String, Object> arguments = new Map<String, Object>();
      arguments.put('appraisalFirm', 'US RES');
      arguments.put('productType', 'Interior Appraisal with ARV');
      arguments.put('rushOrder', false);
      // arguments.put('turnTime', '48');
      // arguments.put('dueDate', String.valueOf(System.today().addDays(10)));
      arguments.put('vendorComments', 'adsfa');
      arguments.put('', '');
      AppraisalMergeController.submitOrder(p.Id, arguments);
  
      Test.stopTest();
    }
  
    static testMethod void unittest4() {
      Property__c p = [SELECT Id FROM Property__c LIMIT 1];
  
      Test.startTest();
      // System.enqueueJob(new SmartyStreetsQueueable(new List<Id>{ p.Id }));
  
      Map<String, Object> arguments = new Map<String, Object>();
      arguments.put('appraisalFirm', 'US RES');
      arguments.put('productType', 'Exterior Appraisal with ARV');
      arguments.put('rushOrder', false);
      // arguments.put('turnTime', '48');
      // arguments.put('dueDate', String.valueOf(System.today().addDays(10)));
      arguments.put('vendorComments', 'adsfa');
      arguments.put('', '');
      AppraisalMergeController.submitOrder(p.Id, arguments);
  
      Appraisal__c app = [SELECT Id FROM Appraisal__c LIMIT 1];
  
      AppraisalMergeController.checkStatus(app.Id);
  
      // Database.executeBatch(new ClearCapitalBatch(), 1);
      AppraisalMergeController.retrieveOrderUSRES(app.Id);
  
      Test.stopTest();
    }
  
    static testMethod void unittest5() {
      Property__c p = [SELECT Id FROM Property__c LIMIT 1];
  
      Test.startTest();
      // System.enqueueJob(new SmartyStreetsQueueable(new List<Id>{ p.Id }));
  
      Map<String, Object> arguments = new Map<String, Object>();
      arguments.put('appraisalFirm', 'US RES');
      arguments.put('productType', 'Final Inspection');
      arguments.put('rushOrder', false);
      // arguments.put('turnTime', '48');
      // arguments.put('dueDate', String.valueOf(System.today().addDays(10)));
      arguments.put('vendorComments', 'adsfa');
      arguments.put('', '');
      AppraisalMergeController.submitOrder(p.Id, arguments);
  
      Appraisal__c app = [SELECT Id FROM Appraisal__c LIMIT 1];
  
      AppraisalMergeController.checkStatus(app.Id);
  
      // Database.executeBatch(new ClearCapitalBatch(), 1);
      AppraisalMergeController.retrieveOrderUSRES(app.Id);
  
      Test.stopTest();
    }
  
    static testMethod void unittest6() {
      Property__c p = [SELECT Id FROM Property__c LIMIT 1];
  
      Test.startTest();
      // System.enqueueJob(new SmartyStreetsQueueable(new List<Id>{ p.Id }));
  
      Map<String, Object> arguments = new Map<String, Object>();
      arguments.put('appraisalFirm', 'US RES');
      arguments.put('productType', 'Appraisal Update');
      arguments.put('rushOrder', false);
      // arguments.put('turnTime', '48');
      // arguments.put('dueDate', String.valueOf(System.today().addDays(10)));
      arguments.put('vendorComments', 'adsfa');
      arguments.put('', '');
      AppraisalMergeController.submitOrder(p.Id, arguments);
  
      Appraisal__c app = [SELECT Id FROM Appraisal__c LIMIT 1];
  
      AppraisalMergeController.checkStatus(app.Id);
  
      // Database.executeBatch(new ClearCapitalBatch(), 1);
      AppraisalMergeController.retrieveOrderUSRES(app.Id);
  
      Test.stopTest();
    }
  
    //   static testMethod void unittest7() {
    //     Property__c p = [SELECT Id FROM Property__c LIMIT 1];
  
    //     Test.startTest();
    //     // System.enqueueJob(new SmartyStreetsQueueable(new List<Id>{ p.Id }));
  
    //     Map<String, Object> arguments = new Map<String, Object>();
    //     arguments.put('appraisalFirm', 'US RES');
    //     arguments.put('productType', 'CoreVal+');
    //     arguments.put('rushOrder', false);
    //     // arguments.put('turnTime', '48');
    //     arguments.put('dueDate', String.valueOf(System.today().addDays(10)));
    //     arguments.put('vendorComments', 'adsfa');
    //     arguments.put('', '');
    //     AppraisalMergeController.submitOrder(p.Id, arguments);
  
    //     Appraisal__c app = [SELECT Id FROM Appraisal__c LIMIT 1];
  
    //     AppraisalMergeController.checkStatus(app.Id);
  
    //     // Database.executeBatch(new ClearCapitalBatch(), 1);
    //     AppraisalMergeController.retrieveOrderValuationServices(app.Id);
  
    //     Test.stopTest();
    //   }
  
    //   static testMethod void unittest9() {
    //     Property__c p = [SELECT Id FROM Property__c LIMIT 1];
    //     p.Property_Type__c = '2-4 Unit';
    //     p.Number_of_Units__c = 2;
    //     update p;
    //     Test.startTest();
    //     // System.enqueueJob(new SmartyStreetsQueueable(new List<Id>{ p.Id }));
  
    //     Map<String, Object> arguments = new Map<String, Object>();
    //     arguments.put('appraisalFirm', 'US RES');
    //     arguments.put('productType', 'CoreVal+');
    //     arguments.put('rushOrder', false);
    //     // arguments.put('turnTime', '48');
    //     arguments.put('dueDate', String.valueOf(System.today().addDays(10)));
    //     arguments.put('vendorComments', 'adsfa');
    //     arguments.put('', '');
    //     AppraisalMergeController.submitOrder(p.Id, arguments);
  
    //     Appraisal__c app = [SELECT Id FROM Appraisal__c LIMIT 1];
  
    //     AppraisalMergeController.checkStatus(app.Id);
  
    //     // Database.executeBatch(new ClearCapitalBatch(), 1);
    //     AppraisalMergeController.retrieveOrderValuationServices(app.Id);
  
    //     Test.stopTest();
    //   }
  
    static testMethod void unittest10() {
      Property__c p = [SELECT Id FROM Property__c LIMIT 1];
      p.Property_Type__c = '2-4 Unit';
      p.Number_of_Units__c = 2;
      update p;
      Test.startTest();
      // System.enqueueJob(new SmartyStreetsQueueable(new List<Id>{ p.Id }));
  
      Map<String, Object> arguments = new Map<String, Object>();
      arguments.put('appraisalFirm', 'US RES');
      arguments.put('productType', 'Interior Appraisal');
      arguments.put('rushOrder', false);
      // arguments.put('turnTime', '48');
      // arguments.put('dueDate', String.valueOf(System.today().addDays(10)));
      arguments.put('vendorComments', 'adsfa');
      arguments.put('', '');
      AppraisalMergeController.submitOrder(p.Id, arguments);
  
      Appraisal__c app = [SELECT Id FROM Appraisal__c LIMIT 1];
  
      AppraisalMergeController.checkStatus(app.Id);
  
      // Database.executeBatch(new ClearCapitalBatch(), 1);
      AppraisalMergeController.retrieveOrderUSRES(app.Id);
  
      Test.stopTest();
    }
  
    static testMethod void unittest11() {
      Property__c p = [SELECT Id FROM Property__c LIMIT 1];
      p.Property_Type__c = '2-4 Unit';
      p.Number_of_Units__c = 2;
      update p;
      Test.startTest();
      // System.enqueueJob(new SmartyStreetsQueueable(new List<Id>{ p.Id }));
  
      Map<String, Object> arguments = new Map<String, Object>();
      arguments.put('appraisalFirm', 'US RES');
      arguments.put('productType', 'Exterior Appraisal');
      arguments.put('rushOrder', false);
      // arguments.put('turnTime', '48');
      // arguments.put('dueDate', String.valueOf(System.today().addDays(10)));
      arguments.put('vendorComments', 'adsfa');
      arguments.put('', '');
      AppraisalMergeController.submitOrder(p.Id, arguments);
  
      Appraisal__c app = [SELECT Id FROM Appraisal__c LIMIT 1];
  
      AppraisalMergeController.checkStatus(app.Id);
  
      // Database.executeBatch(new ClearCapitalBatch(), 1);
      AppraisalMergeController.retrieveOrderUSRES(app.Id);
      // AppraisalMergeController.refreshAppraisalStatus(new List<Id>{ app.Id });
      List<Appraisal__c> queriedApps = [
        SELECT
          id,
          createddate,
          report_type__c,
          appraisal_firm_transaction_id__c,
          appraisal_product_ordered__c,
          property__r.deal__r.recordtype.developername,
          Vendor_Ordered_From__c
        FROM appraisal__c
        WHERE
          Id = :app.Id
          AND appraisal_firm_transaction_id__c != NULL
          AND Vendor_Ordered_From__c = 'US RES'
        ORDER BY createddate DESC
      ];
  
    //   Map<String, Object> resp = USResAPI.getAppraisalDetail(
    //     queriedApps[0].Appraisal_Firm_Transaction_ID__c,
    //     queriedApps[0].property__r.deal__r.recordtype.developername,
    //     app.Id
    //   );
      Test.stopTest();
    }
  
    static testMethod void unittest12() {
      Property__c p = [SELECT Id FROM Property__c LIMIT 1];
      p.Property_Type__c = '2-4 Unit';
      p.Number_of_Units__c = 2;
      update p;
      Test.startTest();
      // System.enqueueJob(new SmartyStreetsQueueable(new List<Id>{ p.Id }));
  
      Map<String, Object> arguments = new Map<String, Object>();
      arguments.put('appraisalFirm', 'US RES');
      arguments.put('productType', 'Desktop Summary Appraisal');
      arguments.put('rushOrder', false);
      // arguments.put('turnTime', '48');
      // arguments.put('dueDate', String.valueOf(System.today().addDays(10)));
      arguments.put('vendorComments', 'adsfa');
      arguments.put('', '');
      AppraisalMergeController.submitOrder(p.Id, arguments);
  
      Appraisal__c app = [SELECT Id FROM Appraisal__c LIMIT 1];
  
      AppraisalMergeController.checkStatus(app.Id);
  
      // Database.executeBatch(new ClearCapitalBatch(), 1);
      AppraisalMergeController.retrieveOrderUSRES(app.Id);
  
      Test.stopTest();
    }

    static testMethod void unittest13() {
      Property__c p = [SELECT Id FROM Property__c LIMIT 1];
      p.Property_Type__c = '2-4 Unit';
      p.Number_of_Units__c = 2;
      update p;
      Test.startTest();
      // System.enqueueJob(new SmartyStreetsQueueable(new List<Id>{ p.Id }));
  
      Map<String, Object> arguments = new Map<String, Object>();
      arguments.put('appraisalFirm', 'US RES');
      arguments.put('productType', 'Interior Appraisal');
      arguments.put('rushOrder', false);
      // arguments.put('turnTime', '48');
      // arguments.put('dueDate', String.valueOf(System.today().addDays(10)));
      arguments.put('vendorComments', 'adsfa');
      arguments.put('', '');
      AppraisalMergeController.submitOrder(p.Id, arguments);
  
      Appraisal__c app = [SELECT Id FROM Appraisal__c LIMIT 1];
  
      AppraisalMergeController.checkStatus(app.Id);
  
      // Database.executeBatch(new ClearCapitalBatch(), 1);
      AppraisalMergeController.retrieveOrderUSRES(app.Id);
  
      Test.stopTest();
    }
  
    static testMethod void unittest14() {
      Property__c p = [SELECT Id FROM Property__c LIMIT 1];
      p.Property_Type__c = '2-4 Unit';
      p.Number_of_Units__c = 2;
      update p;
      Test.startTest();
      // System.enqueueJob(new SmartyStreetsQueueable(new List<Id>{ p.Id }));
  
      Map<String, Object> arguments = new Map<String, Object>();
      arguments.put('appraisalFirm', 'US RES');
      arguments.put('productType', 'Final Inspection');
      arguments.put('rushOrder', false);
      // arguments.put('turnTime', '48');
      // arguments.put('dueDate', String.valueOf(System.today().addDays(10)));
      arguments.put('vendorComments', 'adsfa');
      arguments.put('', '');
      AppraisalMergeController.submitOrder(p.Id, arguments);
  
      Appraisal__c app = [SELECT Id FROM Appraisal__c LIMIT 1];
  
      AppraisalMergeController.checkStatus(app.Id);
  
      // Database.executeBatch(new ClearCapitalBatch(), 1);
      AppraisalMergeController.retrieveOrderUSRES(app.Id);
  
      Test.stopTest();
    }
  
    static testMethod void unittest15() {
      Property__c p = [SELECT Id FROM Property__c LIMIT 1];
      p.Property_Type__c = '2-4 Unit';
      p.Number_of_Units__c = 2;
      update p;
      Test.startTest();
      // System.enqueueJob(new SmartyStreetsQueueable(new List<Id>{ p.Id }));
  
      Map<String, Object> arguments = new Map<String, Object>();
      arguments.put('appraisalFirm', 'US RES');
      arguments.put('productType', 'Appraisal Update');
      arguments.put('rushOrder', false);
      // arguments.put('turnTime', '48');
      // arguments.put('dueDate', String.valueOf(System.today().addDays(10)));
      arguments.put('vendorComments', 'adsfa');
      arguments.put('', '');
      AppraisalMergeController.submitOrder(p.Id, arguments);
  
      Appraisal__c app = [SELECT Id FROM Appraisal__c LIMIT 1];
  
      AppraisalMergeController.checkStatus(app.Id);
  
      // Database.executeBatch(new ClearCapitalBatch(), 1);
      AppraisalMergeController.retrieveOrderUSRES(app.Id);
  
      Test.stopTest();
    }
  }