public class CTMtoLead {

	public static CTM_Settings__c ctmSettings = CTM_Settings__c.getInstance();
	static String ACCESS_KEY = ctmSettings.Access_Key__c;
	static String SECRET_KEY = ctmSettings.Secret_Key__c;
	static String BASE_URL = ctmSettings.Endpoint__c; //https://api.calltrackingmetrics.com/api/v1/accounts/34785/

	public static String callout(String method, String endpoint, String body, Map<String, String> headers) {
		HttpResponse response;
		HttpRequest request;

		request = new httpRequest();
		request.setTimeout(60000);
		request.setMethod(method);
		request.setEndpoint(endpoint);
		if (headers != null) {
			for (String key : headers.keySet()) {
				request.setHeader(key, headers.get(key));
			}
		}
		if (body != null) {
			request.setBody(body);
		}
		response = new Http().send(request);
		return response.getBody();
	}

	public class CtmData {
		List<CallClass> calls;
		String next_page;

		public CtmData(Map<String, Object> ctmDataMap) {
			next_page = (String)ctmDataMap.get('next_page');

			calls = new List<CallClass>();
			if (ctmDataMap.containsKey('calls') && ctmDataMap.get('calls') != null) {
				List<Object> callsList = (List<Object>)ctmDataMap.get('calls');
				for (Object call : callsList) {
					calls.add(new CallClass((Map<String, Object>)call));
				}
			}
		}
	}

	public class CallClass {
		Boolean mediumExists;
		Boolean adContentExists;
		Boolean campaignExists;
		Boolean sourceExists;
		Boolean keywordExists;
		String campaign;
		String source;
		String tracking_label;
		String medium;
		String keyword;
		Integer ring_time;
		String referrer;
		String caller_number_bare;
		String caller_number_format;
		String called_at;
		String web_source;
		String ad_content;
		PaidClass paid;
		GaClass ga;

		public CallClass(Map<String, Object> callMap) {
			mediumExists = callMap.containsKey('medium');
			adContentExists = callMap.containsKey('ad_content');
			campaignExists = callMap.containsKey('campaign');
			sourceExists = callMap.containsKey('source');
			keywordExists = callMap.containsKey('keyword');

			campaign = (String)callMap.get('campaign');
			source = (String)callMap.get('source');
			tracking_label = (String)callMap.get('tracking_label');
			medium = (String)callMap.get('medium');
			keyword = (String)callMap.get('keyword');
			ring_time = (Integer)callMap.get('ring_time');
			referrer = (String)callMap.get('referrer');
			caller_number_bare = (String)callMap.get('caller_number_bare');
			caller_number_format = (String)callMap.get('caller_number_format');
			called_at = (String)callMap.get('called_at');
			web_source = (String)callMap.get('web_source');
			ad_content = (String)callMap.get('ad_content');

			if (callmap.containsKey('ga') && callMap.get('ga') != null) {
				ga = new GaClass((Map<String, Object>)callMap.get('ga'));
			}

			if (callmap.containsKey('paid') && callMap.get('paid') != null) {
				paid = new PaidClass((Map<String, Object>)callMap.get('paid'));
			}
		}
	}

	public class PaidClass {
		Boolean mediumExists;
		Boolean adContentExists;
		Boolean campaignExists;
		Boolean sourceExists;
		Boolean keywordExists;
		String source;
		String campaign;
		String medium;
		String keyword;
		String ad_content;

		public PaidClass(Map<String, Object> paidMap) {
			mediumExists = paidMap.containsKey('medium');
			adContentExists = paidMap.containsKey('ad_content');
			campaignExists = paidMap.containsKey('campaign');
			sourceExists = paidMap.containsKey('source');
			keywordExists = paidMap.containsKey('keyword');

			campaign = (String)paidMap.get('campaign');
			source = (String)paidMap.get('source');
			medium = (String)paidMap.get('medium');
			keyword = (String)paidMap.get('keyword');
			ad_content = (String)paidMap.get('ad_content');
		}
	}

