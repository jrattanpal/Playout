({
    doInit: function(component, event, helper){
        //Clear error message first (if any)
        component.find('utils').destroyComponents(component.find('uiMessage'));



        //Check if current object supports LDS
        var sObjectListForLDS = JSON.parse(component.get('v.sObjectListForLDS'));
        var sObjectName = component.get('v.sObjectName');



        //Check if current obejct supports LDS
        //Doing this manually because currently there is no way to check this dynamically
        if(!$A.util.isUndefined(sObjectListForLDS[sObjectName]) && (sObjectListForLDS[sObjectName] == true)){
            component.set('v.canUseLDS', true);

            /*
            var userFields = component.get('v.userFields');

            var userFieldsForLDS = '';
            //Generate list of fields from "userFields" so LDS can consume
            for(var i=0; i<userFields.length; i++) {
                userFieldsForLDS += userFields[i]['apiname'] + ',';
            }
            userFieldsForLDS = userFieldsForLDS.substring(0, userFieldsForLDS.length-1);
            component.set('v.userFieldsForLDS', userFieldsForLDS);
            /**/
        }

        //Use Apex to load record
        //LDS will be used to listen to changes and to call this method again when record changes
        helper.getRecordInfo(component, helper);


        /**/

    },
    refreshData: function(component, event, helper){
        var callbackMethod;
        var source = event.getSource();
        if(source.get('v.value') == 'RefreshButton'){
            source.set('v.disabled', true);
            callbackMethod =   helper.activateRefreshButton;
        }

        //Clear error message first (if any)
        component.find('utils').destroyComponents(component.find('uiMessage'));

        helper.getRecordInfo(component, helper, callbackMethod);


    },
    recordUpdated: function(component, event, helper) {

        var changeType = event.getParams().changeType;

        component.find('utils').log('Playout_Form:recordUpdated:changeType:', changeType);
        if (changeType === "CHANGED") { /* handle record change */
            helper.getRecordInfo(component, helper);
        }
    }
})