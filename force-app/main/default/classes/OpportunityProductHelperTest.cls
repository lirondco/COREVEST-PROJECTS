@isTest
public with sharing class OpportunityProductHelperTest {
  @isTest
  public static void OpportunityProductHelperTest1() {
    Account testAcct = Test_Helper.createAccount();
    Contact testCont = Test_Helper.createContact(testAcct);

    Product2 p = new Product2();
    p.Name = ' Test Product ';
    p.Description = 'Test Product Entry For Product';
    p.productCode = 'Term_Loan';
    p.isActive = true;
    insert p;

    PricebookEntry standardPrice = new PricebookEntry();
    standardPrice.Pricebook2Id = Test.getStandardPricebookId();
    standardPrice.Product2Id = p.Id;
    standardPrice.UnitPrice = 100;
    standardPrice.IsActive = true;
    standardPrice.UseStandardPrice = false;
    insert standardPrice;

    Opportunity testDeal = Test_Helper.createTermDeal(testAcct, testCont);

    OpportunityLineItem oppLineItem = new OpportunityLineItem();
    oppLineItem.OpportunityId = testDeal.Id;
    oppLineItem.PricebookEntryId = standardPrice.Id;
    oppLineItem.UnitPrice = 7000;
    oppLineItem.Quantity = 5;
    insert oppLineItem;

    Product_Goal__c testPg = new Product_Goal__c();
    testPg.Amount__c = 1;
    testPg.Month_Start_Date__c = Date.newInstance(1990, 11, 1);
    testPg.Product__c = 'Term';
    testPg.Name = 'TEST PRODUCT GOAL';
    insert testPg;

    testDeal.Loan_Size__c = 1;
    testDeal.CloseDate = Date.newInstance(1990, 11, 14);
    testDeal.Current_Loan_Amount__c = null;
    testDeal.Final_Loan_Amount__c = null;
    update testDeal;

    update opportunity_Helper.updateOppLineItems(new Map<Id, Opportunity>{testDeal.Id => testDeal}, 'ServiceDate', 'CloseDate');
    update opportunity_Helper.updateOppLineItems(new Map<Id, Opportunity>{testDeal.Id => testDeal}, 'UnitPrice', 'Loan_Size__c');

    OpportunityLineItem updatedOli = [
      SELECT Id, Product_Goal__c, UnitPrice, ProductCode, ServiceDate
      FROM OpportunityLineItem
      WHERE Id = :oppLineItem.Id
      LIMIT 1
    ];


    System.assertEquals('Term_Loan', updatedOli.ProductCode, 'ProductCode should be Term_Loan');
    System.assertEquals(
      testDeal.Loan_Size__c,
      updatedOli.UnitPrice,
      'UnitPrice should match Loan Size.'
    );
    System.assertEquals(
      testDeal.CloseDate,
      updatedOli.ServiceDate,
      'ServiceDate and CloseDate should match.'
    );
    System.assertEquals(
      testPg.Id,
      updatedOli.Product_Goal__c,
      'Should have updated the product goal.'
    );

  }
}