#! /usr/bin/env python
# vim: set ts=4 sw=4:

# vyznamy jednotlivych sloupcu v csv souboru:
# 0, 1 - datumy
# 2    - predepsana castka
# 3    - mena
# 4    - prevedena castka, ta se muze zmenit, napr. pri zmene stavu z Nerealizovano na Zrealizovano 
# 5    - timestamp (datum je shodne s datumem ze sloupce 0
# 6    - cislo uctu z nejz prisla platba
# 7    - kod banky z nejz prisla platba
# 8    - cislo uctu na nejz prisla platba
# 9    - kod bankdy na nejz prisla platba
# 10   - variabilni symbol
# 11   - konstantni symbol
# 12   - poznamka
# 13   - stav 
#         0 - Nezrealizovano
#         1 - Castecne realizovano
#         2 - Zrealizovano
#         3 - Suspendovano
#         4 - Ukonceno
#         5 - Cekani na clearing
# 14   - jmeno uctu protistrany
# 15   - identifikacni cislo

import sys
import csv
from datetime import datetime

from fred_transproc.template import render_template_head, render_template_tail, render_template_item

status_mapping = {
    0: 3,
    1: 2,
    2: 1,
    3: 4,
    4: 5,
    5: 6,
}

def error(msg):
    sys.stderr.write('Invalid format: ' + msg + '\n')
    sys.exit(1)

if __name__ == '__main__':
    source_lines = sys.stdin.readlines()
    reader = csv.reader(source_lines, delimiter=";")
    first_time = True
    for row in reader:
        if row == [' ']:
            # if no bank transaction, raifaisen bank returns file with one space :-(
            # we don't want to see this as error so just quit silently
            sys.exit(0)
        if len(row) != 16:
            error('Bad number of columns, text in source is:\n' + ''.join(source_lines))
        if first_time:
            first_time = False
            own_account_number = row[8].strip()
            own_account_bank_code = row[9].strip()
            number = ""
            date = ""
            balance = ""
            old_date = ""
            old_balance = ""
            credit = ""
            debet = ""
            print render_template_head([own_account_number, own_account_bank_code, number, date, balance,
                                        old_date, old_balance, credit, debet])
        ident = row[15].strip()
        account_number = row[6].strip()
        bank_code = row[7].strip()
        const_symbol = row[11].strip()
        var_symbol = row[10].strip()
        spec_symbol = ""
        price = row[4].strip().replace(',', '.').replace(' ', '')
        currency = row[3]
        if currency != 'CZK':
            # transfers which are not in CZK are processed throught
            # raiffeisen TXT reports
            # we set price to zero here in order to import the payment
            # and be sure that it will not be processed by backend
            # till correct price in CZK is known
            price = 0
        type = "" # only for output for backend, transproc leaves this blank

        # status
        #    * 1-Realized (only this should be further processed)
        #    * 2-Partially realized
        #    * 3-Not realized
        #    * 4-Suspended
        #    * 5-Ended
        #    * 6-Waiting for clearing 
        status = status_mapping[int(row[13].strip())]
        # import only realized payments
        if status != 1:
            continue

        # all transfers in CSV file are deposit from registrars
        code = "1"
        memo = row[12].strip()[:64]
        date = datetime.strptime(row[5].strip(), "%d.%m.%Y %H:%M:%S").date().isoformat()
        crtime = ""
        name = row[14].strip()
        print render_template_item([ident, account_number, bank_code, const_symbol,
                                    var_symbol, spec_symbol, price, type, code, status, memo,
                                    date, crtime, name])
    if first_time == False: # there was at least one row in input csv
        print render_template_tail()