	public class GaClass {
		Boolean mediumExists;
		Boolean adContentExists;
		Boolean campaignExists;
		Boolean sourceExists;
		Boolean keywordExists;
		String source;
		String campaign;
		String medium;
		String keyword;
		String ad_content;

		public GaClass(Map<String, Object> gaMap) {
			mediumExists = gaMap.containsKey('medium');
			adContentExists = gaMap.containsKey('ad_content');
			campaignExists = gaMap.containsKey('campaign');
			sourceExists = gaMap.containsKey('source');
			keywordExists = gaMap.containsKey('keyword');

			campaign = (String)gaMap.get('campaign');
			source = (String)gaMap.get('source');
			medium = (String)gaMap.get('medium');
			keyword = (String)gaMap.get('keyword');
			ad_content = (String)gaMap.get('ad_content');
		}
	}



	public static List<CallClass> getCtmCalls(Date startDate, Date endDate) {
		String method = 'GET';

		// if (queryDate == null) {
		// 	queryDate = Date.Today().addDays(-1);
		// }
		System.debug('startDate');
		System.debug(startDate);
		String formattedStartDate = startDate.year() + '-' + startDate.month() + '-' + startDate.day();
		String formattedEndDate = endDate.year() + '-' + endDate.month() + '-' + endDate.day();
		String perPage = '100';
		String endpoint = BASE_URL + '/calls?' + 'per_page=' + perPage + '&start_date=' + formattedStartDate + '&end_date=' + formattedEndDate + '&order=metrics';
		System.debug('endpoint');
		System.debug(endpoint);


		String body = null;

		String base64EncodedAuth = EncodingUtil.base64Encode(Blob.valueOf(ACCESS_KEY + ':' + SECRET_KEY));
		Map<String, String> headers = new Map<String, String>();
		headers.put('Authorization', 'Basic ' + base64EncodedAuth);
		headers.put('Accept', 'application/json');

		System.debug(88888444);
		List<CallClass> callClasses = new List<CallClass>();
		Integer callOutCount = 0;
		while (callOutCount < 10) {
			String rawJSON = callOut(method, endpoint, body, headers);
			System.debug(rawJSON);
			CtmData ctmData = new CtmData((Map<String, Object>)JSON.deserializeUntyped(rawJSON));
			//CtmData ctmData = (CtmData)JSON.deserialize(rawJSON, CtmData.class);
			System.debug(123);
			if (ctmData.calls != null) {
				callClasses.addAll(ctmData.calls);
			}
			callOutCount++;
			System.debug(ctmData.next_page);
			if (ctmData.next_page == null) {
				break;
			}
			else {
				endpoint = ctmData.next_page;
			}
		}
		System.debug(132424);
		System.debug(callClasses.size());
		return callClasses;
	}

	public static Boolean hasUtmParameters(CallClass call) {
		hasRingTime(call);
		hasLeadSource(call);
		hasCampaign(call);
		hasMedium(call);
		hasContent(call);
		hasKeyword(call);
		hasSource(call);
		hasReferrer(call);

		return hasCampaign(call) || hasMedium(call) || hasKeyword(call) || hasSource(call) || hasContent(call);
	}

	public static Boolean hasRingTime(CallClass call) {
		return call.ring_time != null;
	}

	public static Boolean hasLeadSource(CallClass call) {
		return (call.source != null || call.tracking_label != null);
	}

	public static Boolean hasCampaign(CallClass call) {
		return ( call.campaign != null || (call.paid != null && call.paid.campaign != null) || (call.ga != null && call.ga.campaign != null) );
	}

	public static Boolean hasMedium(CallClass call) {
		return ( call.medium != null || (call.paid != null && call.paid.medium != null) || (call.ga != null && call.ga.medium != null) );
	}

	public static Boolean hasKeyword(CallClass call) {
		return ( call.keyword != null || (call.paid != null && call.paid.keyword != null) || (call.ga != null && call.ga.keyword != null) );
	}

	public static Boolean hasSource(CallClass call) {
		return ( (call.paid != null && call.paid.source != null) || (call.ga != null && call.ga.source != null) || (call.web_source != null) );
	}

