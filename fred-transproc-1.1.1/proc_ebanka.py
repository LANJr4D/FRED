#!/usr/bin/env python
#

import sys
from fred_transproc.template import template_head
from fred_transproc.template import template_tail
from fred_transproc.template import template_item

def error(msg):
    sys.stderr.write('Invalid format: ' + msg + '\n')
    sys.exit(1)

def getfield(str, i, delim = ' '):
    list = [ field for field in str.split(delim) if field ]
    if len(list) < i:
        error('Required field %d is not present in string "%s"' % (i, str))
    return list[i - 1]


if __name__ == '__main__':
    
    sys.stderr.write('''proc_ebanka processor is not up to date!!! 
    There were several changes in format of output XML which are not possible 
    to do for text source of statement from raifaisen bank (ebanka) 
    like unique identifier of payment, so this processor is obsolete.''')
    sys.exit(1)
    
    input = sys.stdin.read()
    input = input.replace('\r', '').strip() # delete \r characters
    sections = [ section.strip() for section in input.split('\n\n') if section ]
    if len(sections) != 3:
        if len(sections) >= 4 and not sections[3].startswith('Detaily ZPS'):
            error('Transcript has %d sections and should have 3' % len(sections))

    # header 1
    lines = [ line.strip() for line in sections[0].split('\n') ]
    if not lines[0] in ('Raiffeisenbank a.s.', 'eBanka'):
        error('Transcript does not start with "Raiffeisenbank a.s." word')
    var_number = getfield(lines[1], 4)
    if lines[2].find('/') != -1:
        dates = getfield(lines[2], 3).split('/')
        tmp_date_old = dates[0].split('.')
        tmp_date_new = dates[1].split('.')
        var_date_new = tmp_date_new[2] + '-' + tmp_date_new[1] + '-' + tmp_date_new[0]
        var_date_old = tmp_date_old[2] + '-' + tmp_date_old[1] + '-' + tmp_date_old[0]
    else:
        tmp_date = getfield(lines[2], 2).split('.')
        var_date_new = tmp_date[2] + '-' + tmp_date[1] + '-' + tmp_date[0]
        var_date_old  = var_date_new
    year = var_date_new.split('-')[0][2:]
    # header 2
    lines = [ line.strip() for line in sections[1].split('\n') ]
    var_account_id = getfield(lines[1], 3)
    # header 3 + body
    subsections = [ section.strip('\n') for section in sections[2].split('=' * 86) if section ]
    if len(subsections) not in [2, 5]:
        error('Transcript has %d subsections and should have 3 or 5' %
                len(subsections))
        # header 3
    lines = [ line.strip() for line in subsections[1].split('\n') ]
    var_oldBalance = getfield(lines[0], 2, '  ').replace(' ', '')
    var_credit     = getfield(lines[1], 3, '  ').replace(' ', '')
    var_debet      = getfield(lines[2], 3, '  ').replace(' ', '')
    var_balance    = getfield(lines[4], 2, '  ').replace(' ', '')
    # print what we have so far
    print template_head % (var_account_id, var_number, var_date_new, var_balance,
            var_date_old, var_oldBalance, var_credit, var_debet)
    # body
    if len(subsections) > 2:
        transfers = [ transfer for transfer in subsections[4].split('-' * 86) if transfer ]
        for transfer in transfers:
            lines = [ line for line in transfer.split('\n') if line ]#[:3]
            if not (len(lines) == 3 or len(lines) == 4 or len(lines) == 5):
                error('Bad number of lines of transaction item')
            item_spec_symbol = lines[0][44:55].strip()
            item_number = lines[0][:5].strip()
            item_price = lines[0][55:76].strip().replace(' ','')
            if item_price == '':
                item_price = lines[0][79:86].strip().replace(' ', '')
            item_date_tmp = lines[0][5:11].strip().strip('.').split('.')
            item_date = '20' + year + '-' + item_date_tmp[1] + '-' + item_date_tmp[0]
            item_time= lines[1][5:11].strip()
            item_name = lines[1][11:33].strip()
            item_currency = lines[1][34:36].strip()
            item_var_symbol = lines[1][44:55].strip()
            item_const_symbol = lines[2][44:55].strip()
            if item_price.startswith('-'):
                item_code = '1'
            else:
                item_code = '2'

            # payments between us and bank (and vice versa) has constant symbol 598 or 898
            if item_const_symbol == '598' or item_const_symbol == '898':
                item_type = '2'
            else:
                # other transfers are from registrars
                item_type = '1'

            if lines[2].find('/') != -1:
                (item_account_number, item_account_bank_code) = \
                        lines[2][11:33].strip().split('/')
            else:
                item_account_number, item_account_bank_code = \
                        var_account_id.split('/')

            if len(lines) == 4:
                item_memo = lines[3].strip()
            elif len(lines) == 5:
                # this is for foreign currency transfers
                item_memo = lines[3].strip() + lines[4].strip()
            else:
                item_memo = lines[0][11:33].strip()

            # there is a limit in the database (varchar(64))
            item_memo = item_memo[:63]
            item_ident = '' # this statement does not contain ident as ebanka_csv source :(

            print template_item % (item_ident,
                    item_account_number, item_account_bank_code,
                    item_const_symbol, item_var_symbol, item_spec_symbol,
                    item_price, item_type, item_code, item_memo, item_date,
                    item_date + ' ' + item_time, item_name)

    print template_tail
    sys.exit(0)
