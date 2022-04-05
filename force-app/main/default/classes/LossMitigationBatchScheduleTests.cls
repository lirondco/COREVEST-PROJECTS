@isTest
public with sharing class LossMitigationBatchScheduleTests {
  @TestSetup
  static void makeData() {
    Account a = Test_Helper.createAccount();
    Contact c = Test_Helper.createContact(a);
    Opportunity o = Test_Helper.createOpportunity(a, c);
    List<Property__c> props = Test_Helper.createProperties(o);
    for(Property__c p : props) {
      p.Updated_Asset_Maturity_Date__c = System.today();
    }
    update props;
    AccountTeamMember act = new AccountTeamMember();
    act.UserId = UserInfo.getUserId();
    act.AccountId = a.Id;
    act.TeamMemberRole = 'Loss Mitigation Associate';
    insert act;
  }

  @isTest
  public static void testSchedule() {
    Integer yearPlusOne = System.today().year() + 1;
    String cron = '0 0 0 15 3 ? ' + yearPlusOne;

    Test.startTest();
    System.schedule('Test Schedule', cron, new LossMitigationSchedule());
    Test.stopTest();

    List<AsyncApexJob> jobsScheduled = [
      SELECT Id, ApexClassID, ApexClass.Name, Status, JobType
      FROM AsyncApexJob
      WHERE JobType = 'ScheduledApex'
    ];
    System.assertEquals(1, jobsScheduled.size(), 'expecting one scheduled job');
    System.assertEquals(
      'LossMitigationSchedule',
      jobsScheduled[0].ApexClass.Name,
      'expecting specific scheduled job'
    );

    // check apex batch is in the job list
    List<AsyncApexJob> jobsApexBatch = [
      SELECT Id, ApexClassID, ApexClass.Name, Status, JobType
      FROM AsyncApexJob
      WHERE JobType = 'BatchApex'
    ];
    System.assertEquals(
      1,
      jobsApexBatch.size(),
      'expecting one apex batch job'
    );
    System.assertEquals(
      'LossMitigationBatch',
      jobsApexBatch[0].ApexClass.Name,
      'expecting specific batch job'
    );
  }

  @isTest
  public static void testBatchClass() {
    Opportunity o = [SELECT Id, Loss_Mitigation_Associate__c FROM Opportunity LIMIT 1];
    System.assertEquals(true, o.Loss_Mitigation_Associate__c == null, 'expecting no loss mitigation associate');
    Test.startTest();
    Database.executeBatch(new LossMitigationBatch(), 1);
    Test.stopTest();
    o = [SELECT Id, Loss_Mitigation_Associate__c FROM Opportunity LIMIT 1];
    System.assertEquals(
      true,
      o.Loss_Mitigation_Associate__c != null,
      'expecting loss mitigation associate'
    );
  }
}