	public static Boolean hasReferrer(CallClass call) {
		return call.referrer != null && call.referrer != '';
	}

	public static Boolean hasContent(CallClass call) {
		return ( call.ad_content != null || (call.paid != null && call.paid.ad_content != null) || (call.ga != null && call.ga.ad_content != null) );
	}

	public static Datetime getCtmCallDatetime(String calledAt) {
		List<String> calledAtSplit = calledAt.split(' ');
		String hourStr = calledAtSplit[1].substring(0, 2);
		String minStr = calledAtSplit[1].substring(3, 5);
		String amPm = calledAtSplit[2];
		//String offset = calledAtSplit[3];
		//Integer offsetDirection = offset.subString(0, 1) == '-' ? 1 : -1;
		//String offsetHourStr = offset.subString(1).split(':')[0];
		//String offsetMinStr = offset.subString(1).split(':')[1];

		if (hourStr != '12' && amPm == 'PM') {
			hourStr = String.valueOf(Integer.valueOf(hourStr) + 12);
		}
		else if (hourStr == '12' && amPm == 'AM') {
			hourStr = '00';
		}
		//hourStr = String.valueOf(Integer.valueOf(hourStr) + offsetDirection * Integer.valueOf(offsetHourStr));
		//minStr = String.valueOf(Integer.valueOf(minStr) + offsetDirection * Integer.valueOf(offsetMinStr));

		String correctFormat = calledAtSplit[0] + ' ' + hourStr + ':' + minStr + ':00';
		return Datetime.valueOfGMT(correctFormat);
	}

