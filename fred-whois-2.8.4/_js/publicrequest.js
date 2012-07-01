var isIE = window.ActiveXObject?true:false;

function getSelectItemIndex(field, value) {
    for (var i = 0; i < field.options.length; i++) {
        if (field.options[i].value == value) {
            return field.options[i].index;
        }
    }
}
function setRequestType(requestType) {
    var field = document.getElementById('requestType');
    field.selectedIndex = getSelectItemIndex(field, requestType);
    switchRequestType(field);
    return true;
}
function setFormPartsVisibility() {
    function setDisplay(elementsIDs, displayValue) {
        for (var i = 0; i < elementsIDs.length; i++) {
            var elem = document.getElementById(elementsIDs[i]);
            elem.style.display = displayValue;
        }
    }
    var field = document.getElementById('requestType');
    var isAuthInfo = (field.item(field.options.selectedIndex).value == 'authinfo');
    var sections=[
        ['confirmMethodTR'],
        ['sendingMethodTR', 'replymailTR', 'reasonTR', 'txtreasonTR']
    ];
    var showDisplay = isIE?'inline':'table-row';
    if (isAuthInfo) {
        setDisplay(sections[0], 'none');
        setDisplay(sections[1], showDisplay);
    } else {
        setDisplay(sections[1], 'none');
        setDisplay(sections[0], showDisplay);
    }
}

function switchRequestType(field) {
    setFormPartsVisibility();
}

function switchReplymail(field) {
    txt = document.getElementById('replymail')
    div = document.getElementById('divreplymail')
    if (field.options.selectedIndex == 0) {
        txt.disabled = 'disabled';
        getElement('mail_missing').className = '';
    } else {
        txt.disabled = '';
    }
}

function switchReason(field) {
    txt = document.getElementById('txtreason')
    div = document.getElementById('divreason')
    if (field.options.selectedIndex != 2) {
        txt.disabled = 'disabled';
        getElement('reason_missing').className = '';
    } else {
        txt.disabled = '';
    }
}

function checkSendPasswordByEmail() {
    if (document.getElementById('requestType').selectedIndex != 0) { // not authinfo 
        return '';
    }
    retval = '';
    replyMail = document.getElementById('replymail');
    field = document.getElementById('sendingMethod');

    if (field.options.selectedIndex > 0) {

        missing = false;
        if (replyMail.value.trim() == '') {
            retval = _T('Email missing.');
            missing = true;
        } else {
            if (!checkEmail(replyMail.value)) {
                retval = _T('Invalid email address.');
                missing = true;
            }
        }
        if (missing)
             getElement('mail_missing').className = 'missing';
        else getElement('mail_missing').className = '';
    }
    return retval;
}

function checkReason() {
    if (document.getElementById('requestType').selectedIndex != 0) { // not authinfo:
        return '';
    }
    retval = '';
    reason = document.getElementById('txtreason');
    field = document.getElementById('reason');

    if (field.options.selectedIndex == 2) {

        if (reason.value.trim() == '') {
            retval = _T('Other reason missing.');
            getElement('reason_missing').className = 'missing';

        } else getElement('reason_missing').className = '';
    }
    return retval;
}

function checkHandle(name) {

    retval = '';
    handle = document.getElementById(name);
    if (handle.value.trim() == '') {
        retval = _T('Handle missing.');
        getElement('missing_handle').className = 'missing';

    } else getElement('missing_handle').className = '';

    return retval;
}

var updateCaptchaPending = false;

function reset_pendings() {
    // If ajax request fails we need reset captcha updating.
    updateCaptchaPending = false;
}

function updateCaptcha() {
    if (updateCaptchaPending) {
        alert(_T('Image is loading. Please wait...'));
        return;
    }
    updateCaptchaPending = true;
    getStyle('captcha_updating').visibility = 'visible';
    request('/whois/create_captcha.py', updateCaptchaHandler);
}
function updateCaptchaHandler(req) {
    updateCaptchaPending = false;
    try {
        image_url = req.responseText;
    } catch (e) {
        alert(_T('Error')+': '+e);
        getStyle('captcha_updating').visibility = 'hidden';
        return;
    }
    hash = image_url.match(/id=(.+)$/);
    if (hash) {
        getElement('captcha_img').src = image_url;
        getElement('captchakey').value = hash[1];
    } else {
        alert(_T('Error')+': '+_T('Invalid captcha code.'));
    }
    setTimeout("getStyle('captcha_updating').visibility = 'hidden'", 1000);
}

function checkCaptcha() {

    retval = '';

    if (typeof(disableCaptcha) != 'undefined' && disableCaptcha)
        return retval;

    handle = document.getElementById('captcha');
    if (handle.value.trim() == '') {
        retval = _T('Security code missing.');
        getElement('missing_captcha').className = 'missing';

    } else getElement('missing_captcha').className = '';

    return retval;
}

function checkFormPublicRequest() {

    errors = new Array();

    errorMessage = checkHandle('handle');
    if (errorMessage) errors[errors.length] = errorMessage;

    errorMessage = checkSendPasswordByEmail();
    if (errorMessage) errors[errors.length] = errorMessage;

    errorMessage = checkReason();
    if (errorMessage) errors[errors.length] = errorMessage;

    errorMessage = checkCaptcha();
    if (errorMessage) errors[errors.length] = errorMessage;

    if (errors.length) {
        alert(_T('Error')+':\n'+errors.join('\n'));
        retval = false;
    } else {
        retval = true;
    }

    return retval;
}

function checkFormWhois() {
    errors = new Array();

    errorMessage = checkHandle('q');
    if (errorMessage) errors[errors.length] = errorMessage;

    errorMessage = checkCaptcha();
    if (errorMessage) errors[errors.length] = errorMessage;


    if (errors.length) {
        alert(_T('Error')+':\n'+errors.join('\n'));
        retval = false;
    } else {
        retval = true;
    }

    return retval;
}

function initCaptcha() {
    el = getElement('captcha_frame');
    if (el) {
        body = getElement('captcha_frame').innerHTML;
        getElement('captcha_frame').innerHTML = '<a href="javascript:updateCaptcha()" title="'+_T('Display another image.')+'">'+body+'</a>';
    }
}

function onLoad() {
    initCaptcha();
    var field = document.getElementById('requestType');
    if (field) {
        switchRequestType(field);
    }
}

//MochiKit.DOM.addLoadEvent(initCaptcha);
MochiKit.Signal.connect(window, "onload", onLoad);

