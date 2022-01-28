public class SourceToLeadBatch implements Database.Batchable<sObject> {
  public static final Map<String, String> fieldMapping = new Map<String, String>{
    'Account_Converted_Into__c' => 'Account_Converted_Into__c',
    'Company' => 'Company__c',
    'Conference_Year__c' => 'Conference_Year__c',
    'Contact_Converted_Into__c' => 'Contact_Converted_Into__c',
    'Contact_Notes__c' => 'Contact_Notes__c',
    'CreatedById' => 'CreatedById',
    'CreatedDate' => 'CreatedDate',
    'CTM_Ring_Time__c' => 'CTM_Ring_Time__c',
    'Deal_Converted_Into__c' => 'Deal_Converted_Into__c',
    'Email' => 'Email__c',
    'Existing_Contact__c' => 'Existing_Contact__c',
    'First_Touch_checkbox__c' => 'first_Touch_checkbox__c',
    'IsConverted' => 'IsConvertedLead__c',
    'IsDeleted' => 'IsDeleted__c',
    // 'LastModifiedDate' => 'LastModifiedDate',
    // 'LastActivityDate' => 'LastActivityDate',
    // 'LastModifiedById' => 'LastModifiedById',
    // 'LastReferencedDate' => 'LastReferencedDate',
    // 'LastViewedDate' => 'LastViewedDate',
    'Id' => 'lead_id__c',
    'FirstName' => 'Lead_First_Name__c',
    'LastName' => 'Lead_Last_Name__c',
    'Full_Name__c' => 'Lead_Name__c',
    'Status' => 'Primary_Lead_status__c',
    'Loan_Product_s__c' => 'Primary_Loan_Product__c',
    'MobilePhone' => 'Mobile__c',
    'Phone' => 'Phone__c',
    'Source__c' => 'Primary_Source__c',
    'Referral_Source__c' => 'Referral_Source__c',
    'Referral_Source_Contact__c' => 'Referral_Source_Contact__c',
    'Referring_URL__c' => 'Referring_URL__c',
    'Requested_Loan_Size__c' => 'Requested_Loan_Size__c',
    // 'SystemModstamp' => 'SystemModstamp',
    'True_source__c' => 'True_source__c',
    'utm_Campaign_Content__c' => 'utm_Campaign_Content__c',
    'utm_Campaign_Medium__c' => 'utm_Campaign_Medium__c',
    'utm_Campaign_Name__c' => 'utm_Campaign_Name__c',
    'utm_Campaign_Source__c' => 'utm_Campaign_Source__c',
    'utm_Campaign_Term__c' => 'utm_Campaign_Term__c'
  };

  public Database.QueryLocator start(Database.BatchableContext BC) {
    List<String> fieldsList = new List<String>();
    fieldsList.addAll(fieldMapping.keySet());
    String fields = String.join(fieldsList, ',');

    String q =
      'SELECT ' +
      fields +
      ' FROM Lead WHERE Id NOT IN (SELECT Lead__c FROM Source__c)';
    // String q = 'SELECT ' + fields + ' FROM Lead WHERE Id = \'00Q0a00000lqxn5EAA\' ';
    // String q = 'SELECT ' + fields + ' FROM Lead WHERE Id NOT IN (SELECT Lead__c FROM Source__c) AND CALENDAR_MONTH(CreatedDate) IN (3) AND CALENDAR_YEAR(CreatedDate) IN (2015)';

    return Database.getQueryLocator(q);
  }

  public void execute(Database.BatchableContext BC, List<Lead> scope) {
    List<Source__c> convertedSources = new List<Source__c>();

    for (Lead s : scope) {
      convertedSources.add(createSourceRecord(s));
    }

    try {
      if (Test.isRunningTest() && scope[0].FirstName == 'EXCEPTION') {
        throw new DmlException('Test Exception');
      }
      upsert convertedSources;
    } catch (Exception err) {
      String a = [
        SELECT a.Name, a.Id
        FROM ApexClass a
        WHERE a.Name LIKE 'source%' AND (NOT a.Name LIKE '%test%')
        LIMIT 1
      ]
      .Id;

      List<AsyncApexJob> jobs = [
        SELECT Id, createddate
        FROM AsyncApexJob
        WHERE ApexClassID = :a AND status != 'completed' AND status != 'aborted'
      ];

      for (AsyncApexJob j : jobs) {
        System.abortJob(j.Id);
      }

      Integer remainingRecords = scope.size() * jobs.size();

      sendExceptionEmails(err, jobs.size(), remainingRecords);
    }
  }

  public void finish(Database.BatchableContext BC) {
    String a = [
      SELECT a.Name, a.Id
      FROM ApexClass a
      WHERE a.Name LIKE 'source%' AND (NOT a.Name LIKE '%test%')
      LIMIT 1
    ]
    .Id;

    List<AsyncApexJob> jobs = [
      SELECT
        Id,
        status,
        createddate,
        NumberOfErrors,
        JobItemsProcessed,
        TotalJobItems
      FROM AsyncApexJob
      WHERE
        ApexClassID = :a
        AND completeddate > :Datetime.now().addMinutes(-2)
        AND Status IN ('Aborted', 'Completed')
      ORDER BY createddate DESC
      LIMIT 1
    ];

    if (jobs.size() > 0) {
      sendCompletedEmail(jobs[0]);
    }
  }

  public static Source__c createSourceRecord(Lead l) {
    Source__c s = new Source__c();
    s.Lead__c = l.Id;
    for (String key : fieldMapping.keySet()) {
      s.put(fieldMapping.get(key), l.get(key));
    }

    return s;
  }

  public static void sendExceptionEmails(
    Exception ex,
    Integer jobCount,
    Integer remainingRecords
  ) {
    Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();

    email.setToAddresses(new List<String>{ 'ldecastro@mkpartners.com','liron.dco@gmail.com' });
    OrgWideEmailAddress owea = new OrgWideEmailAddress();
    owea = [
      SELECT Id, Address, DisplayName
      FROM OrgWideEmailAddress
      WHERE DisplayName = 'Integrations User'
    ];
    String body = '';
    body += 'Line Number: ' + ex.getLineNumber();
    body += '\nStacktrace: ' + ex.getStackTraceString();
    body += '\nType: ' + ex.getTypeName();
    body += '\nMessage:  ' + ex.getMessage();
    body += '\nAborted Job Count: ' + jobCount;
    body += '\nRemaining Records (Approx.): ' + remainingRecords;

    if ( owea != null) {
      email.setOrgWideEmailAddressId(owea.Id);
    }
    email.setPlainTextbody(body);
    email.setSubject('Lead to Source Batch Error');

    Messaging.sendEmail(new List<Messaging.SIngleEmailMessage>{ email });
  }

  public static void sendCompletedEmail(AsyncApexJob job) {
    Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();

    email.setToAddresses(new List<String>{ 'ldecastro@mkpartners.com','liron.dco@gmail.com' });
    OrgWideEmailAddress owea = new OrgWideEmailAddress();
    owea = [
      SELECT Id, Address, DisplayName
      FROM OrgWideEmailAddress
      WHERE DisplayName = 'Integrations User'
    ];

    String body = 'Batch Completed.';
    body += '\nTotal Job Items: ' + job.TotalJobItems;
    body += '\nJob Items Processed: ' + job.JobItemsProcessed;
    body += '\nNumber of Errors: ' + job.NumberOfErrors;
    body += '\nStatus: ' + job.Status;

    if (job.NumberOfErrors > 0) {
      body += '\nPlease refer to separate email with details about the error.';
    }
    if ( owea != null) {
      email.setOrgWideEmailAddressId(owea.Id);
    }

    email.setPlainTextbody(body);
    email.setSubject('Lead to Source Batch Completed');

    Messaging.sendEmail(new List<Messaging.SIngleEmailMessage>{ email });
  }
}
