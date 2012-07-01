import types
from fred_webadmin.webwidgets.gpyweb.gpyweb import WebWidget, tagid, attr, notag, div, span, table, caption, tbody, tr, th, td, input, label, select, option, ul, li, script, a, img, strong
from fred_webadmin.webwidgets.details.abstractdetaillayout import AbstractDetailLayout

class SectionLayout(AbstractDetailLayout):
    def __init__(self, detail, section_spec, *content, **kwd):
        super(SectionLayout, self).__init__(detail, *content, **kwd)
        self.tag = 'table'
        self.tattr_list = table.tattr_list
        if isinstance(section_spec[1], (types.StringTypes)): # if only one field_name is specified, convert it to string
            raise RuntimeError('Section spec field names have to be tuple or list, not string ("%s")' % section_spec[1])
        self.section_spec = section_spec
            
        self.create_layout()
        
    def get_fields(self):
        section_fields_names = self.section_spec[1]
        return [item[1] for item in self.detail.fields.items() if item[0] in section_fields_names]
    
    def get_fields_dict(self):
        section_fields_names = self.section_spec[1]
        return dict([item for item in self.detail.fields.items() if item[0] in section_fields_names])
    
    def layout_start(self):
        section_name = self.section_spec[0]

        css_class = 'section_table'
#        if self.detail.is_nested:
#            css_class = 'nested_' + css_class
        self.cssc=css_class
        if section_name:
            self.add(caption(attr(cssc='section_label'), section_name + ':'))
        self.add(tbody(tagid('tbody')))
        
    def layout_fields(self):        
        fields_in_section = self.get_fields()
        
        for field in fields_in_section:
            label_str = self.get_label_name(field)
            self.tbody.add(tr(td(attr(cssc='left_label'), label_str),
                                 td(field)
                             ))
    
    def create_layout(self):
        self.layout_start()
        self.layout_fields()
        


class DirectSectionLayout(SectionLayout):
    ''' Section layout that adds fields directly (without any table or other tags)
    '''
    def __init__(self, detail, section_spec, *content, **kwd):
        super(DirectSectionLayout, self).__init__(detail, section_spec, *content, **kwd)
        self.tag = ''
    
    def layout_start(self):
        section_name = self.section_spec[0]
        self.add(div(attr(cssc='section_label'), section_name + ':'))
        
    def layout_fields(self):        
        fields_in_section = self.get_fields()
        
        for field in fields_in_section:
            self.add(field)
    
    
        
