// global flag
var isIE = window.ActiveXObject?true:false;

// global request and XML document objects
var req;

function reset_pendings() {
    // Overwrite this function by other one with values what must be reset.
}

function request(url, handler) {
    var req = (window.XMLHttpRequest ? new XMLHttpRequest : 
        (window.ActiveXObject ? new ActiveXObject('Microsoft.XMLHTTP') : false)
    );
    if (!req) {
        alert('AJAX XMLHttpRequest failed.');
        reset_pendings();
        return false;
    }

    req.open('GET', url);
    req.onreadystatechange = function() {

        if (req.readyState == 4) {
            // done
            if (req.status == 200)
                 handler(req); // OK
            else {
                alert('XMLHttpRequest Error: '+req.status+'; '+req.statusText); // Error
                reset_pendings();
            }
        }
    }
    req.send(null);
    return true;
}

// retrieve XML document (reusable generic function);
// parameter is URL string (relative or complete) to
// an .xml file whose Content-Type is a valid XML
// type, such as text/xml; XML source must be from
// same domain as HTML file
function loadXMLDoc(url) {
    // branch for native XMLHttpRequest object
    if (window.XMLHttpRequest) {
        req = new XMLHttpRequest();
        req.onreadystatechange = processReqChange;
        req.open("GET", url, true);
        
        req.send(null);
    // branch for IE/Windows ActiveX version
    } else if (window.ActiveXObject) {
        req = new ActiveXObject("Microsoft.XMLHTTP");
        if (req) {
            req.onreadystatechange = processReqChange;
            req.open("GET", url, true);
            req.send();
        }
    }
}

function loadXMLDocPOST(url, parameters, final) {
	if (final) parameters += "&final=1"
    if (window.XMLHttpRequest) {// branch for native XMLHttpRequest object
        req = new XMLHttpRequest();
    } else if (window.ActiveXObject) {// branch for IE/Windows ActiveX version
        req = new ActiveXObject("Microsoft.XMLHTTP");
    } else return False;
    if (req) {
        req.onreadystatechange = processReqChange;    
        req.open("POST", document.location.href, true);
        req.setRequestHeader("Content-type", "application/x-www-form-urlencoded");
        req.setRequestHeader("Content-length", parameters.length);
        req.send(parameters);
    }
}

function loadDoc(evt, final) {
    // equalize W3C/IE event models to get event object
    evt = (evt) ? evt : ((window.event) ? window.event : null);
    if (evt) {
        // equalize W3C/IE models to get event target reference
        var elem = (evt.target) ? evt.target : ((evt.srcElement) ? evt.srcElement : null);
        if (elem) {
            try {
                    loadXMLDocPOST('/', getFormValues(elem.form), final);
            }
            catch(e) {
                var msg = (typeof e == "string") ? e : ((e.message) ? e.message : "Unknown Error");
                alert("Unable to get XML data:\n" + msg);
                return;
            }
        }
    }
    return false;
}
// handle onreadystatechange event of req object
function processReqChange() {
    // only if req shows "loaded"
    if (req.readyState == 4) {
        // only if "OK"
        if (req.status == 200) {
            clearPage();
            buildPage();
         } else {
            alert("There was a problem retrieving the XML data:\n" +
                req.statusText);
         }
    }
}

function clearPage() {

}


function buildPage() {
	var response_xml = req.responseXML
	if (response_xml) {
		window.content_type_name = response_xml.getElementsByTagName('content_type_name')[0].textContent;
		window.object_id = response_xml.getElementsByTagName('object_id')[0].textContent;
		window.close()
		return;
	}

//	var response_body = response_xml.getElementByTagName('body')[0]
    //document.body = response_xml_body
    var response_text = req.responseText;
//    document.body.innerHTML = response_text;
    document.getElementById('form_div').innerHTML = response_text;
}

// fill Topics select list with items from
// the current XML document
/*function buildTopicList() {
    var select = document.getElementById("topics");
    var items = req.responseXML.getElementsByTagName("item");
    // loop through <item> elements, and add each nested
    // <title> element to Topics select element
    for (var i = 0; i < items.length; i++) {
        appendToSelect(select, i,
            document.createTextNode(getElementTextNS("", "title", items[i], 0)));
    }
    // clear detail display
    document.getElementById("details").innerHTML = "";
}

// display details retrieved from XML document
function showDetail(evt) {
    evt = (evt) ? evt : ((window.event) ? window.event : null);
    var item, content, div;
    if (evt) {
        var select = (evt.target) ? evt.target : ((evt.srcElement) ? evt.srcElement : null);
        if (select && select.options.length > 1) {
            // copy <content:encoded> element text for
            // the selected item
            item = req.responseXML.getElementsByTagName("item")[select.value];
            content = getElementTextNS("content", "encoded", item, 0);
            div = document.getElementById("details");
            div.innerHTML = "";
            // blast new HTML content into "details" <div>
            div.innerHTML = content;
        }
    }
}*/




function getFormValues(fobj,valFunc) {
	var str = "";
	var valueArr = null;
	var val = "";
	var cmd = "";
	for(var i = 0;i < fobj.elements.length;i++) {
	    switch(fobj.elements[i].type) {
	        case "text":
	        case "hidden":
	             if(valFunc) {
	                 //use single quotes for argument so that the value of
	                 //fobj.elements[i].value is treated as a string not a literal
	                 cmd = valFunc + "(" + 'fobj.elements[i].value' + ")";
	                 val = eval(cmd)
	             }
	
	             str += fobj.elements[i].name + "=" + escape(fobj.elements[i].value) + "&";
	             break;
	        case "select-one":
	             str += fobj.elements[i].name + "=" + fobj.elements[i].options[fobj.elements[i].selectedIndex].value + "&";
	             break;
	    }
	}
	str = str.substr(0,(str.length - 1));
	return str;
}
    





















