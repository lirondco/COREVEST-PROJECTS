public without sharing class BoxAPI {
  public static String accessToken = '';
  public static String authEndpoint = 'https://api.box.com/oauth2/token';

  public static String BOUNDARY = 'BoxApexSDKcjhJ$vXxPaCKo=83up1oadb0undary';
  public static String AS_USER = '257409297';
  public static String getAccessToken() {
    if (String.isNotBlank(accessToken)) {
      return accessToken;
    }

    Settings__mdt settings = Settings__mdt.getInstance('Universal_Settings');

    String grant_type = 'client_credentials';
    String box_subject_type = 'enterprise';
    String box_subject_id = settings.Box_Subject_Id__c; //'786745';
    String client_id = settings.Box_Client_Id__c; //'6j821cmxtkmpmy144abj7y94tgqshm8b';
    String client_secret = settings.Box_Client_Secret__c; //'npPwz6fxqMrEzFZOrJsOIiKEOprolPXn';

    String body = 'grant_type=' + grant_type;
    body += '&box_subject_type=' + box_subject_type;
    body += '&box_subject_id=' + box_subject_id;
    body += '&client_id=' + client_id;
    body += '&client_secret=' + client_secret;

    HttpRequest request = new HttpRequest();
    request.setEndpoint(authEndpoint);
    request.setMethod('POST');
    request.setBody(body);
    String responseBody = '{"access_token":"EjgX2hnlA55CvDxBilscSSxnjzCvbak3","expires_in":3941,"restricted_to":[],"token_type":"bearer"}';

    if (!Test.isRunningTest()) {
      HttpResponse response = new Http().send(request);
      responseBody = response.getBody();
    }

    // system.debug(responseBody);

    Map<String, Object> parsedBody = (Map<String, Object>) JSON.deserializeUntyped(
      responseBody
    );

    // system.debug(parsedBody);

    accessToken = (String) parsedBody.get('access_token');

    return accessToken;
  }

  public static void uploadFile(
    Blob fileBody,
    String fileName,
    String folderId,
    Id parentId
  ) {
    String accessToken = getAccessToken();

    Blob bodyBlob = buildMultipartFileBody(
      fileBody,
      fileName,
      folderId,
      BOUNDARY
    );

    HttpRequest request;
    HttpResponse response;

    try {
      String uploadEndpoint = 'https://upload.box.com/api/2.0/files/content';
      system.debug(uploadEndpoint);
      request = new HttpRequest();
      request.setMethod('POST');
      request.setTimeout(120000);
      request.setHeader(
        'Content-Type',
        'multipart/form-data; boundary=' + BOUNDARY
      );
      request.setHeader('Authorization', 'Bearer ' + accessToken);
      request.setHeader('as-user', '257409297');
      request.setBodyAsBlob(bodyBlob);
      request.setHeader(
        'Content-Length',
        String.valueof(request.getBodyAsBlob().size())
      );
      request.setEndpoint(uploadEndpoint);

      if (!Test.isRunningTest()) {
        response = new Http().send(request);
      }

      System.enqueueJob(
        new APILoggerQueueable(request, response, parentId, false)
      );
    } catch (Exception e) {
      System.enqueueJob(new APILoggerQueueable(request, response, parentId, e));
    }
  }

  public static String prepareStringForBase64Decoding(String stringToPrepare) {
    String last4Bytes = stringToPrepare.substring(
      stringToPrepare.length() - 4,
      stringToPrepare.length()
    );
    if (last4Bytes.endsWith('==')) {
      last4Bytes = last4Bytes.substring(0, 2) + '0K';
      stringToPrepare =
        stringToPrepare.substring(0, stringToPrepare.length() - 4) + last4Bytes;
    } else if (last4Bytes.endsWith('=')) {
      last4Bytes = last4Bytes.substring(0, 3) + 'N';
      stringToPrepare =
        stringToPrepare.substring(0, stringToPrepare.length() - 4) + last4Bytes;
    }
    return stringToPrepare;
  }

  public static Blob buildMultipartFileBody(
    Blob fileBody,
    String fileName,
    String folderId,
    String boundary
  ) {
    String header =
      '--' +
      boundary +
      '\r\nContent-Disposition: form-data; name="attributes"';
    header +=
      '\r\n\r\n' +
      '{"name":"' +
      fileName +
      '", "parent":{"id":"' +
      folderId +
      '"}}';

    header +=
      '\r\n--' +
      boundary +
      '\r\nContent-Disposition: form-data; name="file"; filename="' +
      fileName +
      '";\r\nContent-Type: application/octet-stream';

    system.debug(header);
    String footer = '--' + boundary + '--';
    String headerEncoded = EncodingUtil.base64Encode(
      Blob.valueOf(header + '\r\n\r\n')
    );
    String footerEncoded;
    while (headerEncoded.endsWith('=')) {
      header += ' ';
      headerEncoded = EncodingUtil.base64Encode(
        Blob.valueOf(header + '\r\n\r\n')
      );
    }
    String bodyEncoded = EncodingUtil.base64Encode(fileBody);
    String last4Bytes = bodyEncoded.substring(
      bodyEncoded.length() - 4,
      bodyEncoded.length()
    );
    if (last4Bytes.endsWith('==')) {
      last4Bytes = last4Bytes.substring(0, 2) + '0K';
      bodyEncoded =
        bodyEncoded.substring(0, bodyEncoded.length() - 4) + last4Bytes;
      footerEncoded = EncodingUtil.base64Encode(Blob.valueOf(footer));
    } else if (last4Bytes.endsWith('=')) {
      last4Bytes = last4Bytes.substring(0, 3) + 'N';
      bodyEncoded =
        bodyEncoded.substring(0, bodyEncoded.length() - 4) + last4Bytes;
      footer = '\n' + footer;
      footerEncoded = EncodingUtil.base64Encode(Blob.valueOf(footer));
    } else {
      footer = '\r\n' + footer;
      footerEncoded = EncodingUtil.base64Encode(Blob.valueOf(footer));
    }
    Blob bodyBlob = EncodingUtil.base64Decode(
      headerEncoded +
      bodyEncoded +
      footerEncoded
    );
    return bodyBlob;
  }
}