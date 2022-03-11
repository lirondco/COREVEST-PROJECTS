public without sharing class ClearCapitalAPI {
  public static Clear_Capital_API__c apiSettings = Clear_Capital_API__c.getInstance();
  static String USERNAME = apiSettings.Username__c;
  static String PASSWORD = apiSettings.Password__c;
  static String BASE_URL = apiSettings.Endpoint__c;
  static String ACCOUNTID = apiSettings.Account_Id__c;

  static String BRIDGE_USERNAME = apiSettings.Bridge_Username__c;
  static String BRIDGE_PASSWORD = apiSettings.Bridge_Password__c;
  static String BRIDGE_ACCOUNTID = apiSettings.Bridge_Account_Id__c;


  public static final Map<String, String> CLEARVAL_ADDON_MAP = new Map<String,String>{
    'Estimated Monthly Rent Addendum' => '302',
    'Comparable Sales History' => '303',
    'As-Repaired Value Addendum' => '304',
    'Budget Analysis w/ As-Repaired Value Addendum' => '308'
   };

  //String baseEndpoint = 'https://integration.clearcapital.com/xml/orders/order_generation_manager_cc.cfc?method=createOrder';
  static String baseEndpoint =
    BASE_URL + '/xml/orders/order_generation_manager_cc.cfc?method=createOrder'; //'https://integrationdev01.npe.clearcapital.net';
  static String statusEndpoint =
    BASE_URL + '/xml/services/Status.cfc?method=processRequest'; //'https://integrationdev01.npe.clearcapital.net';
  static String retrieveEndpoint =
    BASE_URL + '/xml/services/ProductDocument.cfc?method=processRequest'; //'https://integrationdev01.npe.clearcapital.net';

  // public static void testOrder(Id propertyId) {
  //   Property__c p = [
  //     SELECT id, city__c, state__c, name, zipcode__c, Property_Type__c, Interior_Access_POC__c, Interior_Access_POC_Phone__c, Asset_ID__c, Square_Feet__c, Number_of_Units__c
  //     FROM property__c
  //     WHERE id = :propertyId
  //     LIMIT 1
  //   ];

  //   //createOrder(p);
  // }

  @future(callout=true)
  public static void retrieveOrderFuture(String appraisalId, String fileType) {
    Appraisal__c appraisal = [
      SELECT
        id,
        createddate,
        Deal__r.RecordType.DeveloperName,
        report_type__c,
        appraisal_firm_transaction_id__c,
        Property_Address__c,
        Property__r.Deal__c,
        appraisal_product_ordered__c,
        Property__c,
        Property__r.Deal_Record_Type__C
      FROM appraisal__c
      WHERE Id = :appraisalId
      ORDER BY createddate DESC
    ];

    Map<String, String> results = ClearCapitalAPI.retrieveOrder(
      appraisal.Appraisal_Firm_Transaction_ID__c,
      fileType,
      appraisal.Deal__r.RecordType.DeveloperName
    );

    system.debug(results);

    List<ContentVersion> cvs = new List<ContentVersion>();
    String propertyAddress = appraisal.Property_Address__c;
    String xmlFileId = '';
    if (results.containsKey('file')) {
      ContentVersion cv = new ContentVersion();
      cv.ContentLocation = 'S';
      //cv.ContentDocumentId = contentDocumentId;

      if (Test.isRunningTest()) {
        StaticResource xml = [
          SELECT Id, Body
          FROM StaticResource
          WHERE Name = 'AppraisalXMLTest'
          LIMIT 1
        ];
        cv.VersionData = xml.Body;
      } else {
        cv.VersionData = EncodingUtil.base64Decode(results.get('file'));
      }

      cv.Title = propertyAddress + '.' + fileType;
      cv.PathOnClient = propertyAddress + '.' + fileType;

      cvs.add(cv);
    } //

    if (cvs.size() > 0) {
      insert cvs;

      List<String> docIds = new List<String>();
      for (ContentVersion cv : [
        SELECT Id, ContentDocumentId, FileExtension
        FROM ContentVersion
        WHERE Id IN :cvs
      ]) {
        ContentDocumentLink link = new ContentDocumentLink();
        link.ShareType = 'I';
        link.LinkedEntityId = appraisalId;
        link.ContentDocumentId = cv.ContentDocumentId;
        link.Visibility = 'AllUsers';

        insert link;

        if (cv.FileExtension == 'xml') {
          xmlFIleId = link.ContentDocumentId;
        }

        docIds.add(link.ContentDocumentId);
      }

      List<Deal_Document__c> dealDocs = BorrowerChecklistController.createDealDocs(
        appraisal.Property__r.Deal__c,
        docIds,
        'Diligence Documents;Property Level Documents|Valuations',
        appraisal.Property__c,
        appraisalId
      );
      List<Deal_Document__c> needAppraisals = new List<Deal_Document__c>();
      for (Deal_Document__c doc : dealDocs) {
        if (doc.Attachment_Id__c == xmlFileId) {
          needAppraisals.add(doc);
        }
      }

      if (needAppraisals.size() > 0) {
        system.enqueueJob(new AppraisalParser(needAppraisals));
      }
    }

    return;
  }

  public static Map<String, String> retrieveOrder(
    String orderId,
    String fileType,
    String recordType
  ) {
    if (recordType == 'LOC_Loan' || recordType == 'Single_Asset_Bridge_Loan') {
      USERNAME = BRIDGE_USERNAME;
      PASSWORD = BRIDGE_PASSWORD;
    }

    Map<String, String> results = new Map<String, String>();

    HttpRequest req = new HttpRequest();
    req.setEndpoint(retrieveEndpoint);
    req.setMethod('POST');

    req.setHeader(
      'Authorization',
      'Basic ' +
      EncodingUtil.base64Encode(Blob.valueOf(USERNAME + ':' + PASSWORD))
    );
    req.setHeader(
      'Content-Type',
      'multipart/form-data; boundary=------7MA4YWxkTrZu0gW'
    );

    String body = '';
    body += '--------7MA4YWxkTrZu0gW\r\n';
    body += 'Content-Disposition: form-data; name="transactionId"\r\n\r\n';
    body += orderId + '\r\n';
    body += '--------7MA4YWxkTrZu0gW--\r\n';
    body += 'Content-Disposition: form-data; name="productFileType"\r\n\r\n';
    body += fileType + '\r\n';
    body += '--------7MA4YWxkTrZu0gW--';

    // req.setBody(body);
    // req.setHeader('Content-Length', String.valueOf(body.length()));
    req.setTimeout(120000);
    req.setBodyAsBlob(Blob.valueOf(body)); //(body);
    req.setHeader('Content-Length', String.ValueOf(req.getBodyAsBlob().size()));
    //system.debug(body);

    Integer statusCode = 200;
    String respBody =
      '<?xml version="1.0" encoding="UTF-8"?><clearcapital schema_type="document" schema_version="1.0"><product name="Appraisal Form-1075" scope="Exterior"><transaction><transaction_order_id>6271437</transaction_order_id><transaction_id>26971226</transaction_id><client_reference_id>20191115</client_reference_id></transaction><document encoding="base64" extension="' +
      fileType +
      '">dGVzdA==</document></product></clearcapital>';

    // if(Test.isRunningTest()){
    //   StaticResource xml = [SELECT Id, Body FROM StaticResource WHERE Name = 'AppraisalXMLTest' LIMIT 1];
    //   // respBody.replace('dGVzdA==', EncodingUtil.base64Encode(xml.Body));
    //   respBody += EncodingUtil.base64Encode(xml.Body);
    // }

    // respBody += '</document></product></clearcapital>';

    if (!Test.isRunningTest()) {
      HttpResponse resp = new Http().send(req);

      statusCode = resp.getStatusCode();

      respBody = resp.getBody();
    }

    system.debug(JSON.serialize(respBody));

    //system.debug(statusCode);

    //system.debug(respBody);
    if (statusCode == 200 || statusCode == 201) {
      results = parseOrderRetrieval(respBody, fileType);
    } else {
    }

    return results;
  }

  public static Map<String, String> parseOrderRetrieval(
    String body,
    String fileType
  ) {
    // body = body.replaceAll('\n', '').replaceAll('\r', '');

    Map<String, String> results = new Map<String, String>();

    results.put(
      'file',
      body.substringBetween(
        '<document encoding="base64" extension="' +
        fileType +
        '">',
        '</document>'
      )
    );

    return results;
  }

  public static Map<String, Object> parseTransactionStatus(String body) {
    body = body.replaceAll('\n', '').replaceAll('\r', '');
    Map<String, Object> results = new Map<String, Object>();

    String commentsBody = body.substringBetween('<comments>', '</comments>');
    List<Map<String, String>> comments = new List<Map<String, String>>();
    while (String.isNotBlank(commentsBody)) {
      String commentBody = commentsBody.substringBetween(
        '<comment>',
        '</comment>'
      );
      String commentDate = commentBody.substringBetween('<date>', '</date>');
      String comment = commentBody.substringBetween('<body>', '</body>');

      Map<String, String> commentMap = new Map<String, String>();
      commentMap.put('date', commentDate);
      commentMap.put('body', comment);

      comments.add(commentMap);

      commentsBody = commentsBody.subStringAfter(
        '<comment>' +
        commentBody +
        '</comment>'
      );
    }

    String statusBody = body.substringBetween('<status>', '</status>');
    String status = statusBody.substringBetween('<name>', '</name>');
    String statusDescription = statusBody.substringBetween(
      '<description>',
      '</description>'
    );

    String propertyBody = body.substringBetween('<property>', '</property>');
    String addressBody = propertyBody.substringBetween(
      '<address>',
      '</address>'
    );
    String street = addressBody.substringBetween('<street>', '</street>');
    String city = addressBody.substringBetween('<city>', '</city>');
    String state = addressBody.substringBetween('<state>', '</state>');
    String zip = addressBody.substringBetween('<zip>', '</zip>');

    String cancelledBody = statusBody.substringBetween(
      '<cancelled>',
      '</cancelled>'
    );
    String cancelledDate = cancelledBody.substringBetween('<date>', '</date>');

    String onHoldBody = statusBody.substringBetween('<on_hold>', '</on_hold>');
    String onHoldDate = onHoldBody.substringBetween('<date>', '</date>');

    String estCompletedDate = body.substringBetween(
      '<est_completed_date>',
      '</est_completed_date>'
    );
    String completedDate = body.substringBetween(
      '<completed_date>',
      '</completed_date>'
    );
    String appraisalEffectiveDate = body.substringBetween(
      '<completed_date>',
      '</completed_date>'
    );
    String inspectionComplete = body.substringBetween(
      '<inspection_complete>',
      '</inspection_complete>'
    );
    String appraisedValue = body.substringBetween(
      '<as_is_value>',
      '</as_is_value>'
    );
    String appraisalFee = body.substringBetween('<fee>', '</fee>');

    results.put('status', status);
    results.put('statusDescription', statusDescription);

    results.put('cancelledDate', cancelledDate);
    results.put('onHoldDate', onHoldDate);
    results.put('completedDate', completedDate);
    results.put('estimatedCompletedDate', estCompletedDate);
    results.put('inspectionComplete', inspectionComplete);
    results.put('appraisalEffectiveDate', appraisalEffectiveDate);
    results.put('appraisedValue', appraisedValue);
    results.put('appraisalFee', appraisalFee);
    results.put('street', street);
    results.put('city', city);
    results.put('state', state);
    results.put('zip', zip);

    results.put('comments', comments);

    return results;
  }

  public static Map<String, Object> checkStatus(
    String orderId,
    String recordType
  ) {
    if (recordType == 'LOC_Loan' || recordType == 'Single_Asset_Bridge_Loan') {
      USERNAME = BRIDGE_USERNAME;
      PASSWORD = BRIDGE_PASSWORD;
    }

    Map<String, Object> results = new Map<String, Object>();

    HttpRequest req = new HttpRequest();
    req.setEndpoint(statusEndpoint);
    req.setMethod('POST');
    system.debug(statusEndpoint);
    system.debug(USERNAME);
    system.debug(PASSWORD);
    req.setHeader(
      'Authorization',
      'Basic ' +
      EncodingUtil.base64Encode(Blob.valueOf(USERNAME + ':' + PASSWORD))
    );
    req.setHeader(
      'Content-Type',
      'multipart/form-data; boundary=------7MA4YWxkTrZu0gW'
    );

    String body = '';
    body += '--------7MA4YWxkTrZu0gW\r\n';
    body += 'Content-Disposition: form-data; name="transactionId"\r\n\r\n'; //';// filename="'+attachments[0].Name+'"\n';
    body += orderId + '\r\n';
    body += '--------7MA4YWxkTrZu0gW--';

    req.setTimeout(120000);
    req.setBodyAsBlob(Blob.valueOf(body)); //(body);
    req.setHeader('Content-Length', String.ValueOf(req.getBodyAsBlob().size()));
    // system.debug(body);

    Integer statusCode = 200;
    String respBody = '<?xml version="1.0" encoding="UTF-8"?><clearcapital schema_type="status" schema_version="1.0"><product name="Appraisal Form-1004" scope="Interior"> <transaction><transaction_order_id>5730630</transaction_order_id> <transaction_id>23920111</transaction_id> <client_reference_id>214806</client_reference_id> <request_date>2019-05-05T00:00:00-07:00</request_date> <est_completed_date> 2019-05-05T00:00:00-07:00</est_completed_date> <inspection_date>2019-05-05T00:00:00-07:00</inspection_date> <inspection_complete>No</inspection_complete> <completed_date>2019-05-05T00:00:00-07:00</completed_date> <as_is_value>10000</as_is_value><fee>450</fee><status><name>ON HOLD</name><description>Contact Number(s) Needed - New numbers needed. The provided number is no longer in service.</description><cancelled><date /></cancelled><on_hold><date>2019-05-05T00:00:00-07:00</date> </on_hold></status></transaction><property><address><street>123 CHERRYTREE LN</street> <city>DECATUR</city> <state>GA</state><zip>30032</zip></address> <loan_number>ABC123</loan_number> <comments><comment><date>2019-05-05T00:00:00-07:00</date><body>Re: Inspection Scheduled Hello,We wanted to provide you with an update and letyou knowhave confirmed the inspection has occurred.Should you have any questions, please do not hesitate to contact us.Have a great day! Thanks.</body></comment><comment><date>2019-05-05T00:00:00-07:00</date><body>Re: Appraisal Assigned Hello,Thank you for your order!We wanted to let you know that this report has been assigned to one of our appraisers.We will provide you with another update once the inspection date has been set.Please do not hesitate to contact us if you have any questions.Have a great day! Thanks.</body>that the inspection date has been set for 02/03/2018. We will be sure to update you once we</comment></comments></property></product></clearcapital>';

    if (!Test.isRunningTest()) {
      HttpResponse resp = new Http().send(req);
      statusCode = resp.getStatusCode();
      respBody = resp.getBody();
    }

    system.debug(statusCode);
    system.debug(respBody);
    if (statusCode == 200 || statusCode == 201) {
      results = parseTransactionStatus(respBody);
    } else {
    }

    return results;
  }

  public static Appraisal__c createOrder(
    Property__c property,
    String productType,
    String turnTime,
    // List<Object> addOns,
    String vendorComments
  ) {
    String reportType = getReportType(productType, property.Property_Type__c);
    String propertyType = getPropertyType(
      property.Property_Type__c,
      property.Number_of_Units__c
    );

    // system.debug('--report type--');
    //system.debug(reportType);

    User runningUser = [
      SELECT Id, Full_Name__c, Phone, Email
      FROM User
      WHERE Id = :UserInfo.getUserId()
    ];
    String trackingString =
      'Order Placed By: ' +
      runningUser.Full_Name__c +
      ', ' +
      runningUser.Phone +
      ', ' +
      runningUser.Email;
    String interiorAccessPOC = property.Interior_Access_POC__c;

    String body = '<?xml version="1.0" encoding="UTF-8"?>';
    body += '<clearcapital>';
    body += createAuthenticationXML(property.Deal__r.RecordType.DeveloperName);

    String purpose = '0';
    if (!productType.contains('BPO')) {
      if (
        property.Refinance_Acquisition__c == 'Purchase' ||
        property.Refinance_Acquisition__c == 'Acquisition'
      ) {
        purpose = '21';
      } else if (property.Refinance_Acquisition__c == 'Refinance') {
        purpose = '22';
      }
    }
    String dealName = property.Deal__r.Name.replaceAll('&', '&amp;')
      .replaceAll('"', '&quot;')
      .replaceAll('\'', '');

    body +=
      '<order_submit batch_id="' +
      property.Deal__r.Deal_Loan_Number__c +
      '"  order_tracking_id="' +
      dealName +
      ' ' +
      property.Deal__r.Deal_Loan_Number__c +
      '" purpose="' +
      purpose +
      '" ';
    body += 'report_type="' + reportType + '" turn_time="' + turntime + '" ';

    String versionNumber = '1.0';
    // if(productType == 'ClearVal Plus (Interior PCI)' || productType == 'ClearVal Plus (Exterior PCI)'){
    //   versionNumber = '1.2';
    // }

    // if(productType == 'ClearVal Plus (Exterior PCI)'){
    //   versionNumber = '1.2';
    // }

    body += 'version="' + versionNumber + '">';
    // if(addOns.size() > 0) {
    //   body += '<addons>';

    //   for(Object a : addons) {
    //     body += '<addon>' + CLEARVAL_ADDON_MAP.get(String.valueof(a)) + '</addon>';
    //   } 


    //   body += '</addons>';    
    // }
    // body += '<addons>';
    // body += '<addon>';
    // body += addons;
    // body += '</addon>';
    // body += '</addons>';
    body += '<notes/>';
    body += '<properties>';
    body += '<property apn="" appraised_date="" appraised_value="" ';
    body +=
      'borrower="Not Provided" city="' +
      property.City__c +
      '" current_loan_balance="" ';

    if (String.isBlank(interiorAccessPOC)) {
      interiorAccessPOC = '';
    }

    body +=
      'interior_access_name="' +
      interiorAccessPOC.replaceAll('&', '&amp;')
        .replaceAll('"', '&quot;')
        .replaceAll('\'', '') +
      '" interior_access_phone="' +
      property.Interior_Access_POC_Phone__c +
      ' ' +
      property.Interior_Access_POC_Email__c +
      '" lender_address_1="4 Park Plaza" ';
    body += 'lender_address_2="Suite 900" lender_city="Irvine" lender_name="CoreVest" ';

    if (String.isBlank(vendorComments)) {
      vendorComments = '';
    }

    String originalComments = vendorComments;
    vendorComments = vendorComments.replaceAll('&', '&amp;')
      .replaceAll('"', '&quot;')
      .replaceAll('\'', '');

    body +=
      'lender_state="CA" lender_zip="92614" loan_num="' +
      property.Deal__r.Deal_Loan_Number__c +
      '" notes="' +
      vendorComments +
      '" ';
    body +=
      'property_type="' +
      propertyType +
      '" square_feet="' +
      property.Square_Feet__c +
      '" state="' +
      property.State__c +
      '" street_address="' +
      property.Name.replaceAll('&', '&amp;')
        .replaceAll('"', '&quot;')
        .replaceAll('\'', '') +
      '" ';

    body +=
      'tracking_1="' +
      dealName +
      ' ' +
      property.Deal__r.Deal_Loan_Number__c +
      '" tracking_2="' +
      trackingString +
      '" tracking_3="Asset ID: ' +
      property.Asset_ID__c +
      '" tracking_4="' +
      property.Id +
      '" ';
    body +=
      'tracking_5="" zip4="" zip5="' +
      property.ZipCode__c.subStringBefore('-') +
      '">';
    body += '<supporting_documents/>';
    body += '</property> ';
    body += '</properties>';
    body += '</order_submit>';
    body += '</clearcapital>';

    system.debug('---submit body---');
    system.debug(body);

    // String responseBody = ''

    String responseBody = doCallout(body);

    system.debug(responseBody);

    Appraisal__c appraisal;
    if (responseBody.contains('order_submit_confirmation errors="Yes"')) {
      throw new AuraHandledException(
        responseBody.substringBetween('<error_message>', '</error_message>')
      );
    } else {
      appraisal = new Appraisal__c();

      System.debug('--це респонсь боді--');
      System.debug(responseBody);
      String received_date = responseBody.substringBetween(
        '<received_date>',
        '</received_date>'
      );
      String received_time = responseBody.substringBetween(
        '<received_time>',
        '</received_time>'
      );
      String due_date = responseBody.substringBetween(
        '<due_date>',
        '</due_date>'
      );
      String due_time = responseBody.substringBetween(
        '<due_time>',
        '</due_time>'
      );
      String support_name = responseBody.substringBetween(
        '<support_name>',
        '</support_name>'
      );
      String support_email = responseBody.substringBetween(
        '<support_email>',
        '</support_email>'
      );
      String support_phone = responseBody.substringBetween(
        '<support_phone>',
        '</support_phone>'
      );
      String order_id = responseBody.substringBetween(
        '<order_id>',
        '</order_id>'
      );

      // String transaction_id = responseBody.substringBetween(
      //   '<order_tracking_id>',
      //   '</order_tracking_id>'
      // );

      system.debug('--property id--');
      system.debug(responseBody.substringbetween('PROPERTY_ID="', '"'));

      String transaction_id = responseBody.substringbetween(
        'PROPERTY_ID="',
        '"'
      );

      if (due_time.contains('AM')) {
        due_time = due_time.substringBefore('AM') + ' AM';
      } else {
        due_time = due_time.substringBefore('PM') + ' PM';
      }

      if (received_time.contains('AM')) {
        received_time = received_time.substringBefore('AM') + ' AM';
      } else {
        received_time = received_time.substringBefore('PM') + ' PM';
      }

      appraisal.Estimated_Completion_Date__c = DateTime.parse(
        due_date +
        ' ' +
        due_time
      );
      appraisal.Order_Received_Date__c = DateTime.parse(
        received_date +
        ' ' +
        received_time
      );
      appraisal.Vendor_Support_Name__c = support_name;
      appraisal.Vendor_Support_Email__c = support_email;
      appraisal.Vendor_Support_Phone__c = support_phone;
      appraisal.Appraisal_Firm_Order_ID__c = order_id;
      appraisal.Comments_to_Vendor__c = originalComments;
      appraisal.Status__c = 'Ordered';
      appraisal.Report_Type__c = reportType;
      appraisal.Appraisal_Firm_Transaction_ID__c = transaction_id;
    }

    //Appraisal__c appraisal = new Appraisal__c();

    return appraisal;
  }

  public static String doCallout(String body) {
    //body = '<?xml version="1.0" encoding="UTF-8"?><clearcapital><authenticate><username>ws_user_4330556</username><password>"h_R4rPZ+b</password><account_id>189060</account_id><account_key></account_key></authenticate><order_submit batch_id="" notify_on_receive="" order_tracking_id="test02112019" purpose="0" report_type="27" turn_time="120" version="1.0"><notes>testNotes</notes><properties><property apn="" appraised_date="" appraised_value="" borrower="John Doe" city="BRONX" current_loan_balance="" interior_access_name="Judy Smith" interior_access_phone="1112223344" loan_num="1000002167" notes="" property_type="" square_feet=""  state="NY" street_address="1268 CROES AVE" tracking_1="test02112019" tracking_2="" tracking_3="" zip4="" zip5="10472"/></properties></order_submit></clearcapital>';
    HttpRequest req = new HttpRequest();
    req.setEndpoint(baseEndpoint);
    req.setMethod('POST');
    // req.setBody(JSON.serialize(wrappers, true));
    req.setHeader('Content-Type', 'application/xml;charset=UTF-8');
    req.setHeader('type', 'formfield');
    req.setHeader('name', 'newXmlOrder');
    // req.setHeader('value', body);
    req.setHeader('Content-Length', String.valueOf(body.length()));
    req.setTimeout(120000);
    req.setBody(body);
    //req.setHeader('Host', 'us-street.api.smartystreets.com');

    String respBody = '<?xml version="1.0" encoding="UTF-8"?><clearcapital><order_submit_confirmation errors="No" version="1.0"><received_date>12/11/2019</received_date><received_time>10:13AM</received_time><due_date>12/20/2019</due_date><due_time>10:00AM</due_time><property_bill_rate>415</property_bill_rate><order_tracking_id>20191211</order_tracking_id><order_id>6273237</order_id><property_count>1</property_count><support_name>Tera Coupe</support_name><support_email>dev@clearcapital.com</support_email><support_phone>(530) 550-2130</support_phone><properties><property LOAN_NUM="480884" PROPERTY_ID="26984254"/></properties><error_message/></order_submit_confirmation> </clearcapital>';
    if (!Test.isRunningTest()) {
      HttpResponse resp = new Http().send(req);
      respBody = resp.getBody();
    }

    //system.debug(resp.getStatus());
    //system.debug(resp.getStatusCode());
    //system.debug(resp.getBody());
    // system.debug(JSON.serialize(body));
    //system.debug(JSON.deserializeStrict(resp.getBody(), List<SmartyStreetsAPI.ResponseResource>.class));

    return respBody;
  }

  public static String createAuthenticationXML(String recordType) {
    if (recordType == 'LOC_Loan' || recordType == 'Single_Asset_Bridge_Loan') {
      USERNAME = BRIDGE_USERNAME;
      PASSWORD = BRIDGE_PASSWORD;
      ACCOUNTID = BRIDGE_ACCOUNTID;
    }

    return createAuthenticationXML();
  }

  public static String createAuthenticationXML() {
    String manipulatedPassword = '';
    if (String.isNotBlank(PASSWORD)) {
      manipulatedPassword = PASSWORD.replaceAll('<', '&lt;');
    }

    String xmlSection = '<authenticate>';
    xmlSection += '<username>' + USERNAME + '</username>';
    xmlSection += '<password>' + manipulatedPassword + '</password>';
    xmlSection += '<account_id>' + ACCOUNTID + '</account_id>';
    xmlSection += '<account_key></account_key>';
    xmlSection += '</authenticate>';

    return xmlSection;
  }

  public static String getPropertyType(
    String propertyType,
    Decimal numberOfUnits
  ) {
    String property_type = '';

    if (
      propertyType == 'SFR' ||
      propertyType == 'Townhome' ||
      propertyType == 'Condo'
    ) {
      property_type = 'SFR';
    } else if (propertyType == '2-4 Unit') {
      if (numberOfUnits == 2) {
        property_type = '2PLX';
      } else if (numberOfUnits == 3) {
        property_type = '3PLX';
      } else if (numberOfUNits == 4) {
        property_type = '4PLX';
      } else if (propertyType == 'Multifamily' || propertyType == 'Mixed Use') {
        property_type = 'Multi';
      } else if (propertyType == 'Commercial') {
        property_type = 'COM';
      }
    }

    return property_type;
  }

  public static String getReportType(String productType, String propertyType) {
    String reportType = '';
    if (productType == 'Interior Appraisal') {
      if (propertyType == 'SFR' || propertyType == 'Townhome') {
        reportType = '41';
      } else if (propertyType == 'Condo') {
        reportType = '45';
      } else if (propertyType == '2-4 Unit') {
        reportType = '43';
      }
    } else if (productType == 'Exterior Appraisal') {
      if (propertyType == 'SFR' || propertyType == 'Townhome') {
        reportType = '47';
      } else if (propertyType == 'Condo') {
        reportType = '50';
      } else if (propertyType == '2-4 Unit') {
        reportType = '47';
      }
    } else if (productType == 'Appraisal Update') {
      reportType = '96';
    } else if (productType == 'Certification of Completion') {
      reportType = '76';
    } else if (productType == 'Post Disaster Inspection') {
      reportType = '19';
    } else if (productType == 'ClearVal 2.0 (Interior PCI)') {
      reportType = '298';
    } else if (productType == 'ClearVal 2.0 (Exterior PCI)') {
      reportType = '297';
    } else if (productType == 'Commercial') {
      reportType = '49';
    } else if (productType == 'Drive By BPO') {
      reportType = '28';
    } else if (productType == 'Interior BPO') {
      reportType = '27';
    } else if (productType == '1004 Hybrid Report') {
      reportType = '110';
    }

    return reportType;
  }
}