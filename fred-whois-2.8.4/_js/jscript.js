imgpath = '/apl/getImage.php';

function showData(e)
{
   if(document.forms['request'].format.selectedIndex == 1) {
      showImage(e);
   return false;
   }
}

function showImage(e)
{
   if(!e) e = window.event;
   var f = document.forms['request'];
   var url = "?";
   
   for(var x=0;x<f.length;x++){
    if(f.elements[x].type == "text" || f.elements[x].type == "hidden") url += f.elements[x].name+'='+f.elements[x].value+"&";
   else if(f.elements[x].type == "select-one") url+=(f.elements[x].value==''?f.elements[x].name+'='+f.elements[x].options[f.elements[x].selectedIndex].text+'&':f.elements[x].name+'='+f.elements[x].value+'&');
   else if(f.elements[x].type == "checkbox")  (f.elements[x].checked?url+=f.elements[x].name+'=on&':false);
   else if(f.elements[x].type == "radio")  (f.elements[x].checked?url+=f.elements[x].name+'='+f.elements[x].value+'&':false)
   }
   url = url.substring(0,(url.length-1));
   self.open(imgpath+url+'&is_image=1&srv='+srv_name,'','resizable=no,width=800,height=560,scrollbars=no,top=0,left=0');
   return false;
}



