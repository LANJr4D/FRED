//----------------------------------------------------
// indicate browser
//----------------------------------------------------
var isIE4 = (document.all ? true : false);
var isNS6 = ((document.rowsgetElementById && !isIE4) ? true : false);
var isNS4 = (document.layers ? true : false);
var isIE6 = (isIE4 && navigator.appVersion.match('MSIE [67]') ? true : false);

function getElement(id) {
        if (isNS6) return document.getElementById(id);
        if (isIE4) return document.all[id];
        if (isNS4) return document.layers[id];
        if (document.getElementById != 'undefined') return document.getElementById(id);
        return Null;
}

function getStyle(id) {
	return (isNS4 ? getElement(id) : getElement(id).style);
}

String.prototype.trim = function() {
  return this.replace(/^\s*|\s*$/g, "");
}

function checkEmail(text) {
    var filter  = /^([a-zA-Z0-9_\.\-])+\@(([a-zA-Z0-9_\-])+\.)+([a-zA-Z0-9]{2,4})+$/;
    return filter.test(text.trim());
}

function _T(text) {
    // messages translation
    if(typeof(translation) == "undefined")
        return text;

    for (i=0; i < translation.length; i++) {
        if (translation[i][0] == text) return translation[i][1];
    }
    return text;
}
