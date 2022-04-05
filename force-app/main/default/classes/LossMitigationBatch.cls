global class LossMitigationBatch implements Database.Batchable<sObject>, Database.Stateful {
  public LossMitigationBatch() {
  }

  public List<Opportunity> start(Database.BatchableContext BC) {
    List<Opportunity> deals = [
      SELECT Id, AccountId
      FROM Opportunity
      WHERE
        Loss_Mitigation_Associate__c = NULL
        AND Id IN (
          SELECT Deal__c
          FROM Property__c
          WHERE Updated_Asset_Maturity_Date__c = LAST_N_DAYS:60
        )
        AND AccountId IN (
          SELECT AccountId
          FROM AccountTeamMember
          WHERE TeamMemberRole = 'Loss Mitigation Associate'
        )
    ];
    return deals;
  }

	public void execute(Database.BatchableContext BC, List<Opportunity> scope) {
		Set<Id> accountIds = new Set<Id>();
		List<Opportunity> updatedDeals = new List<Opportunity>();

		for(Opportunity deal : scope) {
			accountIds.add(deal.AccountId);
		}

		Map<Id,Account> accMap = new Map<Id,Account>([
			SELECT Id, (
				SELECT UserId, AccountId
				FROM AccountTeamMembers
				WHERE TeamMemberRole = 'Loss Mitigation Associate'
			)
			FROM Account
			WHERE Id IN :accountIds
		]);

		for(Opportunity deal : scope) {
			Account acc = accMap.get(deal.AccountId);
			if(acc != null && acc.AccountTeamMembers != null && acc.AccountTeamMembers.size() > 0) {
				deal.Loss_Mitigation_Associate__c = acc.AccountTeamMembers[0].UserId;
				updatedDeals.add(deal);
			}
		}

		if(updatedDeals.size() > 0) {
			update updatedDeals;
		}
	}

	public void finish(Database.BatchableContext BC) {
    List<AsyncApexJob> jobs = [
      SELECT
        Id,
        status,
        createddate,
        NumberOfErrors,
        JobItemsProcessed,
        TotalJobItems,
        CompletedDate
      FROM AsyncApexJob
      WHERE
        Id = :BC.getJobId()
        AND completeddate > :Datetime.now().addMinutes(-2)
        AND Status IN ('Aborted', 'Completed')
        AND JobType != 'BatchApexWorker'
      ORDER BY createddate DESC
      LIMIT 1
    ];

    if (jobs.size() > 0) {
      sendCompletedEmail(jobs[0]);
    }
  }

  public static void sendCompletedEmail(AsyncApexJob job) {
    Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();

    email.setToAddresses(
      new List<String>{
        'ldecastro@mkpartners.com',
        'logins+cvest@mkpartners.com'
        ,
        'integrations@cvest.com',
        'jonathan.lay@cvest.com',
        'bryon.harland@cvest.com'
      }
    );
    OrgWideEmailAddress owea = new OrgWideEmailAddress();
    owea = [
      SELECT Id, Address, DisplayName
      FROM OrgWideEmailAddress
      WHERE DisplayName = 'Integrations User'
    ];


    String body = 'Batch ' + job.Status + '.\n';
    body += '\nTotal Job Items: ' + job.TotalJobItems;
    body += '\nJob Items Processed: ' + job.JobItemsProcessed;
    body += '\nNumber of Errors: ' + job.NumberOfErrors;
    body += '\nStatus: ' + job.Status;
    body +=
      '\nStarted Date: ' +
      job.CreatedDate.format('MM/dd/yyyy HH:mm:ss', 'America/Los_Angeles');
    body +=
      '\nCompleted Date: ' +
      job.CompletedDate.format('MM/dd/yyyy HH:mm:ss', 'America/Los_Angeles');
    // if (job.NumberOfErrors > 0) {
    //   body += '\n\nPlease refer to separate email with details about the error.';
    // }
    if (owea != null) {
      email.setOrgWideEmailAddressId(owea.Id);
    }

    email.setPlainTextbody(body);
    email.setSubject('Loss Mitigation Batch ' + job.Status);

    Messaging.sendEmail(new List<Messaging.SIngleEmailMessage>{ email });
  }
}
