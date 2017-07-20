/**
 * Playout_Controller
 *
 * ETLC_ApexBridge_Abstract is from ETLC_ApexBridge library
 */
public with sharing class Playout_Controller extends ETLC_ApexBridge_Abstract{

    /**
     * Handle all user requests to decide which function to call
     */
    public override Object handleRequest(ETLC_ApexBridge_Request request){
        //Set debug log based on admin preference
        Util.debug = request.debug;

        String message = '';
        ETLC_ApexBridge_Request.MessageType messageType = ETLC_ApexBridge_Request.MessageType.Errors;
        //Get "Available Field" and "User Selected Field" lists
        if (request.method == 'getFieldList') {
            Map<String, Object> retVal = new Map<String, Object>();

            try {
                //Get available fields for a given object from Global Describe
                retVal.put('availableFields', getAvailableFieldList(request, String.valueOf(request.getInputValue('sObjectName'))));

                //Get fields for a particular user and particular object
                retVal.put('userFields', getUserFields(request, String.valueOf( request.getInputValue('sObjectName'))));

                Util.debug('Playout_Controller:getFieldList::' + retVal);
            }catch (SFDCAccessControlException e) {message = 'Playout_Controller.getFieldList():SFDCAccessControlException:Type: ' + e.getExceptionType() + ' Reason: ' + e.getExceptionReason() + ' Object: ' + e.getExceptionObject() + ' Field: ' + e.getExceptionField() + ' Text: ' + e.getText();
            }catch(Exception e){message = 'Playout_Controller.handleRequest().getFieldList:Exception: ' + e.getMessage();}

            //display error message in debug logs if debug is enabled by admin for component
            //Also send this message back to client in Lightning component
            if(String.isNotEmpty(message)){
                Util.debug(message);
                request.addMessage(messageType, message);
            }
            return retVal;
        }
        //Save fields that user has selected for particular object
        else if (request.method == 'saveFields') {
            Boolean retval = false;

            try {
                String temp = String.valueOf(request.getInputValue('order'));
                Integer order = 0;

                if(!String.isEmpty(temp) && temp.isNumeric()){
                    order = Integer.valueOf(temp);
                }
                //Store user selection of field and object and associated order of field
                retval = saveFields(request, String.valueOf(request.getInputValue('sObjectName')), String.valueOf(request.getInputValue('field')), order);

                Util.debug('Playout_Controller:saveFields::' + retVal);

            }catch (SFDCAccessControlException e) {message = 'Playout_Controller.saveFields():SFDCAccessControlException:Type: ' + e.getExceptionType() + ' Reason: ' + e.getExceptionReason() + ' Object: ' + e.getExceptionObject() + ' Field: ' + e.getExceptionField() + ' Text: ' + e.getText();
            }catch(Exception e){message = 'Playout_Controller.handleRequest().saveFields():Exception: ' + e.getMessage();}

            if(String.isNotEmpty(message)){
                Util.debug(message);
                request.addMessage(messageType, message);
            }
            return retval;
        }
        //Remove fields
        else if (request.method == 'removeFields') {
            Boolean retval = false;

            try {
                //remove fields from user selected list
                retval = removeFields(request, String.valueOf(request.getInputValue('sObjectName')), String.valueOf(request.getInputValue('field')));

                Util.debug('Playout_Controller:removeFields::' + retVal);
            }catch (SFDCAccessControlException e) {message = 'Playout_Controller.removeFields():SFDCAccessControlException:Type: ' + e.getExceptionType() + ' Reason: ' + e.getExceptionReason() + ' Object: ' + e.getExceptionObject() + ' Field: ' + e.getExceptionField() + ' Text: ' + e.getText();
            }catch(Exception e){message = 'Playout_Controller.handleRequest().removeFields():Exception: ' + e.getMessage();}

            if(String.isNotEmpty(message)){
                Util.debug(message);
                request.addMessage(messageType, message);
            }
            return retval;
        }
        //Get Record Info
        else if (request.method == 'getRecordInfo') {
            sObject retval;

            try {
                //return record data
                //Normally, we will use Lightning Data Service but due to some Lightning Component restrictions, we have to use Apex
                //restrictions include Object support (like Case is not supported right now) or be able to dynamically loop through fields
                retval = getRecordInfo(request, String.valueOf(request.getInputValue('sObjectName')), (ID)request.getInputValue('recordId'));

                Util.debug('Playout_Controller:getRecordInfo::' + retVal);

            }catch (SFDCAccessControlException e) {message = 'Playout_Controller.getRecordInfo():SFDCAccessControlException:Type: ' + e.getExceptionType() + ' Reason: ' + e.getExceptionReason() + ' Object: ' + e.getExceptionObject() + ' Field: ' + e.getExceptionField() + ' Text: ' + e.getText();
            }catch(Exception e){message = 'Playout_Controller.handleRequest().getRecordInfo():Exception: ' + e.getMessage();}

            if(String.isNotEmpty(message)){
                Util.debug(message);
                request.addMessage(messageType, message);
            }
            return retval;
        }
        throw new ETLC_ApexBridge_InvalidRequest_Exception();
    }
    /**
     * Return field map for provided object using Global Describe call
     */

    private Map<String, Schema.SObjectField> getFieldMap(ETLC_ApexBridge_Request request, String sObjectName){
        Map<String, Schema.SObjectField> schemaFieldMap = new Map<String, Schema.SObjectField>();

        String[] types = new String[]{sObjectName};

        Schema.DescribeSobjectResult[] results = Schema.describeSObjects(types);

        schemaFieldMap = results[0].fields.getMap();

        return schemaFieldMap;
    }
    /**
     * Get fields selected by current user for provided object
     */
    private List<FieldWrapper> getUserFields(ETLC_ApexBridge_Request request, String sObjectName){
        //CRUD/FLS check
        //Only show fields if user has access to this object; for getFieldMap()
        Util.AccessController.assertAuthorizedToView(
                Schema.Playout__c.getSobjectType(),
                new List<Schema.SobjectField>{
                        Schema.Playout__c.fields.Name
                }
        );
        Map<String, Schema.SObjectField> schemaFieldMap = getFieldMap(request, sObjectName);
        
        Util.debug('getUserFields: '+ sObjectName + ':' + UserInfo.getUserId());
        List<FieldWrapper> retVal = new List<FieldWrapper>();

        Schema.SObjectField sObjectField;
            
        List<Playout__c> objList = Playout_DataQuery.getPlayoutByObjectName(sObjectName);
        for(Playout__c obj: objList){
            //Only add a field if it exists and has not been deleted from object
            //Only add field if it's accessible; Technically if user doesn't have access then this field should be here
            //-- But if that user had access before and was revoked after then we have to be careful to show that data
            //-- Field might still be in the list of fields available to user but will be removed from the list
            if(schemaFieldMap.containsKey(obj.Field__c) && schemaFieldMap.get(obj.Field__c).getDescribe().isAccessible()){
                FieldWrapper p = new FieldWrapper();
    	        p.apiname = obj.Field__c;
        	    p.label = schemaFieldMap.get(obj.Field__c).getDescribe().getLabel();
                p.isUpdatable = schemaFieldMap.get(obj.Field__c).getDescribe().isUpdateable();
                p.order = Integer.valueOf(obj.Order__c);
				retVal.add(p);                
            }
        }

        return retVal;
    }

    /**
     * return all available AND accesible fields for provided object
     */
    private List<FieldWrapper> getAvailableFieldList(ETLC_ApexBridge_Request request, String sObjectName){
        List<FieldWrapper> lstfieldname = new List<FieldWrapper>();

        //CRUD/FLS check
        //Only show fields if user has access to this object; for getFieldMap()
        Util.AccessController.assertAuthorizedToView(
                Schema.Playout__c.getSobjectType(),
                new List<Schema.SobjectField>{
                        Schema.Playout__c.fields.Name
                }
        );

        Map<String, Schema.SObjectField> schemaFieldMap = getFieldMap(request, sObjectName);


        if(schemaFieldMap != null){
            for (Schema.SObjectField sfield : schemaFieldMap.Values()) {
                schema.describefieldresult dfield = sfield.getDescribe();
                //Only add field to the list if it's accessible to user
                if (dfield.isAccessible()) {
                    FieldWrapper field = new FieldWrapper();
                    field.apiname = dfield.getname();
                    field.label = dfield.getLabel();
                    field.isUpdatable = dfield.isUpdateable();
                    lstfieldname.add(field);
                }
            }
        }
        return lstfieldname;
    }

    public sObject getRecordInfo(ETLC_ApexBridge_Request request, String sObjectName, ID recordId){
        String[] types = new String[]{sObjectName};

        Schema.DescribeSobjectResult[] results = Schema.describeSObjects(types);


        Map<String, Schema.SObjectField> schemaFieldMap = results[0].fields.getMap();
        //CRUD/FLS check - SELECT
        Util.AccessController.assertAuthorizedToView(
                results[0].getSobjectType(),
                new List<Schema.SobjectField>{
                        schemaFieldMap.get('Id')
                }
        );

        sObject retVal;
        List<FieldWrapper> getUserFields = getUserFields(request, sObjectName);

        String fields = '';
        for(FieldWrapper obj: getUserFields){
            fields += obj.apiname + ',';
        }
        fields = fields.removeEnd(',');

        if(String.isNotEmpty(fields)) {
            fields = String.escapeSingleQuotes(fields);
            sObjectName = String.escapeSingleQuotes(sObjectName);

            String soql = 'SELECT ' + fields + ' FROM ' + sObjectName + ' where ID=:recordId';

            Util.debug('Playout_Controller:getRecordInfo:soql::' + soql);

            List<sObject> obj = Database.query(soql);
            if (obj.size() > 0) {
                retVal = obj[0];
            } else {
                request.addMessage(ETLC_ApexBridge_Request.MessageType.Errors, 'No '+ sObjectName + ' record found with ID ' + recordId);
            }
        }else{
            request.addMessage(ETLC_ApexBridge_Request.MessageType.Information, 'Please add some fields!');
        }

        return retval;

    }
    public Boolean saveFields(ETLC_ApexBridge_Request request, String sObjectName, String field, Integer order){

        Boolean retVal = false;

        //CRUD/FLS check
        //Only show fields if user has access to this object; for getFieldMap()
        Util.AccessController.assertAuthorizedToView(
                Schema.Playout__c.getSobjectType(),
                new List<Schema.SobjectField>{
                        Schema.Playout__c.fields.Name
                }
        );

        //CRUD/FLS check - Update
        Util.AccessController.assertAuthorizedToUpdate(
                Schema.Playout__c.getSobjectType(),
                new List<Schema.SobjectField>{
                        Schema.Playout__c.fields.Name, Schema.Playout__c.fields.Field__c,
                        Schema.Playout__c.fields.Order__c
                }
        );
        //CRUD/FLS check - INSERT
        Util.AccessController.assertAuthorizedToCreate(
                Schema.Playout__c.getSobjectType(),
                new List<Schema.SobjectField>{
                        Schema.Playout__c.fields.Name, Schema.Playout__c.fields.Field__c,
                        Schema.Playout__c.fields.Order__c
                }
        );



        Map<String, Schema.SObjectField> schemaFieldMap = getFieldMap(request, sObjectName);




        if(schemaFieldMap != null) {
            Schema.SObjectField sObjectField = schemaFieldMap.get(field);
            
            List<Playout__c> obj = Playout_DataQuery.getPlayoutByField(sObjectName, field);

            //That means this field already exists so we need to update it with new order
            //But only if new order is different (save DML operation
            if (obj.size() > 0) {
                if ((obj[0].Order__c != order)) {
                    obj[0].Order__c = order;
                    update obj[0];
                    request.addMessage(ETLC_ApexBridge_Request.MessageType.Information, 'Field succesfully updated!');
                } else {
                    request.addMessage(ETLC_ApexBridge_Request.MessageType.Information, 'Field already added to user list');
                }
                retVal = true;
            } else {
                Playout__c objNew = new Playout__c();
                objNew.Name = 'User_' + UserInfo.getUserId();
                objNew.User__c = UserInfo.getUserId();
                objNew.Order__c = order;
                objNew.Field__c = field;
                objNew.Object__c = sObjectName;

                insert objNew;

                retVal = true;
                request.addMessage(ETLC_ApexBridge_Request.MessageType.Information, 'Field succesfully added!');

            }
        }
        return retVal;
    }

    public Boolean removeFields(ETLC_ApexBridge_Request request, String sObjectName, String field){
        Boolean retVal = false;

        //CRUD/FLS check - Delete)
        if(Util.AccessController.isAuthorizedToDelete(Schema.Playout__c.getSobjectType())){
            List<Playout__c> obj = Playout_DataQuery.getPlayoutByField(sObjectName, field);
            //That means this field exists so we an delete it
            if(obj.size()>0){
                delete obj[0];
                request.addMessage(ETLC_ApexBridge_Request.MessageType.Information, 'Field succesfully removed!');
                retVal = true;
            }
        }else{
            throw new SFDCAccessControlException('Access Violation',
                    SFDCAccessControlException.ExceptionType.OBJECT_ACCESS_VIOLATION,
                    SFDCAccessControlException.ExceptionReason.NO_DELETE,
                    Schema.Playout__c.getSobjectType().getDescribe().getName(),
                    null);
        }
        return retVal;
    }

    public class FieldWrapper
    {
        public String apiname;
        public String label;
        public Boolean isUpdatable;
        public Integer order;
    }
    /**/
}