	public static void updateLeads(Date startDate, Date endDate, Boolean globalJob) {
		List<CallClass> calls = getCtmCalls(startDate, endDate);

		Set<String> ctmNumbers = new Set<String>();
		Map<String, List<CallClass>> numberToCallMap = new Map<String, List<CallClass>>();

		if (globalJob) {
			for (Integer i = 0; i < calls.size(); i++) {
				CallClass call = calls[i];
				String formattedNumber = call.caller_number_bare;
				if (formattedNumber == null && call.caller_number_format != null) {
					formattedNumber = removeNonDigits(call.caller_number_format);
				}
				if (formattedNumber != null && (hasUtmParameters(call) || hasReferrer(call) || hasRingTime(call))) {
					ctmNumbers.add(formattedNumber);
					if (numberToCallMap.get(formattedNumber) == null) {
						numberToCallMap.put(formattedNumber, new List<CallClass>());
					}
					List<CallClass> callsList = numberToCallMap.get(formattedNumber);
					callsList.add(call);
					numberToCallMap.put(formattedNumber, callsList);
				}
			}
		}
		else {
			for (Integer i = calls.size() - 1; i >= 0; i--) {
				CallClass call = calls[i];
				String formattedNumber = call.caller_number_bare;
				if (formattedNumber == null && call.caller_number_format != null) {
					formattedNumber = removeNonDigits(call.caller_number_format);
				}
				if (formattedNumber != null && (hasUtmParameters(call) || hasReferrer(call) || hasRingTime(call))) {
					ctmNumbers.add(formattedNumber);
					if (numberToCallMap.get(formattedNumber) == null) {
						numberToCallMap.put(formattedNumber, new List<CallClass>());
					}
					List<CallClass> callsList = numberToCallMap.get(formattedNumber);
					callsList.add(call);
					numberToCallMap.put(formattedNumber, callsList);
				}
			}
		}

		System.debug(ctmNumbers);

		List<Lead> leadsToUpdate = new List<Lead>();
		List<Contact> contactsToUpdate = new List<Contact>();
		Set<Id> convertedContactIdSet = new Set<Id>();
		Map<Id, Lead> leadMapForSource = new Map<Id, Lead>();

		for (Lead l : [SELECT Id, CreatedDate, Introduction_Source__c, ConvertedContactId, Formatted_Phone__c, Updated_By_CTM__c, Updated_UTM_by_CTM__c, Updated_Referrer_by_CTM__c, utm_Campaign_Content__c, utm_Campaign_Medium__c, utm_Campaign_Name__c, utm_Campaign_Source__c, utm_Campaign_Term__c, Referring_URL_Text__c, CTM_Ring_Time__c,
		                      ConvertedContact.Id, ConvertedContact.Updated_By_CTM__c, ConvertedContact.Updated_UTM_by_CTM__c, ConvertedContact.Updated_Referrer_by_CTM__c, ConvertedContact.utm_Campaign_Content__c, ConvertedContact.utm_Campaign_Medium__c, ConvertedContact.utm_Campaign_Name__c,
													Referring_URL__c, ConvertedContact.utm_Campaign_Source__c, ConvertedContact.utm_Campaign_Term__c, ConvertedContact.Referring_URL_Text__c
									 FROM Lead
									 WHERE
									   Formatted_Phone__c != null
									 AND
									   Formatted_Phone__c IN :ctmNumbers]) {

			List<CallClass> matchedCalls = numberToCallMap.get(l.Formatted_Phone__c);
			Contact c = l.ConvertedContact == null ? new Contact() : l.ConvertedContact;


			for (CallClass matchedCall : matchedCalls) {

				Datetime matchedCallDatetime = getCtmCallDatetime(matchedCall.called_at);

				if (matchedCallDatetime < l.CreatedDate) {

					if ((globalJob && hasUtmParameters(matchedCall)) || (!globalJob && !l.Updated_by_CTM__c && hasUtmParameters(matchedCall))) {
						updateLead(l, matchedCall);
						l.Updated_by_CTM__c = True;
						l.Updated_UTM_by_CTM__c = True;
						l.Updated_Referrer_by_CTM__c = False;

						if (c.Id != null) {
							//Contact c = l.ConvertedContact;
							updateContact(c, matchedCall);
							c.Updated_by_CTM__c = True;
							c.Updated_UTM_by_CTM__c = True;
							c.Updated_Referrer_by_CTM__c = False;
							//convertedContactIdSet.add(l.ConvertedContact.Id);
							//contactsToUpdate.add(c);
						}
					}
					else if (!l.Updated_UTM_by_CTM__c && hasReferrer(matchedCall) && hasRingTime(matchedCall)) {
						updateLead(l, matchedCall);
						l.Updated_by_CTM__c = True;
						l.Updated_Referrer_by_CTM__c = True;

						if (c.Id != null) {
							//Contact c = l.ConvertedContact;
							updateContact(c, matchedCall);
							c.Updated_by_CTM__c = True;
							c.Updated_Referrer_by_CTM__c = True;
							//convertedContactIdSet.add(l.ConvertedContact.Id);
							//contactsToUpdate.add(c);
						}
					}
					else if (!l.Updated_UTM_by_CTM__c && !l.Updated_Referrer_by_CTM__c && hasRingTime(matchedCall)) {
						updateLead(l, matchedCall);
						l.Updated_by_CTM__c = True;

						if (c.Id != null) {
							//Contact c = l.ConvertedContact;
							updateContact(c, matchedCall);
							c.Updated_by_CTM__c = True;
							//convertedContactIdSet.add(l.ConvertedContact.Id);
							//contactsToUpdate.add(c);
						}
					}

				}
			}
			if (l.Updated_By_CTM__c) {
				leadsToUpdate.add(l);
				if(l.Introduction_Source__c == 'Hotline') {
					leadMapForSource.put(l.Id, l);
				}
				if (c.Id != null && !convertedContactIdSet.contains(c.Id)) {
					contactsToUpdate.add(c);
					convertedContactIdSet.add(c.Id);
				}
			}
		}
		System.debug(90);
		System.debug(contactsToUpdate);
		System.debug(leadsToUpdate);
		System.debug(999991);
		Database.update(leadsToUpdate, false);
		System.debug(999992);
		Database.update(contactsToUpdate, false);

		if(leadMapForSource.size() > 0) {
			updateSources(leadMapForSource);
		}


	}

