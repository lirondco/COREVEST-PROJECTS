public class ClearBase {
  private class ClearConfig {
    String Sandbox_Username;
    String Production_Username;
    String Sandbox_Password;
    String Production_Password;
    String Sandbox_Client_Certificate_Name;
    String Sandbox_Endpoint;
    String Production_Endpoint;
    String Production_Client_Certificate_Name;
    String Person_Search_SubRoute;
    String Person_Report_SubRoute;
    String Person_Risk_SubRoute;
    String Risk_Report_SubRoute;

    ClearConfig() {
      this.Sandbox_Username = Clear_Api_Config__c.getOrgDefaults()
        .Sandbox_Username__c;
      this.Sandbox_Password = Clear_Api_Config__c.getOrgDefaults()
        .Sandbox_Password__c;
      this.Sandbox_Client_Certificate_Name = Clear_Api_Config__c.getOrgDefaults()
        .Sandbox_Client_Certificate_Name__c;
      this.Sandbox_Endpoint = Clear_Api_Config__c.getOrgDefaults()
        .Sandbox_Endpoint__c;

      this.Production_Username = Clear_Api_Config__c.getOrgDefaults()
        .Production_Username__c;
      this.Production_Password = Clear_Api_Config__c.getOrgDefaults()
        .Production_Password__c;
      this.Production_Client_Certificate_Name = Clear_Api_Config__c.getOrgDefaults()
        .Production_Client_Certificate_Name__c;
      this.Production_Endpoint = Clear_Api_Config__c.getOrgDefaults()
        .Production_Endpoint__c;

      this.Person_Search_SubRoute = '/api/v2/person/searchResults';
      this.Person_Report_SubRoute = '/api/v2/personReport/reportResults';
      this.Person_Risk_SubRoute = '/api/v2/riskinformperson/searchResults';
      this.Risk_Report_SubRoute = '/api/v2/riskInformPersonReport/reportResults';
    }
  }

  public static Boolean orgIsSandbox {
    get {
      if (orgIsSandbox == null) {
        orgIsSandbox = [SELECT IsSandbox FROM Organization LIMIT 1].IsSandbox;
      }
      return orgIsSandbox;
    }
    set;
  }

  //generate HTTP request
  public static HttpRequest generateRequest(
    string body,
    string type,
    string method,
    string endpoint
  ) {
    HttpRequest req = new HttpRequest();
    try {
      //get CLEAR API credentials from custom settings
      ClearConfig clear = new ClearConfig();
      Blob header;
      String endpt = '';
      String str = '';

      if (orgIsSandbox == true) {
        header = Blob.valueOf(
          clear.Sandbox_Username +
          ':' +
          clear.Sandbox_Password
        );
        if (endpoint == null)
          endpt = clear.Sandbox_Endpoint;
        req.setClientCertificateName(clear.Sandbox_Client_Certificate_Name);
      } else {
        header = Blob.valueOf(
          clear.Production_Username +
          ':' +
          clear.Production_Password
        );
        if (endpoint == null)
          endpt = clear.Production_Endpoint;
        req.setClientCertificateName(clear.Production_Client_Certificate_Name);
      }
      if (endpoint != null) {
        req.setEndpoint(endpoint);
      } else {
        if (type.equalsIgnoreCase('search')) {
          req.setEndpoint(endpt + clear.Person_Search_SubRoute);
        }
        if (type.equalsIgnoreCase('PersonSearchReport')) {
          req.setEndpoint(endpt + clear.Person_Report_SubRoute);
        }
        if (type.equalsIgnoreCase('risk')) {
          req.setEndpoint(endpt + clear.Person_risk_SubRoute);
        }
        if (type.equalsIgnoreCase('RiskSearchReport')) {
          req.setEndpoint(endpt + clear.Risk_Report_SubRoute);
        }
      }
      if (body != null) {
        req.setBody(body);
      }
      req.setHeader(
        'Authorization',
        'Basic ' + EncodingUtil.base64Encode(header)
      );
      req.setMethod(method);
      req.setTimeout(120000);
      //req.setEndpoint(endpoint + '/api/v2/person/searchResults');
      req.setHeader('Content-Type', 'application/xml');
      //return req;
    } catch (exception e) {
      System.debug('The following exception has occurred: ' + e.getMessage());
    }
    if(test.isRunningTest()) {
      req.setEndpoint('thomsonreuters.com');
    }
    return req;
  }
  public static HttpRequest generategetRequest(
    string URL,
    string method,
    string endpoint
  ) {
    HttpRequest req = new HttpRequest();
    try {
      //get CLEAR API credentials from custom settings
      if(test.isRunningTest()) {
        req.setEndpoint('thomsonreuters.com');
      }
      ClearConfig clear = new ClearConfig();
      Blob header;
      String endpt = '';
      String str = '';
      if (orgIsSandbox) {
        header = Blob.valueOf(
          clear.Sandbox_Username +
          ':' +
          clear.Sandbox_Password
        );
        if (endpoint == null)
          endpt = clear.Sandbox_Endpoint;
        req.setClientCertificateName(clear.Sandbox_Client_Certificate_Name);
        system.debug('header::::if' + header);
      } else {
        header = Blob.valueOf(
          clear.Production_Username +
          ':' +
          clear.Production_Password
        );
        if (endpoint == null)
          endpt = clear.Production_Endpoint;
        req.setClientCertificateName(clear.Production_Client_Certificate_Name);
        system.debug('header::::else' + header);
      }
      if (URL != null) {
        req.setEndpoint(URL);
      } else {
      }

      req.setHeader(
        'Authorization',
        'Basic ' + EncodingUtil.base64Encode(header)
      );
      req.setMethod(method);
      req.setTimeout(120000);
      //req.setEndpoint(endpoint + '/api/v2/person/searchResults');
      req.setHeader('Content-Type', 'application/xml');
    } catch (exception e) {
      System.debug('The following exception has occurred: ' + e.getMessage());
    }
    return req;
  }
  @auraenabled
  public static Map<String, String> getContactDetailforRiskSearch(Id id) {
    Map<String, String> resultlist = new Map<String, String>();
    try {
      system.debug('id:::::' + id);
      list<Deal_Contact__c> dealContactList = new List<Deal_Contact__c>();
      list<Contact> ContactList = new List<Contact>();
      list<string> ContactIDList = new List<string>();

      for (Deal_Contact__c dc : [
        SELECT id, name, Contact__c
        FROM Deal_Contact__c
        WHERE id = :id
        LIMIT 1
      ]) {
        ContactIDList.add(dc.Contact__c);
      }

      system.debug('ContactIDList:::::' + ContactIDList);

      string message = 'Get Response from Risk Search.';
      List<Clear_Result__c> clearResultlist = [
        SELECT
          id,
          Contact__c,
          EntityId__c,
          akaLastName__c,
          Risk_Number__c,
          akaFirstName__c
        FROM Clear_Result__c
        WHERE Contact__c = :ContactIDList
        LIMIT 1
      ];
      system.debug('clearResultlist:::::' + clearResultlist);
      system.debug('EntityId__c:::::' + clearResultlist[0].EntityId__c);
      if (
        clearResultlist != null &&
        clearResultlist.size() > 0 &&
        clearResultlist[0].EntityId__c != null &&
        clearResultlist[0].EntityId__c != ''
      ) {
        String RiskLink = riskPersonInfo(clearResultlist);
        if (RiskLink != '') {
          Http http = new Http();
          HttpRequest request = ClearBase.generategetRequest(
            RiskLink,
            'GET',
            null
          );
          HTTPResponse res1 = new HTTPResponse();
          try {
            string finalresponse = '';
            if (Test.isRunningTest() == false) {
              res1 = http.send(request);
              finalresponse = res1.getBody();
            } else {
              res1.setBody(
                '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><ns2:RiskInformPersonSearchResponse xmlns:ns2="com/thomsonreuters/schemas/riskinformperson-search" xmlns:ns3="com/thomsonreuters/schemas/riskflags" xmlns:ns4="com/thomsonreuters/schemas/news-search" xmlns:ns5="com/thomsonreuters/schemas/webanalytics-search" xmlns:ns6="com/thomsonreuters/schemas/search" xmlns:ns7="com/thomsonreuters/schemas/criminal-data"><Status><StatusCode>200</StatusCode><SubStatusCode>200</SubStatusCode></Status><RiskInformPersonSearchResult><PersonEntity><GroupId>8a56c8a57722ecde017771b6220f4a72</GroupId><TotalScore>5.00</TotalScore><EntityId>P1__MTM3MzQ5NjI3ODY</EntityId><Header><AllFlags sectioncount="1" sectionscore="5.00"/><AddressFlags sectioncount="0" sectionscore="0.00"/><SyntheticIdentity sectioncount="0" sectionscore="0.00"/><SingleRiskIndicators sectioncount="1" sectionscore="5.00"/><Custom sectioncount="0" sectionscore="0.00"/><News sectionscore="Not Applicable"/><WebAnalytics sectionscore="0.00"/><RealTimeIncarcerationRecords sectioncount="0" sectionscore="0.00"/></Header><Sections><Section><SectionName>Address Flags</SectionName><SectionScore>0.00</SectionScore><SectionDetails><AddressFlags><GovernmentalAddress><RiskFlagName>Address is Governmental</RiskFlagName><RiskFlagScore>0.00</RiskFlagScore><RiskFlagHitIndicator>No</RiskFlagHitIndicator></GovernmentalAddress><NewsResult><RecordId>8a56c8a57722ecde017771b6318f4c3e</RecordId><NewsSummary><Headline>Jharkhand High Court Aditya Anand vs The State Of Jharkhand</Headline><PublicationInfo><Publication>Pakistan Law Reporter</Publication><WordCount>Word Count: 823</WordCount></PublicationInfo><CitationInfo><Citation>5/25/16 PAKLREP (No Page)</Citation><WestlawCitation>2016 WLNR 15927962</WestlawCitation></CitationInfo><ArticleSnippet><PublicationDate>May 25, 2016</PublicationDate><WordCount>Word Count: 823</WordCount><LeadParagraph>Jharkhand:</LeadParagraph></ArticleSnippet></NewsSummary></NewsResult></News></SectionDetails></Section><Section><SectionName>RealTimeIncarcerationRecords</SectionName><SectionScore>0.00</SectionScore><SectionDetails></SectionDetails></Section></Sections></PersonEntity></RiskInformPersonSearchResult></ns2:RiskInformPersonSearchResponse>'
              );
              res1.setStatusCode(200);
              finalresponse = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><ns2:RiskInformPersonSearchResponse xmlns:ns2="com/thomsonreuters/schemas/riskinformperson-search" xmlns:ns3="com/thomsonreuters/schemas/riskflags" xmlns:ns4="com/thomsonreuters/schemas/news-search" xmlns:ns5="com/thomsonreuters/schemas/webanalytics-search" xmlns:ns6="com/thomsonreuters/schemas/search" xmlns:ns7="com/thomsonreuters/schemas/criminal-data"><Status><StatusCode>200</StatusCode><SubStatusCode>200</SubStatusCode></Status><RiskInformPersonSearchResult><PersonEntity><GroupId>8a56c8a57722ecde017771b6220f4a72</GroupId><TotalScore>5.00</TotalScore><EntityId>P1__MTM3MzQ5NjI3ODY</EntityId><Header><AllFlags sectioncount="1" sectionscore="5.00"/><AddressFlags sectioncount="0" sectionscore="0.00"/><SyntheticIdentity sectioncount="0" sectionscore="0.00"/><SingleRiskIndicators sectioncount="1" sectionscore="5.00"/><Custom sectioncount="0" sectionscore="0.00"/><News sectionscore="Not Applicable"/><WebAnalytics sectionscore="0.00"/><RealTimeIncarcerationRecords sectioncount="0" sectionscore="0.00"/></Header><Sections><Section><SectionName>Address Flags</SectionName><SectionScore>0.00</SectionScore><SectionDetails><AddressFlags><GovernmentalAddress><RiskFlagName>Address is Governmental</RiskFlagName><RiskFlagScore>0.00</RiskFlagScore><RiskFlagHitIndicator>No</RiskFlagHitIndicator></GovernmentalAddress><NewsResult><RecordId>8a56c8a57722ecde017771b6318f4c3e</RecordId><NewsSummary><Headline>Jharkhand High Court Aditya Anand vs The State Of Jharkhand</Headline><PublicationInfo><Publication>Pakistan Law Reporter</Publication><WordCount>Word Count: 823</WordCount></PublicationInfo><CitationInfo><Citation>5/25/16 PAKLREP (No Page)</Citation><WestlawCitation>2016 WLNR 15927962</WestlawCitation></CitationInfo><ArticleSnippet><PublicationDate>May 25, 2016</PublicationDate><WordCount>Word Count: 823</WordCount><LeadParagraph>Jharkhand:</LeadParagraph></ArticleSnippet></NewsSummary></NewsResult></News></SectionDetails></Section><Section><SectionName>RealTimeIncarcerationRecords</SectionName><SectionScore>0.00</SectionScore><SectionDetails></SectionDetails></Section></Sections></PersonEntity></RiskInformPersonSearchResult></ns2:RiskInformPersonSearchResponse>';
            }
            system.debug(
              'getContactDetailforRiskSearch: finalresponse==' + finalresponse
            );
            DOM.Document document1 = new DOM.Document();
            document1.load(finalresponse);
            //Dom.XmlNode sta = document1.getRootElement().getChildElement('Status', null);
            //string scode = sta.getChildElement('StatusCode', null).getText();

            //system.debug('risk -- scode==='+scode);
            system.debug(
              'getContactDetailforRiskSearch:==' + res1.getStatusCode()
            );
            if (res1.getStatusCode() == 200) {
              Dom.XmlNode rootElement = document1.getRootElement()
                .getChildElement('RiskInformPersonSearchResult', null);
              Dom.XmlNode PersonEntitynode = rootElement.getChildElement(
                'PersonEntity',
                null
              );
              String TotalScore = PersonEntitynode.getChildElement(
                  'TotalScore',
                  null
                )
                .getText();
              String GroupId = PersonEntitynode.getChildElement('GroupId', null)
                .getText();
              clearResultlist[0].Risk_Number__c = Decimal.valueof(TotalScore);
              clearResultlist[0].Group_ID_for_Risk_search__c = GroupId;
              resultlist.put('message', message);
              resultlist.put('GroupId', GroupId);
              system.debug(
                'getContactDetailforRiskSearch:GroupId===risk' + GroupId
              );
              update clearResultlist;

              String JsonclearResultlist = JSON.serialize(clearResultlist);


              Deal_Contact__c dcObj = new Deal_Contact__c();
              dcObj.id = id;
              dcObj.Background_Risk_Number__c = Decimal.valueof(TotalScore);
              dcObj.Clear_Result__c = clearResultlist[0].id;
              dealContactList.add(dcObj);

              if (dealContactList != null && dealContactList.size() > 0) {
                update dealContactList;
              }

              contact conObj = new contact();
              conObj.id = ContactIDList[0];
              conObj.Background_Risk_Number__c = Decimal.valueof(TotalScore);
              ContactList.add(conObj);

              if (ContactList != null && ContactList.size() > 0) {
                update ContactList;
              }

              System.enqueueJob(
                new APILoggerQueueable(request, res1, id, false)
              );
            } else {
              message = 'Get Error in response';
              resultlist.put('message', message);
              System.CalloutException e = new System.CalloutException();
              e.setMessage(res1.getStatusCode() + ': ' + res1.getStatus());
              System.enqueueJob(new APILoggerQueueable(request, res1, id, e));
            }
          } catch (Exception e) {
            System.enqueueJob(new APILoggerQueueable(request, res1, id, e));
            throw e;
          }
        } else {
          message = 'Get Error in response';
          resultlist.put('message', message);
        }
      } else {
        message = 'Please click person search befor risk search';
        resultlist.put('message', message);
      }
      //return resultlist;
    } catch (exception e) {
      System.debug('The following exception has occurred: ' + e.getMessage());
      resultlist.put('errorMessage', e.getMessage());
      return resultlist;

    }
    return resultlist;
  }


  @future
  public static void performUpdateDmlInFuture(String sobjectJson) {
    update (SObject) JSON.deserialize(sobjectJson, SObject.class);
  }


  @auraenabled
  public static String riskPersonInfo(list<Clear_Result__c> clearResultlist) {
    DOM.Document doc = new DOM.Document();
    dom.XmlNode products = doc.createRootElement(
      'rips:RiskInformPersonSearchRequest',
      null,
      null
    );
    products.setAttribute(
      'xmlns:rips',
      'http://clear.thomsonreuters.com/api/search/2.0'
    );
    dom.XmlNode PermissiblePurposeVar = products.addChildElement(
      'PermissiblePurpose',
      null,
      null
    );
    PermissiblePurposeVar.addChildElement('GLB', null, null).addTextNode('Q');
    PermissiblePurposeVar.addChildElement('DPPA', null, null).addTextNode('3');
    PermissiblePurposeVar.addChildElement('VOTER', null, null).addTextNode('5');
    dom.XmlNode ReferenceVar = products.addChildElement('Reference', null, null)
      .addTextNode('S2S Risk Inform Person Search');
    dom.XmlNode CriteriaVar = products.addChildElement('Criteria', null, null);
    dom.XmlNode riskCriteriaVar = CriteriaVar.addChildElement(
      'rip1:RiskInformPersonSearchCriteria',
      null,
      null
    );
    riskCriteriaVar.setAttribute(
      'xmlns:rip1',
      'com/thomsonreuters/schemas/riskinformperson-search'
    );
    riskCriteriaVar.addChildElement('EntityId', null, null)
      .addTextNode(clearResultlist[0].EntityId__c);
    riskCriteriaVar.addChildElement('RiskInformDefName', null, null)
      .addTextNode('CoreVest Finance All Flags Person');
    riskCriteriaVar.addChildElement('RiskInformDefVersion', null, null)
      .addTextNode('');
    riskCriteriaVar.addChildElement('InternalID', null, null).addTextNode('');
    dom.XmlNode akanamenode = riskCriteriaVar.addChildElement(
      'AKAName',
      null,
      null
    );
    if (clearResultlist[0].akaFirstName__c != null) {
      akanamenode.addChildElement('FirstName', null, null)
        .addTextNode(clearResultlist[0].akaFirstName__c);
    }
    akanamenode.addChildElement('MiddleName', null, null).addTextNode('');
    akanamenode.addChildElement('LastName', null, null)
      .addTextNode(clearResultlist[0].akaLastName__c);
    dom.XmlNode IncludeAdditionalSearches = riskCriteriaVar.addChildElement(
      'IncludeAdditionalSearches',
      null,
      null
    );
    IncludeAdditionalSearches.addChildElement('WebAnalyticsSearch', null, null)
      .addTextNode('true');
    String xmlstring = doc.toXmlString();
    Http http = new Http();
    HTTPResponse res = new HTTPResponse();
    HttpRequest req = ClearBase.generateRequest(
      xmlstring,
      'risk',
      'POST',
      null
    );

    try {
      system.debug('riskPersonInfo::req==' + req);
      string response = '';

      if (Test.isRunningTest() == false) {
        res = http.send(req);
        response = res.getBody();
      } else {
        res.setBody(
          '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><ns2:PersonResults xmlns:ns2="http://clear.thomsonreuters.com/api/search/2.0"><Status><StatusCode>200</StatusCode><SubStatusCode>0</SubStatusCode></Status><Uri>https://s2s.beta.thomsonreuters.com/api/v2/person/searchResults/8a57c89268a623ec016909c791112578</Uri><GroupCount>1</GroupCount></ns2:PersonResults>'
        );
        res.setStatusCode(200);
        response = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><ns2:PersonResults xmlns:ns2="http://clear.thomsonreuters.com/api/search/2.0"><Status><StatusCode>200</StatusCode><SubStatusCode>0</SubStatusCode></Status><Uri>https://s2s.beta.thomsonreuters.com/api/v2/person/searchResults/8a57c89268a623ec016909c791112578</Uri><GroupCount>1</GroupCount></ns2:PersonResults>';
      }

      String Link;
      System.debug('riskPersonInfo::response::' + response);
      DOM.Document document = new DOM.Document();
      document.load(response);
      string groupcount = document.getRootElement()
        .getChildElement('GroupCount', null)
        .getText();
      if (res.getStatusCode() == 200 && Integer.valueOf(groupcount) > 0) {
        Link = document.getRootElement().getChildElement('Uri', null).getText();
        system.debug('riskPersonInfo::Link==' + Link);
      } else {
        Link = '';
      }

      // System.enqueueJob(
      //   new APILoggerQueueable(req, res, clearResultlist[0].id, false)
      // );
      return Link;
    } catch (Exception e) {
      // System.enqueueJob(
      //   new APILoggerQueueable(req, res, clearResultlist[0].id, e)
      // );
      throw new AuraHandledException(e.getMessage());
    }
  }

  @auraenabled
  public static Map<string, string> getContactDetailforPersonSearch(
    ID id,
    boolean SteetAddressCheck,
    boolean CityCheck,
    boolean StateCheck,
    boolean CountryCheck,
    boolean ZipCheck
  ) {
    Map<String, String> retrunlist = new Map<String, String>();
    //try{
    string message = '';
    String FirstName = '';
    String LastName = '';
    String Street = '';
    String City = '';
    String State = '';
    String ZipCode = '';
    String Birthdate = '';
    List<Contact> conlist = [
      SELECT
        id,
        FirstName,
        LastName,
        SponsorHomeAddress__c,
        SponsorCity__c,
        SponsorState__c,
        SponsorZipCode__c,
        SponsorDateofBirth__c,
        Birthdate
      FROM Contact
      WHERE id = :id
      LIMIT 1
    ];
    if (SteetAddressCheck) {
      conlist[0].SponsorHomeAddress__c = '';
    }
    if (CityCheck) {
      conlist[0].SponsorCity__c = '';
    }
    if (StateCheck) {
      conlist[0].SponsorState__c = '';
    }
    /* if(CountryCheck){
                conlist[0].MailingCountry = '';
            } */
    if (ZipCheck) {
      conlist[0].SponsorZipCode__c = '';
    }

    system.debug('getContactDetailforPersonSearch::conlist==' + conlist);
    system.debug('SteetAddress==' + SteetAddressCheck);
    system.debug('City==' + CityCheck);
    system.debug('State==' + StateCheck);
    system.debug('Country==' + CountryCheck);
    system.debug('Zip==' + ZipCheck);
    //if(conlist[0].Birthdate != null){

    message = 'Get the Person Search Report.';

    if(conlist == null) {
      retrunlist.put('errorMessage', 'Your request could not be processed due to incomplete contact details.');
      return retrunlist;
    }
    String xmlstring;
    
    try {
      xmlstring = DomXmlUserInfo(conlist);
    } catch (Exception e) {
      retrunlist.put('errorMessage', 'Your request could not be processed due to incomplete contact details.');
      return retrunlist;
    }
    system.debug('getContactDetailforPersonSearch:  xmlstring==' + xmlstring);
    Http http = new Http();
    HTTPResponse res = new HTTPResponse();
    HttpRequest req = ClearBase.generateRequest(
      xmlstring,
      'search',
      'POST',
      null
    );
    string response = '';

    try {
      if (Test.isRunningTest() == false) {
        res = http.send(req);
        response = res.getBody();
      } else {
        res.setBody(
          '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><ns2:PersonResults xmlns:ns2="http://clear.thomsonreuters.com/api/search/2.0"><Status><StatusCode>200</StatusCode><SubStatusCode>0</SubStatusCode></Status><Uri>https://s2s.beta.thomsonreuters.com/api/v2/person/searchResults/8a57c89268a623ec016909c791112578</Uri><GroupCount>1</GroupCount></ns2:PersonResults>'
        );
        res.setStatusCode(200);
        response = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><ns2:PersonResults xmlns:ns2="http://clear.thomsonreuters.com/api/search/2.0"><Status><StatusCode>200</StatusCode><SubStatusCode>0</SubStatusCode></Status><Uri>https://s2s.beta.thomsonreuters.com/api/v2/person/searchResults/8a57c89268a623ec016909c791112578</Uri><GroupCount>1</GroupCount></ns2:PersonResults>';
      }
      system.debug('response::==' + response);
      system.debug('res.getStatusCode()::::' + res.getStatusCode());

      /* DOM.Document document12 = new DOM.Document();
            document12.load(response);
            Dom.XmlNode status12 = document12.getRootElement().getChildElement('Status', null);
            string SubStatusCode = status12.getChildElement('SubStatusCode', null).getText();
            system.debug('SubStatusCode=='+SubStatusCode); */

      if (res.getStatusCode() == 200) {
        //System.debug('response::'+response);
        DOM.Document document = new DOM.Document();
        document.load(response);
        Dom.XmlNode status = document.getRootElement()
          .getChildElement('Status', null);
        string statuscode = status.getChildElement('StatusCode', null)
          .getText();
        string groupcount = document.getRootElement()
          .getChildElement('GroupCount', null)
          .getText();
        if (integer.valueof(groupcount) > 0) {
          system.debug(
            'getContactDetailforPersonSearch:statuscode==' + statuscode
          );
          system.debug('inside if: getContactDetailforPersonSearch');
          String Link = document.getRootElement()
            .getChildElement('Uri', null)
            .getText();
          Dom.XmlNode childnodeLink = document.getRootElement()
            .getChildElement('Uri', null);

          HttpRequest request = ClearBase.generategetRequest(Link, 'GET', null);
          system.debug('inside if:request=' + request);
          string finalresponse = '';
          HTTPResponse res1 = new HTTPResponse();
          try {
            if (Test.isRunningTest() == false) {
              res1 = http.send(request);
              finalresponse = res1.getBody();
            } else {
              res1.setBody(
                '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><ns4:PersonResultsPage xmlns:ns2="com/thomsonreuters/schemas/common-data" xmlns:ns3="com/thomsonreuters/schemas/search" xmlns:ns4="http://clear.thomsonreuters.com/api/search/2.0"><Status><StatusCode>200</StatusCode><SubStatusCode>200</SubStatusCode></Status><StartIndex>0</StartIndex><EndIndex>1</EndIndex><ResultGroup><GroupId>b8cc66b9af4d44ccb9f7dc63aea85a91</GroupId><RecordCount>1</RecordCount><Relevance>97</Relevance><DominantValues><ns3:PersonDominantValues><Name><FirstName>DANIEL</FirstName><MiddleName>J</MiddleName><LastName>GALLI</LastName><FullName>DANIEL J GALLI</FullName></Name><SSN>005-62-XXXX</SSN><AgeInfo><PersonBirthDate>04/XX/1961</PersonBirthDate><PersonAge>60</PersonAge></AgeInfo><Address><Street>1024 WASHINGTON AVE UNIT 8</Street><City>PORTLAND</City><State>ME</State><ZipCode>04103</ZipCode><ReportedDate>01/15/2021</ReportedDate></Address></ns3:PersonDominantValues></DominantValues><RecordDetails><ns3:PersonResponseDetail><Name><FirstName>DANIEL</FirstName><MiddleName>J</MiddleName><LastName>GALLI</LastName><FullName>DANIEL J GALLI</FullName></Name><SSN>005-62-XXXX</SSN><PersonProfile><PersonBirthDate>04/XX/1961</PersonBirthDate><PersonBirthDate>04/1961</PersonBirthDate><PersonSex>MALE</PersonSex><PersonSpouseName>REBECCA</PersonSpouseName></PersonProfile><DriverLicenseInfo><DriverLicenseNumber>6490XXX</DriverLicenseNumber><DriverLicenseState>ME</DriverLicenseState></DriverLicenseInfo><AKANames><FirstName>DANIEL</FirstName><MiddleName>J.</MiddleName><LastName>GALLI</LastName></AKANames><AKANames><FirstName>DANIEL</FirstName><MiddleName>JOSEPH</MiddleName><LastName>GALLI</LastName><SourceInfo><SourceName>TransUnion</SourceName><SourceDocumentGuid>I0EF608EAE12211D59A400E00E20D7175</SourceDocumentGuid></SourceInfo><SourceInfo><SourceName>Historic Credit Bureau</SourceName><SourceDocumentGuid>I89990d72b1f011de9b8c850332338889</SourceDocumentGuid></SourceInfo></AKANames><PersonEntityId>P1__NDExNjYyNTQ4</PersonEntityId></ns3:PersonResponseDetail></RecordDetails></ResultGroup><ResultGroup><GroupId>a74901e4723f43ffa4209ab8e3d33831</GroupId><RecordCount>1</RecordCount><Relevance>90</Relevance><DominantValues><ns3:PersonDominantValues><Name><FirstName>JOSEPH</FirstName><MiddleName>D</MiddleName><LastName>GALLI</LastName></Name><SSN>007-90-XXXX</SSN><AgeInfo><PersonBirthDate>03/XX/1986</PersonBirthDate><PersonAge>35</PersonAge></AgeInfo><Address><Street>700 N RANDOLPH ST APT 1100</Street><City>ARLINGTON</City><State>VA</State><ZipCode>22203</ZipCode><ReportedDate>11/18/2020</ReportedDate></Address></ns3:PersonDominantValues></DominantValues><RecordDetails><ns3:PersonResponseDetail><Name><FirstName>JOSEPH</FirstName><MiddleName>D</MiddleName><LastName>GALLI</LastName></Name><SSN>007-90-XXXX</SSN><PersonProfile><PersonBirthDate>03/XX/1986</PersonBirthDate><PersonBirthDate>1986</PersonBirthDate><PersonBirthDate>06/XX/1988</PersonBirthDate><PersonBirthDate>01/XX/1985</PersonBirthDate><PersonBirthDate>03/1986</PersonBirthDate><PersonSex>MALE</PersonSex></PersonProfile><AKANames><FirstName>THOMAS</FirstName><MiddleName>S</MiddleName><LastName>BERENZ</LastName><SourceInfo><SourceName>Bank Account Header Records</SourceName><SourceDocumentGuid>I11c84450ee1611eabea4f0dc9fb69570</SourceDocumentGuid></SourceInfo></AKANames></ns3:PersonResponseDetail></RecordDetails></ResultGroup></ns4:PersonResultsPage>'
              );
              res1.setStatusCode(200);
              finalresponse = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><ns4:PersonResultsPage xmlns:ns2="com/thomsonreuters/schemas/common-data" xmlns:ns3="com/thomsonreuters/schemas/search" xmlns:ns4="http://clear.thomsonreuters.com/api/search/2.0"><Status><StatusCode>200</StatusCode><SubStatusCode>200</SubStatusCode></Status><StartIndex>0</StartIndex><EndIndex>1</EndIndex><ResultGroup><GroupId>b8cc66b9af4d44ccb9f7dc63aea85a91</GroupId><RecordCount>1</RecordCount><Relevance>97</Relevance><DominantValues><ns3:PersonDominantValues><Name><FirstName>DANIEL</FirstName><MiddleName>J</MiddleName><LastName>GALLI</LastName><FullName>DANIEL J GALLI</FullName></Name><SSN>005-62-XXXX</SSN><AgeInfo><PersonBirthDate>04/XX/1961</PersonBirthDate><PersonAge>60</PersonAge></AgeInfo><Address><Street>1024 WASHINGTON AVE UNIT 8</Street><City>PORTLAND</City><State>ME</State><ZipCode>04103</ZipCode><ReportedDate>01/15/2021</ReportedDate></Address></ns3:PersonDominantValues></DominantValues><RecordDetails><ns3:PersonResponseDetail><Name><FirstName>DANIEL</FirstName><MiddleName>J</MiddleName><LastName>GALLI</LastName><FullName>DANIEL J GALLI</FullName></Name><SSN>005-62-XXXX</SSN><PersonProfile><PersonBirthDate>04/XX/1961</PersonBirthDate><PersonBirthDate>04/1961</PersonBirthDate><PersonSex>MALE</PersonSex><PersonSpouseName>REBECCA</PersonSpouseName></PersonProfile><DriverLicenseInfo><DriverLicenseNumber>6490XXX</DriverLicenseNumber><DriverLicenseState>ME</DriverLicenseState></DriverLicenseInfo><AKANames><FirstName>DANIEL</FirstName><MiddleName>J.</MiddleName><LastName>GALLI</LastName></AKANames><AKANames><FirstName>DANIEL</FirstName><MiddleName>JOSEPH</MiddleName><LastName>GALLI</LastName><SourceInfo><SourceName>TransUnion</SourceName><SourceDocumentGuid>I0EF608EAE12211D59A400E00E20D7175</SourceDocumentGuid></SourceInfo><SourceInfo><SourceName>Historic Credit Bureau</SourceName><SourceDocumentGuid>I89990d72b1f011de9b8c850332338889</SourceDocumentGuid></SourceInfo></AKANames><PersonEntityId>P1__NDExNjYyNTQ4</PersonEntityId></ns3:PersonResponseDetail></RecordDetails></ResultGroup><ResultGroup><GroupId>a74901e4723f43ffa4209ab8e3d33831</GroupId><RecordCount>1</RecordCount><Relevance>90</Relevance><DominantValues><ns3:PersonDominantValues><Name><FirstName>JOSEPH</FirstName><MiddleName>D</MiddleName><LastName>GALLI</LastName></Name><SSN>007-90-XXXX</SSN><AgeInfo><PersonBirthDate>03/XX/1986</PersonBirthDate><PersonAge>35</PersonAge></AgeInfo><Address><Street>700 N RANDOLPH ST APT 1100</Street><City>ARLINGTON</City><State>VA</State><ZipCode>22203</ZipCode><ReportedDate>11/18/2020</ReportedDate></Address></ns3:PersonDominantValues></DominantValues><RecordDetails><ns3:PersonResponseDetail><Name><FirstName>JOSEPH</FirstName><MiddleName>D</MiddleName><LastName>GALLI</LastName></Name><SSN>007-90-XXXX</SSN><PersonProfile><PersonBirthDate>03/XX/1986</PersonBirthDate><PersonBirthDate>1986</PersonBirthDate><PersonBirthDate>06/XX/1988</PersonBirthDate><PersonBirthDate>01/XX/1985</PersonBirthDate><PersonBirthDate>03/1986</PersonBirthDate><PersonSex>MALE</PersonSex></PersonProfile><AKANames><FirstName>THOMAS</FirstName><MiddleName>S</MiddleName><LastName>BERENZ</LastName><SourceInfo><SourceName>Bank Account Header Records</SourceName><SourceDocumentGuid>I11c84450ee1611eabea4f0dc9fb69570</SourceDocumentGuid></SourceInfo></AKANames></ns3:PersonResponseDetail></RecordDetails></ResultGroup></ns4:PersonResultsPage>';
            }
            system.debug(
              'getContactDetailforPersonSearch::finalresponse==' + finalresponse
            );
            DOM.Document document1 = new DOM.Document();
            document1.load(finalresponse);

            //Dom.XmlNode sta = document1.getRootElement().getChildElement('Status', null);
            //string scode = sta.getChildElement('StatusCode', null).getText();
            //system.debug('scode==='+scode);
            if (res1.getStatusCode() == 200) {
              Dom.XmlNode rootElement = document1.getRootElement()
                .getChildElement('ResultGroup', null);
              String groupid = rootElement.getChildElement('GroupId', null)
                .getText();
              system.debug(
                'getContactDetailforPersonSearch::groupid==' + groupid
              );
              String ns2 = 'com/thomsonreuters/schemas/search';
              String ns3 = 'http://clear.thomsonreuters.com/api/search/2.0';
              Dom.XmlNode root = document1.getRootElement()
                .getChildElement('ResultGroup', null);
              Dom.XmlNode DominantValues = root.getChildElement(
                'DominantValues',
                null
              );
              system.debug('DominantValues==' + DominantValues);
              Dom.XmlNode ns = DominantValues.getChildElement(
                'PersonDominantValues',
                ns2
              );
              system.debug('ns==' + ns);
              Dom.XmlNode Name = ns.getChildElement('Name', null);
              FirstName = Name.getChildElement('FirstName', null).getText();
              LastName = Name.getChildElement('LastName', null).getText();
              system.debug('FirstName==' + FirstName);
              system.debug('LastName==' + LastName);
              system.debug('ns==' + ns);
              //Dom.XmlNode AgeInfo= ns.getChildElement('AgeInfo', null);
              //Birthdate = AgeInfo.getChildElement('PersonBirthDate', null).getText();
              //system.debug('Birthdate:::::'+Birthdate);
              Dom.XmlNode Address = ns.getChildElement('Address', null);
              system.debug('Address==' + Address);
              Street = Address.getChildElement('Street', null).getText();
              City = Address.getChildElement('City', null).getText();
              State = Address.getChildElement('State', null).getText();
              ZipCode = Address.getChildElement('ZipCode', null).getText();
              system.debug('Street==' + Street);
              system.debug('City==' + City);
              system.debug('State==' + State);
              system.debug('ZipCode==' + ZipCode);
              Dom.XmlNode RecordDetails = root.getChildElement(
                'RecordDetails',
                null
              );
              Dom.XmlNode PersonResponseDetail = RecordDetails.getChildElement(
                'PersonResponseDetail',
                ns2
              );
              string PersonEntityId = PersonResponseDetail.getChildElement(
                  'PersonEntityId',
                  null
                )
                .getText();
              system.debug(
                'getContactDetailforPersonSearch::PersonEntityId==' +
                PersonEntityId
              );
              Dom.XmlNode AKANamesnode = PersonResponseDetail.getChildElement(
                'AKANames',
                null
              );
              String akaFistname;
              String akaLastName;
              if (AKANamesnode != null) {
                akaFistname = AKANamesnode.getChildElement('FirstName', null)
                  .getText();
                akalastname = AKANamesnode.getChildElement('LastName', null)
                  .getText();
              }
              system.debug(akaFistname + ':::' + akalastname);
              //retrunlist.put('PersonEntityId',PersonEntityId);

              List<Clear_Result__c> clearResult = new List<Clear_Result__c>();
              clearResult = [
                SELECT
                  First_Name__c,
                  Last_Name__c,
                  Birth_date__c,
                  Contact__c,
                  Group_ID_for_Person_Search__c,
                  City__c,
                  State__c,
                  Street__c,
                  Zip_Code__c
                FROM Clear_Result__c
                WHERE Contact__c = :id
                LIMIT 1
              ];
              if (clearResult != null && clearResult.size() > 0) {
                clearResult[0].First_Name__c = FirstName;
                clearResult[0].Last_Name__c = LastName;
                clearResult[0].Street__c = Street;
                clearResult[0].City__c = City;
                clearResult[0].State__c = State;
                clearResult[0].Zip_Code__c = ZipCode;
                clearResult[0].EntityId__c = PersonEntityId;
                clearResult[0].akaFirstName__c = akaFistname;
                clearResult[0].akaLastName__c = akalastname;
                clearResult[0].Group_ID_for_Person_Search__c = groupid;
                //clearResult[0].Birth_date__c=date.valueof(Birthdate);
              } else {
                Clear_Result__c cr = new Clear_Result__c();
                cr.Name = FirstName + ' ' + LastName + '-Clear Result';
                cr.First_Name__c = FirstName;
                cr.Last_Name__c = LastName;
                cr.Street__c = Street;
                cr.City__c = City;
                cr.State__c = State;
                cr.EntityId__c = PersonEntityId;
                cr.akaFirstName__c = akaFistname;
                cr.akaLastName__c = akalastname;
                cr.Group_ID_for_Person_Search__c = groupid;
                //cr.Birth_date__c=date.valueof(Birthdate);
                cr.Contact__c = id;
                clearResult.add(cr);
              }
              system.debug(
                'getContactDetailforPersonSearch::clearResult==' + clearResult
              );
              upsert clearResult;
              APILoggerQueueable nextQueue = new APILoggerQueueable(
                request,
                res1,
                id,
                false
              );
              System.enqueueJob(
                new APILoggerQueueable(req, res, id, nextQueue)
              );
            } else {
              message = 'Failed to get a response from Person Search.';
              System.CalloutException e = new System.CalloutException();
              e.setMessage(message);
              throw e;
            }
          } catch (Exception e) {
            throw e;
          }
        } else {
          message = 'Person not found.';
          System.CalloutException e = new System.CalloutException();
          e.setMessage(message);
          throw e;
        }
      } else {
        message = 'Error occurred. Please try again.';
        System.CalloutException ce = new System.CalloutException();
        ce.setMessage(res.getStatusCode() + ': ' + res.getStatus());
        throw ce;
      }
    } catch (Exception er) {
      System.enqueueJob(new APILoggerQueueable(req, res, id, er));

      retrunlist.put('errorMessage', er.getMessage());
      return retrunlist;
    }
    /*  }else{
                message='Please Enter Date of Birth first.'; 
            } */
    retrunlist.put('message', message);
    //return  retrunlist;
    //}catch(exception e){
    //  System.debug('getContactDetailforPersonSearch::The following exception has occurred: ' + e.getMessage());
    //  }
    return retrunlist;
  }
  // create XML to send as body for person search request
  @auraenabled
  public static string DomXmlUserInfo(list<Contact> conlist) {
    string street = '';
    string city = '';
    string country = '';
    string postalcode = '';
    Map<String, String> statemap = new Map<String, String>();

    statemap.put('alabama', 'AL');
    statemap.put('alaska', 'AK');
    statemap.put('arizona', 'AZ');
    statemap.put('arkansas', 'AR');
    statemap.put('california', 'CA');
    statemap.put('colorado', 'CO');
    statemap.put('connecticut', 'CT');
    statemap.put('delaware', 'DE');
    statemap.put('florida', 'FL');
    statemap.put('georgia', 'GA');
    statemap.put('hawaii', 'HI');
    statemap.put('idaho', 'ID');
    statemap.put('illinois', 'IL');
    statemap.put('indiana', 'IN');
    statemap.put('iowa', 'IA');
    statemap.put('kansas', 'KS');
    statemap.put('kentucky', 'KY');
    statemap.put('louisiana', 'LA');
    statemap.put('maine', 'ME');
    statemap.put('maryland', 'MD');
    statemap.put('massachusetts', 'MA');
    statemap.put('michigan', 'MI');
    statemap.put('minnesota', 'MN');
    statemap.put('mississippi', 'MS');
    statemap.put('missouri', 'MO');
    statemap.put('montana', 'MT');
    statemap.put('nebraska', 'NE');
    statemap.put('nevada', 'NV');
    statemap.put('new Hampshire', 'NH');
    statemap.put('new Jersey', 'NJ');
    statemap.put('new Mexico', 'NM');
    statemap.put('new York', 'NY');
    statemap.put('north Carolina', 'NC');
    statemap.put('north Dakota', 'ND');
    statemap.put('ohio', 'OH');
    statemap.put('oklahoma', 'OK');
    statemap.put('oregon', 'OR');
    statemap.put('pennsylvania', 'PA');
    statemap.put('rhode Island', 'RI');
    statemap.put('south Carolina', 'SC');
    statemap.put('south Dakota', 'SD');
    statemap.put('tennessee', 'TN');
    statemap.put('texas', 'TX');
    statemap.put('utah', 'UT');
    statemap.put('vermont', 'VT');
    statemap.put('virginia', 'VA');
    statemap.put('washington', 'WA');
    statemap.put('west Virginia', 'WV');
    statemap.put('wisconsin', 'WI');
    statemap.put('wyoming', 'WY');
    statemap.put('ontario', 'ON');
    statemap.put('quebec', 'QC');
    statemap.put('quéBec', 'QC');
    statemap.put('british columbia', 'BC');
    statemap.put('alberta', 'AB');
    statemap.put('manitoba', 'MB');
    statemap.put('saskatchewan', 'SK');
    statemap.put('nova scotia', 'NS');
    statemap.put('new brunswick', 'NB');
    statemap.put('newfoundland and labrador', 'NL');
    statemap.put('prince edward island', 'PE');
    statemap.put('northwest territories', 'NT');
    statemap.put('yukon', 'YT');
    statemap.put('nunavut', 'NU');
    system.debug('street==' + street);
    system.debug('city==' + city);
    system.debug('country==' + country);
    system.debug('postalcode==' + postalcode);
    statemap.get(conlist[0].SponsorState__c);
    system.debug(
      'statemap.get(conlist[0].SponsorState__c)==' +
      statemap.get(conlist[0].SponsorState__c.toLowerCase())
    );
    DOM.Document doc = new DOM.Document();
    dom.XmlNode products = doc.createRootElement(
      'ps:PersonSearchRequest',
      null,
      null
    );
    products.setAttribute(
      'xmlns:ps',
      'http://clear.thomsonreuters.com/api/search/2.0'
    );
    dom.XmlNode PermissiblePurposeVar = products.addChildElement(
      'PermissiblePurpose',
      null,
      null
    );
    PermissiblePurposeVar.addChildElement('GLB', null, null).addTextNode('Q');
    PermissiblePurposeVar.addChildElement('DPPA', null, null).addTextNode('3');
    PermissiblePurposeVar.addChildElement('VOTER', null, null).addTextNode('5');
    dom.XmlNode ReferenceVar = products.addChildElement('Reference', null, null)
      .addTextNode('S2S Person Search');
    dom.XmlNode CriteriaVar = products.addChildElement('Criteria', null, null);
    dom.XmlNode PersonCriteriaVar = CriteriaVar.addChildElement(
      'p1:PersonCriteria',
      null,
      null
    );
    PersonCriteriaVar.setAttribute(
      'xmlns:p1',
      'com/thomsonreuters/schemas/search'
    );
    dom.XmlNode NameInfoVar = PersonCriteriaVar.addChildElement(
      'NameInfo',
      null,
      null
    );
    dom.XmlNode AgeInfoVar = PersonCriteriaVar.addChildElement(
      'AgeInfo',
      null,
      null
    );
    dom.XmlNode addressInfoVar = PersonCriteriaVar.addChildElement(
      'AddressInfo',
      null,
      null
    );
    if (
      conlist[0].SponsorHomeAddress__c != '' &&
      conlist[0].SponsorHomeAddress__c != null
    ) {
      addressInfoVar.addChildElement('Street', null, null)
        .addTextNode(conlist[0].SponsorHomeAddress__c);
    } else {
      addressInfoVar.addChildElement('Street', null, null).addTextNode('');
    }
    if (conlist[0].SponsorCity__c != '' && conlist[0].SponsorCity__c != null) {
      addressInfoVar.addChildElement('City', null, null)
        .addTextNode(conlist[0].SponsorCity__c);
    } else {
      addressInfoVar.addChildElement('City', null, null).addTextNode('');
    }

    system.debug(conlist[0].SponsorState__c);
    system.debug(statemap.get(conlist[0].SponsorState__c.toLowerCase()));
    system.debug(addressInfoVar);
    if (
      conlist[0].SponsorState__c != '' &&
      conlist[0].SponsorState__c != null &&
      statemap.containsKey(conlist[0].SponsorState__c.toLowercase())
    ) {
      addressInfoVar.addChildElement('State', null, null)
        .addTextNode(statemap.get(conlist[0].SponsorState__c.toLowercase()));
    } else {
      addressInfoVar.addChildElement('State', null, null).addTextNode('');
    }
    /* if(conlist[0].MailingCountry!='' && conlist[0].MailingCountry!=null )
        {
           addressInfoVar.addChildElement('County', null, null).addTextNode(conlist[0].MailingCountry);
        }
        else
        {
            addressInfoVar.addChildElement('County', null, null).addTextNode('');
        } */
    if (
      conlist[0].SponsorZipCode__c != '' &&
      conlist[0].SponsorZipCode__c != null
    ) {
      addressInfoVar.addChildElement('ZipCode', null, null)
        .addTextNode(conlist[0].SponsorZipCode__c);
    } else {
      addressInfoVar.addChildElement('ZipCode', null, null).addTextNode('');
    }
    //addressInfoVar.addChildElement('Street', null, null).addTextNode('');
    //addressInfoVar.addChildElement('City', null, null).addTextNode('');
    //addressInfoVar.addChildElement('State', null, null).addTextNode('CA');
    //addressInfoVar.addChildElement('County', null, null).addTextNode('');
    //addressInfoVar.addChildElement('ZipCode', null, null).addTextNode('');
    PersonCriteriaVar.addChildElement('SSN', null, null).addTextNode('');
    //FirstName,LastName,MailingCountry,MailingStreet,MailingCity,MailingState,MailingPostalCode
    NameInfoVar.addChildElement('LastName', null, null)
      .addTextNode(conlist[0].LastName);
    NameInfoVar.addChildElement('FirstName', null, null)
      .addTextNode(conlist[0].FirstName);
    if (conlist[0].SponsorDateofBirth__c != null) {
      system.debug(
        'conlist[0].SponsorDateofBirth__c:::' + conlist[0].SponsorDateofBirth__c
      );
      date dob = conlist[0].SponsorDateofBirth__c;
      //Date d = date.today();
      String dt = DateTime.newInstance(dob.year(), dob.month(), dob.day())
        .format('MM/dd/YYYY');
      system.debug('dt==' + dt);
      AgeInfoVar.addChildElement('PersonBirthDate', null, null).addTextNode(dt);
    } else {
      AgeInfoVar.addChildElement('PersonBirthDate', null, null).addTextNode('');
    }
    //Birthdate
    //AgeInfoVar.addChildElement('PersonBirthDate', null, null).addTextNode('');
    dom.XmlNode DatasourcesVar = products.addChildElement(
      'Datasources',
      null,
      null
    );
    DatasourcesVar.addChildElement('PublicRecordPeople', null, null)
      .addTextNode('true');
    DatasourcesVar.addChildElement('NPIRecord', null, null)
      .addTextNode('false');
    DatasourcesVar.addChildElement('WorldCheckRiskIntelligence', null, null)
      .addTextNode('false');
    String xmlstring = doc.toXmlString();
    System.debug('xmlstring++++' + xmlstring);
    return xmlstring;
  }

  // create XML to send as body to get person URI Link using the GroupId
  @auraenabled
  public static string DomXmlpersonInfosec(string GroupId) {
    DOM.Document doc = new DOM.Document();
    dom.XmlNode products = doc.createRootElement(
      'pr:PersonReportRequest',
      null,
      null
    );
    products.setAttribute(
      'xmlns:pr',
      'http://clear.thomsonreuters.com/api/report/2.0'
    );
    dom.XmlNode PermissiblePurposeVar = products.addChildElement(
      'PermissiblePurpose',
      null,
      null
    );
    PermissiblePurposeVar.addChildElement('GLB', null, null).addTextNode('Q');
    PermissiblePurposeVar.addChildElement('DPPA', null, null).addTextNode('3');
    PermissiblePurposeVar.addChildElement('VOTER', null, null).addTextNode('5');
    dom.XmlNode ReferenceVar = products.addChildElement('Reference', null, null)
      .addTextNode('S2S Person Report');
    dom.XmlNode CriteriaVar = products.addChildElement('Criteria', null, null);
    dom.XmlNode ReportCriteriaVar = CriteriaVar.addChildElement(
      'rc:ReportCriteria',
      null,
      null
    );
    ReportCriteriaVar.setAttribute(
      'xmlns:rc',
      'com/thomsonreuters/schemas/person-report'
    );
    dom.XmlNode GroupIDVar = ReportCriteriaVar.addChildElement(
        'GroupID',
        null,
        null
      )
      .addTextNode(GroupId);
    dom.XmlNode ReportChoiceVar = ReportCriteriaVar.addChildElement(
        'ReportChoice',
        null,
        null
      )
      .addTextNode('Individual');
    dom.XmlNode ReportOptionsVar = ReportCriteriaVar.addChildElement(
      'ReportOptions',
      null,
      null
    );
    ReportOptionsVar.addChildElement(
        'AssociatesSectionAddressOption',
        null,
        null
      )
      .addTextNode('3');
    ReportOptionsVar.addChildElement(
        'AssociatesSectionTimeframeOption',
        null,
        null
      )
      .addTextNode('2');
    ReportOptionsVar.addChildElement(
        'AssociateSectionDisplayOption',
        null,
        null
      )
      .addTextNode('F');
    ReportOptionsVar.addChildElement('NeighborsTypeOption', null, null)
      .addTextNode('3');
    ReportOptionsVar.addChildElement('NeighborsTimeframeOption', null, null)
      .addTextNode('2');
    ReportOptionsVar.addChildElement('RelativesSectionDegreeOption', null, null)
      .addTextNode('1');
    ReportOptionsVar.addChildElement(
        'RelativesSectionDisplayOption',
        null,
        null
      )
      .addTextNode('F');
    ReportOptionsVar.addChildElement(
        'RelativesSectionIncludeAkasOption',
        null,
        null
      )
      .addTextNode('false');
    ReportOptionsVar.addChildElement(
        'VehiclesSectionLimitAssocOption',
        null,
        null
      )
      .addTextNode('true');
    ReportOptionsVar.addChildElement(
        'VehiclesSectionLimitYearOption',
        null,
        null
      )
      .addTextNode('false');
    ReportOptionsVar.addChildElement('AddressSectionAddressOption', null, null)
      .addTextNode('A');
    ReportOptionsVar.addChildElement(
        'BusinessAtSubjectAddressSectionAddressOption',
        null,
        null
      )
      .addTextNode('3');
    ReportOptionsVar.addChildElement('LicenseSectionAddressOption', null, null)
      .addTextNode('3');
    ReportOptionsVar.addChildElement(
        'LicenseSectionTimeframeOption',
        null,
        null
      )
      .addTextNode('0');
    ReportOptionsVar.addChildElement(
        'PropertyOwnerSectionAddressOption',
        null,
        null
      )
      .addTextNode('3');
    ReportOptionsVar.addChildElement(
        'VehiclesAtSubjectAddressSectionAddressOption',
        null,
        null
      )
      .addTextNode('3');
    ReportOptionsVar.addChildElement(
        'VehiclesAtSubjectAddressSectionTimeframeOption',
        null,
        null
      )
      .addTextNode('0');
    ReportOptionsVar.addChildElement(
        'PropertyOwnerSectionLimitAssocOption',
        null,
        null
      )
      .addTextNode('false');
    dom.XmlNode ReportSectionsVar = ReportCriteriaVar.addChildElement(
      'ReportSections',
      null,
      null
    );
    ReportSectionsVar.addChildElement('AddressSection', null, null)
      .addTextNode('true');
    ReportSectionsVar.addChildElement('DeathSection', null, null)
      .addTextNode('true');
    ReportSectionsVar.addChildElement('WorkAffiliationSection', null, null)
      .addTextNode('true');
    ReportSectionsVar.addChildElement('UtilitySection', null, null)
      .addTextNode('true');
    ReportSectionsVar.addChildElement('SSNAddressFraudSection', null, null)
      .addTextNode('true');
    ReportSectionsVar.addChildElement('OtherSSNSection', null, null)
      .addTextNode('true');
    ReportSectionsVar.addChildElement('OtherNamesforSSNSection', null, null)
      .addTextNode('true');
    ReportSectionsVar.addChildElement('PhoneNumberSection', null, null)
      .addTextNode('true');
    ReportSectionsVar.addChildElement('PhoneListingSection', null, null)
      .addTextNode('true');
    ReportSectionsVar.addChildElement('CanadianPhoneSection', null, null)
      .addTextNode('true');
    ReportSectionsVar.addChildElement('EmailSection', null, null)
      .addTextNode('true');
    ReportSectionsVar.addChildElement('DriverLicenseSection', null, null)
      .addTextNode('true');
    ReportSectionsVar.addChildElement('DivorceSection', null, null)
      .addTextNode('true');
    ReportSectionsVar.addChildElement('LicenseSection', null, null)
      .addTextNode('true');
    ReportSectionsVar.addChildElement('HealthcareLicenseSection', null, null)
      .addTextNode('true');
    ReportSectionsVar.addChildElement('NPISection', null, null)
      .addTextNode('true');
    ReportSectionsVar.addChildElement('MilitarySection', null, null)
      .addTextNode('true');
    ReportSectionsVar.addChildElement('PoliticalDonorSection', null, null)
      .addTextNode('true');
    ReportSectionsVar.addChildElement('VoterRegistrationSection', null, null)
      .addTextNode('true');
    ReportSectionsVar.addChildElement(
        'DriversAtSubjectAddressSection',
        null,
        null
      )
      .addTextNode('true');
    ReportSectionsVar.addChildElement('GlobalSanctionSection', null, null)
      .addTextNode('true');
    ReportSectionsVar.addChildElement('HealthcareSanctionSection', null, null)
      .addTextNode('true');
    ReportSectionsVar.addChildElement('ExcludedPartySection', null, null)
      .addTextNode('true');
    ReportSectionsVar.addChildElement('WorldCheckSection', null, null)
      .addTextNode('true');
    ReportSectionsVar.addChildElement('ArrestSection', null, null)
      .addTextNode('true');
    ReportSectionsVar.addChildElement('InfractionSection', null, null)
      .addTextNode('true');
    ReportSectionsVar.addChildElement('CriminalSection', null, null)
      .addTextNode('true');
    ReportSectionsVar.addChildElement('RealTimeArrestSection', null, null)
      .addTextNode('true');
    ReportSectionsVar.addChildElement('ExecutiveAffiliationSection', null, null)
      .addTextNode('true');
    ReportSectionsVar.addChildElement('DunBradstreetSection', null, null)
      .addTextNode('true');
    ReportSectionsVar.addChildElement('ShareholderSection', null, null)
      .addTextNode('true');
    ReportSectionsVar.addChildElement(
        'BusinessAtSubjectAddressSection',
        null,
        null
      )
      .addTextNode('true');
    ReportSectionsVar.addChildElement('LienJudgmentSection', null, null)
      .addTextNode('true');
    ReportSectionsVar.addChildElement('BankruptcySection', null, null)
      .addTextNode('true');
    ReportSectionsVar.addChildElement('LawsuitSection', null, null)
      .addTextNode('true');
    ReportSectionsVar.addChildElement('DocketSection', null, null)
      .addTextNode('true');
    ReportSectionsVar.addChildElement('CorporateSection', null, null)
      .addTextNode('true');
    ReportSectionsVar.addChildElement('UCCSection', null, null)
      .addTextNode('true');
    ReportSectionsVar.addChildElement('RealPropertySection', null, null)
      .addTextNode('true');
    ReportSectionsVar.addChildElement('PropertyOwnerSection', null, null)
      .addTextNode('true');
    ReportSectionsVar.addChildElement('PreForeclosureSection', null, null)
      .addTextNode('true');
    ReportSectionsVar.addChildElement('RealTimeVehicleSection', null, null)
      .addTextNode('true');
    ReportSectionsVar.addChildElement('VehicleSection', null, null)
      .addTextNode('true');
    ReportSectionsVar.addChildElement(
        'VehiclesAtSubjectAddressSection',
        null,
        null
      )
      .addTextNode('true');
    ReportSectionsVar.addChildElement('WatercraftSection', null, null)
      .addTextNode('true');
    ReportSectionsVar.addChildElement('AircraftSection', null, null)
      .addTextNode('true');
    ReportSectionsVar.addChildElement('UnclaimedAssetSection', null, null)
      .addTextNode('true');
    ReportSectionsVar.addChildElement('RelativeSection', null, null)
      .addTextNode('true');
    ReportSectionsVar.addChildElement('AssociateSection', null, null)
      .addTextNode('true');
    ReportSectionsVar.addChildElement('NeighborSection', null, null)
      .addTextNode('true');
    ReportSectionsVar.addChildElement('QuickAnalysisFlagSection', null, null)
      .addTextNode('true');
    ReportSectionsVar.addChildElement(
        'AssociateAnalyticsChartSection',
        null,
        null
      )
      .addTextNode('true');
    ReportSectionsVar.addChildElement('ObituariesNewsSection', null, null)
      .addTextNode('false');
    ReportSectionsVar.addChildElement('WebAnalyticsSection', null, null)
      .addTextNode('false');
    ReportSectionsVar.addChildElement(
        'MotorVehicleServiceAndWarrantyRecordsSection',
        null,
        null
      )
      .addTextNode('true');
    ReportSectionsVar.addChildElement(
        'MarijuanaRelatedBusinessesSection',
        null,
        null
      )
      .addTextNode('true');
    ReportSectionsVar.addChildElement('PermissiblePurposeSection', null, null)
      .addTextNode('true');
    String xmlString = doc.toXmlString();
    return xmlString;
  }
  @auraenabled
  public static string DomXmlpersonriskInfosec(string GroupID) {
    String xmlString = '';
    //string GroupId = resultlist.get('GroupId');
    DOM.Document doc = new DOM.Document();
    dom.XmlNode products = doc.createRootElement(
      'ripr:RiskInformPersonReportRequest',
      null,
      null
    );
    products.setAttribute(
      'xmlns:ripr',
      'http://clear.thomsonreuters.com/api/report/2.0'
    );
    dom.XmlNode PermissiblePurposeVar = products.addChildElement(
      'PermissiblePurpose',
      null,
      null
    );
    PermissiblePurposeVar.addChildElement('GLB', null, null).addTextNode('Q');
    PermissiblePurposeVar.addChildElement('DPPA', null, null).addTextNode('3');
    PermissiblePurposeVar.addChildElement('VOTER', null, null).addTextNode('5');
    dom.XmlNode ReferenceVar = products.addChildElement('Reference', null, null)
      .addTextNode('S2S Risk Inform Person Report');
    dom.XmlNode CriteriaVar = products.addChildElement('Criteria', null, null);
    dom.XmlNode ReportCriteriaVar = CriteriaVar.addChildElement(
      'rc:ReportCriteria',
      null,
      null
    );
    ReportCriteriaVar.setAttribute(
      'xmlns:rc',
      'com/thomsonreuters/schemas/riskinformperson-report'
    );
    dom.XmlNode GroupIDVar = ReportCriteriaVar.addChildElement(
        'GroupID',
        null,
        null
      )
      .addTextNode(GroupID);
    dom.XmlNode ReportChoiceVar = ReportCriteriaVar.addChildElement(
        'ReportChoice',
        null,
        null
      )
      .addTextNode('RiskInformPerson');
    dom.XmlNode ReportDisplayHitRiskFlagsOnlynode = ReportCriteriaVar.addChildElement(
        'ReportDisplayHitRiskFlagsOnly',
        null,
        null
      )
      .addTextNode('true');
    dom.XmlNode ReportOptionsVar = ReportCriteriaVar.addChildElement(
      'ReportOptions',
      null,
      null
    );
    ReportOptionsVar.addChildElement(
        'AssociatesSectionAddressOption',
        null,
        null
      )
      .addTextNode('3');
    ReportOptionsVar.addChildElement(
        'AssociatesSectionTimeframeOption',
        null,
        null
      )
      .addTextNode('2');
    ReportOptionsVar.addChildElement(
        'AssociateSectionDisplayOption',
        null,
        null
      )
      .addTextNode('F');
    ReportOptionsVar.addChildElement('NeighborsTypeOption', null, null)
      .addTextNode('3');
    ReportOptionsVar.addChildElement('NeighborsTimeframeOption', null, null)
      .addTextNode('2');
    ReportOptionsVar.addChildElement('RelativesSectionDegreeOption', null, null)
      .addTextNode('1');
    ReportOptionsVar.addChildElement(
        'RelativesSectionDisplayOption',
        null,
        null
      )
      .addTextNode('F');
    ReportOptionsVar.addChildElement(
        'RelativesSectionIncludeAkasOption',
        null,
        null
      )
      .addTextNode('false');
    dom.XmlNode ReportSectionsVar = ReportCriteriaVar.addChildElement(
      'ReportSections',
      null,
      null
    );
    ReportSectionsVar.addChildElement('RiskInformScore', null, null)
      .addTextNode('true');
    ReportSectionsVar.addChildElement('RiskInformSummary', null, null)
      .addTextNode('true');
    ReportSectionsVar.addChildElement('RiskInformCustomDetails', null, null)
      .addTextNode('true');
    ReportSectionsVar.addChildElement(
        'RiskInformHealthcareFraudDetails',
        null,
        null
      )
      .addTextNode('true');
    ReportSectionsVar.addChildElement(
        'RiskInformDangerousCriminalHistoryDetails',
        null,
        null
      )
      .addTextNode('true');
    ReportSectionsVar.addChildElement(
        'RiskInformFinancialCrimesDetails',
        null,
        null
      )
      .addTextNode('true');
    ReportSectionsVar.addChildElement(
        'RiskInformGovProcurementFraudDetails',
        null,
        null
      )
      .addTextNode('true');
    ReportSectionsVar.addChildElement(
        'RiskInformMortgageFraudDetails',
        null,
        null
      )
      .addTextNode('true');
    ReportSectionsVar.addChildElement(
        'RiskInformLitigiousIndividualDetails',
        null,
        null
      )
      .addTextNode('true');
    ReportSectionsVar.addChildElement(
        'RiskInformPropertyCrimesDetails',
        null,
        null
      )
      .addTextNode('true');
    ReportSectionsVar.addChildElement(
        'RiskInformInsuranceFraudDetails',
        null,
        null
      )
      .addTextNode('true');
    ReportSectionsVar.addChildElement('RiskInformTaxFraudDetails', null, null)
      .addTextNode('true');
    ReportSectionsVar.addChildElement('RiskInformNewsDetails', null, null)
      .addTextNode('false');
    ReportSectionsVar.addChildElement(
        'RiskInformSingleRiskIndicatorsDetails',
        null,
        null
      )
      .addTextNode('true');
    ReportSectionsVar.addChildElement(
        'RiskInformSyntheticIDDetails',
        null,
        null
      )
      .addTextNode('true');
    ReportSectionsVar.addChildElement(
        'RiskInformWebAnalyticsDetails',
        null,
        null
      )
      .addTextNode('false');
    ReportSectionsVar.addChildElement('AddressSection', null, null)
      .addTextNode('true');
    ReportSectionsVar.addChildElement('PhoneListingSection', null, null)
      .addTextNode('true');
    ReportSectionsVar.addChildElement('UtilitySection', null, null)
      .addTextNode('true');
    ReportSectionsVar.addChildElement('MarriageSection', null, null)
      .addTextNode('true');
    ReportSectionsVar.addChildElement('DivorceSection', null, null)
      .addTextNode('true');
    ReportSectionsVar.addChildElement('WorkAffiliationSection', null, null)
      .addTextNode('true');
    ReportSectionsVar.addChildElement('RelativeSection', null, null)
      .addTextNode('true');
    ReportSectionsVar.addChildElement('AssociateSection', null, null)
      .addTextNode('true');
    ReportSectionsVar.addChildElement('NeighborSection', null, null)
      .addTextNode('true');
    ReportSectionsVar.addChildElement(
        'AssociateAnalyticsChartSection',
        null,
        null
      )
      .addTextNode('true');
    ReportSectionsVar.addChildElement('LicenseSection', null, null)
      .addTextNode('true');
    ReportSectionsVar.addChildElement('PermissiblePurposeSection', null, null)
      .addTextNode('true');
    xmlString = doc.toXmlString();

    return xmlString;
  }
  @auraenabled
  public static Map<String, String> GetReport(
    ID id,
    String typeofReport,
    String dealRecordId
  ) {

    Map<String, String> resultMap = new Map<String, String>();
    string errorMsg;

    try {
      list<string> ContactIDList = new List<string>();
      for (Deal_Contact__c dc : [
        SELECT id, name, Contact__c
        FROM Deal_Contact__c
        WHERE id = :id
        LIMIT 1
      ]) {
        ContactIDList.add(dc.Contact__c);
      }
      system.debug('ContactIDList:::::' + ContactIDList);

      List<Clear_Result__c> clearResultlist = [
        SELECT
          id,
          Contact__c,
          EntityId__c,
          Group_ID_for_Person_Search__c,
          Group_ID_for_Risk_search__c
        FROM Clear_Result__c
        WHERE Contact__c = :ContactIDList
        LIMIT 1
      ];
      string GroupID = '';
      system.debug(
        'clearResultlist[0].Group_ID_for_Person_Search__c' +
        clearResultlist[0].Group_ID_for_Person_Search__c
      );
      system.debug(
        'clearResultlist[0].Group_ID_for_Risk_search__c' +
        clearResultlist[0].Group_ID_for_Risk_search__c
      );
      system.debug('typeofReport' + typeofReport);

      if (typeofReport == 'PersonSearchReport') {
        if (
          clearResultlist[0].Group_ID_for_Person_Search__c != null &&
          clearResultlist[0].Group_ID_for_Person_Search__c != ''
        ) {
          GroupID = clearResultlist[0].Group_ID_for_Person_Search__c;
        }
      }
      if (typeofReport == 'RiskSearchReport') {
        if (
          clearResultlist[0].Group_ID_for_Risk_search__c != null &&
          clearResultlist[0].Group_ID_for_Risk_search__c != ''
        ) {
          GroupID = clearResultlist[0].Group_ID_for_Risk_search__c;
        }
      }
      system.debug('GetReport:GroupID==' + GroupID);
      if (clearResultlist != null && clearResultlist.size() > 0) {
        if (GroupID != '') {
          String xmlString;
          if (typeofReport == 'PersonSearchReport') {
            xmlString = DomXmlpersonInfosec(GroupID);
            errorMsg = 'Person search';
          }
          if (typeofReport == 'RiskSearchReport') {
            xmlString = DomXmlpersonriskInfosec(GroupID);
            errorMsg = 'Risk search';
          }

          Http http = new Http();
          HTTPResponse res = new HTTPResponse();
          HttpRequest req = ClearBase.generateRequest(
            xmlstring,
            typeofReport,
            'POST',
            null
          );
          system.debug('GetReport:req===' + req);
          string response = '';

          try {
            if (Test.isRunningTest() == false) {
              res = http.send(req);
              response = res.getBody();
            } else {
              res.setBody(
                '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><ns2:PersonResults xmlns:ns2="http://clear.thomsonreuters.com/api/search/2.0"><Status><StatusCode>200</StatusCode><SubStatusCode>0</SubStatusCode></Status><Uri>https://s2s.beta.thomsonreuters.com/api/v2/person/searchResults/8a57c89268a623ec016909c791112578</Uri><GroupCount>1</GroupCount></ns2:PersonResults>'
              );
              res.setStatusCode(200);
              response = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><ns2:PersonResults xmlns:ns2="http://clear.thomsonreuters.com/api/search/2.0"><Status><StatusCode>200</StatusCode><SubStatusCode>0</SubStatusCode></Status><Uri>https://s2s.beta.thomsonreuters.com/api/v2/person/searchResults/8a57c89268a623ec016909c791112578</Uri><GroupCount>1</GroupCount></ns2:PersonResults>';
            }

            System.debug('GetReport: response::' + response);
            DOM.Document document = new DOM.Document();
            document.load(response);
            Dom.XmlNode status = document.getRootElement()
              .getChildElement('Status', null);
            string SubStatusCode = status.getChildElement('SubStatusCode', null)
              .getText();
            system.debug('SubStatusCode==' + SubStatusCode);

            if (res.getStatusCode() == 200) {
              ClearBase.sleepDelay(10000);

              String Link = document.getRootElement()
                .getChildElement('Uri', null)
                .getText();
              if (typeofReport == 'PersonSearchReport') {
                //ClearBase.sleepDelay(10000);
                ClearBase.getReportXml(ContactIDList[0], link);
              }
              Link = Link + '?reportType=pdf';
              system.debug('GetReport:Link==' + Link);
              system.debug('GetReport:dealRecordId==' + dealRecordId);

              ClearBase.processlink(
                link,
                id,
                clearResultlist[0].id,
                typeofReport,
                dealRecordId
              );
              resultMap.put('message', 'Report is being prepared.');
            } else {
              if (SubStatusCode == '40002') {
                resultMap.put(
                  'message',
                  'Please click on ' +
                  errorMsg +
                  ' button to get latest group ID.'
                );
                resultMap.put(
                  'errorMessage',
                  'Please click on ' +
                  errorMsg +
                  ' button to get latest group ID.'
                );
              } else {
                resultMap.put('message', 'Error occurred please try again.');
                resultMap.put(
                  'errorMessage',
                  'Error occurred please try again.'
                );
              }
            }

            System.enqueueJob(new APILoggerQueueable(req, res, id, false));
          } catch (Exception e) {
            System.enqueueJob(new APILoggerQueueable(req, res, id, e));
            throw e;
          }
        } else {
          resultMap.put('message', 'Please click ' + errorMsg + ' first.');
          resultMap.put(
            'errorMessage',
            'Please click ' + errorMsg + ' first.'
          );
        }
      } else {
        resultMap.put('message', 'Please click ' + errorMsg + ' first.');
        resultMap.put(
          'errorMessage',
          'Please click ' + errorMsg + ' first.'
        );
      }
    } catch (exception e) {
      System.debug('The following exception has occurred: ' + e.getMessage());
      resultMap.put('errorMessage', e.getMessage());
      return resultMap;
    }
    return resultMap;
  }

  @auraenabled
  public static Map<String, String> riskReport(ID id) {
    Map<String, String> resultMap = new Map<String, String>();
    try {
      List<Clear_Result__c> clearResultlist = [
        SELECT id, Contact__c, EntityId__c, Group_ID_for_Risk_search__c
        FROM Clear_Result__c
        WHERE Contact__c = :id
        LIMIT 1
      ];
      if (clearResultlist != null && clearResultlist.size() > 0) {
        if (clearResultlist[0].Group_ID_for_Risk_search__c != '') {
          String xmlString = DomXmlpersonriskInfosec(
            clearResultlist[0].Group_ID_for_Risk_search__c
          );
          Http http = new Http();
          HTTPResponse res = new HTTPResponse();
          HttpRequest req = ClearBase.generateRequest(
            xmlstring,
            'RiskSearchReport',
            'POST',
            null
          );


          try {
          system.debug('riskReport:req===' + req);
          string response = '';
          if (Test.isRunningTest() == false) {
            res = http.send(req);
            response = res.getBody();
          } else {
            res.setBody(
              '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><ns2:PersonResults xmlns:ns2="http://clear.thomsonreuters.com/api/search/2.0"><Status><StatusCode>200</StatusCode><SubStatusCode>0</SubStatusCode></Status><Uri>https://s2s.beta.thomsonreuters.com/api/v2/person/searchResults/8a57c89268a623ec016909c791112578</Uri><GroupCount>1</GroupCount></ns2:PersonResults>'
            );
            res.setStatusCode(200);
            response = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><ns2:PersonResults xmlns:ns2="http://clear.thomsonreuters.com/api/search/2.0"><Status><StatusCode>200</StatusCode><SubStatusCode>0</SubStatusCode></Status><Uri>https://s2s.beta.thomsonreuters.com/api/v2/person/searchResults/8a57c89268a623ec016909c791112578</Uri><GroupCount>1</GroupCount></ns2:PersonResults>';
          }
          System.debug('riskReport:response::' + response);
          DOM.Document document = new DOM.Document();
          document.load(response);
          Dom.XmlNode status = document.getRootElement()
            .getChildElement('Status', null);
          string SubStatusCode = status.getChildElement('SubStatusCode', null)
            .getText();
          system.debug('riskReport:SubStatusCode==' + SubStatusCode);

          if (res.getStatusCode() == 200) {
            String Link = document.getRootElement()
              .getChildElement('Uri', null)
              .getText();
            Link = Link + '?reportType=pdf';
            ClearBase.sleepDelay(10000);
            system.debug('riskReport:Link==' + Link);
            //ClearBase.processlink(link,clearResultlist[0].id);
            resultMap.put('message', 'report is being prepared.');
          } else {
            if (SubStatusCode == '40002') {
              resultMap.put(
                'message',
                'GroupID is invalid. please click Risk search first to get latest GroupID.'
              );
            } else {
              resultMap.put('message', 'Error occurred pelase try again.');
            }
          }
          System.enqueueJob(new APILoggerQueueable(req, res, id, false));
        } catch(Exception e) {
          System.enqueueJob(new APILoggerQueueable(req, res, id, e));

        }
        } else {
          resultMap.put('message', 'please click Risk search first.');
        }
      } else {
        resultMap.put('message', 'please click Person search first.');
      }
    } catch (exception e) {
      System.debug('The following exception has occurred: ' + e.getMessage());
    }
    return resultMap;
  }
  @auraenabled
  public static void sleepDelay(Long milliSeconds) {
    Long timeDiff = 0;
    DateTime firstTime = System.now();
    do {
      timeDiff = System.now().getTime() - firstTime.getTime();
    } while (timeDiff <= milliSeconds);
  }

  @future(callout=true)
  public static void getReportXml(ID id, string link) {
    try {
      sleepDelay(50000);

      String AssocWithOFACGlobalPEP = '';
      String OFAC = '';
      String GlobalSanctions = '';
      String AssocRelativeWithResidentialUsedAsBusiness = '';
      String ResidentialUsedAsBusiness = '';
      String PrisonAddress = '';
      String POBoxAddress = '';
      String Bankruptcy = '';
      String AssocRelativeWithPrisonAddress = '';
      String AssocRelativeWithPOBoxAddress = '';
      String Criminal = '';
      String MultipleSSN = '';
      String SSNMultipleIndividuals = '';
      String RecordedAsDeceased = '';
      String AgeYoungerThanSSN = '';
      String AddressReportedLessNinetyDays = '';
      String SSNFormatInvalid = '';
      String HealthcareSanction = '';
      String PhoneNumberInconsistentAddress = '';
      String Arrest = '';
      String AssociatedWithMarijuanaBusiness = '';

      HttpRequest request = ClearBase.generategetRequest(Link, 'GET', null);
      Http http1 = new Http();
      HTTPResponse res1 = new HTTPResponse();
      //res1 = http1.send(request);
      string finalresponse;

      try {
      if (Test.isRunningTest() == false) {
        res1 = http1.send(request);
        finalresponse = res1.getBody();
      } else {
        res1.setBody(
          '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><ns12:PersonReportDetails xmlns:ns2="com/thomsonreuters/schemas/common-data" xmlns:ns3="com/thomsonreuters/schemas/person-report" xmlns:ns4="com/thomsonreuters/schemas/criminal-data" xmlns:ns5="com/thomsonreuters/schemas/court-data" xmlns:ns6="com/thomsonreuters/schemas/business-data" xmlns:ns7="com/thomsonreuters/schemas/license-data" xmlns:ns8="com/thomsonreuters/schemas/news-search" xmlns:ns9="com/thomsonreuters/schemas/company-report" xmlns:ns10="com/thomsonreuters/schemas/vehicle-data" xmlns:ns11="com/thomsonreuters/schemas/webanalytics-search" xmlns:ns12="http://clear.thomsonreuters.com/api/report/2.0"><Status><StatusCode>200</StatusCode><SubStatusCode>200</SubStatusCode><Reference>S2S Person Report</Reference></Status><ReportId>4c6299c8a9524174823205fa87eb90df</ReportId><SectionResults><SectionName>UserTermsSection</SectionName><CLEARReportDescription>User Search Terms</CLEARReportDescription><SectionStatus>COMPLETE</SectionStatus><SectionRecordCount>1</SectionRecordCount><SectionDetails><ns3:UserTermsSection><UserTermRecord><PersonSearch><Name><FirstName>Daniel</FirstName><LastName>Galli</LastName></Name><PersonProfile/><SSN/><Address><Street>1024 Washington Ave</Street><City>Portland</City><State>ME</State><ZipCode>04103-2779</ZipCode></Address><Phone/><DriverLicense/></PersonSearch></UserTermRecord></ns3:UserTermsSection></SectionDetails></SectionResults><SectionResults><SectionName>QuickAnalysisFlagSection</SectionName><CLEARReportDescription>Quick Analysis Flags</CLEARReportDescription><SectionStatus>COMPLETE</SectionStatus><SectionRecordCount>1</SectionRecordCount><SectionDetails><ns3:QuickAnalysisFlagSection><QuickAnalysisFlagRecord><RiskFlags/><RiskFlagsWithDocguids><AssocWithOFACGlobalPEP><RiskFlag>No</RiskFlag></AssocWithOFACGlobalPEP><OFAC><RiskFlag>No</RiskFlag></OFAC><GlobalSanctions><RiskFlag>No</RiskFlag></GlobalSanctions><ResidentialUsedAsBusiness><RiskFlag>Yes</RiskFlag><DocumentGuids><SourceName>Dun &amp; Bradstreet</SourceName><SourceDocumentGuid>I7F534FDCB63311D49DEB0C00C20D8B6F</SourceDocumentGuid></DocumentGuids><DocumentGuids><SourceName>Corp Record</SourceName><SourceDocumentGuid>I1ca470c24ecb11de9b8c850332338889</SourceDocumentGuid></DocumentGuids></ResidentialUsedAsBusiness><PrisonAddress><RiskFlag>No</RiskFlag></PrisonAddress><POBoxAddress><RiskFlag>Yes</RiskFlag><DocumentGuids><SourceName>Experian</SourceName><SourceDocumentGuid>Iebe876111e2011dd86d5f687b7443f19</SourceDocumentGuid></DocumentGuids><DocumentGuids><SourceName>Equifax</SourceName><SourceDocumentGuid>Iaa046483a46b11e79bef99c0ee06c731</SourceDocumentGuid></DocumentGuids></POBoxAddress><Bankruptcy><RiskFlag>No</RiskFlag></Bankruptcy><AssocRelativeWithResidentialUsedAsBusiness><RiskFlag>Yes</RiskFlag><DocumentGuids><SourceName>Corp Record</SourceName><SourceDocumentGuid>I540528a057db11eaadfea82903531a62</SourceDocumentGuid></DocumentGuids><DocumentGuids><SourceName>Corp Record</SourceName><SourceDocumentGuid>If640b58032b711e89bf099c0ee06c731</SourceDocumentGuid></DocumentGuids><DocumentGuids><SourceName>Corp Record</SourceName><SourceDocumentGuid>I2ae2eee0df9411e9adfea82903531a62</SourceDocumentGuid></DocumentGuids><DocumentGuids><SourceName>Corp Record</SourceName><SourceDocumentGuid>Ic1d5f54191ba11e9adfea82903531a62</SourceDocumentGuid></DocumentGuids><DocumentGuids><SourceName>Corp Record</SourceName><SourceDocumentGuid>I9f3b23d0b08a11eabea3f0dc9fb69570</SourceDocumentGuid></DocumentGuids><DocumentGuids><SourceName>Business Profile</SourceName><SourceDocumentGuid>I1f2bfcb0be1111ebbea4f0dc9fb69570</SourceDocumentGuid></DocumentGuids><DocumentGuids><SourceName>Executive Profile</SourceName><SourceDocumentGuid>I732fa590a81911e698dc8b09b4f043e0</SourceDocumentGuid></DocumentGuids><DocumentGuids><SourceName>Executive Profile</SourceName><SourceDocumentGuid>I21fc7bb1db1111e598dc8b09b4f043e0</SourceDocumentGuid></DocumentGuids><DocumentGuids><SourceName>Business Phone</SourceName><SourceDocumentGuid>I76E2F8B0744111D788560E00E20D7175</SourceDocumentGuid></DocumentGuids><DocumentGuids><SourceName>Business Profile</SourceName><SourceDocumentGuid>I0afc0713621111e08b05fdf15589d8e8</SourceDocumentGuid></DocumentGuids><DocumentGuids><SourceName>Corp Record</SourceName><SourceDocumentGuid>I5d9f3090d66c11df9b8c850332338889</SourceDocumentGuid></DocumentGuids></AssocRelativeWithResidentialUsedAsBusiness><AssocRelativeWithPrisonAddress><RiskFlag>No</RiskFlag></AssocRelativeWithPrisonAddress><AssocRelativeWithPOBoxAddress><RiskFlag>Yes</RiskFlag><DocumentGuids><SourceName>TransUnion</SourceName><SourceDocumentGuid>IC29E0A94E11511D58E860E00E20D7175</SourceDocumentGuid></DocumentGuids><DocumentGuids><SourceName>Historic Credit Bureau</SourceName><SourceDocumentGuid>Ic7914c82b14d11de9b8c850332338889</SourceDocumentGuid></DocumentGuids><DocumentGuids><SourceName>Bank Account Header Records</SourceName><SourceDocumentGuid>I5a513d85f23a11eabea4f0dc9fb69570</SourceDocumentGuid></DocumentGuids><DocumentGuids><SourceName>Experian</SourceName><SourceDocumentGuid>I110d84701e6d11dd86d5f687b7443f19</SourceDocumentGuid></DocumentGuids><DocumentGuids><SourceName>Experian</SourceName><SourceDocumentGuid>I5125a8f1282011ddb86fead008c6b935</SourceDocumentGuid></DocumentGuids><DocumentGuids><SourceName>Bank Account Header Records</SourceName><SourceDocumentGuid>Iaf676231ed3111eabea4f0dc9fb69570</SourceDocumentGuid></DocumentGuids><DocumentGuids><SourceName>Corp Record</SourceName><SourceDocumentGuid>I9f3b23d0b08a11eabea3f0dc9fb69570</SourceDocumentGuid></DocumentGuids><DocumentGuids><SourceName>Corp Record</SourceName><SourceDocumentGuid>Ic1d5f54191ba11e9adfea82903531a62</SourceDocumentGuid></DocumentGuids><DocumentGuids><SourceName>Corp Record</SourceName><SourceDocumentGuid>If640b58032b711e89bf099c0ee06c731</SourceDocumentGuid></DocumentGuids><DocumentGuids><SourceName>Corp Record</SourceName><SourceDocumentGuid>I2ae2eee0df9411e9adfea82903531a62</SourceDocumentGuid></DocumentGuids><DocumentGuids><SourceName>Phone Record</SourceName><SourceDocumentGuid>Ic3f10d601c3411e598db8b09b4f043e0</SourceDocumentGuid></DocumentGuids><DocumentGuids><SourceName>Household Listing</SourceName><SourceDocumentGuid>I71213940b98111e498db8b09b4f043e0</SourceDocumentGuid></DocumentGuids><DocumentGuids><SourceName>Historic Credit Bureau</SourceName><SourceDocumentGuid>I71f06e86ab9611de9b8c850332338889</SourceDocumentGuid></DocumentGuids><DocumentGuids><SourceName>Experian</SourceName><SourceDocumentGuid>I141f58501e6d11ddb827ead008c6b935</SourceDocumentGuid></DocumentGuids><DocumentGuids><SourceName>Experian</SourceName><SourceDocumentGuid>Ibc1ea6f0289011dd935de7477da167c1</SourceDocumentGuid></DocumentGuids><DocumentGuids><SourceName>Bank Account Header Records</SourceName><SourceDocumentGuid>I5ec0fb17034e11ebbea4f0dc9fb69570</SourceDocumentGuid></DocumentGuids><DocumentGuids><SourceName>Experian</SourceName><SourceDocumentGuid>I260269611f0611dd86d5f687b7443f19</SourceDocumentGuid></DocumentGuids><DocumentGuids><SourceName>Experian</SourceName><SourceDocumentGuid>Ia2c17b4028ba11ddb877ead008c6b935</SourceDocumentGuid></DocumentGuids><DocumentGuids><SourceName>Bank Account Header Records</SourceName><SourceDocumentGuid>I36776502f79a11eabea4f0dc9fb69570</SourceDocumentGuid></DocumentGuids></AssocRelativeWithPOBoxAddress><Criminal><RiskFlag>No</RiskFlag></Criminal><CriminalLowLevelTrafficOffense><RiskFlag>No</RiskFlag></CriminalLowLevelTrafficOffense><CriminalUncategorized><RiskFlag>No</RiskFlag></CriminalUncategorized><MultipleSSN><RiskFlag>No</RiskFlag></MultipleSSN><SSNMultipleIndividuals><RiskFlag>Yes</RiskFlag><DocumentGuids><SourceName>Utility Listing</SourceName><SourceDocumentGuid>If179e4c3af8811e79bef99c0ee06c731</SourceDocumentGuid></DocumentGuids></SSNMultipleIndividuals><RecordedAsDeceased><RiskFlag>No</RiskFlag></RecordedAsDeceased><AgeYoungerThanSSN><RiskFlag>No</RiskFlag></AgeYoungerThanSSN><AddressReportedLessNinetyDays><RiskFlag>No</RiskFlag></AddressReportedLessNinetyDays><SSNFormatInvalid><RiskFlag>No</RiskFlag></SSNFormatInvalid><HealthcareSanction><RiskFlag>No</RiskFlag></HealthcareSanction><PhoneNumberInconsistentAddress><RiskFlag>No</RiskFlag></PhoneNumberInconsistentAddress><Arrest><RiskFlag>No</RiskFlag></Arrest><AssociatedWithMarijuanaBusiness><RiskFlag>No</RiskFlag></AssociatedWithMarijuanaBusiness></RiskFlagsWithDocguids></QuickAnalysisFlagRecord></ns3:QuickAnalysisFlagSection></SectionDetails></SectionResults></ns12:PersonReportDetails>'
        );
        res1.setStatusCode(200);
        finalresponse = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><ns12:PersonReportDetails xmlns:ns2="com/thomsonreuters/schemas/common-data" xmlns:ns3="com/thomsonreuters/schemas/person-report" xmlns:ns4="com/thomsonreuters/schemas/criminal-data" xmlns:ns5="com/thomsonreuters/schemas/court-data" xmlns:ns6="com/thomsonreuters/schemas/business-data" xmlns:ns7="com/thomsonreuters/schemas/license-data" xmlns:ns8="com/thomsonreuters/schemas/news-search" xmlns:ns9="com/thomsonreuters/schemas/company-report" xmlns:ns10="com/thomsonreuters/schemas/vehicle-data" xmlns:ns11="com/thomsonreuters/schemas/webanalytics-search" xmlns:ns12="http://clear.thomsonreuters.com/api/report/2.0"><Status><StatusCode>200</StatusCode><SubStatusCode>200</SubStatusCode><Reference>S2S Person Report</Reference></Status><ReportId>4c6299c8a9524174823205fa87eb90df</ReportId><SectionResults><SectionName>UserTermsSection</SectionName><CLEARReportDescription>User Search Terms</CLEARReportDescription><SectionStatus>COMPLETE</SectionStatus><SectionRecordCount>1</SectionRecordCount><SectionDetails><ns3:UserTermsSection><UserTermRecord><PersonSearch><Name><FirstName>Daniel</FirstName><LastName>Galli</LastName></Name><PersonProfile/><SSN/><Address><Street>1024 Washington Ave</Street><City>Portland</City><State>ME</State><ZipCode>04103-2779</ZipCode></Address><Phone/><DriverLicense/></PersonSearch></UserTermRecord></ns3:UserTermsSection></SectionDetails></SectionResults><SectionResults><SectionName>QuickAnalysisFlagSection</SectionName><CLEARReportDescription>Quick Analysis Flags</CLEARReportDescription><SectionStatus>COMPLETE</SectionStatus><SectionRecordCount>1</SectionRecordCount><SectionDetails><ns3:QuickAnalysisFlagSection><QuickAnalysisFlagRecord><RiskFlags/><RiskFlagsWithDocguids><AssocWithOFACGlobalPEP><RiskFlag>No</RiskFlag></AssocWithOFACGlobalPEP><OFAC><RiskFlag>No</RiskFlag></OFAC><GlobalSanctions><RiskFlag>No</RiskFlag></GlobalSanctions><ResidentialUsedAsBusiness><RiskFlag>Yes</RiskFlag><DocumentGuids><SourceName>Dun &amp; Bradstreet</SourceName><SourceDocumentGuid>I7F534FDCB63311D49DEB0C00C20D8B6F</SourceDocumentGuid></DocumentGuids><DocumentGuids><SourceName>Corp Record</SourceName><SourceDocumentGuid>I1ca470c24ecb11de9b8c850332338889</SourceDocumentGuid></DocumentGuids></ResidentialUsedAsBusiness><PrisonAddress><RiskFlag>No</RiskFlag></PrisonAddress><POBoxAddress><RiskFlag>Yes</RiskFlag><DocumentGuids><SourceName>Experian</SourceName><SourceDocumentGuid>Iebe876111e2011dd86d5f687b7443f19</SourceDocumentGuid></DocumentGuids><DocumentGuids><SourceName>Equifax</SourceName><SourceDocumentGuid>Iaa046483a46b11e79bef99c0ee06c731</SourceDocumentGuid></DocumentGuids></POBoxAddress><Bankruptcy><RiskFlag>No</RiskFlag></Bankruptcy><AssocRelativeWithResidentialUsedAsBusiness><RiskFlag>Yes</RiskFlag><DocumentGuids><SourceName>Corp Record</SourceName><SourceDocumentGuid>I540528a057db11eaadfea82903531a62</SourceDocumentGuid></DocumentGuids><DocumentGuids><SourceName>Corp Record</SourceName><SourceDocumentGuid>If640b58032b711e89bf099c0ee06c731</SourceDocumentGuid></DocumentGuids><DocumentGuids><SourceName>Corp Record</SourceName><SourceDocumentGuid>I2ae2eee0df9411e9adfea82903531a62</SourceDocumentGuid></DocumentGuids><DocumentGuids><SourceName>Corp Record</SourceName><SourceDocumentGuid>Ic1d5f54191ba11e9adfea82903531a62</SourceDocumentGuid></DocumentGuids><DocumentGuids><SourceName>Corp Record</SourceName><SourceDocumentGuid>I9f3b23d0b08a11eabea3f0dc9fb69570</SourceDocumentGuid></DocumentGuids><DocumentGuids><SourceName>Business Profile</SourceName><SourceDocumentGuid>I1f2bfcb0be1111ebbea4f0dc9fb69570</SourceDocumentGuid></DocumentGuids><DocumentGuids><SourceName>Executive Profile</SourceName><SourceDocumentGuid>I732fa590a81911e698dc8b09b4f043e0</SourceDocumentGuid></DocumentGuids><DocumentGuids><SourceName>Executive Profile</SourceName><SourceDocumentGuid>I21fc7bb1db1111e598dc8b09b4f043e0</SourceDocumentGuid></DocumentGuids><DocumentGuids><SourceName>Business Phone</SourceName><SourceDocumentGuid>I76E2F8B0744111D788560E00E20D7175</SourceDocumentGuid></DocumentGuids><DocumentGuids><SourceName>Business Profile</SourceName><SourceDocumentGuid>I0afc0713621111e08b05fdf15589d8e8</SourceDocumentGuid></DocumentGuids><DocumentGuids><SourceName>Corp Record</SourceName><SourceDocumentGuid>I5d9f3090d66c11df9b8c850332338889</SourceDocumentGuid></DocumentGuids></AssocRelativeWithResidentialUsedAsBusiness><AssocRelativeWithPrisonAddress><RiskFlag>No</RiskFlag></AssocRelativeWithPrisonAddress><AssocRelativeWithPOBoxAddress><RiskFlag>Yes</RiskFlag><DocumentGuids><SourceName>TransUnion</SourceName><SourceDocumentGuid>IC29E0A94E11511D58E860E00E20D7175</SourceDocumentGuid></DocumentGuids><DocumentGuids><SourceName>Historic Credit Bureau</SourceName><SourceDocumentGuid>Ic7914c82b14d11de9b8c850332338889</SourceDocumentGuid></DocumentGuids><DocumentGuids><SourceName>Bank Account Header Records</SourceName><SourceDocumentGuid>I5a513d85f23a11eabea4f0dc9fb69570</SourceDocumentGuid></DocumentGuids><DocumentGuids><SourceName>Experian</SourceName><SourceDocumentGuid>I110d84701e6d11dd86d5f687b7443f19</SourceDocumentGuid></DocumentGuids><DocumentGuids><SourceName>Experian</SourceName><SourceDocumentGuid>I5125a8f1282011ddb86fead008c6b935</SourceDocumentGuid></DocumentGuids><DocumentGuids><SourceName>Bank Account Header Records</SourceName><SourceDocumentGuid>Iaf676231ed3111eabea4f0dc9fb69570</SourceDocumentGuid></DocumentGuids><DocumentGuids><SourceName>Corp Record</SourceName><SourceDocumentGuid>I9f3b23d0b08a11eabea3f0dc9fb69570</SourceDocumentGuid></DocumentGuids><DocumentGuids><SourceName>Corp Record</SourceName><SourceDocumentGuid>Ic1d5f54191ba11e9adfea82903531a62</SourceDocumentGuid></DocumentGuids><DocumentGuids><SourceName>Corp Record</SourceName><SourceDocumentGuid>If640b58032b711e89bf099c0ee06c731</SourceDocumentGuid></DocumentGuids><DocumentGuids><SourceName>Corp Record</SourceName><SourceDocumentGuid>I2ae2eee0df9411e9adfea82903531a62</SourceDocumentGuid></DocumentGuids><DocumentGuids><SourceName>Phone Record</SourceName><SourceDocumentGuid>Ic3f10d601c3411e598db8b09b4f043e0</SourceDocumentGuid></DocumentGuids><DocumentGuids><SourceName>Household Listing</SourceName><SourceDocumentGuid>I71213940b98111e498db8b09b4f043e0</SourceDocumentGuid></DocumentGuids><DocumentGuids><SourceName>Historic Credit Bureau</SourceName><SourceDocumentGuid>I71f06e86ab9611de9b8c850332338889</SourceDocumentGuid></DocumentGuids><DocumentGuids><SourceName>Experian</SourceName><SourceDocumentGuid>I141f58501e6d11ddb827ead008c6b935</SourceDocumentGuid></DocumentGuids><DocumentGuids><SourceName>Experian</SourceName><SourceDocumentGuid>Ibc1ea6f0289011dd935de7477da167c1</SourceDocumentGuid></DocumentGuids><DocumentGuids><SourceName>Bank Account Header Records</SourceName><SourceDocumentGuid>I5ec0fb17034e11ebbea4f0dc9fb69570</SourceDocumentGuid></DocumentGuids><DocumentGuids><SourceName>Experian</SourceName><SourceDocumentGuid>I260269611f0611dd86d5f687b7443f19</SourceDocumentGuid></DocumentGuids><DocumentGuids><SourceName>Experian</SourceName><SourceDocumentGuid>Ia2c17b4028ba11ddb877ead008c6b935</SourceDocumentGuid></DocumentGuids><DocumentGuids><SourceName>Bank Account Header Records</SourceName><SourceDocumentGuid>I36776502f79a11eabea4f0dc9fb69570</SourceDocumentGuid></DocumentGuids></AssocRelativeWithPOBoxAddress><Criminal><RiskFlag>No</RiskFlag></Criminal><CriminalLowLevelTrafficOffense><RiskFlag>No</RiskFlag></CriminalLowLevelTrafficOffense><CriminalUncategorized><RiskFlag>No</RiskFlag></CriminalUncategorized><MultipleSSN><RiskFlag>No</RiskFlag></MultipleSSN><SSNMultipleIndividuals><RiskFlag>Yes</RiskFlag><DocumentGuids><SourceName>Utility Listing</SourceName><SourceDocumentGuid>If179e4c3af8811e79bef99c0ee06c731</SourceDocumentGuid></DocumentGuids></SSNMultipleIndividuals><RecordedAsDeceased><RiskFlag>No</RiskFlag></RecordedAsDeceased><AgeYoungerThanSSN><RiskFlag>No</RiskFlag></AgeYoungerThanSSN><AddressReportedLessNinetyDays><RiskFlag>No</RiskFlag></AddressReportedLessNinetyDays><SSNFormatInvalid><RiskFlag>No</RiskFlag></SSNFormatInvalid><HealthcareSanction><RiskFlag>No</RiskFlag></HealthcareSanction><PhoneNumberInconsistentAddress><RiskFlag>No</RiskFlag></PhoneNumberInconsistentAddress><Arrest><RiskFlag>No</RiskFlag></Arrest><AssociatedWithMarijuanaBusiness><RiskFlag>No</RiskFlag></AssociatedWithMarijuanaBusiness></RiskFlagsWithDocguids></QuickAnalysisFlagRecord></ns3:QuickAnalysisFlagSection></SectionDetails></SectionResults></ns12:PersonReportDetails>';
      }
      /* 
      string response='';
      if(Test.isRunningTest()==false){
        res = http.send(req);
        response = res.getBody();
      }
      else{
        res.setBody('<?xml version="1.0" encoding="UTF-8" standalone="yes"?><ns2:PersonResults xmlns:ns2="http://clear.thomsonreuters.com/api/search/2.0"><Status><StatusCode>200</StatusCode><SubStatusCode>0</SubStatusCode></Status><Uri>https://s2s.beta.thomsonreuters.com/api/v2/person/searchResults/8a57c89268a623ec016909c791112578</Uri><GroupCount>1</GroupCount></ns2:PersonResults>');
        res.setStatusCode(200);
        response='<?xml version="1.0" encoding="UTF-8" standalone="yes"?><ns2:PersonResults xmlns:ns2="http://clear.thomsonreuters.com/api/search/2.0"><Status><StatusCode>200</StatusCode><SubStatusCode>0</SubStatusCode></Status><Uri>https://s2s.beta.thomsonreuters.com/api/v2/person/searchResults/8a57c89268a623ec016909c791112578</Uri><GroupCount>1</GroupCount></ns2:PersonResults>';
      } */

      system.debug('finalresponse::::' + finalresponse);
      system.debug('res1.getStatusCode()::::' + res1.getStatusCode());

      DOM.Document document1 = new DOM.Document();
      document1.load(finalresponse);

      if (res1.getStatusCode() == 200) {
        for (
          Dom.XmlNode fluxNode : document1.getRootElement().getChildElements()
        ) {
          for (Dom.XmlNode fluxChildNode : fluxNode.getChildElements()) {
            String ns2 = 'com/thomsonreuters/schemas/person-report';
            Dom.XmlNode ns = fluxChildNode.getChildElement(
              'QuickAnalysisFlagSection',
              ns2
            );
            if (ns != null) {
              Dom.XmlNode QuickAnalysisFlagRecord = ns.getChildElement(
                'QuickAnalysisFlagRecord',
                null
              );
              Dom.XmlNode RiskFlagsWithDocguids = QuickAnalysisFlagRecord.getChildElement(
                'RiskFlagsWithDocguids',
                null
              );

              Dom.XmlNode AssocWithOFACGlobalPEPNode = RiskFlagsWithDocguids.getChildElement(
                'AssocWithOFACGlobalPEP',
                null
              );
              AssocWithOFACGlobalPEP = AssocWithOFACGlobalPEPNode.getChildElement(
                    'RiskFlag',
                    null
                  )
                  .getText() == 'Yes'
                ? 'true'
                : 'false';
              system.debug(
                'AssocWithOFACGlobalPEP::::' + AssocWithOFACGlobalPEP
              );

              Dom.XmlNode OFACNode = RiskFlagsWithDocguids.getChildElement(
                'OFAC',
                null
              );
              OFAC = OFACNode.getChildElement('RiskFlag', null).getText() ==
                'Yes'
                ? 'true'
                : 'false';
              system.debug('OFAC::::' + OFAC);

              Dom.XmlNode GlobalSanctionsNode = RiskFlagsWithDocguids.getChildElement(
                'GlobalSanctions',
                null
              );
              GlobalSanctions = GlobalSanctionsNode.getChildElement(
                    'RiskFlag',
                    null
                  )
                  .getText() == 'Yes'
                ? 'true'
                : 'false';
              system.debug('GlobalSanctions::::' + GlobalSanctions);

              Dom.XmlNode ResidentialUsedAsBusinessNode = RiskFlagsWithDocguids.getChildElement(
                'ResidentialUsedAsBusiness',
                null
              );
              ResidentialUsedAsBusiness = ResidentialUsedAsBusinessNode.getChildElement(
                    'RiskFlag',
                    null
                  )
                  .getText() == 'Yes'
                ? 'true'
                : 'false';
              system.debug(
                'ResidentialUsedAsBusiness::::' + ResidentialUsedAsBusiness
              );

              Dom.XmlNode PrisonAddressNode = RiskFlagsWithDocguids.getChildElement(
                'PrisonAddress',
                null
              );
              PrisonAddress = PrisonAddressNode.getChildElement(
                    'RiskFlag',
                    null
                  )
                  .getText() == 'Yes'
                ? 'true'
                : 'false';
              system.debug('PrisonAddress::::' + PrisonAddress);

              Dom.XmlNode POBoxAddressNode = RiskFlagsWithDocguids.getChildElement(
                'POBoxAddress',
                null
              );
              POBoxAddress = POBoxAddressNode.getChildElement('RiskFlag', null)
                  .getText() == 'Yes'
                ? 'true'
                : 'false';
              system.debug('POBoxAddress::::' + POBoxAddress);

              Dom.XmlNode BankruptcyNode = RiskFlagsWithDocguids.getChildElement(
                'Bankruptcy',
                null
              );
              Bankruptcy = BankruptcyNode.getChildElement('RiskFlag', null)
                  .getText() == 'Yes'
                ? 'true'
                : 'false';
              system.debug('Bankruptcy::::' + Bankruptcy);

              Dom.XmlNode AssocRelativeWithResidentialUsedAsBusinessNode = RiskFlagsWithDocguids.getChildElement(
                'AssocRelativeWithResidentialUsedAsBusiness',
                null
              );
              AssocRelativeWithResidentialUsedAsBusiness = AssocRelativeWithResidentialUsedAsBusinessNode.getChildElement(
                    'RiskFlag',
                    null
                  )
                  .getText() == 'Yes'
                ? 'true'
                : 'false';
              system.debug(
                'AssocRelativeWithResidentialUsedAsBusiness::::' +
                AssocRelativeWithResidentialUsedAsBusiness
              );

              Dom.XmlNode AssocRelativeWithPrisonAddressNode = RiskFlagsWithDocguids.getChildElement(
                'AssocRelativeWithPrisonAddress',
                null
              );
              AssocRelativeWithPrisonAddress = AssocRelativeWithPrisonAddressNode.getChildElement(
                    'RiskFlag',
                    null
                  )
                  .getText() == 'Yes'
                ? 'true'
                : 'false';
              system.debug(
                'AssocRelativeWithPrisonAddress::::' +
                AssocRelativeWithPrisonAddress
              );

              Dom.XmlNode AssocRelativeWithPOBoxAddressNode = RiskFlagsWithDocguids.getChildElement(
                'AssocRelativeWithPOBoxAddress',
                null
              );
              AssocRelativeWithPOBoxAddress = AssocRelativeWithPOBoxAddressNode.getChildElement(
                    'RiskFlag',
                    null
                  )
                  .getText() == 'Yes'
                ? 'true'
                : 'false';
              system.debug(
                'AssocRelativeWithPOBoxAddress::::' +
                AssocRelativeWithPOBoxAddress
              );

              Dom.XmlNode CriminalNode = RiskFlagsWithDocguids.getChildElement(
                'Criminal',
                null
              );
              Criminal = CriminalNode.getChildElement('RiskFlag', null)
                  .getText() == 'Yes'
                ? 'true'
                : 'false';
              system.debug('Criminal::::' + Criminal);

              Dom.XmlNode MultipleSSNNode = RiskFlagsWithDocguids.getChildElement(
                'MultipleSSN',
                null
              );
              MultipleSSN = MultipleSSNNode.getChildElement('RiskFlag', null)
                  .getText() == 'Yes'
                ? 'true'
                : 'false';
              system.debug('MultipleSSN::::' + MultipleSSN);

              Dom.XmlNode SSNMultipleIndividualsNode = RiskFlagsWithDocguids.getChildElement(
                'SSNMultipleIndividuals',
                null
              );
              SSNMultipleIndividuals = SSNMultipleIndividualsNode.getChildElement(
                    'RiskFlag',
                    null
                  )
                  .getText() == 'Yes'
                ? 'true'
                : 'false';
              system.debug(
                'SSNMultipleIndividuals::::' + SSNMultipleIndividuals
              );

              Dom.XmlNode RecordedAsDeceasedNode = RiskFlagsWithDocguids.getChildElement(
                'RecordedAsDeceased',
                null
              );
              RecordedAsDeceased = RecordedAsDeceasedNode.getChildElement(
                    'RiskFlag',
                    null
                  )
                  .getText() == 'Yes'
                ? 'true'
                : 'false';
              system.debug('RecordedAsDeceased::::' + RecordedAsDeceased);

              Dom.XmlNode AgeYoungerThanSSNNode = RiskFlagsWithDocguids.getChildElement(
                'AgeYoungerThanSSN',
                null
              );
              AgeYoungerThanSSN = AgeYoungerThanSSNNode.getChildElement(
                    'RiskFlag',
                    null
                  )
                  .getText() == 'Yes'
                ? 'true'
                : 'false';
              system.debug('AgeYoungerThanSSN::::' + AgeYoungerThanSSN);

              Dom.XmlNode AddressReportedLessNinetyDaysNode = RiskFlagsWithDocguids.getChildElement(
                'AddressReportedLessNinetyDays',
                null
              );
              AddressReportedLessNinetyDays = AddressReportedLessNinetyDaysNode.getChildElement(
                    'RiskFlag',
                    null
                  )
                  .getText() == 'Yes'
                ? 'true'
                : 'false';
              system.debug(
                'AddressReportedLessNinetyDays::::' +
                AddressReportedLessNinetyDays
              );

              Dom.XmlNode SSNFormatInvalidNode = RiskFlagsWithDocguids.getChildElement(
                'SSNFormatInvalid',
                null
              );
              SSNFormatInvalid = SSNFormatInvalidNode.getChildElement(
                    'RiskFlag',
                    null
                  )
                  .getText() == 'Yes'
                ? 'true'
                : 'false';
              system.debug('SSNFormatInvalid::::' + SSNFormatInvalid);

              Dom.XmlNode HealthcareSanctionNode = RiskFlagsWithDocguids.getChildElement(
                'HealthcareSanction',
                null
              );
              HealthcareSanction = HealthcareSanctionNode.getChildElement(
                    'RiskFlag',
                    null
                  )
                  .getText() == 'Yes'
                ? 'true'
                : 'false';
              system.debug('HealthcareSanction::::' + HealthcareSanction);

              Dom.XmlNode PhoneNumberInconsistentAddressNode = RiskFlagsWithDocguids.getChildElement(
                'PhoneNumberInconsistentAddress',
                null
              );
              PhoneNumberInconsistentAddress = PhoneNumberInconsistentAddressNode.getChildElement(
                    'RiskFlag',
                    null
                  )
                  .getText() == 'Yes'
                ? 'true'
                : 'false';
              system.debug(
                'PhoneNumberInconsistentAddress::::' +
                PhoneNumberInconsistentAddress
              );

              Dom.XmlNode ArrestNode = RiskFlagsWithDocguids.getChildElement(
                'Arrest',
                null
              );
              Arrest = ArrestNode.getChildElement('RiskFlag', null).getText() ==
                'Yes'
                ? 'true'
                : 'false';
              system.debug('Arrest::::' + Arrest);

              Dom.XmlNode AssociatedWithMarijuanaBusinessNode = RiskFlagsWithDocguids.getChildElement(
                'AssociatedWithMarijuanaBusiness',
                null
              );
              AssociatedWithMarijuanaBusiness = AssociatedWithMarijuanaBusinessNode.getChildElement(
                    'RiskFlag',
                    null
                  )
                  .getText() == 'Yes'
                ? 'true'
                : 'false';
              system.debug(
                'AssociatedWithMarijuanaBusiness::::' +
                AssociatedWithMarijuanaBusiness
              );
            }
          }
        }

        List<Clear_Result__c> clearResult = new List<Clear_Result__c>();
        List<Clear_Result__c> clearResultForUpdate = new List<Clear_Result__c>();
        clearResult = [
          SELECT
            Associate_with_OFAC_Global_Sanction_or__c,
            OFAC_listing__c,
            Global_Sanctions__c,
            Residential_Address_Used_as_a_Business_A__c,
            Prison_Address_on_Record__c,
            P_O_Box_listed_as_Address__c,
            Bankruptcy__c,
            Associate_or_Relative_With_a_Residential__c,
            Associate_or_Relative_with_a_Prison_Addr__c,
            Associate_or_Relative_with_P_O_Box_list__c,
            Criminal_Record__c,
            Multiple_SSNs__c,
            SSN_Matches_multiple_individuals__c,
            Recorded_as_Deceased__c,
            Age_Younger_than_SSN_Issue_Date__c,
            Address_1ST_Reported_90_Days__c,
            SSN_Format_is_Invalid__c,
            Healthcare_Sanction__c,
            Telephone_Number_Inconsistent_with_Addre__c,
            Arrest_Record__c,
            Person_Associated_with_Marijuana_Related__c
          FROM Clear_Result__c
          WHERE Contact__c = :id
          LIMIT 1
        ];

        for (Clear_Result__c crlist : clearResult) {
          Clear_Result__c cr = new Clear_Result__c();
          cr.id = crlist.id;
          cr.Associate_with_OFAC_Global_Sanction_or__c = boolean.valueOf(
            AssocWithOFACGlobalPEP
          );
          cr.OFAC_listing__c = boolean.valueOf(OFAC);
          cr.Global_Sanctions__c = boolean.valueOf(GlobalSanctions);
          cr.Residential_Address_Used_as_a_Business_A__c = boolean.valueOf(
            ResidentialUsedAsBusiness
          );
          cr.Prison_Address_on_Record__c = boolean.valueOf(PrisonAddress);
          cr.P_O_Box_listed_as_Address__c = boolean.valueOf(POBoxAddress);
          cr.Bankruptcy__c = boolean.valueOf(Bankruptcy);
          cr.Associate_or_Relative_With_a_Residential__c = boolean.valueOf(
            AssocRelativeWithResidentialUsedAsBusiness
          );
          cr.Associate_or_Relative_with_a_Prison_Addr__c = boolean.valueOf(
            AssocRelativeWithPrisonAddress
          );
          cr.Associate_or_Relative_with_P_O_Box_list__c = boolean.valueOf(
            AssocRelativeWithPOBoxAddress
          );
          cr.Criminal_Record__c = boolean.valueOf(Criminal);
          cr.Multiple_SSNs__c = boolean.valueOf(MultipleSSN);
          cr.SSN_Matches_multiple_individuals__c = boolean.valueOf(
            SSNMultipleIndividuals
          );
          cr.Recorded_as_Deceased__c = boolean.valueOf(RecordedAsDeceased);
          cr.Age_Younger_than_SSN_Issue_Date__c = boolean.valueOf(
            AgeYoungerThanSSN
          );
          cr.Address_1ST_Reported_90_Days__c = boolean.valueOf(
            AddressReportedLessNinetyDays
          );
          cr.SSN_Format_is_Invalid__c = boolean.valueOf(SSNFormatInvalid);
          cr.Healthcare_Sanction__c = boolean.valueOf(HealthcareSanction);
          cr.Telephone_Number_Inconsistent_with_Addre__c = boolean.valueOf(
            PhoneNumberInconsistentAddress
          );
          cr.Arrest_Record__c = boolean.valueOf(Arrest);
          cr.Person_Associated_with_Marijuana_Related__c = boolean.valueOf(
            AssociatedWithMarijuanaBusiness
          );
          clearResultForUpdate.add(cr);
        }
        system.debug('clearResultForUpdate::::' + clearResultForUpdate);
        update clearResultForUpdate;
      }
      System.enqueueJob(new APILoggerQueueable(request, res1, id, false));

    } catch (exception er) { 
      System.enqueueJob(new APILoggerQueueable(request, res1, id, er));
    }
    } catch (exception e) {
      System.debug('The following exception has occurred: ' + e.getMessage());
    }
  }

  @future(callout=true)
  public static void processlink(
    string link,
    ID id,
    string clearResultId,
    string typeofReport,
    string dealRecordId
  ) {
    // Map<String, String> resultlist = new  Map<String, String>();
    try {
      list<Deal_Contact__c> contactIDList = [
        SELECT id, name, Contact__c
        FROM Deal_Contact__c
        WHERE id = :id
        LIMIT 1
      ];
      system.debug('contactIDList:::::' + contactIDList);
      list<contact> contactList = [
        SELECT id, name
        FROM contact
        WHERE id = :contactIDList[0].Contact__c
        LIMIT 1
      ];

      system.debug('processlink:::dealRecordId::::' + dealRecordId);
      list<Deal_Document__c> dealDocList = new List<Deal_Document__c>();
      list<Attachment> attachmentList = new List<Attachment>();
      sleepDelay(40000);
      HttpRequest request = ClearBase.generategetRequest(Link, 'GET', null);
      Http http1 = new Http();
      HTTPResponse res1 = new HTTPResponse();
      blob finalresponse;
      /* res1 = http1.send(request);
                blob  finalresponse = res1.getBodyasBlob();
                system.debug('processlink::response=='+res1.getStatusCode());
                system.debug('processlink::finalresponse=='+finalresponse); */

      string response = '';

      try {

      if (Test.isRunningTest() == false) {
        res1 = http1.send(request);
        finalresponse = res1.getBodyasBlob();
        system.debug('processlink::response==' + res1.getStatusCode());
        system.debug('processlink::finalresponse==' + finalresponse);

        /* res = http.send(req);
         response = res.getBody(); */
      } else {
        res1.setBody('Unit Test Attachment Body');
        res1.setStatusCode(200);
        finalresponse = Blob.valueOf('Unit Test Attachment Body');
      }

      if (res1.getStatusCode() == 200) {
        list<Deal_Document__c> dealDocumentList = [
          SELECT id, Contact__c, Clear_Result_Report_Type__c
          FROM Deal_Document__c
          WHERE Contact__c = :contactList[0].id
        ];
        system.debug('dealDocumentList::::' + dealDocumentList);
        map<string, string> reportTypeVSDealDocIDMap = new Map<string, string>();
        for (Deal_Document__c dealDoc : dealDocumentList) {
          reportTypeVSDealDocIDMap.put(
            dealDoc.Clear_Result_Report_Type__c,
            dealDoc.id
          );
        }

        system.debug(
          'reportTypeVSDealDocIDMap:::::::' + reportTypeVSDealDocIDMap
        );

        if (typeofReport == 'PersonSearchReport') {
          if (dealDocumentList != null && dealDocumentList.size() > 0) {
            if (dealDocumentList.size() < 2) {
              for (Deal_Document__c dcList : dealDocumentList) {
                if (
                  dcList.Clear_Result_Report_Type__c == 'PersonSearchReport'
                ) {
                  Deal_Document__c dealDoc = new Deal_Document__c();
                  dealDoc.id = dcList.id;
                  dealDoc.Added_By__c = UserInfo.getUserId();
                  dealDoc.Added_On__c = Datetime.now();
                  dealDoc.File_Name__c =
                    contactList[0].name +
                    ' Clear Report ' +
                    System.now() +
                    '.pdf';

                  dealDocList.add(dealDoc);

                  ContentVersion cv = new ContentVersion();
                  cv.Title =
                    contactList[0].name +
                    ' Clear Report ' +
                    System.now() +
                    '.pdf';
                  cv.PathOnClient =
                    contactList[0].name +
                    ' Clear Report ' +
                    System.now() +
                    '.pdf';
                  cv.VersionData = finalresponse;
                  insert cv;

                  ContentVersion cvRecord = [
                    SELECT Id, ContentDocumentId
                    FROM ContentVersion
                    WHERE Id = :cv.Id
                  ];
                  ContentDocumentLink cl = new ContentDocumentLink();
                  cl.ContentDocumentId = cvRecord.ContentDocumentId;
                  //cl.LinkedEntityId = dealDocumentList[0].id;
                  cl.LinkedEntityId = reportTypeVSDealDocIDMap.get(
                    typeofReport
                  );
                  cl.ShareType = 'V';
                  cl.Visibility = 'AllUsers';
                  insert cl;
                } else {
                  //createDealDocumentRecord(dealRecordId,contactIDList[0].Contact__c,id,typeofReport,contactList[0].name);

                  Deal_Document__c dealDoc = new Deal_Document__c();
                  dealDoc.Deal__c = dealRecordId;
                  dealDoc.Type__c = 'Diligence Documents';
                  dealDoc.Section__c = 'Background and Credit Search';
                  dealDoc.Document_Type__c = 'Sponsor Clear Search';
                  dealDoc.Contact__c = contactIDList[0].Contact__c;
                  dealDoc.Document_Loaded__c = true;
                  dealDoc.Deal_Contact__c = id;
                  dealDoc.Added_By__c = UserInfo.getUserId();
                  dealDoc.Added_On__c = Datetime.now();
                  dealDoc.Clear_Result_Report_Type__c = 'PersonSearchReport';
                  dealDoc.File_Name__c =
                    contactList[0].name +
                    ' Clear Report ' +
                    System.now() +
                    '.pdf';

                  dealDocList.add(dealDoc);
                }
              }
            } else {
              for (Deal_Document__c dcList : dealDocumentList) {
                if (
                  dcList.Clear_Result_Report_Type__c == 'PersonSearchReport'
                ) {
                  Deal_Document__c dealDoc = new Deal_Document__c();
                  dealDoc.id = dcList.id;
                  dealDoc.Added_By__c = UserInfo.getUserId();
                  dealDoc.Added_On__c = Datetime.now();
                  dealDoc.File_Name__c =
                    contactList[0].name +
                    ' Clear Report ' +
                    System.now() +
                    '.pdf';

                  dealDocList.add(dealDoc);

                  ContentVersion cv = new ContentVersion();
                  cv.Title =
                    contactList[0].name +
                    ' Clear Report ' +
                    System.now() +
                    '.pdf';
                  cv.PathOnClient =
                    contactList[0].name +
                    ' Clear Report ' +
                    System.now() +
                    '.pdf';
                  cv.VersionData = finalresponse;
                  insert cv;

                  ContentVersion cvRecord = [
                    SELECT Id, ContentDocumentId
                    FROM ContentVersion
                    WHERE Id = :cv.Id
                  ];
                  ContentDocumentLink cl = new ContentDocumentLink();
                  cl.ContentDocumentId = cvRecord.ContentDocumentId;
                  //cl.LinkedEntityId = dealDocumentList[0].id;
                  cl.LinkedEntityId = reportTypeVSDealDocIDMap.get(
                    typeofReport
                  );
                  cl.ShareType = 'V';
                  cl.Visibility = 'AllUsers';
                  insert cl;
                }
              }
            }
          } else {
            //createDealDocumentRecord(dealRecordId,contactIDList[0].Contact__c,id,typeofReport,contactList[0].name);

            Deal_Document__c dealDoc = new Deal_Document__c();
            dealDoc.Deal__c = dealRecordId;
            dealDoc.Type__c = 'Diligence Documents';
            dealDoc.Section__c = 'Background and Credit Search';
            dealDoc.Document_Type__c = 'Sponsor Clear Search';
            dealDoc.Contact__c = contactIDList[0].Contact__c;
            dealDoc.Document_Loaded__c = true;
            dealDoc.Deal_Contact__c = id;
            dealDoc.Added_By__c = UserInfo.getUserId();
            dealDoc.Added_On__c = Datetime.now();
            dealDoc.Clear_Result_Report_Type__c = 'PersonSearchReport';
            dealDoc.File_Name__c =
              contactList[0].name +
              ' Clear Report ' +
              System.now() +
              '.pdf';

            dealDocList.add(dealDoc);
          }
        }

        if (typeofReport == 'RiskSearchReport') {
          if (dealDocumentList != null && dealDocumentList.size() > 0) {
            if (dealDocumentList.size() < 2) {
              for (Deal_Document__c dcList : dealDocumentList) {
                if (dcList.Clear_Result_Report_Type__c == 'RiskSearchReport') {
                  Deal_Document__c dealDoc = new Deal_Document__c();
                  dealDoc.id = dcList.id;
                  dealDoc.Added_By__c = UserInfo.getUserId();
                  dealDoc.Added_On__c = Datetime.now();
                  dealDoc.File_Name__c =
                    contactList[0].name +
                    ' Risk Report ' +
                    System.now() +
                    '.pdf';

                  dealDocList.add(dealDoc);

                  ContentVersion cv = new ContentVersion();
                  cv.Title =
                    contactList[0].name +
                    ' Risk Report ' +
                    System.now() +
                    '.pdf';
                  cv.PathOnClient =
                    contactList[0].name +
                    ' Risk Report ' +
                    System.now() +
                    '.pdf';
                  cv.VersionData = finalresponse;
                  insert cv;

                  ContentVersion cvRecord = [
                    SELECT Id, ContentDocumentId
                    FROM ContentVersion
                    WHERE Id = :cv.Id
                  ];
                  ContentDocumentLink cl = new ContentDocumentLink();
                  cl.ContentDocumentId = cvRecord.ContentDocumentId;
                  //cl.LinkedEntityId = dealDocumentList[0].id;
                  cl.LinkedEntityId = reportTypeVSDealDocIDMap.get(
                    typeofReport
                  );
                  cl.ShareType = 'V';
                  cl.Visibility = 'AllUsers';
                  insert cl;
                } else {
                  //createDealDocumentRecord(dealRecordId,contactIDList[0].Contact__c,id,typeofReport,contactList[0].name);

                  Deal_Document__c dealDoc = new Deal_Document__c();
                  dealDoc.Deal__c = dealRecordId;
                  dealDoc.Type__c = 'Diligence Documents';
                  dealDoc.Section__c = 'Background and Credit Search';
                  dealDoc.Document_Type__c = 'Sponsor Risk Search';
                  dealDoc.Contact__c = contactIDList[0].Contact__c;
                  dealDoc.Document_Loaded__c = true;
                  dealDoc.Deal_Contact__c = id;
                  dealDoc.Added_By__c = UserInfo.getUserId();
                  dealDoc.Added_On__c = Datetime.now();
                  dealDoc.Clear_Result_Report_Type__c = 'RiskSearchReport';
                  dealDoc.File_Name__c =
                    contactList[0].name +
                    ' Risk Report ' +
                    System.now() +
                    '.pdf';

                  dealDocList.add(dealDoc);
                }
              }
            } else {
              for (Deal_Document__c dcList : dealDocumentList) {
                if (dcList.Clear_Result_Report_Type__c == 'RiskSearchReport') {
                  Deal_Document__c dealDoc = new Deal_Document__c();
                  dealDoc.id = dcList.id;
                  dealDoc.Added_By__c = UserInfo.getUserId();
                  dealDoc.Added_On__c = Datetime.now();
                  dealDoc.File_Name__c =
                    contactList[0].name +
                    ' Risk Report ' +
                    System.now() +
                    '.pdf';

                  dealDocList.add(dealDoc);

                  ContentVersion cv = new ContentVersion();
                  cv.Title =
                    contactList[0].name +
                    ' Risk Report ' +
                    System.now() +
                    '.pdf';
                  cv.PathOnClient =
                    contactList[0].name +
                    ' Risk Report ' +
                    System.now() +
                    '.pdf';
                  cv.VersionData = finalresponse;
                  insert cv;

                  ContentVersion cvRecord = [
                    SELECT Id, ContentDocumentId
                    FROM ContentVersion
                    WHERE Id = :cv.Id
                  ];
                  ContentDocumentLink cl = new ContentDocumentLink();
                  cl.ContentDocumentId = cvRecord.ContentDocumentId;
                  //cl.LinkedEntityId = dealDocumentList[0].id;
                  cl.LinkedEntityId = reportTypeVSDealDocIDMap.get(
                    typeofReport
                  );
                  cl.ShareType = 'V';
                  cl.Visibility = 'AllUsers';
                  insert cl;
                }
              }
            }
          } else {
            //createDealDocumentRecord(dealRecordId,contactIDList[0].Contact__c,id,typeofReport,contactList[0].name);

            Deal_Document__c dealDoc = new Deal_Document__c();
            dealDoc.Deal__c = dealRecordId;
            dealDoc.Type__c = 'Diligence Documents';
            dealDoc.Section__c = 'Background and Credit Search';
            dealDoc.Document_Type__c = 'Sponsor Clear Search';
            dealDoc.Contact__c = contactIDList[0].Contact__c;
            dealDoc.Document_Loaded__c = true;
            dealDoc.Deal_Contact__c = id;
            dealDoc.Added_By__c = UserInfo.getUserId();
            dealDoc.Added_On__c = Datetime.now();
            dealDoc.Clear_Result_Report_Type__c = 'PersonSearchReport';
            dealDoc.File_Name__c =
              contactList[0].name +
              ' Clear Report ' +
              System.now() +
              '.pdf';

            dealDocList.add(dealDoc);
          }
        }

        system.debug('dealDocList::::' + dealDocList);

        Attachment attach = new Attachment();
        attach.contentType = 'application/pdf';
        attach.Body = finalresponse;
        //attach.Name =   typeofReport + system.today() + '.pdf';
        if (typeofReport == 'PersonSearchReport') {
          attach.Name =
            contactList[0].name +
            ' Clear Report ' +
            System.now() +
            '.pdf';
        }
        if (typeofReport == 'RiskSearchReport') {
          attach.Name =
            contactList[0].name +
            ' Risk Report ' +
            System.now() +
            '.pdf';
        }
        attach.IsPrivate = false;
        attach.ParentId = clearResultId;
        attachmentList.add(attach);
        insert attach;

        if (dealDocList != null && dealDocList.size() > 0) {
          Database.UpsertResult[] srList = Database.upsert(dealDocList, false);

          for (Database.UpsertResult sr : srList) {
            if (sr.isSuccess()) {
              // Operation was successful, so get the ID of the record that was processed
              System.debug('Successfully inserted.  ID: ' + sr.getId());

              if (sr.isCreated()) {
                ContentVersion cv = new ContentVersion();
                if (typeofReport == 'PersonSearchReport') {
                  cv.Title =
                    contactList[0].name +
                    ' Clear Report ' +
                    System.now() +
                    '.pdf';
                  cv.PathOnClient =
                    contactList[0].name +
                    ' Clear Report ' +
                    System.now() +
                    '.pdf';
                }
                if (typeofReport == 'RiskSearchReport') {
                  cv.Title =
                    contactList[0].name +
                    ' Risk Report ' +
                    System.now() +
                    '.pdf';
                  cv.PathOnClient =
                    contactList[0].name +
                    ' Risk Report ' +
                    System.now() +
                    '.pdf';
                }

                cv.VersionData = finalresponse;
                insert cv;

                ContentVersion cvRecord = [
                  SELECT Id, ContentDocumentId
                  FROM ContentVersion
                  WHERE Id = :cv.Id
                ];
                ContentDocumentLink cl = new ContentDocumentLink();
                cl.ContentDocumentId = cvRecord.ContentDocumentId;
                cl.LinkedEntityId = sr.getId();
                cl.ShareType = 'V';
                cl.Visibility = 'AllUsers';
                insert cl;

                Deal_Document__c dealDOcObj = new Deal_Document__c();
                dealDOcObj.id = sr.getId();
                dealDOcObj.Attachment_Id__c = cvRecord.ContentDocumentId;
                update dealDOcObj;
              }
            } else {
              // Operation failed, so get all errors
              for (Database.Error err : sr.getErrors()) {
                System.debug('The following error has occurred.');
                System.debug(err.getStatusCode() + ': ' + err.getMessage());
                System.debug(
                  'fields that affected this error: ' + err.getFields()
                );
              }
            }
          }
        }
      }
      Clear_Result__c crobj = new Clear_Result__c();
      crobj.id = clearResultId;
      if (typeofReport == 'PersonSearchReport') {
        crobj.Person_Search_Report_Result__c = String.valueof(
          res1.getStatusCode()
        );
      }
      if (typeofReport == 'RiskSearchReport') {
        crobj.Risk_Search_Report_Result__c = String.valueof(
          res1.getStatusCode()
        );
      }
      update crobj;
      System.enqueueJob(new APILoggerQueueable(request, res1, id, false));
    } catch (exception er) {
      System.enqueueJob(new APILoggerQueueable(request, res1, id, er));
    }
    } catch (exception e) {
      System.debug('The following exception has occurred: ' + e.getMessage());
    }
  }

  @auraenabled
  public static Boolean getEntityId(list<string> conRecordID) {
    Boolean isEntityId = false;

    if (conRecordID != null || conRecordID.size() > 0) {
      for (Clear_Result__c crList : [
        SELECT id, Contact__c, EntityId__c
        FROM Clear_Result__c
        WHERE Contact__c = :conRecordID
      ]) {
        system.debug('crList:::' + crList);
        if (crList.EntityId__c == null || crList.EntityId__c == '') {
          isEntityId = false;
          break;
        } else {
          isEntityId = true;
        }
      }
    }
    system.debug('isEntityId:::' + isEntityId);
    return isEntityId;
  }

  /*  @auraenabled 
    public static string checkConAddressAndBirthDate(list<string> conRecordID) {
        string message = '';
        system.debug('conRecordID::::'+conRecordID);
        if(conRecordID != null || conRecordID.size() > 0){
            for(Contact con : [select id, FirstName,LastName,MailingCountry,MailingStreet,MailingCity,MailingState,MailingPostalCode,Birthdate from Contact where id=:conRecordID]){
                if(con.Birthdate == null){
                    message = 'Please Enter borrower Birthdate First.';
                }
            }
        }
        system.debug('message::::'+message); 
        return message;
    } */
}