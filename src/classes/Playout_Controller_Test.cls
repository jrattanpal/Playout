@isTest
private class Playout_Controller_Test {

    static String controller = 'Playout_Controller';
    static Boolean debug = true;
    static ETLC_ApexBridge_BaseTests base = new ETLC_ApexBridge_BaseTests();


    private static Profile p;
    private static User u;

    private static void dataSetupForRunAs(){
        p = [SELECT Id FROM Profile WHERE Name='Standard User'];
        u = new User(Alias = 'standt', Email='playoutuser@test.playoutapp',
                EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
                LocaleSidKey='en_US', ProfileId = p.Id,
                TimeZoneSidKey='America/Los_Angeles', UserName='playoutuser@test.playoutapp');
    }


    /**
     * Do any presetup here like setting up debug to true or other variable
     */
    private static void envSetup(){
        //base.debug for Request debug
        //Util.debug to use Util.debu() in this function; just to ensure it is set
        //Utildebug = true is not needed if we call Util.debug() after base.testHelper()
        base.debug = debug;
    }

    /**
     * Add fields based on aavailable fields to make it dynamic and avoid hardcoding that metadata as it might change
     */
    private static void getFieldMap(List<Playout__c>  objList, String sObjectName){
        String[] types = new String[]{sObjectName};

        Schema.DescribeSobjectResult[] results = Schema.describeSObjects(types);
        //If above statement returned the object AND if that object is accessible to user
        Map<String, Schema.SObjectField> schemaFieldMap = results[0].fields.getMap();


        if(schemaFieldMap != null){
            for (Schema.SObjectField sfield : schemaFieldMap.Values()) {
                schema.describefieldresult dfield = sfield.getDescribe();
                if (dfield.isAccessible()) {
                    Playout__c objNew = new Playout__c();
                    objNew.Name = 'User_' + UserInfo.getUserId();
                    objNew.User__c = UserInfo.getUserId();
                    objNew.Order__c = 5;
                    objNew.Field__c = dfield.getname();
                    objNew.Object__c = sObjectName;

                    objList.add(objNew);
                }
            }
        }
    }

    /**
     * Call this method when data is needed
     * @testSetup wasn't used as want to have data selectively
     */
    private static void dataSetup(){

        List<Playout__c>  objList = new List<Playout__c>();
        getFieldMap(objList, 'Case');
        getFieldMap(objList, 'Account');

        insert objList;

    }

    @isTest
    private static void getFieldList_getRecordInfo_withUserFieldsAdded_withData_Test(){
        envSetup();
        dataSetup();

        Case c = new Case();
        c.Subject = 'Test';
        insert c;


        //Save Field
        Map<String, Object> data = new Map<String, Object>();
        data.put('sObjectName', 'case');
        data.put('recordId', c.Id);

        ETLC_ApexBridge_Request request = base.testHelper(controller, 'getRecordInfo', data);


        Case obj = (Case)JSON.deserialize(request.output, sObject.class);

        //Empty because no user fields added
        System.assertEquals('Test', obj.Subject);
    }


    @isTest
    private static void getFieldList_getRecordInfo_withUserFieldsAdded_withData_Test_runAs_negative(){
        envSetup();
        dataSetup();
        dataSetupForRunAs();

        System.runAs(u) {

            Case c = new Case();
            c.Subject = 'Test';
            insert c;


            //Save Field
            Map<String, Object> data = new Map<String, Object>();
            data.put('sObjectName', 'case');
            data.put('recordId', c.Id);

            ETLC_ApexBridge_Request request = base.testHelper(controller, 'getRecordInfo', data);


            //Empty because of CRUD check
            System.assertEquals('""', request.output);
        }
    }


    @isTest
    private static void getFieldList_getRecordInfo_noUserFieldsAdded_withData_Test(){
        envSetup();

        Case c = new Case();
        c.Subject = 'Test';
        insert c;


        //Save Field
        Map<String, Object> data = new Map<String, Object>();
        data.put('sObjectName', 'case');
        data.put('recordId', c.Id);

        ETLC_ApexBridge_Request request = base.testHelper(controller, 'getRecordInfo', data);

        //Empty because no user fields added
        System.assertEquals('""', request.output);



    }


    @isTest
    private static void getFieldList_getRecordInfo_withUserFieldsAdded_noData_Test(){
        envSetup();
        dataSetup();

        //Save Field
        Map<String, Object> data = new Map<String, Object>();
        data.put('sObjectName', 'case');
        data.put('recordId', null);

        ETLC_ApexBridge_Request request = base.testHelper(controller, 'getRecordInfo', data);

        System.debug('getFieldList_getRecordInfo_noData_Test:request:' + request);
        System.assertEquals('""', request.output);

        Map<ETLC_ApexBridge_Request.MessageType, List<String>> retMessages = request.messages;
        //This should fail because of exception
        System.assertEquals(true, retMessages.get(ETLC_ApexBridge_Request.MessageType.Errors).size() > 0);


    }


