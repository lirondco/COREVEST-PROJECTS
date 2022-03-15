public without sharing class APILoggerQueueable implements Queueable {
  API_Log__c log;
  Id parentId;
  Boolean error;
  APILoggerQueueable next;

  public APILoggerQueueable(
    HttpRequest request,
    HttpResponse response,
    Id parentId,
    Boolean error
  ) {
    this.parentId = parentId;
    this.error = error;
    this.log = new APILogger(request, response).getLog();
  }

  public APILoggerQueueable(
    HttpRequest request,
    HttpResponse response,
    Id parentId,
    APILoggerQueueable nextQueue
  ) {
    this.parentId = parentId;
    this.error = false;
    this.next = nextQueue;
    this.log = new APILogger(request, response).getLog();
  }

  public APILoggerQueueable(
    HttpRequest request,
    HttpResponse response,
    Id parentId,
    Exception e
  ) {
    this.parentId = parentId;
    this.error = true;
    this.log = new APILogger(request, response, e).getLog();
  }

  public void execute(QueueableContext qc) {
    log.Callout_Failed__c = error;

    String endpoint = log.Request_Endpoint__c;

    List<Settings__mdt> settings = [
      SELECT
        Enable_Yardi_API_Response_Logging__c,
        Enable_BOX_API_Response_Logging__c,
        Enable_Valuation_API_Response_Logging__c,
        Enable_Clear_API_Response_Logging__c,
        Enable_CoreLogic_API_Response_Logging__c
      FROM Settings__mdt
      WHERE DeveloperName = 'Universal_Settings'
    ];

    Clarocity_API_Settings__c clarocitySettings = Clarocity_API_Settings__c.getInstance();
    Appraisal_Nation_API__c appraisalSettings = Appraisal_Nation_API__c.getInstance();
    Valuation_Services_API__c valuationSettings = Valuation_Services_API__c.getInstance();
    String appraisalBaseEndPoint = appraisalSettings.Endpoint__c;
    String clarocityBaseEndpoint = clarocitySettings.Endpoint__c;
    String valuationBaseEndpoint = valuationSettings.Endpoint__c;

    if (Test.isRunningTest()) {
      clarocityBaseEndpoint = 'cvs';
      appraisalBaseEndPoint = 'appraisal';
      valuationBaseEndpoint = 'valuation';
    }

    Boolean enableLogging = true;

    if (endpoint.contains('yardi')) {
      enableLogging = settings.size() > 0
        ? settings[0].Enable_Yardi_API_Response_Logging__c
        : true;
      log.Type__c = 'Yardi';
    } else if (endpoint.contains('box.com')) {
      enableLogging = settings.size() > 0
        ? settings[0].Enable_BOX_API_Response_Logging__c
        : true;
      log.Type__c = 'Box';
    // } else if (endpoint.contains('clearcapital')) {
    //   enableLogging = settings.size() > 0
    //     ? settings[0].Enable_Valuation_API_Response_Logging__c
    //     : true;
    //   log.Type__c = 'Clear Capital';
    // } else if (endpoint.contains(clarocityBaseEndpoint)) {
    //   enableLogging = settings.size() > 0
    //     ? settings[0].Enable_Valuation_API_Response_Logging__c
    //     : true;
    //   log.Type__c = 'Clarocity';
    // } else if (endpoint.contains(appraisalBaseEndPoint)) {
    //   enableLogging = settings.size() > 0
    //     ? settings[0].Enable_Valuation_API_Response_Logging__c
    //     : true;
    //   log.Type__c = 'Appraisal';
    // } else if (endpoint.contains(valuationBaseEndpoint)) {
    //   enableLogging = settings.size() > 0
    //     ? settings[0].Enable_Valuation_API_Response_Logging__c
    //     : true;
    //   log.Type__c = 'Valuation';
    } else if (endpoint.contains('thomsonreuters')) {
      enableLogging = settings.size() > 0
        ? settings[0].Enable_Clear_API_Response_Logging__c
        : true;
      log.Type__c = 'Clear';
    // } else if (endpoint.contains('corelogic')) {
    //   enableLogging = settings.size() > 0
    //     ? settings[0].Enable_CoreLogic_API_Response_Logging__c
    //     : true;
    //   log.Type__c = 'CoreLogic';
    }

    if (enableLogging || test.isRunningTest()) {
      if (parentId != null) {
        String sobjectType = parentId.getSObjectType().getDescribe().getName();

        switch on sobjectType {
          when 'Opportunity' {
            log.Deal__c = parentId;
          }
          when 'Property__c' {
            log.Property__c = parentId;
          }
          when 'Advance__c' {
            log.Advance__c = parentId;
          }
          when 'Deal_Document__c' {
            log.Deal_Document__c = parentId;
          }
          when 'Appraisal__c' {
            log.Appraisal__c = parentId;
          }
          when 'Deal_Contact__c' {
            log.Deal_Contact__c = parentId;
          }
          when 'Clear_Result__c' {
            log.Clear_Result__c = parentId;
          }
          when 'Contact__c' {
            log.Contact__c = parentId;
          }
        }
      }

      insert log;

      if (next != null && !Test.isRunningTest()) {
        System.enqueueJob(next);
      }
    }
  }

  class APILogger {
    API_Log__c log;

    public APILogger(HttpRequest request, HttpResponse response) {
      if (request == null) {
        request = new HttpRequest();
      }

      if (response == null) {
        response = new HttpResponse();
      }

      log = new API_log__c();
      log.Request_Endpoint__c = request.getEndpoint();
      log.Request_Method__c = request.getMethod();

      String requestContentType = request.getHeader('Content-Type');
      if (requestContentType == 'application/json') {
        Map<String, Object> body = (Map<String, Object>) JSON.deserializeUntyped(
          request.getBody()
        );
        log.Request_Body__c = JSON.serializePretty(body);
      } else {
        //    else if (requestContentType.contains('text/xml')) {
        //     Dom.Document domDoc = new Dom.Document(); //new Dom.Document(request.getBody());
        //     domDoc.load(request.getBody());
        //     dom.Xmlnode root = domDoc.getRootElement();
        //     if (root != null) {
        //       String body = util.prettyPrint(root, 4);
        //       log.Request_Body__c = body;
        //     } else {
        //       log.Request_Body__c = request.getBody();
        //     }
        //   }
        log.Request_Body__c = request.getBody();
      }

      log.Response_Status__c = response.getStatus();
      log.Response_Status_Code__c = response.getStatusCode();

      Map<String, String> responseHeaders = new Map<String, String>();
      for (String key : response.getHeaderKeys()) {
        responseHeaders.put(key, response.getHeader(key));
      }
      log.Response_Headers__c = JSON.serializePretty(responseHeaders);

      String responseContentType = response.getHeader('Content-Type');
      if (responseContentType == 'application/json') {
        Map<String, Object> body = (Map<String, Object>) JSON.deserializeUntyped(
          response.getBody()
        );
        String resBody = String.valueOf(JSON.serializePretty(body));

        if (resBody.length() > 32700) {
          resBody = resBody.substring(0, 32700);
          resBody += ' ... (truncated)';
        }

        log.Response_Body__c = resBody;

      } else {
        //   else if (responseContentType.contains('text/xml')) {
        //     Dom.Document domDoc = new Dom.Document(); //new Dom.Document(request.getBody());
        //     domDoc.load(response.getBody());
        //     dom.Xmlnode root = domDoc.getRootElement();
        //     if (root != null) {
        //       String body = util.prettyPrint(root, 4);
        //       log.Response_Body__c = body;
        //     } else {
        //       log.Response_Body__c = request.getBody();
        //     }
        //   }

        String resBody = response.getBody();

        if (resBody.length() > 32700) {
          resBody = resBody.substring(0, 32700);
          resBody += ' ... (truncated)';
        }

        log.Response_Body__c = resBody;
      }
    }

    public APILogger(HttpRequest request, HttpResponse response, Exception e) {
      this(request, response);
      this.log.Exception_Line_Number__c = e.getLineNumber();
      this.log.Exception_Message__c = e.getMessage();
      this.log.Exception_Stack_Trace__c = e.getStackTraceString();
      this.log.Exception_Type__c = e.getTypeName();
      this.log.Callout_Failed__c = true;
    }

    public API_Log__c getLog() {
      return this.log;
    }
  }
}