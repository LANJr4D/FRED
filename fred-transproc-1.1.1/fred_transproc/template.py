from xml.sax.saxutils import escape
import types

_template_head = '''<?xml version="1.0" encoding="UTF-8"?>
<statements>
  <statement>
    <account_number>%s</account_number>
    <account_bank_code>%s</account_bank_code>
    <number>%s</number>
    <date>%s</date>
    <balance>%s</balance>
    <old_date>%s</old_date>
    <old_balance>%s</old_balance>
    <credit>%s</credit>
    <debet>%s</debet>
    <items>'''

_template_tail = '''    </items>
  </statement>
</statements>'''

_template_item = '''      <item>
        <ident>%s</ident>
        <account_number>%s</account_number>
        <account_bank_code>%s</account_bank_code>
        <const_symbol>%s</const_symbol>
        <var_symbol>%s</var_symbol>
        <spec_symbol>%s</spec_symbol>
        <price>%s</price>
        <type>%s</type>
        <code>%s</code>
        <status>%s</status>
        <memo>%s</memo>
        <date>%s</date>
        <crtime>%s</crtime>
        <name>%s</name>
      </item>'''


def _escape_data_list(data_list):
    return tuple(escape(item if isinstance(item, types.StringTypes) else str(item)) for item in data_list)


def render_template_head(data_list):
    return _template_head % _escape_data_list(data_list)

def render_template_tail():
    return _template_tail

def render_template_item(data_list):
    return _template_item % _escape_data_list(data_list)