    @isTest
    private static void getFieldList_getRecordInfo_noUserFieldsAdded_noData_Test(){
        envSetup();

        //Save Field
        Map<String, Object> data = new Map<String, Object>();
        data.put('sObjectName', 'case');
        data.put('recordId', null);

        ETLC_ApexBridge_Request request = base.testHelper(controller, 'getRecordInfo', data);

        System.assertEquals('""', request.output);


    }


    @isTest
    private static void getFieldList_removeFields_Test_runAs_negative(){
        envSetup();
        dataSetupForRunAs();

        System.runAs(u) {

            //Save Field before removing it
            Map<String, Object> data = new Map<String, Object>();
            data.put('sObjectName', 'case');
            data.put('field', 'Subject');

            ETLC_ApexBridge_Request request = base.testHelper(controller, 'removeFields', data);

            System.assertEquals(false, Boolean.valueOf(request.output));

            Map<ETLC_ApexBridge_Request.MessageType, List<String>> retMessages = request.messages;
            //This should fail because of exception
            System.assertEquals(true, retMessages.get(ETLC_ApexBridge_Request.MessageType.Errors).size() > 0);
        }
    }


    @isTest
    private static void getFieldList_saveFields_updateExisting_Test(){

        //Save Field
        Map<String, Object> data = new Map<String, Object>();
        data.put('sObjectName', 'Case');
        data.put('field', 'Subject');
        data.put('order', 0);

        ETLC_ApexBridge_Request request = base.testHelper(controller, 'saveFields', data);

        System.assertEquals(true, Boolean.valueOf(request.output));

        Playout__c p = [select id, Field__c, Order__c from Playout__c where Object__c='Case' and Field__c='Subject' and Order__c = 0];
        System.assertEquals('Subject', p.Field__c);
        System.assertEquals(0, p.Order__c);


        //Update that field that field was successfully added
        data = new Map<String, Object>();
        data.put('sObjectName', 'case');
        data.put('field', 'Subject');
        data.put('order', 0);

        //Doing this manually rather than using base.testHelper()
        //This is because testHelper() uses test.start() and test.stop()
        //We can't do that twice
        ETLC_ApexBridge_Request requestIn = new ETLC_ApexBridge_Request();
        requestIn.controller = controller;
        requestIn.method = 'saveFields';
        requestIn.input = ETLC_ApexBridge_Request.encodeData(data);

        request = ETLC_ApexBridge_Request.fromJSON(
                ETLC_ApexBridge_Controller.execute(requestIn.toJSON())
        );
        System.assertEquals(true, Boolean.valueOf(request.output));


        p = [select id, Field__c, Order__c from Playout__c where Object__c='Case' and Field__c='Subject' and Order__c = 0];
        System.assertEquals('Subject', p.Field__c);
        System.assertEquals(0, p.Order__c);
    }



    @isTest
    private static void getFieldList_removeFields_Test(){
        envSetup();

        //Save Field before removing it
        Map<String, Object> data = new Map<String, Object>();
        data.put('sObjectName', 'case');
        data.put('field', 'Subject');

        ETLC_ApexBridge_Request request = base.testHelper(controller, 'removeFields', data);

        System.assertEquals(false, Boolean.valueOf(request.output));


        //Now add a new field to actually remove it

        data = new Map<String, Object>();
        data.put('sObjectName', 'case');
        data.put('field', 'Subject');
        data.put('order', 5);

        //Doing this manually rather than using base.testHelper()
        //This is because testHelper() uses test.start() and test.stop()
        //We can't do that twice
        ETLC_ApexBridge_Request requestIn = new ETLC_ApexBridge_Request();
        requestIn.controller = controller;
        requestIn.method = 'saveFields';
        requestIn.input = ETLC_ApexBridge_Request.encodeData(data);

        request = ETLC_ApexBridge_Request.fromJSON(
                ETLC_ApexBridge_Controller.execute(requestIn.toJSON())
        );

        List<Playout__c> p = [select id, Field__c, Order__c from Playout__c where Object__c='Case'];
        System.assertEquals(1, p.size());
        System.assertEquals('Subject', p[0].Field__c);
        System.assertEquals(5, p[0].Order__c);


        //Let's remove field now that we added
        data = new Map<String, Object>();
        data.put('sObjectName', 'case');
        data.put('field', 'Subject');


        requestIn = new ETLC_ApexBridge_Request();
        requestIn.controller = controller;
        requestIn.method = 'removeFields';
        requestIn.input = ETLC_ApexBridge_Request.encodeData(data);

        request = ETLC_ApexBridge_Request.fromJSON(
                ETLC_ApexBridge_Controller.execute(requestIn.toJSON())
        );


        p = [select id, Field__c, Order__c from Playout__c where Object__c='Case'];
        System.assertEquals(0, p.size());


    }

    @isTest
    private static void getFieldList_saveFields_Test(){
        envSetup();

        //Save Field
        Map<String, Object> data = new Map<String, Object>();
        data.put('sObjectName', 'case');
        data.put('field', 'Subject');
        data.put('order', 0);

        ETLC_ApexBridge_Request request = base.testHelper(controller, 'saveFields', data);

        System.assertEquals(true, Boolean.valueOf(request.output));

        //Check that field was successfully added
        data = new Map<String, String>();
        data.put('sObjectName', 'case');

        List<Playout__c> p = [select id, Field__c, Order__c from Playout__c where Object__c='Case'];
        System.assertEquals(1, p.size());
        System.assertEquals('Subject', p[0].Field__c);
        System.assertEquals(0, p[0].Order__c);
    }


