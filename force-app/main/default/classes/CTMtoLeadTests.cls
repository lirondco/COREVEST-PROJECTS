@isTest
public class CTMtoLeadTests {
  @TestSetup
  static void setupData() {
    List<Lead> sampleLeads = new List<Lead>();
    List<Master_Source__c> sampleMasterSources = new List<Master_Source__c>();
    List<Source__c> sampleSources = new List<Source__c>();

    Lead ld = new Lead();
    ld.LastName = 'Doe';
    ld.FirstName = 'John';
    ld.Company = 'Test';
    ld.Status = 'Open';
    ld.Phone = '5165266300';
    ld.Email = '5165266300@gmail.com';
    ld.Introduction_Source__c = 'Hotline';
    ld.Introduction_Subsource__c = 'Pardot';
    ld.Street = '123 test st';
    ld.City = 'Irvine';
    sampleLeads.add(ld);

    Master_Source__c ms = new Master_Source__c();
    ms.Name = 'Hotline';
    ms.Email__c = ld.Email;
    ms.First_Name__c = ld.FirstName;
    ms.Last_Name__c = ld.LastName;
    ms.Mobile__c = ld.Phone;
    sampleMasterSources.add(ms);

    Lead ld2 = new Lead();
    ld2.LastName = 'Doe2';
    ld2.FirstName = 'John2';
    ld2.Company = 'Test';
    ld2.Status = 'Open';
    ld2.Phone = '6098618891';
    ld2.Email = '6098618891@gmail.com';
    ld2.Introduction_Source__c = 'Hotline';
    ld2.Introduction_Subsource__c = 'Pardot';
    ld2.Street = '123 test st';
    ld2.City = 'Irvine';
    sampleLeads.add(ld2);

    Master_Source__c ms2 = new Master_Source__c();
    ms2.Name = 'Hotline';
    ms2.Email__c = ld2.Email;
    ms2.First_Name__c = ld2.FirstName;
    ms2.Last_Name__c = ld2.LastName;
    ms2.Mobile__c = ld2.Phone;
    sampleMasterSources.add(ms2);

    Lead ld3 = new Lead();
    ld3.LastName = 'Doe3';
    ld3.FirstName = 'John';
    ld3.Company = 'Test';
    ld3.Status = 'Open';
    ld3.Phone = '9042386718';
    ld3.Email = '9042386718@gmail.com';
    ld3.Introduction_Source__c = 'Hotline';
    ld3.Introduction_Subsource__c = 'Pardot';
    ld3.Street = '123 test st';
    ld3.City = 'Irvine';
    sampleLeads.add(ld3);

    Master_Source__c ms3 = new Master_Source__c();
    ms3.Name = 'Hotline';
    ms3.Email__c = ld3.Email;
    ms3.First_Name__c = ld3.FirstName;
    ms3.Last_Name__c = ld3.LastName;
    ms3.Mobile__c = ld3.Phone;
    sampleMasterSources.add(ms3);

    Lead ld4 = new Lead();
    ld4.LastName = 'Doe4';
    ld4.FirstName = 'John2';
    ld4.Company = 'Test';
    ld4.Status = 'Open';
    ld4.Phone = '7175549417';
    ld4.Email = '7175549417@gmail.com';
    ld4.Introduction_Source__c = 'Hotline';
    ld4.Introduction_Subsource__c = 'Pardot';
    ld3.Street = '123 test st';
    ld3.City = 'Irvine';
    sampleLeads.add(ld4);

    Master_Source__c ms4 = new Master_Source__c();
    ms4.Name = 'Hotline';
    ms4.Email__c = ld4.Email;
    ms4.First_Name__c = ld4.FirstName;
    ms4.Last_Name__c = ld4.LastName;
    ms4.Mobile__c = ld4.Phone;
    sampleMasterSources.add(ms4);

    Lead ld5 = new Lead();
    ld5.LastName = 'Doe5';
    ld5.FirstName = 'John';
    ld5.Company = 'Test';
    ld5.Status = 'Open';
    ld5.Phone = '9103548743';
    ld5.Email = '9103548743@gmail.com';
    ld5.Introduction_Source__c = 'Hotline';
    ld5.Introduction_Subsource__c = 'Pardot';
    ld5.Street = '123 test st';
    ld5.City = 'Irvine';
    sampleLeads.add(ld5);

    Master_Source__c ms5 = new Master_Source__c();
    ms5.Name = 'Hotline';
    ms5.Email__c = ld5.Email;
    ms5.First_Name__c = ld5.FirstName;
    ms5.Last_Name__c = ld5.LastName;
    ms5.Mobile__c = ld5.Phone;
    sampleMasterSources.add(ms5);

    Lead ld6 = new Lead();
    ld6.LastName = 'Doe6';
    ld6.FirstName = 'John2';
    ld6.Company = 'Test';
    ld6.Status = 'Open';
    ld6.Phone = '2817634217';
    ld6.Email = '2817634217@gmail.com';
    ld6.Introduction_Source__c = 'Hotline';
    ld6.Introduction_Subsource__c = 'Pardot';
    ld6.Street = '123 test st';
    ld6.City = 'Irvine';
    sampleLeads.add(ld6);

    Master_Source__c ms6 = new Master_Source__c();
    ms6.Name = 'Hotline';
    ms6.Email__c = ld6.Email;
    ms6.First_Name__c = ld6.FirstName;
    ms6.Last_Name__c = ld6.LastName;
    ms6.Mobile__c = ld6.Phone;
    sampleMasterSources.add(ms6);

    List<Database.SaveResult> leadResults = Database.insert(sampleLeads, false);
    List<Database.SaveResult> masterResults = Database.insert(
      sampleMasterSources, false
    );

    LeadStatus convertStatus = [SELECT Id, MasterLabel FROM LeadStatus WHERE IsConverted=true LIMIT 1];
    List<Database.LeadConvert> convertedLeads = new List<Database.LeadConvert>();
    for (Integer i = 0; i < leadResults.size(); i++) {
      if (leadResults[i].isSuccess() && masterResults[i].isSuccess()) {
        Lead l = sampleLeads[i];
        l.Id = leadResults[i].getId();
        Master_Source__c m = sampleMasterSources[i];
        m.Id = masterResults[i].getId();
        Database.LeadConvert lc = new Database.LeadConvert();
        lc.setLeadId(l.Id);
        lc.setConvertedStatus(convertStatus.MasterLabel);
        convertedLeads.add(lc);

        Source__c sc = new Source__c();
        sc.Lead__c = l.Id;
        sc.Master_Source__c = m.Id;
        sc.Lead_Name__c = l.FirstName + ' ' + l.LastName;
        sampleSources.add(sc);
      } else {
        String errorMessage = '';
        if(leadResults[i].getErrors() != null && leadResults[i].getErrors().size() > 0) {
          errorMessage += leadResults[i].getErrors()[0].getMessage() + '\n';
        } else if(masterResults[i].getErrors() != null && masterResults[i].getErrors().size() > 0) {
          errorMessage += masterResults[i].getErrors()[0].getMessage();
        }
        throw new DmlException(
          errorMessage
        );
      }
    }

    List<Database.SaveResult> sourceResults = Database.insert(sampleSources);
    if(convertedLeads.size() > 0) {
      Database.convertLead(convertedLeads);
    }
  }
  