	public static void updateSources(Map<Id, Lead> leadMap) {
		List<Source__c> sourcesToUpdate = new List<Source__c>();

		for(Source__c s: [
			SELECT Id, Lead__c
			FROM Source__c
			WHERE Lead__c IN :leadMap.keySet()
		]) {
			Lead sourceLead = leadMap.get(s.Lead__c);
			s.utm_Campaign_Content__c = sourceLead.utm_Campaign_Content__c != null ? sourceLead.utm_Campaign_Content__c : null;
			s.utm_Campaign_Medium__c = sourceLead.utm_Campaign_Medium__c != null ? sourceLead.utm_Campaign_Medium__c : null;
			s.utm_Campaign_Name__c = sourceLead.utm_Campaign_Name__c != null ? sourceLead.utm_Campaign_Name__c : null;
			s.utm_Campaign_Source__c = sourceLead.utm_Campaign_Source__c != null ? sourceLead.utm_Campaign_Source__c : null;
			s.utm_Campaign_Term__c = sourceLead.utm_Campaign_Term__c != null ? sourceLead.utm_Campaign_Term__c : null;
			s.CTM_Ring_Time__c = sourceLead.CTM_Ring_Time__c != null ? sourceLead.CTM_Ring_Time__c : null;
			s.Referring_URL__c = sourceLead.Referring_URL__c != null ? sourceLead.Referring_URL__c : null;
			sourcesToUpdate.add(s);
		}

		List<Database.SaveResult> saveResults = Database.update(sourcesToUpdate, false);

		for(Database.SaveResult s : saveResults) {
			if(!s.isSuccess()) {
				for(Database.Error err : s.getErrors()) {
					System.debug('The following error has occurred.');                    
					System.debug(err.getStatusCode() + ': ' + err.getMessage());
					System.debug('Source__c fields that affected this error: ' + err.getFields());
				}
			}
		}
	}


	public static String removeNonDigits(String phone) {
		return phone.replaceAll('\\D','');
	}

	public static void updateLead(Lead l, CallClass matchedCall) {

		if (matchedCall.mediumExists) {
			l.utm_Campaign_Medium__c = matchedCall.medium;
		}
		else if (matchedCall.ga != null && matchedCall.ga.mediumExists) {
			l.utm_Campaign_Medium__c = matchedCall.ga.medium;
		}
		else if (matchedCall.paid != null && matchedCall.paid.mediumExists) {
			l.utm_Campaign_Medium__c = matchedCall.paid.medium;
		}
		else {
			l.utm_Campaign_Medium__c = null;
		}

		if (matchedCall.adContentExists) {
			l.utm_Campaign_Content__c = matchedCall.ad_content;
		}
		else if (matchedCall.ga != null && matchedCall.ga.adContentExists) {
			l.utm_Campaign_Content__c = matchedCall.ga.ad_content;
		}
		else if (matchedCall.paid != null && matchedCall.paid.adContentExists) {
			l.utm_Campaign_Content__c = matchedCall.paid.ad_content;
		}
		else {
			l.utm_Campaign_Content__c = null;
		}

		if (matchedCall.campaignExists) {
			l.utm_Campaign_Name__c = matchedCall.campaign;
		}
		else if (matchedCall.ga != null && matchedCall.ga.campaignExists) {
			l.utm_Campaign_Name__c = matchedCall.ga.campaign;
		}
		else if (matchedCall.paid != null && matchedCall.paid.campaignExists) {
			l.utm_Campaign_Name__c = matchedCall.paid.campaign;
		}
		else {
			l.utm_Campaign_Name__c = null;
		}

		if (matchedCall.ga != null && matchedCall.ga.sourceExists) {
			l.utm_Campaign_Source__c = matchedCall.ga.source;
		}
		else if (matchedCall.paid != null && matchedCall.paid.sourceExists) {
			l.utm_Campaign_Source__c = matchedCall.paid.source;
		}
		else if (matchedCall.web_source != null) {
			l.utm_Campaign_Source__c = matchedCall.web_source;
		}
		else {
			l.utm_Campaign_Source__c = null;
		}

		if (matchedCall.sourceExists) {
			l.LeadSource = matchedCall.source;
		}
		else if (matchedCall.tracking_label != null) {
			l.LeadSource = matchedCall.tracking_label;
		}
		else {
			l.LeadSource = null;
		}

		if (matchedCall.keywordExists) {
			l.utm_Campaign_Term__c = matchedCall.keyword;
		}		
		else if (matchedCall.ga != null && matchedCall.ga.keywordExists) {
			l.utm_Campaign_Term__c = matchedCall.ga.keyword;
		}
		else if (matchedCall.paid != null && matchedCall.paid.keywordExists) {
			l.utm_Campaign_Term__c = matchedCall.paid.keyword;
		}
		else {
			l.utm_Campaign_Term__c = null;
		}

		l.Referring_URL_Text__c = matchedCall.referrer;

		l.CTM_Ring_Time__c = matchedCall.ring_time != null ? String.valueOf(matchedCall.ring_time) : null;

	}

