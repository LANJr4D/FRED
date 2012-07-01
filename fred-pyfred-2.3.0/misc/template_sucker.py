#!/usr/bin/env python
# vim:ts=4 sw=4:
import pgdb, re

def print_tpl(conn):
	'''
	Suck & print templates from database.
	'''
	cur = conn.cursor()
	print 'Listing of templates for mailer'
	print 'Delimiter of templates is line made of "*" characters.'
	cur.execute('SELECT id, name, subject FROM mail_type')
	for row in cur.fetchall():
		(id, name, subject) = row
		print '*' * 80
		print
		print 'Email\'s identifier: %s' % name
		print '---------------------'
		print 'Email\'s subject: %s' % subject
		print '---------------'
		print 'Email\'s template:'
		print '---------------'
		cur.execute('SELECT mt.template, mf.footer '
				'FROM mail_type_template_map mttm '
				'LEFT JOIN mail_templates mt ON (mt.id = mttm.templateid) '
				'LEFT JOIN mail_footer mf ON (mf.id = mt.footer) '
				'WHERE mttm.typeid = %d' % id)
		for templ in cur.fetchall():
			print templ[0]
			if templ[1]:
				print '\n'+ templ[1]
		print '*' * 80
	cur.close()

def __enrich_dict(dict, str):
	'''
	Add variables to dictionary.
	'''
	pat = re.compile('<\?cs [a-z]+:([\w.]+)\W')
	res = pat.findall(str)
	if not res:
		return
	for item in res:
		if dict.has_key(item):
			dict[item] += 1
		else:
			dict[item] = 1

def __merge_dicts(dict1, dict2):
	'''
	Merge variables in 2nd dict to 1th dict.
	'''
	for key in dict2:
		if dict1.has_key(key):
			dict1[key] += dict2[key]
		else:
			dict1[key] = dict2[key]

def print_vars(conn):
	'''
	Print variables used in templates.
	'''
	cur = conn.cursor()
	print 'Listing of variables used in templates:'
	print 'Delimiter of templates is line made of "*" characters.'
	global_vars = {}
	cur.execute('SELECT id, name, subject FROM mail_type')
	for row in cur.fetchall():
		(id, name, subject) = row
		local_vars = {}
		print 'Email\'s identifier: %s' % name
		__enrich_dict(local_vars, subject)
		cur.execute('SELECT mt.template, mf.footer '
				'FROM mail_type_template_map mttm '
				'LEFT JOIN mail_templates mt ON (mt.id = mttm.templateid) '
				'LEFT JOIN mail_footer mf ON (mf.id = mt.footer) '
				'WHERE mttm.typeid = %d' % id)
		for templ in cur.fetchall():
			__enrich_dict(local_vars, templ[0])
			__enrich_dict(local_vars, templ[1])
		for key in local_vars:
			print '    %s = %d' % (key, local_vars[key])
		__merge_dicts(global_vars, local_vars)
		print '*' * 80
	print 'Total counts in all templates:'
	list = []
	for key in global_vars:
		list.append( (global_vars[key], key) )
	list.sort(reverse=True)
	for item in list:
		print '    %s = %d' % (item[1], item[0])
	cur.close()

def main():
	conn = pgdb.connect(host = 'curlew', database = 'ccregdbs01', user = 'ccreg')
	print_vars(conn)
	conn.close()

if __name__ == '__main__':
	main()
