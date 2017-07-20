/**
 * Created by jrattanpal on 7/14/17.
 *
 */
({
    activateRefreshButton: function(component, helper){
        var refreshButton = component.find('refreshButton');
        refreshButton.set('v.disabled', false);

        var messages = [];
        messages.push(
            ["markup://ui:message", {
                'severity': 'information',
                'body': 'Data was refreshed!',
                'closable': true
            }]
        );

        component.find('utils').createComponents(messages, component.find('uiMessage'));

    },
    getRecordInfo: function(component, helper, callBack){
        var userFields = component.get('v.userFields');
        component.find('utils').log('userFields.length:', userFields.length);
        if(userFields.length <=0){
            var messages = [];
            messages.push(
                ["markup://ui:message", {
                    'severity': 'information',
                    'body': 'Please add some fields!',
                    'closable': false
                }]
            );

            component.find('utils').createComponents(messages, component.find('uiMessage'));
            return;
        }



        var recordId = component.get('v.recordId');

        var apexBridge = component.find("ETLC_ApexBridge");
        apexBridge.callApex({
            component: component,
            request: {
                controller: "Playout_Controller",
                method: "getRecordInfo",
                input: {
                    'recordId': recordId,
                    'sObjectName': component.get('v.sObjectName')
                },
                doesCallout: false
            },
            forceRefresh: true,
            pleaseWait: {
                type: "None",
            },
            callBackMethod: function (serverResponse) {
                component.find('utils').log('Playout_form:h.getRecordInfo:serverResponse:', serverResponse);
                component.set('v.record', serverResponse.output);

                var record = component.get('v.record');

                var form = [0,1];
                form[0] = [];
                form[1] = [];
                for(var i=0; i<userFields.length; i++){
                    var index = i%2;

                    form[index].push(
                        ["c:Playout_FormField", {
                            'value': record[userFields[i]['apiname']],
                            'label': userFields[i]['label']
                        }]
                    );
                }
                component.find('utils').createComponents(form[0], component.find('formcol1'));
                component.find('utils').createComponents(form[1], component.find('formcol2'));


                if(!$A.util.isUndefined(callBack)){
                    callBack.call(this, component, helper);
                }
            },
            errorHandler: function (serverResponse) {
                console.error('ERROR serverResponse:', serverResponse);
            }
        });
    }
})