    @isTest
    private static void getFieldList_saveFields_update_Test(){

        //Save Field
        Map<String, Object> data = new Map<String, Object>();
        data.put('sObjectName', 'Case');
        data.put('field', 'Subject');
        data.put('order', 0);

        ETLC_ApexBridge_Request request = base.testHelper(controller, 'saveFields', data);

        System.assertEquals(true, Boolean.valueOf(request.output));

        Playout__c p = [select id, Field__c, Order__c from Playout__c where Object__c='Case' and Field__c='Subject' and Order__c = 0];
        System.assertEquals('Subject', p.Field__c);
        System.assertEquals(0, p.Order__c);


        //Update that field that field was successfully added
        data = new Map<String, Object>();
        data.put('sObjectName', 'case');
        data.put('field', 'Subject');
        data.put('order', 5);

        //Doing this manually rather than using base.testHelper()
        //This is because testHelper() uses test.start() and test.stop()
        //We can't do that twice
        ETLC_ApexBridge_Request requestIn = new ETLC_ApexBridge_Request();
        requestIn.controller = controller;
        requestIn.method = 'saveFields';
        requestIn.input = ETLC_ApexBridge_Request.encodeData(data);

        request = ETLC_ApexBridge_Request.fromJSON(
                ETLC_ApexBridge_Controller.execute(requestIn.toJSON())
        );
        System.assertEquals(true, Boolean.valueOf(request.output));


        p = [select id, Field__c, Order__c from Playout__c where Object__c='Case' and Field__c='Subject' and Order__c = 5];
        System.assertEquals('Subject', p.Field__c);
        System.assertEquals(5, p.Order__c);
    }


    @isTest
    private static void getFieldList_saveFields_Test_runAs_negative(){
        envSetup();
        dataSetupForRunAs();

        System.runAs(u) {

            //Save Field
            Map<String, Object> data = new Map<String, Object>();
            data.put('sObjectName', 'case');
            data.put('field', 'Subject');
            data.put('order', 0);

            ETLC_ApexBridge_Request request = base.testHelper(controller, 'saveFields', data);

            System.assertEquals(false, Boolean.valueOf(request.output));
        }
    }




    @isTest
    private static void getFieldList_withUserData_Test(){
        envSetup();
        dataSetup();

        Map<String, String> data = new Map<String, String>();
        data.put('sObjectName', 'case');

        ETLC_ApexBridge_Request request = base.testHelper(controller, 'getFieldList', data);

        Map<String, Object> retVal = (Map<String, Object>)JSON.deserializeUntyped(request.output);

        System.assertEquals(true, retVal.containsKey('availableFields'));
        System.assertEquals(true, retVal.containsKey('userFields'));

        List<Object> availableFields = (List<Object>)retVal.get('availableFields');
        List<Object> userFields = (List<Object>)retVal.get('userFields');


        System.assertEquals(true, availableFields.size()>0);
        System.assertEquals(true, userFields.size()>0);

        //When doing data setup, we are adding ALL available fields to user fields so both should match
        System.assertEquals(availableFields.size(), userFields.size());
    }


    @isTest
    private static void getFieldList_Test_runAs_noAccess(){
        envSetup();
        dataSetupForRunAs();

        System.runAs(u) {
            Map<String, String> data = new Map<String, String>();
            data.put('sObjectName', 'case');

            ETLC_ApexBridge_Request request = base.testHelper(controller, 'getFieldList', data);


            Map<ETLC_ApexBridge_Request.MessageType, List<String>> retMessages = request.messages;
            //This should fail because of exception
            System.assertEquals(true, retMessages.get(ETLC_ApexBridge_Request.MessageType.Errors).size() > 0);


            Map<String, Object> retVal = (Map<String, Object>)JSON.deserializeUntyped(request.output);
            //This should fail because of exception
            System.assertEquals(false, retVal.containsKey('availableFields'));
            System.assertEquals(false, retVal.containsKey('userFields'));
        }
    }


    @isTest
    private static void getFieldList_noUserData_Test(){
        envSetup();

        Map<String, String> data = new Map<String, String>();
        data.put('sObjectName', 'case');

        ETLC_ApexBridge_Request request = base.testHelper(controller, 'getFieldList', data);

        Map<String, Object> retVal = (Map<String, Object>)JSON.deserializeUntyped(request.output);

        System.assertEquals(true, retVal.containsKey('availableFields'));
        System.assertEquals(true, retVal.containsKey('userFields'));

        List<Object> availableFields = (List<Object>)retVal.get('availableFields');
        List<Object> userFields = (List<Object>)retVal.get('userFields');


        System.assertEquals(true, availableFields.size()>0);
        System.assertEquals(0, userFields.size());
    }


    @isTest public static void invalidMethodTest() { base.invalidMethodTest(controller); }
    /**/
}