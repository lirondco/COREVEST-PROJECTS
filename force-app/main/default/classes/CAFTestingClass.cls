public without sharing class CAFTestingClass {
  public static final List<String> VALID_DOCTYPES = new List<String>{
    'Application',
    'CAF Application'
  };

  public static void checkUploadedDocs(Map<Id, Deal_Document__c> oldDocs, Map<Id, Deal_Document__c> dealDocs) {
    List<Id> applicationDocs = new List<Id>();
    List<String> cvIds = new List<String>();
    for (Deal_Document__c doc : dealDocs.values()) {
      Deal_Document__c oldDoc = oldDocs.get(doc.Id);
      if (VALID_DOCTYPES.contains(doc.Document_Type__c) && doc.ContentVersion_Id__c != null) {
        applicationDocs.add(doc.Id);
        cvIds.add(doc.ContentVersion_Id__c);
      }
    }

    if (applicationDocs.size() > 0) {
      sendEmails(applicationDocs, cvIds);
    }
  }

  public static void sendEmails(List<Id> docIds, List<String> cvIds) {
    List<Deal_Document__c> dealdocs = [
      SELECT
        Id,
        CreatedById,
        CreatedBy.UserRole.DeveloperName,
        CreatedBy.Name,
        Deal__c,
        Deal__r.StageName,
        Deal__r.Name,
        Deal__r.OwnerId,
        Deal__r.Owner.Name,
        Deal__r.CloseDate,
        Deal__r.Deal_Loan_Number__c,
        ContentVersion_Id__c
      FROM Deal_Document__c
      WHERE Id IN :docIds
    ];

    List<ContentVersion> cvs = [
      SELECT Id, Title, PathOnClient, FileType, VersionData
      FROM ContentVersion
      WHERE Id IN :cvIds
    ];
    System.debug('cvs: ' + cvs);
    List<OrgWideEmailAddress> owas = [
      SELECT Id, Address, DisplayName
      FROM OrgWideEmailAddress
      WHERE Address = 'caf-apps@cvest.com'
    ];

    Map<Id, Messaging.EmailFileAttachment> attachmentsMap = new Map<Id, Messaging.EmailFileAttachment>();

    for (ContentVersion c : cvs) {
      Blob data = c.VersionData;
      Messaging.EmailFileAttachment efa1 = new Messaging.EmailFileAttachment();
      if (data.size() > 0) {
        efa1.setBody(data);
        efa1.setFileName(c.Title);
        attachmentsMap.put(c.Id, efa1);
      }
    }

    Map<String, CAFTestSetting__mdt> settingsMap = new Map<String, CAFTestSetting__mdt>{
      'Bridge' => CAFTestSetting__mdt.getInstance('Bridge'),
      'Term' => CAFTestSetting__mdt.getInstance('Term'),
      'Origination' => CAFTestSetting__mdt.getInstance('Origination'),
      'SandboxTester' => CAFTestSetting__mdt.getInstance('SandboxTester')
    };

    List<EmailServicesAddress> esas = [
      SELECT Id, LocalPart, EmailDomainName
      FROM EmailServicesAddress
      WHERE DeveloperName = 'Deal_Email_Handler'
    ];

    String emailServiceEmail;

    if (esas.size() > 0) {
      emailServiceEmail = esas[0].LocalPart + '@' + esas[0].EmailDomainName;
    }

    List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();

    for (Deal_Document__c doc : dealdocs) {
      CAFTestSetting__mdt setting = new CAFTestSetting__mdt();
      if(Test.isRunningTest()) {
        setting.Active__c = true;
        setting.RecipientEmail__c = 'test@domain.ua';
      }
      else if (settingsMap.get('SandboxTester') != null) {
        setting = settingsMap.get('SandboxTester');
      } else {
        setting = settingsMap.get(
          doc.CreatedBy.UserRole.DeveloperName.replace('_Manager', '')
        );
      }
      if (
        setting != null &&
        setting.Active__c &&
        String.isNotEmpty(setting.RecipientEmail__c)
      ) {
        String subject =
          'CAF Application Uploaded for Deal: #' +
          doc.Deal__r.Deal_Loan_Number__c +
          ' ' +
          doc.Deal__r.Name;
        String dealLink =
          URL.getOrgDomainUrl().toExternalForm() +
          '/' +
          doc.Deal__c;

        DateTime dt = doc.Deal__r.CloseDate;
        Date myDate;
        String dateString = 'N/A';
        if(dt != null) {
            myDate = date.newInstance(dt.year(), dt.month(), dt.day());
            dateString = String.valueOf(myDate);
        }

        String htmlBody =
          '<p>A CAF Application was uploaded in Salesforce. Please run a Clear Background Check, if needed.</p>' +
          '<p><a href="' +
          dealLink +
          '">' +
          doc.Deal__r.Name +
          '</a>' +
          '<span>&nbsp;|&nbsp;Deal Stage: ' +
          doc.Deal__r.StageName +
          ' | Deal Close Date: ' +
          dateString +
          ' | CAF Originator: ' +
          doc.Deal__r.Owner.Name +
          '</span>' +
          '</p>' +
          '<p> Uploaded By: ' +
          doc.CreatedBy.Name +
          '</p>';

        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();

        email.setToAddresses(new List<String>{ setting.RecipientEmail__c });

        email.setFileAttachments(
          new List<Messaging.EmailFileAttachment>{
            attachmentsMap.get(doc.ContentVersion_Id__c)
          }
        );
        email.setSubject(subject);
        email.setHtmlBody(htmlBody);
        if (owas.size() > 0) {
          email.setOrgWideEmailAddressId(owas[0].Id);
        }
        if (String.isNotEmpty(emailServiceEmail)) {
          email.setBccAddresses(new List<String>{ emailServiceEmail });
        }
        emails.add(email);
      } else {
        continue;
      }
    }

    if (emails.size() > 0) {
      Messaging.sendEmail(emails);
    }
  }
}