  @isTest
  private static void testCTMtoLead() {
    test.startTest();
    test.setMock(HttpCalloutMock.class, new MockCTMtoLeadCallout());
    AllCTMtoLeadBatchable b = new AllCTMtoLeadBatchable();
    b.lastDate = System.today().addDays(-1);
    Database.executeBatch(b);
    test.stopTest();

   

    Lead ld = [
      SELECT utm_Campaign_Content__c, Id, ConvertedContactId
      FROM Lead
      WHERE utm_Campaign_Content__c != null
      AND Introduction_Source__c = 'Hotline'
      LIMIT 1
    ];

    Source__c sc = [
      SELECT utm_Campaign_Content__c, Id
      FROM Source__c
      WHERE Lead__c = :ld.Id
      LIMIT 1
    ];

    

    System.assertEquals(ld.utm_Campaign_Content__c, sc.utm_Campaign_Content__c, 'Campaign content should match');
  }

  public class MockCTMtoLeadCallout implements HttpCalloutMock {
    public HttpResponse respond(HTTPRequest request) {
      String endpoint = request.getEndpoint();
      String method = request.getMethod();
      HttpResponse response = new HttpResponse();
      response.setBody(
        '{"calls":[{"id":527960343,"sid":"CA01a55661ff94d0e242d9f309a6292c76","account_id":34785,"name":"Gerardi Propert","cnam":"GARDEN CITY, NY","search":"(not provided)","referrer":"https://www.google.com/","location":"https://www.corevestfinance.com/?&utm_source=google&utm_medium=cpc&utm_campaign=branded&utm_term=corevest&utm_network=g&utm_device=c&utm_content=V2&gclid=CjwKCAiA7vTiBRAqEiwA4NTO6zBixFHeIZxEzts6UpsPVePOT6XW7wExgGwD6zbEVowwYjLMcz3wkxoCBIYQAvD_BwE","source_id":82443,"source_sid":"TSOF6FC2D2594D22C528265C519C54257E4AB68C5D55BCF168AB109A73B91EBA036","tgid":1847491,"likelihood":62.5038,"duration":253,"direction":"inbound","talk_time":251,"ring_time":2,"hold_time":0,"parent_id":null,"email":null,"street":"","city":"Garden City","state":"NY","country":"US","postal_code":"11040","called_at":"2019-02-08 08:45 AM -08:00","unix_time":1549644332,"tracking_number_id":142125,"tracking_number_sid":"TPNC3C4B23C348AEC2EE54EFD301979CD2E5AEC7ABEAAD87415694D17BBC3DBBAEA","tracking_number":"+18443361233","dial_status":"completed","is_new_caller":true,"indexed_at":1549644644.9025092,"last_location":"https://www.corevestfinance.com/?&utm_source=google&utm_medium=cpc&utm_campaign=branded&utm_term=corevest&utm_network=g&utm_device=c&utm_content=V2&gclid=CjwKCAiA7vTiBRAqEiwA4NTO6zBixFHeIZxEzts6UpsPVePOT6XW7wExgGwD6zbEVowwYjLMcz3wkxoCBIYQAvD_BwE","inbound_rate_center":{"country":"US","prefix":"1","tollfree":true},"business_number":"+19493536847","business_label":"RingDNA Sales Hotline","receiving_number_id":955824,"receiving_number_sid":"RPN34D8AC3F61E8848FEA641CEF711011AAB8018611126A36376E273D4AF8CFD7EAF59710E7B4E9D61A","billed_amount":2500,"billed_at":"2019-02-08T16:49:45","caller_number_split":["1","516","526","6300"],"contact_number":"+15165266300","excluded":false,"redacted":false,"tracking_number_format":"(844) 336-1233","business_number_format":"(949) 353-6847","caller_number_format":"(516) 526-6300","alternative_number":"5165266300","caller_number_complete":"+15165266300","caller_number_bare":"5165266300","tracking_number_bare":"8443361233","caller_number":"+15165266300","visitor":true,"call_path":[{"route_name":"RingDNA Sales Hotline","route_id":"RPN34D8AC3F61E8848FEA641CEF711011AAB8018611126A36376E273D4AF8CFD7EAF59710E7B4E9D61A","route_type":"PhysicalPhoneNumber","started_at":"2019-02-08T08:45:32Z"}],"left_talk_time":158,"right_talk_time":176,"transfers":[],"call_status":"answered","status":"answered","spotted":[],"salesforce":{},"audio":"https://app.calltrackingmetrics.com/api/v1/accounts/34785/calls/CA01a55661ff94d0e242d9f309a6292c76/recording","callbacks":[],"emails":[],"webvisit":{"score":62.5038,"keywords":"(not provided)","referrer_host":"www.google.com","referrer_path":"/","location_host":"www.corevestfinance.com","location_path":"/","browser":"Chrome","device":"Windows","mobile":"desktop"},"day":"Friday","month":"February","hour":"08AM","visitor_ip":"71.223.68.95","tag_list":[],"notes":"","latitude":40.8152,"longitude":-73.5006,"extended_lookup_on":false,"extended_lookup":{"first_name":null,"last_name":null,"name_type":"B","phone_type":"mobile","business_name":"Gerardi Propert","street_number":null,"street_name":null,"gender":null,"city":"Garden City Park","state":"NY","zipcode":"11040","facebook":null,"linkedin":null,"twitter":null,"education":null,"language":null,"carrier":null,"age":null,"high_net_worth":null,"home_owner_status":null,"household_income":null,"marital_status":null,"length_of_residence":null,"market_value":null,"occupation":null,"presence_of_children":null},"legs":[]},{"id":527926356,"sid":"CAe59b3095af0049af9112ed57452fabb4","account_id":34785,"name":"E Velazquez","cnam":"E Velazquez","search":"","referrer":"","location":"","source_id":82446,"source_sid":"TSOF6FC2D2594D22C528265C519C54257E4AB68C5D55BCF168AF14C13C22E4BB2C8","tgid":634706,"likelihood":null,"duration":58,"direction":"inbound","talk_time":57,"ring_time":1,"hold_time":0,"parent_id":null,"email":null,"street":"","city":"Woodbine","state":"NJ","country":"US","postal_code":"08232","called_at":"2019-02-08 08:18 AM -08:00","unix_time":1549642685,"tracking_number_id":142128,"tracking_number_sid":"TPNC3C4B23C348AEC2EE54EFD301979CD2E5AEC7ABEAAD87415A283C722D1ADE16F","tracking_number":"+18443360233","tracking_label":"AdWords ad extension","dial_status":"completed","is_new_caller":true,"indexed_at":1549644665.3404844,"inbound_rate_center":{"country":"US","prefix":"1","tollfree":true},"business_number":"+19493536847","business_label":"RingDNA Sales Hotline","receiving_number_id":955824,"receiving_number_sid":"RPN34D8AC3F61E8848FEA641CEF711011AAB8018611126A36376E273D4AF8CFD7EAF59710E7B4E9D61A","billed_amount":500,"billed_at":"2019-02-08T16:19:03","caller_number_split":["1","609","861","8891"],"contact_number":"+16098618891","excluded":false,"redacted":false,"tracking_number_format":"(844) 336-0233","business_number_format":"(949) 353-6847","caller_number_format":"(609) 861-8891","alternative_number":"6098618891","caller_number_complete":"+16098618891","caller_number_bare":"6098618891","tracking_number_bare":"8443360233","caller_number":"+16098618891","visitor":false,"call_path":[{"route_name":"RingDNA Sales Hotline","route_id":"RPN34D8AC3F61E8848FEA641CEF711011AAB8018611126A36376E273D4AF8CFD7EAF59710E7B4E9D61A","route_type":"PhysicalPhoneNumber","started_at":"2019-02-08T08:18:05Z"}],"left_talk_time":44,"right_talk_time":36,"transfers":[],"call_status":"answered","status":"answered","spotted":[],"salesforce":{"reference":"lead","url":"https://cvest.my.salesforce.com/00Q0a00000gWgRgEAK"},"audio":"https://app.calltrackingmetrics.com/api/v1/accounts/34785/calls/CAe59b3095af0049af9112ed57452fabb4/recording","callbacks":[],"emails":[],"day":"Friday","month":"February","hour":"08AM","tag_list":[],"notes":"","latitude":39.1762,"longitude":-74.8172,"extended_lookup_on":false,"extended_lookup":{"first_name":null,"last_name":null,"name_type":"B","phone_type":"mobile","business_name":null,"street_number":null,"street_name":null,"gender":null,"city":"Dennisville","state":"NJ","zipcode":"08232","facebook":null,"linkedin":null,"twitter":null,"education":null,"language":null,"carrier":null,"age":null,"high_net_worth":null,"home_owner_status":null,"household_income":null,"marital_status":null,"length_of_residence":null,"market_value":null,"occupation":null,"presence_of_children":null},"legs":[]},{"id":527909280,"sid":"CAf0541e5b892965e2d4c9e8607bf187b1","account_id":34785,"name":"SHARIE  MYRICK","cnam":"SHARIE MYRICK","search":"","referrer":"","location":"","source":"AdWords Ad Extension","source_id":82446,"source_sid":"TSOF6FC2D2594D22C528265C519C54257E4AB68C5D55BCF168AF14C13C22E4BB2C8","tgid":634706,"likelihood":null,"duration":32,"direction":"inbound","talk_time":31,"ring_time":1,"hold_time":0,"parent_id":null,"email":"SMYRICK73@YAHOO.COM","street":"10961 BURNT MILL RD APT 714","city":"Jacksonville","state":"FL","country":"US","postal_code":"32256","called_at":"2019-02-08 08:03 AM -08:00","unix_time":1549641813,"tracking_number_id":142128,"tracking_number_sid":"TPNC3C4B23C348AEC2EE54EFD301979CD2E5AEC7ABEAAD87415A283C722D1ADE16F","tracking_number":"+18443360233","tracking_label":"AdWords ad extension","dial_status":"completed","is_new_caller":true,"indexed_at":1549643761.7005725,"inbound_rate_center":{"country":"US","prefix":"1","tollfree":true},"business_number":"+19493536847","business_label":"RingDNA Sales Hotline","receiving_number_id":955824,"receiving_number_sid":"RPN34D8AC3F61E8848FEA641CEF711011AAB8018611126A36376E273D4AF8CFD7EAF59710E7B4E9D61A","billed_amount":500,"billed_at":"2019-02-08T16:04:06","caller_number_split":["1","904","238","6718"],"contact_number":"+19042386718","excluded":false,"redacted":false,"tracking_number_format":"(844) 336-0233","business_number_format":"(949) 353-6847","caller_number_format":"(904) 238-6718","alternative_number":"9042386718","caller_number_complete":"+19042386718","caller_number_bare":"9042386718","tracking_number_bare":"8443360233","caller_number":"+19042386718","visitor":false,"call_path":[{"route_name":"RingDNA Sales Hotline","route_id":"RPN34D8AC3F61E8848FEA641CEF711011AAB8018611126A36376E273D4AF8CFD7EAF59710E7B4E9D61A","route_type":"PhysicalPhoneNumber","started_at":"2019-02-08T08:03:33Z"}],"left_talk_time":16,"right_talk_time":24,"transfers":[],"call_status":"answered","status":"answered","spotted":[],"salesforce":{},"audio":"https://app.calltrackingmetrics.com/api/v1/accounts/34785/calls/CAf0541e5b892965e2d4c9e8607bf187b1/recording","callbacks":[],"emails":[],"day":"Friday","month":"February","hour":"08AM","paid":{"source":"google","medium":"cpc"},"ga":{"cid":"34785.527909280"},"tag_list":[],"notes":"","latitude":30.351,"longitude":-81.6466,"extended_lookup_on":false,"extended_lookup":{"first_name":"SHARIE","last_name":"MYRICK","name_type":"C","phone_type":null,"business_name":null,"street_number":"10961","street_name":"BURNT MILL RD APT 714","gender":null,"city":"JACKSONVILLE","state":"FL","zipcode":"32256","facebook":null,"linkedin":null,"twitter":null,"education":"Completed Grad School","language":"English","carrier":null,"age":"35-44","high_net_worth":"No","home_owner_status":null,"household_income":"$50,000-99,999","marital_status":"Single","length_of_residence":"5 - 10 years","market_value":"$125,000-149,999","occupation":"Other","presence_of_children":"0"},"legs":[]},{"id":527809149,"sid":"CA784b776095cf2b2d515378eb60dad151","account_id":34785,"name":"M  Steven","cnam":"M Steven","search":"arbir realty trust","referrer":"https://www.google.com/","location":"https://www.corevestfinance.com/products/?utm_source=google&utm_medium=cpc&utm_campaign=competitors&utm_term=arbor%20realty%20trust&utm_network=g&utm_device=m&utm_content=V3&gclid=EAIaIQobChMIjLaS4qms4AIVF4vICh09VQRVEAAYASABEgL7T_D_BwE","source":"Google Adwords","source_id":82443,"source_sid":"TSOF6FC2D2594D22C528265C519C54257E4AB68C5D55BCF168AB109A73B91EBA036","tgid":1847491,"likelihood":94.9147,"duration":130,"direction":"inbound","talk_time":129,"ring_time":1,"hold_time":0,"parent_id":null,"email":null,"street":"314 Cherrington Dr","city":"Harrisburg","state":"PA","country":"US","postal_code":"17110","called_at":"2019-02-08 06:22 AM -08:00","unix_time":1549635766,"tracking_number_id":142125,"tracking_number_sid":"TPNC3C4B23C348AEC2EE54EFD301979CD2E5AEC7ABEAAD87415694D17BBC3DBBAEA","tracking_number":"+18443361233","tracking_label":"Google Adwords","dial_status":"completed","is_new_caller":true,"indexed_at":1549638740.99827,"last_location":"https://www.corevestfinance.com/products/?utm_source=google&utm_medium=cpc&utm_campaign=competitors&utm_term=arbor%20realty%20trust&utm_network=g&utm_device=m&utm_content=V3&gclid=EAIaIQobChMIjLaS4qms4AIVF4vICh09VQRVEAAYASABEgL7T_D_BwE","inbound_rate_center":{"country":"US","prefix":"1","tollfree":true},"business_number":"+19493536847","business_label":"RingDNA Sales Hotline","receiving_number_id":955824,"receiving_number_sid":"RPN34D8AC3F61E8848FEA641CEF711011AAB8018611126A36376E273D4AF8CFD7EAF59710E7B4E9D61A","billed_amount":1500,"billed_at":"2019-02-08T14:24:56","caller_number_split":["1","717","554","9417"],"contact_number":"+17175549417","excluded":false,"redacted":false,"tracking_number_format":"(844) 336-1233","business_number_format":"(949) 353-6847","caller_number_format":"(717) 554-9417","alternative_number":"7175549417","caller_number_complete":"+17175549417","caller_number_bare":"7175549417","tracking_number_bare":"8443361233","caller_number":"+17175549417","visitor":true,"call_path":[{"route_name":"RingDNA Sales Hotline","route_id":"RPN34D8AC3F61E8848FEA641CEF711011AAB8018611126A36376E273D4AF8CFD7EAF59710E7B4E9D61A","route_type":"PhysicalPhoneNumber","started_at":"2019-02-08T06:22:46Z"}],"left_talk_time":46,"right_talk_time":90,"transfers":[],"call_status":"answered","status":"answered","spotted":[],"salesforce":{},"audio":"https://app.calltrackingmetrics.com/api/v1/accounts/34785/calls/CA784b776095cf2b2d515378eb60dad151/recording","callbacks":[],"emails":[],"campaign":"competitors","web_source":"google","medium":"cpc","keyword":"arbor realty trust","ad_match_type":"Exact","ad_content":"Alternative to {KeyWord:Home Loans}","ad_slot":null,"ad_slot_position":"1","ad_network":"Google Search","creative_id":"267478174959","ad_group_id":"44090263603","adgroup_id":"Legacy Competitors","campaign_id":"887202633","ad_format":"Text","ad_targeting_type":"Keyword","keyword_id":319286739773,"webvisit":{"score":94.9147,"keywords":"arbir realty trust","referrer_host":"www.google.com","referrer_path":"/","location_host":"www.corevestfinance.com","location_path":"/products/","browser":"Safari","device":"iPhone","mobile":"mobile"},"day":"Friday","month":"February","hour":"06AM","paid":{"keyword":"arbor realty trust","campaign":"competitors","ad_group":"Legacy Competitors","source":"google","medium":"cpc","ad_match_type":"Exact","ad_content":"Alternative to {KeyWord:Home Loans}","ad_slot_position":"1","ad_network":"Google Search","ad_format":"Text","ad_placement":null},"ga":{"utmz":"","utma":"","utmb":"","utmc":"","medium":"cpc","campaign":"competitors","cid":"GA1.2.594265502.1549635596","gclid":"EAIaIQobChMIjLaS4qms4AIVF4vICh09VQRVEAAYASABEgL7T_D_BwE","gclsrc":null,"events":["Calls:UA-99133242-1"]},"visitor_ip":"73.207.7.158","tag_list":[],"notes":"","latitude":40.2944,"longitude":-76.8938,"extended_lookup_on":false,"extended_lookup":{"first_name":"M","last_name":"Steven","name_type":"C","phone_type":"mobile","business_name":null,"street_number":"314","street_name":"Cherrington Dr","gender":"M","city":"Harrisburg","state":"PA","zipcode":"17110","facebook":null,"linkedin":null,"twitter":null,"education":null,"language":null,"carrier":null,"age":null,"high_net_worth":null,"home_owner_status":null,"household_income":null,"marital_status":null,"length_of_residence":null,"market_value":null,"occupation":null,"presence_of_children":null},"legs":[]},{"id":527790594,"sid":"CAd5f9cefefdbab29e7fb83f5b5fc19192","account_id":34785,"name":"MALEKA  MCDERMOTT","cnam":"MALEKA MCDERMOTT","search":"","referrer":"","location":"","source":"Website - Main","source_id":308066,"source_sid":"TSOF6FC2D2594D22C528265C519C54257E4771F9B78D04A0BA26D22F0E56EE1A402","tgid":2303169,"likelihood":null,"duration":16,"direction":"inbound","talk_time":14,"ring_time":2,"hold_time":0,"parent_id":null,"email":"JAWARIORM@YAHOO.COM","street":"621 BRADFORD DR","city":"Fayetteville","state":"NC","country":"US","postal_code":"28315","called_at":"2019-02-08 05:50 AM -08:00","unix_time":1549633825,"tracking_number_id":543479,"tracking_number_sid":"TPNC3C4B23C348AEC2EE54EFD301979CD2E5AEC7ABEAAD874159EC26DFBC66BD2BB","tracking_number":"+18442232231","tracking_label":"Website - Main","dial_status":"completed","is_new_caller":true,"indexed_at":1549635752.8449025,"inbound_rate_center":{"country":"US","prefix":"1","tollfree":true},"business_number":"+19493536847","business_label":"RingDNA Sales Hotline","receiving_number_id":955824,"receiving_number_sid":"RPN34D8AC3F61E8848FEA641CEF711011AAB8018611126A36376E273D4AF8CFD7EAF59710E7B4E9D61A","billed_amount":500,"billed_at":"2019-02-08T13:50:41","caller_number_split":["1","910","354","8743"],"contact_number":"+19103548743","excluded":false,"redacted":false,"tracking_number_format":"(844) 223-2231","business_number_format":"(949) 353-6847","caller_number_format":"(910) 354-8743","alternative_number":"9103548743","caller_number_complete":"+19103548743","caller_number_bare":"9103548743","tracking_number_bare":"8442232231","caller_number":"+19103548743","visitor":false,"call_path":[{"route_name":"RingDNA Sales Hotline","route_id":"RPN34D8AC3F61E8848FEA641CEF711011AAB8018611126A36376E273D4AF8CFD7EAF59710E7B4E9D61A","route_type":"PhysicalPhoneNumber","started_at":"2019-02-08T05:50:25Z"}],"left_talk_time":0,"right_talk_time":10,"transfers":[],"call_status":"answered","status":"answered","spotted":[],"salesforce":{},"audio":"https://app.calltrackingmetrics.com/api/v1/accounts/34785/calls/CAd5f9cefefdbab29e7fb83f5b5fc19192/recording","callbacks":[],"emails":[],"day":"Friday","month":"February","hour":"05AM","paid":{"source":"website","medium":"direct"},"ga":{"cid":"34785.527790594","events":["Calls:UA-99133242-1"]},"tag_list":[],"notes":"","latitude":35.0284,"longitude":-78.9704,"extended_lookup_on":false,"extended_lookup":{"first_name":"MALEKA","last_name":"MCDERMOTT","name_type":"C","phone_type":null,"business_name":null,"street_number":"621","street_name":"BRADFORD DR","gender":null,"city":"ABERDEEN","state":"NC","zipcode":"28315","facebook":null,"linkedin":null,"twitter":null,"education":"Completed High School","language":"English","carrier":null,"age":"25-34","high_net_worth":"No","home_owner_status":"Rent","household_income":"< $20,000","marital_status":"Single","length_of_residence":null,"market_value":null,"occupation":"Other","presence_of_children":"0"},"legs":[]},{"id":527706261,"sid":"CAeeb7c421ca57b886ea0f1c812bf77696","account_id":34785,"name":"Dulcesita  Rios","cnam":"Dulcesita Rios","search":"transactional lender who lends over one million","referrer":"https://www.google.com/","location":"https://www.corevestfinance.com/?&utm_source=google&utm_medium=cpc&utm_campaign=competitors&utm_term=lendingone.com&utm_network=g&utm_device=c&utm_content=V3&gclid=EAIaIQobChMInrm6gP2q4AIVCqhpCh1VdgkHEAAYASAAEgJJxPD_BwE","source":"Google Adwords","source_id":82443,"source_sid":"TSOF6FC2D2594D22C528265C519C54257E4AB68C5D55BCF168AB109A73B91EBA036","tgid":1847491,"likelihood":94.9289,"duration":38,"direction":"inbound","talk_time":36,"ring_time":2,"hold_time":0,"parent_id":null,"email":null,"street":"","city":"Houston","state":"TX","country":"US","postal_code":"77002","called_at":"2019-02-07 05:25 PM -08:00","unix_time":1549589122,"tracking_number_id":142125,"tracking_number_sid":"TPNC3C4B23C348AEC2EE54EFD301979CD2E5AEC7ABEAAD87415694D17BBC3DBBAEA","tracking_number":"+18443361233","tracking_label":"Google Adwords","dial_status":"completed","is_new_caller":true,"indexed_at":1549595548.9969463,"last_location":"https://www.corevestfinance.com/?&utm_source=google&utm_medium=cpc&utm_campaign=competitors&utm_term=lendingone.com&utm_network=g&utm_device=c&utm_content=V3&gclid=EAIaIQobChMInrm6gP2q4AIVCqhpCh1VdgkHEAAYASAAEgJJxPD_BwE","inbound_rate_center":{"country":"US","prefix":"1","tollfree":true},"business_number":"+19493536847","business_label":"RingDNA Sales Hotline","receiving_number_id":955824,"receiving_number_sid":"RPN34D8AC3F61E8848FEA641CEF711011AAB8018611126A36376E273D4AF8CFD7EAF59710E7B4E9D61A","billed_amount":500,"billed_at":"2019-02-08T01:26:00","caller_number_split":["1","281","763","4217"],"contact_number":"+12817634217","excluded":false,"redacted":false,"tracking_number_format":"(844) 336-1233","business_number_format":"(949) 353-6847","caller_number_format":"(281) 763-4217","alternative_number":"2817634217","caller_number_complete":"+12817634217","caller_number_bare":"2817634217","tracking_number_bare":"8443361233","caller_number":"+12817634217","visitor":true,"call_path":[{"route_name":"RingDNA Sales Hotline","route_id":"RPN34D8AC3F61E8848FEA641CEF711011AAB8018611126A36376E273D4AF8CFD7EAF59710E7B4E9D61A","route_type":"PhysicalPhoneNumber","started_at":"2019-02-07T17:25:22Z"}],"left_talk_time":20,"right_talk_time":28,"transfers":[],"call_status":"answered","status":"answered","spotted":[],"salesforce":{},"audio":"https://app.calltrackingmetrics.com/api/v1/accounts/34785/calls/CAeeb7c421ca57b886ea0f1c812bf77696/recording","callbacks":[],"emails":[],"campaign":"competitors","web_source":"google","medium":"cpc","keyword":"lendingone.com","ad_match_type":"Broad","ad_content":"Alternative to {KeyWord:Home Loans}","ad_slot":null,"ad_slot_position":"1","ad_network":"Google Search","creative_id":"267530097970","ad_group_id":"44090263843","adgroup_id":"Direct","campaign_id":"887202633","ad_format":"Text","ad_targeting_type":"Keyword","keyword_id":294938645947,"webvisit":{"score":94.9289,"keywords":"transactional lender who lends over one million","referrer_host":"www.google.com","referrer_path":"/","location_host":"www.corevestfinance.com","location_path":"/","browser":"Safari","device":"Macintosh","mobile":"desktop"},"day":"Thursday","month":"February","hour":"05PM","paid":{"keyword":"lendingone.com","campaign":"competitors","ad_group":"Direct","source":"google","medium":"cpc","ad_match_type":"Broad","ad_content":"Alternative to {KeyWord:Home Loans}","ad_slot_position":"1","ad_network":"Google Search","ad_format":"Text","ad_placement":null},"ga":{"utmz":"","utma":"","utmb":"","utmc":"","medium":"cpc","campaign":"competitors","cid":"GA1.2.1319637761.1549589054","gclid":"EAIaIQobChMInrm6gP2q4AIVCqhpCh1VdgkHEAAYASAAEgJJxPD_BwE","gclsrc":null,"events":["Calls:UA-99133242-1"]},"visitor_ip":"98.197.176.100","tag_list":[],"notes":"","latitude":29.834,"longitude":-95.4342,"extended_lookup_on":false,"extended_lookup":{"first_name":"Dulcesita","last_name":"Rios","name_type":"C","phone_type":"mobile","business_name":null,"street_number":null,"street_name":null,"gender":null,"city":"Houston","state":"TX","zipcode":"77002","facebook":null,"linkedin":null,"twitter":null,"education":null,"language":null,"carrier":null,"age":null,"high_net_worth":null,"home_owner_status":null,"household_income":null,"marital_status":null,"length_of_residence":null,"market_value":null,"occupation":null,"presence_of_children":null},"legs":[]},{"id":527702226,"sid":"CA4bc9518ed374365e026b2c29ba175e2c","account_id":34785,"name":"San Antonio, TX","cnam":"San Antonio, TX","search":"","referrer":"","location":"https://www.corevestfinance.com/partners/forms/","source":"Website - Partners","source_id":568268,"source_sid":"TSOF6FC2D2594D22C528265C519C54257E406D6822F1EC43661CBF16B0C2A362977","tgid":1902240,"likelihood":99.1967,"duration":32,"direction":"inbound","talk_time":30,"ring_time":2,"hold_time":0,"parent_id":null,"email":null,"street":"","city":"San Antonio","state":"TX","country":"US","postal_code":"78219","called_at":"2019-02-07 05:12 PM -08:00","unix_time":1549588379,"tracking_number_id":546836,"tracking_number_sid":"TPNC3C4B23C348AEC2EE54EFD301979CD2E5AEC7ABEAAD8741520BCC75DB35D37A0","tracking_number":"+18442628177","tracking_label":"Wholesale/Correspondent","dial_status":"completed","is_new_caller":true,"indexed_at":1549638741.1849787,"last_location":"https://www.corevestfinance.com/fix-flip-credit-line/","inbound_rate_center":{"country":"US","prefix":"1","tollfree":true},"business_number":"+19492887376","business_label":null,"receiving_number_id":859367,"receiving_number_sid":"RPN34D8AC3F61E8848FEA641CEF711011AAB8018611126A363706F59ADC1E7D80CDA28886C776FE82F1","billed_amount":500,"billed_at":"2019-02-08T01:13:31","caller_number_split":["1","210","840","5431"],"contact_number":"+12108405431","excluded":false,"redacted":false,"tracking_number_format":"(844) 262-8177","business_number_format":"(949) 288-7376","caller_number_format":"(210) 840-5431","alternative_number":"2108405431","caller_number_complete":"+12108405431","caller_number_bare":"2108405431","tracking_number_bare":"8442628177","caller_number":"+12108405431","visitor":true,"call_path":[{"route_name":null,"route_id":"RPN34D8AC3F61E8848FEA641CEF711011AAB8018611126A363706F59ADC1E7D80CDA28886C776FE82F1","route_type":"PhysicalPhoneNumber","started_at":"2019-02-07T17:12:59Z"}],"left_talk_time":8,"right_talk_time":22,"transfers":[],"call_status":"answered","status":"answered","spotted":[],"salesforce":{},"audio":"https://app.calltrackingmetrics.com/api/v1/accounts/34785/calls/CA4bc9518ed374365e026b2c29ba175e2c/recording","callbacks":[],"emails":[],"campaign":null,"web_source":"(direct)","medium":"(none)","keyword":null,"ad_match_type":null,"ad_content":null,"ad_slot":null,"ad_slot_position":null,"ad_network":null,"creative_id":null,"ad_group_id":null,"adgroup_id":null,"campaign_id":null,"ad_format":null,"ad_targeting_type":null,"webvisit":{"score":99.1967,"keywords":null,"referrer_host":null,"referrer_path":null,"location_host":"www.corevestfinance.com","location_path":"/partners/forms/","browser":"Chrome","device":"Android","mobile":"mobile"},"day":"Thursday","month":"February","hour":"05PM","paid":{"keyword":null,"campaign":null,"ad_group":null,"source":"(direct)","medium":"(none)","ad_match_type":null,"ad_content":null,"ad_slot_position":null,"ad_network":null,"ad_format":null,"ad_placement":null},"ga":{"utmz":"","utma":"","utmb":"","utmc":"","medium":"(none)","campaign":null,"cid":"GA1.2.286463129.1549581559","events":["Calls:UA-99133242-1"]},"visitor_ip":"107.77.200.24","tag_list":[],"notes":"","latitude":31.4628,"longitude":-99.333,"extended_lookup_on":false,"extended_lookup":{"first_name":null,"last_name":null,"name_type":"B","phone_type":"mobile","business_name":null,"street_number":null,"street_name":null,"gender":null,"city":"San Antonio","state":"TX","zipcode":"78219","facebook":null,"linkedin":null,"twitter":null,"education":null,"language":null,"carrier":null,"age":null,"high_net_worth":null,"home_owner_status":null,"household_income":null,"marital_status":null,"length_of_residence":null,"market_value":null,"occupation":null,"presence_of_children":null},"legs":[]},{"id":527648028,"sid":"CA8525e276ed3c6f5537b8520efc84ae39","account_id":34785,"name":"VENKAT SAI TATITURI","cnam":"VENKAT TATITURI","search":"","referrer":"","location":"","source":"Website - Main","source_id":308066,"source_sid":"TSOF6FC2D2594D22C528265C519C54257E4771F9B78D04A0BA26D22F0E56EE1A402","tgid":2303169,"likelihood":null,"duration":322,"direction":"inbound","talk_time":321,"ring_time":1,"hold_time":0,"parent_id":null,"email":"venkat.tatituri@gmail.com","street":"38850 FARWELL DRIVEAPT 6D","city":"Bridgeport","state":"CT","country":"US","postal_code":"94536","called_at":"2019-02-07 03:22 PM -08:00","unix_time":1549581755,"tracking_number_id":543479,"tracking_number_sid":"TPNC3C4B23C348AEC2EE54EFD301979CD2E5AEC7ABEAAD874159EC26DFBC66BD2BB","tracking_number":"+18442232231","tracking_label":"Website - Main","dial_status":"completed","is_new_caller":false,"indexed_at":1549583996.2628486,"inbound_rate_center":{"country":"US","prefix":"1","tollfree":true},"business_number":"+19493536847","business_label":"RingDNA Sales Hotline","receiving_number_id":955824,"receiving_number_sid":"RPN34D8AC3F61E8848FEA641CEF711011AAB8018611126A36376E273D4AF8CFD7EAF59710E7B4E9D61A","billed_amount":3000,"billed_at":"2019-02-07T23:27:58","caller_number_split":["1","203","224","8564"],"contact_number":"+12032248564","excluded":false,"redacted":false,"tracking_number_format":"(844) 223-2231","business_number_format":"(949) 353-6847","caller_number_format":"(203) 224-8564","alternative_number":"2032248564","caller_number_complete":"+12032248564","caller_number_bare":"2032248564","tracking_number_bare":"8442232231","caller_number":"+12032248564","visitor":false,"call_path":[{"route_name":"RingDNA Sales Hotline","route_id":"RPN34D8AC3F61E8848FEA641CEF711011AAB8018611126A36376E273D4AF8CFD7EAF59710E7B4E9D61A","route_type":"PhysicalPhoneNumber","started_at":"2019-02-07T15:22:35Z"}],"left_talk_time":176,"right_talk_time":208,"transfers":[],"call_status":"answered","status":"answered","spotted":[],"salesforce":{"reference":"lead","url":"https://cvest.my.salesforce.com/00Q0a00000gWb4JEAS"},"audio":"https://app.calltrackingmetrics.com/api/v1/accounts/34785/calls/CA8525e276ed3c6f5537b8520efc84ae39/recording","callbacks":[],"emails":[],"day":"Thursday","month":"February","hour":"03PM","paid":{"source":"website","medium":"direct"},"ga":{"cid":"34785.527648028","events":["Calls:UA-99133242-1"]},"tag_list":[],"notes":"","latitude":41.1787,"longitude":-73.2,"extended_lookup_on":false,"extended_lookup":{"first_name":"VENKAT","last_name":"TATITURI","name_type":"C","phone_type":null,"business_name":null,"street_number":"38850","street_name":"FARWELL DRIVEAPT 6D","gender":null,"city":"FREMONT","state":"CA","zipcode":"94536","facebook":null,"linkedin":null,"twitter":null,"education":null,"language":null,"carrier":null,"age":null,"high_net_worth":"No","home_owner_status":null,"household_income":null,"marital_status":null,"length_of_residence":null,"market_value":null,"occupation":null,"presence_of_children":"0"},"legs":[]},{"id":527644566,"sid":"CA152d978517a7b9ff8dfedbbff2aade5e","account_id":34785,"name":"Nhcc","cnam":"Nhcc ","search":"","referrer":"","location":"","source":"Website - Main","source_id":308066,"source_sid":"TSOF6FC2D2594D22C528265C519C54257E4771F9B78D04A0BA26D22F0E56EE1A402","tgid":2303169,"likelihood":null,"duration":199,"direction":"inbound","talk_time":197,"ring_time":2,"hold_time":0,"parent_id":null,"email":null,"street":"","city":"Yorba Linda","state":"CA","country":"US","postal_code":"90071","called_at":"2019-02-07 03:17 PM -08:00","unix_time":1549581440,"tracking_number_id":543479,"tracking_number_sid":"TPNC3C4B23C348AEC2EE54EFD301979CD2E5AEC7ABEAAD874159EC26DFBC66BD2BB","tracking_number":"+18442232231","tracking_label":"Website - Main","dial_status":"completed","is_new_caller":true,"indexed_at":1549583553.4085412,"inbound_rate_center":{"country":"US","prefix":"1","tollfree":true},"business_number":"+19493536847","business_label":"RingDNA Sales Hotline","receiving_number_id":955824,"receiving_number_sid":"RPN34D8AC3F61E8848FEA641CEF711011AAB8018611126A36376E273D4AF8CFD7EAF59710E7B4E9D61A","billed_amount":2000,"billed_at":"2019-02-07T23:20:39","caller_number_split":["1","714","462","3682"],"contact_number":"+17144623682","excluded":false,"redacted":false,"tracking_number_format":"(844) 223-2231","business_number_format":"(949) 353-6847","caller_number_format":"(714) 462-3682","alternative_number":"7144623682","caller_number_complete":"+17144623682","caller_number_bare":"7144623682","tracking_number_bare":"8442232231","caller_number":"+17144623682","visitor":false,"call_path":[{"route_name":"RingDNA Sales Hotline","route_id":"RPN34D8AC3F61E8848FEA641CEF711011AAB8018611126A36376E273D4AF8CFD7EAF59710E7B4E9D61A","route_type":"PhysicalPhoneNumber","started_at":"2019-02-07T15:17:20Z"}],"left_talk_time":110,"right_talk_time":112,"transfers":[],"call_status":"answered","status":"answered","spotted":[],"salesforce":{},"audio":"https://app.calltrackingmetrics.com/api/v1/accounts/34785/calls/CA152d978517a7b9ff8dfedbbff2aade5e/recording","callbacks":[],"emails":[],"day":"Thursday","month":"February","hour":"03PM","paid":{"source":"website","medium":"direct"},"ga":{"cid":"34785.527644566","events":["Calls:UA-99133242-1"]},"tag_list":[],"notes":"","latitude":33.8832,"longitude":-117.739,"extended_lookup_on":false,"extended_lookup":{"first_name":"Nhcc","last_name":"","name_type":"C","phone_type":"landline","business_name":null,"street_number":null,"street_name":null,"gender":null,"city":"Garden Grove","state":"CA","zipcode":"90071","facebook":null,"linkedin":null,"twitter":null,"education":null,"language":null,"carrier":null,"age":null,"high_net_worth":null,"home_owner_status":null,"household_income":null,"marital_status":null,"length_of_residence":null,"market_value":null,"occupation":null,"presence_of_children":null},"legs":[]},{"id":527641461,"sid":"CA42fb3b590a040e962670333f6b4ad6d0","account_id":34785,"name":"Calvin  Richardson","cnam":"Calvin Richardson","search":"","referrer":"","location":"","source":"Website - Main","source_id":308066,"source_sid":"TSOF6FC2D2594D22C528265C519C54257E4771F9B78D04A0BA26D22F0E56EE1A402","tgid":2303169,"likelihood":null,"duration":1147,"direction":"inbound","talk_time":1147,"ring_time":0,"hold_time":0,"parent_id":null,"email":null,"street":"","city":"Windsor Locks","state":"CT","country":"US","postal_code":"06103","called_at":"2019-02-07 03:12 PM -08:00","unix_time":1549581158,"tracking_number_id":543479,"tracking_number_sid":"TPNC3C4B23C348AEC2EE54EFD301979CD2E5AEC7ABEAAD874159EC26DFBC66BD2BB","tracking_number":"+18442232231","tracking_label":"Website - Main","dial_status":"completed","is_new_caller":true,"indexed_at":1549584232.3039465,"inbound_rate_center":{"country":"US","prefix":"1","tollfree":true},"business_number":"+19493536847","business_label":"RingDNA Sales Hotline","receiving_number_id":955824,"receiving_number_sid":"RPN34D8AC3F61E8848FEA641CEF711011AAB8018611126A36376E273D4AF8CFD7EAF59710E7B4E9D61A","billed_amount":10000,"billed_at":"2019-02-07T23:31:47","caller_number_split":["1","860","292","0107"],"contact_number":"+18602920107","excluded":false,"redacted":false,"tracking_number_format":"(844) 223-2231","business_number_format":"(949) 353-6847","caller_number_format":"(860) 292-0107","alternative_number":"8602920107","caller_number_complete":"+18602920107","caller_number_bare":"8602920107","tracking_number_bare":"8442232231","caller_number":"+18602920107","visitor":false,"call_path":[{"route_name":"RingDNA Sales Hotline","route_id":"RPN34D8AC3F61E8848FEA641CEF711011AAB8018611126A36376E273D4AF8CFD7EAF59710E7B4E9D61A","route_type":"PhysicalPhoneNumber","started_at":"2019-02-07T15:12:39Z"}],"left_talk_time":602,"right_talk_time":856,"transfers":[],"call_status":"answered","status":"answered","spotted":[],"salesforce":{},"audio":"https://app.calltrackingmetrics.com/api/v1/accounts/34785/calls/CA42fb3b590a040e962670333f6b4ad6d0/recording","callbacks":[],"emails":[],"day":"Thursday","month":"February","hour":"03PM","paid":{"source":"website","medium":"direct"},"ga":{"cid":"34785.527641461","events":["Calls:UA-99133242-1"]},"tag_list":[],"notes":"","latitude":41.9872,"longitude":-72.5637,"extended_lookup_on":false,"extended_lookup":{"first_name":"Calvin","last_name":"Richardson","name_type":"C","phone_type":"landline","business_name":null,"street_number":null,"street_name":null,"gender":"M","city":"Windsor Locks","state":"CT","zipcode":"06103","facebook":null,"linkedin":null,"twitter":null,"education":null,"language":null,"carrier":null,"age":null,"high_net_worth":null,"home_owner_status":null,"household_income":null,"marital_status":null,"length_of_residence":null,"market_value":null,"occupation":null,"presence_of_children":null},"legs":[]}],"page":1,"total_entries":29970,"total_pages":2997,"per_page":"10","stats":{},"next_page":"https://api.calltrackingmetrics.com/api/v1/accounts/34785/calls.json?account_id=34785&action=index&controller=api%2Fv1%2Fcalls&format=json&page=2&per_page=10"}'
      );
      response.setHeader('Content-Type', 'application/json');
      response.getStatusCode();

      return response;
    }
  }
}