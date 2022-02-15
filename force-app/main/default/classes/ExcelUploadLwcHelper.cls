public without sharing class ExcelUploadLwcHelper {
    @AuraEnabled
    public static Map<String, String> getLastAttachment(String recordId) {
      try {
        Map<String, String> retVal = new Map<String, String>();
  
        List<ContentDocumentLink> docs = [
          SELECT
            ContentDocumentId,
            Id,
            ContentDocument.Title,
            contentdocument.fileextension,
            contentdocument.LatestPublishedVersionId
          FROM ContentDocumentLink
          WHERE
            LinkedEntityId = :recordId
            AND ContentDocument.FileType = 'EXCEL_X'
          ORDER BY contentdocument.ContentModifiedDate DESC
          LIMIT 1
        ];
  
        if (docs.size() > 0) {
          retVal.put(
            'name',
            docs[0].ContentDocument.Title +
            '.' +
            docs[0].ContentDocument.FileExtension
          );
          retVal.put(
            'contentVersionId',
            docs[0].contentdocument.LatestPublishedVersionId
          );
          retVal.put('documentId', docs[0].ContentDocumentId);
        } else {
          retVal.put('noResult', 'true');
        }
  
        return retVal;
      } catch (Exception e) {
        throw new AuraHandledException(e.getMessage());
      }
    }

    @AuraEnabled
    public static String getFileBody(String fileId) {
      try {
        ContentVersion cv = [
          SELECT id, ContentDocumentId, VersionData
          FROM Contentversion
          WHERE id = :fileId
        ];
  
        return EncodingUtil.base64Encode(cv.VersionData);
      } catch (Exception e) {
        throw new AuraHandledException(e.getMessage());
      }
    }
}