	public static void updateContact(Contact c, CallClass matchedCall) {

		if (matchedCall.adContentExists) {
			c.utm_Campaign_Content__c = matchedCall.ad_content;
		}
		else if (matchedCall.ga != null && matchedCall.ga.adContentExists) {
			c.utm_Campaign_Content__c = matchedCall.ga.ad_content;
		}
		else if (matchedCall.paid != null && matchedCall.paid.adContentExists) {
			c.utm_Campaign_Content__c = matchedCall.paid.ad_content;
		}
		else {
			c.utm_Campaign_Content__c = null;
		}

		if (matchedCall.mediumExists) {
			c.utm_Campaign_Medium__c = matchedCall.medium;
		}
		else if (matchedCall.ga != null && matchedCall.ga.mediumExists) {
			c.utm_Campaign_Medium__c = matchedCall.ga.medium;
		}
		else if (matchedCall.paid != null && matchedCall.paid.mediumExists) {
			c.utm_Campaign_Medium__c = matchedCall.paid.medium;
		}
		else {
			c.utm_Campaign_Medium__c = null;
		}

		if (matchedCall.campaignExists) {
			c.utm_Campaign_Name__c = matchedCall.campaign;
		}
		else if (matchedCall.ga != null && matchedCall.ga.campaignExists) {
			c.utm_Campaign_Name__c = matchedCall.ga.campaign;
		}
		else if (matchedCall.paid != null && matchedCall.paid.campaignExists) {
			c.utm_Campaign_Name__c = matchedCall.paid.campaign;
		}
		else {
			c.utm_Campaign_Name__c = null;
		}

		if (matchedCall.ga != null && matchedCall.ga.sourceExists) {
			c.utm_Campaign_Source__c = matchedCall.ga.source;
		}
		else if (matchedCall.paid != null && matchedCall.paid.sourceExists) {
			c.utm_Campaign_Source__c = matchedCall.paid.source;
		}
		else if (matchedCall.web_source != null) {
			c.utm_Campaign_Source__c = matchedCall.web_source;
		}
		else {
			c.utm_Campaign_Source__c = null;
		}

		if (matchedCall.sourceExists) {
			c.LeadSource = matchedCall.source;
		}
		else if (matchedCall.tracking_label != null) {
			c.LeadSource = matchedCall.tracking_label;
		}
		else {
			c.LeadSource = null;
		}

		if (matchedCall.keywordExists) {
			c.utm_Campaign_Term__c = matchedCall.keyword;
		}
		else if (matchedCall.ga != null && matchedCall.ga.keywordExists) {
			c.utm_Campaign_Term__c = matchedCall.ga.keyword;
		}
		else if (matchedCall.paid != null && matchedCall.paid.keywordExists) {
			c.utm_Campaign_Term__c = matchedCall.paid.keyword;
		}
		else {
			c.utm_Campaign_Term__c = null;
		}

		c.Referring_URL_Text__c = matchedCall.referrer;

		c.CTM_Ring_Time__c = matchedCall.ring_time != null ? String.valueOf(matchedCall.ring_time) : null;

	}

}