#!/usr/bin/env python
# vim:set ts=4 sw=4:
"""
Code of file manager daemon.
"""

import os, sys, random, time, ConfigParser, Queue
import pgdb
# corba stuff
from omniORB import CORBA, PortableServer
from pyfred.idlstubs import ccReg, ccReg__POA
from pyfred.utils import isInfinite


class FileManager_i (ccReg__POA.FileManager):
	"""
	This class implements FileManager interface.
	"""
	def __init__(self, logger, db, conf, joblist, corba_refs):
		"""
		Initializer saves db (which is later used for opening database
		connection) and logger (used for logging).
		"""
		# ccReg__POA.FileManager doesn't have constructor
		self.db = db # db object for accessing database
		self.l = logger # syslog functionality
		self.search_objects = Queue.Queue(-1) # list of created search objects
		self.download_objects = Queue.Queue(-1) # list of created download objs
		self.upload_objects = Queue.Queue(-1) # list of created upload objects
		self.corba_refs = corba_refs # poa for creating new objects

		# default configuration
		self.rootdir = "/var/tmp/filemanager"
		self.idletreshold = 3600
		self.checkperiod = 60
		# Parse FileManager-specific configuration
		if conf.has_section("FileManager"):
			try:
				rootdir = conf.get("FileManager", "rootdir")
				if rootdir:
					if not os.path.isabs(rootdir):
						self.l.log(self.l.ERR, "rootdir must be absolute path")
						raise Exception("rootdir must be absolute path")
					self.rootdir = rootdir
			except ConfigParser.NoOptionError, e:
				pass
			# check period
			try:
				self.checkperiod = conf.getint("FileManager", "checkperiod")
				self.l.log(self.l.DEBUG, "checkperiod is set to %d." %
						self.checkperiod)
			except ConfigParser.NoOptionError, e:
				pass
			# idle treshold
			try:
				self.idletreshold = conf.getint("FileManager", "idletreshold")
				self.l.log(self.l.DEBUG, "idletreshold is set to %d." %
						self.idletreshold)
			except ConfigParser.NoOptionError, e:
				pass

		# try to create rootdir if it does not exist
		if os.path.isdir(self.rootdir):
			if not os.access(self.rootdir, os.R_OK | os.W_OK):
				raise Exception("Directory '%s' is not r/w: " % self.rootdir)
		else:
			try:
				os.makedirs(self.rootdir, 0700)
			except Exception, e:
				raise Exception("Cannot create directory for file manager: %s"
						% e)

		# schedule regular cleanup
		joblist.append( { "callback":self.__object_cleaner, "context":None,
			"period":self.checkperiod, "ticks":1 } )
		self.l.log(self.l.DEBUG, "Object initialized")

	def __object_cleaner(self, ctx):
		"""
		Method deletes closed or idle search, upload and download objects.
		"""
		self.l.log(self.l.DEBUG, "Regular maintance procedure.")
		remove = []
		# the queues may change and the number of items in the queues may grow
		# but we can be sure that there will be never less items than nitems
		# therefore we can use blocking call get() on queue
		for queue in [self.search_objects, self.download_objects,
				self.upload_objects]:
			nitems = queue.qsize()
			for i in range(nitems):
				item = queue.get()
				# test idleness of object
				if time.time() - item.lastuse > self.idletreshold:
					item.status = item.IDLE

				# schedule objects to be deleted
				if item.status == item.CLOSED:
					self.l.log(self.l.DEBUG, "Closed object with id %d "
							"destroyed." % item.id)
					remove.append(item)
				elif item.status == item.IDLE:
					self.l.log(self.l.DEBUG, "Idle object with id %d "
							"destroyed." % item.id)
					remove.append(item)
				# if object is active - reinsert the object in queue
				else:
					self.l.log(self.l.DEBUG, "search/download/upload-object with id %d and type %s "
							"left in queue." % (item.id, item.__class__.__name__))
					queue.put(item)
					
			self.l.log(self.l.DEBUG, '%d objects are scheduled to deletion and %d left in queue' % (len(remove), queue.qsize()))
					
		# delete objects scheduled for deletion
		rootpoa = self.corba_refs.rootpoa
		for item in remove:
			id = rootpoa.servant_to_id(item)
			rootpoa.deactivate_object(id)

	def __dbGetId(self, conn):
		"""
		Retrieves Id of save request from database - it is a value of primary
		key.
		"""
		cur = conn.cursor()
		cur.execute("SELECT nextval('files_id_seq')")
		id = cur.fetchone()[0]
		cur.close()
		return int(id)

	def __dbSaveMetadata(self, conn, id, name, path, mimetype, filetype, size=0):
		"""
		Inserts record about saved file in database.
		"""
		if not mimetype:
			mimetype = None# use default value from database if type is not set
		if filetype == 0:
			filetype = None
		cur = conn.cursor()
		# insert new record
		cur.execute("INSERT INTO files (id, name, path, mimetype, filetype, "
					"filesize) "
				"VALUES (%d, %s, %s, %s, %s, %d) ",
				[id, name, path, mimetype, filetype, size])
		cur.close()

	def __dbGetMetadata(self, conn, id):
		"""
		Retrieve record describing a file from database.
		"""
		cur = conn.cursor()
		# check that there is not such a name in database already
		cur.execute("SELECT name, path, mimetype, filetype, crdate, filesize "
				"FROM files WHERE id = %d", [id])
		if cur.rowcount == 0:
			raise ccReg.FileManager.IdNotFound()
		name, path, mimetype, filetype, crdate, filesize = cur.fetchone()
		cur.close()
		if not filetype:
			filetype = 0
		return name, path, mimetype, filetype, crdate, filesize

	def __dbGetFileTypes(self, conn):
		"""
		Retrieve file types from database.
		"""
		cur = conn.cursor()
		# check that there is not such a name in database already
		cur.execute("SELECT id, name FROM enum_filetype")
		filelist = cur.fetchall()
		cur.close()
		return filelist

	def getTypeEnum(self):
		"""
		Method from IDL interface. Get enumeration of file types from database.
		"""
		try:
			# create request id
			id = random.randint(1, 9999)
			self.l.log(self.l.INFO, "<%d> Request for enumeration of types "
					"received" % id)
			# connect to database
			conn = self.db.getConn()
			typelist = self.__dbGetFileTypes(conn)
			self.db.releaseConn(conn)
			return [ ccReg.FileEnumType(item[0], item[1]) for item in typelist ]

		except pgdb.DatabaseError, e:
			self.l.log(self.l.ERR, "<%d> Database error: %s" % (id, e))
			raise ccReg.FileManager.InternalError("Database error")
		except Exception, e:
			self.l.log(self.l.ERR, "<%d> Unexpected exception caugth: %s:%s" %
					(id, sys.exc_info()[0], e))
			raise ccReg.FileManager.InternalError("Unexpected error")

	def save(self, name, mimetype, filetype):
		"""
		Method from IDL interface. It returns object through which is possible
		to upload data.
		"""
		try:
			id = random.randint(1, 9999)
			self.l.log(self.l.INFO, "<%d> Save request received (name = %s, "
					"mimetype = %s, filetype = %d)" %
					(id, name, mimetype, filetype))

			# connect to database
			conn = self.db.getConn()
			# get unique ID of request from database
			dbid = self.__dbGetId(conn)
			self.l.log(self.l.INFO, "<%d> Database id of uploaded file is %d." %
					(id, dbid))

			# generate path to file
			curtime = time.gmtime()
			relpath = "%d/%d/%d/%d" % (curtime[0], curtime[1], curtime[2], dbid)
			abspath = os.path.join(self.rootdir, relpath)
			# write meta-data to database
			self.__dbSaveMetadata(conn, dbid, name, relpath, mimetype, filetype)

			# check accessibility of path
			dir = os.path.dirname(abspath)
			if os.path.isdir(dir):
				if not os.access(dir, os.R_OK | os.W_OK):
					self.l.log(self.l.ERR, "<%d> Directory '%s' is not r/w." %
							(id, dir))
					raise ccReg.FileManager.InternalError("Storage error")
			else:
				try:
					os.makedirs(dir, 0700)
				except Exception, e:
					self.l.log(self.l.ERR, "<%d> Cannot create directory '%s': "
							"%s" % (id, dir, e))
					raise ccReg.FileManager.InternalError("Storage error")
			# save data to file
			fd = open(abspath, "wb")

			# Create an instance of FileUpload_i and an FileUpload object ref
			uploadobj = FileUpload_i(id, dbid, fd, conn, self.l)
			self.upload_objects.put(uploadobj)
			uploadref = self.corba_refs.rootpoa.servant_to_reference(uploadobj)
			return uploadref

		except ccReg.FileManager.InternalError, e:
			raise
		except pgdb.DatabaseError, e:
			self.l.log(self.l.ERR, "<%d> Database error: %s" % (id, e))
			raise ccReg.FileManager.InternalError("Database error")
		except Exception, e:
			self.l.log(self.l.ERR, "<%d> Unexpected exception caugth: %s:%s" %
					(id, sys.exc_info()[0], e))
			raise ccReg.FileManager.InternalError("Unexpected error")

	def load(self, fileid):
		"""
		Method from IDL interface. It loads data from a file.
		"""
		try:
			# create request id
			id = random.randint(1, 9999)
			self.l.log(self.l.INFO, "<%d> Load request received (file id = %d)."%
					(id, fileid))
			# connect to database
			conn = self.db.getConn()
			# get meta-info from database
			(name, relpath, mimetype, filetype, crdate, size) = \
					self.__dbGetMetadata(conn, fileid)
			self.db.releaseConn(conn)

			abspath = os.path.join(self.rootdir, relpath)
			if not os.path.exists(abspath):
				self.l.log(self.l.ERR, "<%d> File '%s' does not exist" %
						(id, abspath))
				raise ccReg.FileManager.FileNotFound()
			if not os.access(abspath, os.R_OK):
				self.l.log(self.l.ERR, "<%d> File '%s' is not accessible" %
						(id, abspath))
				# we will return 'file not exist' in this case
				raise ccReg.FileManager.FileNotFound()
			# open file
			fd = open(abspath, "rb")

			# Create an instance of FileDownload_i and an FileDownload object ref
			downloadobj = FileDownload_i(id, fd, self.l)
			self.download_objects.put(downloadobj)
			downloadref = self.corba_refs.rootpoa.servant_to_reference(downloadobj)
			return downloadref

		except ccReg.FileManager.FileNotFound, e:
			raise
		except ccReg.FileManager.IdNotFound, e:
			self.l.log(self.l.ERR, "<%d> ID '%d' does not exist in database." %
					(id, fileid))
			raise
		except ccReg.FileManager.InternalError, e:
			raise
		except pgdb.DatabaseError, e:
			self.l.log(self.l.ERR, "<%d> Database error: %s" % (id, e))
			raise ccReg.FileManager.InternalError("Database error")
		except Exception, e:
			self.l.log(self.l.ERR, "<%d> Unexpected exception caugth: %s:%s" %
					(id, sys.exc_info()[0], e))
			raise ccReg.FileManager.InternalError("Unexpected error")

	def info(self, fileid):
		"""
		Method from IDL interface. It gets meta info about file.
		"""
		try:
			# create request id
			id = random.randint(1, 9999)
			self.l.log(self.l.INFO, "<%d> Info request received (file id = %d)."%
					(id, fileid))
			# connect to database
			conn = self.db.getConn()
			# get meta-info from database
			name,relpath,mimetype,filetype,crdate,size = self.__dbGetMetadata(
					conn, fileid)
			self.db.releaseConn(conn)

			return ccReg.FileInfo(fileid, name, relpath, mimetype, filetype,
					crdate, size)

		except ccReg.FileManager.IdNotFound, e:
			self.l.log(self.l.ERR, "<%d> Id %d does not have record in database."
					% (id, fileid))
			raise
		except ccReg.FileManager.InternalError, e:
			raise
		except pgdb.DatabaseError, e:
			self.l.log(self.l.ERR, "<%d> Database error: %s" % (id, e))
			raise ccReg.FileManager.InternalError("Database error")
		except Exception, e:
			self.l.log(self.l.ERR, "<%d> Unexpected exception caugth: %s:%s" %
					(id, sys.exc_info()[0], e))
			raise ccReg.FileManager.InternalError("Unexpected error")

	def createSearchObject(self, filter):
		"""
		Method creates object which makes accessible results of a search.
		"""
		try:
			# create request id
			id = random.randint(1, 9999)
			self.l.log(self.l.INFO, "<%d> Search request received." % id)

			# construct SQL query coresponding to filter constraints
			conditions = []
			condvalues = []
			if filter.id != -1:
				conditions.append("files.id = %d")
				condvalues.append(filter.id)
			if filter.name:
				conditions.append("files.name = %s")
				condvalues.append(filter.name)
			if filter.path:
				conditions.append("files.path = %s")
				condvalues.append(filter.path)
			if filter.mimetype:
				conditions.append("files.mimetype = %s")
				condvalues.append(filter.mimetype)
			if filter.filetype != -1:
				if filter.filetype == 0:
					conditions.append("files.filetype IS NULL")
				else:
					conditions.append("files.filetype = %d")
					condvalues.append(filter.filetype)
			fromdate = filter.crdate._from
			if not isInfinite(fromdate):
				conditions.append("files.crdate > '%d-%d-%d %d:%d:%d'" %
						(fromdate.date.year,
						fromdate.date.month,
						fromdate.date.day,
						fromdate.hour,
						fromdate.minute,
						fromdate.second))
			todate = filter.crdate.to
			if not isInfinite(todate):
				conditions.append("files.crdate < '%d-%d-%d %d:%d:%d'" %
						(todate.date.year,
						todate.date.month,
						todate.date.day,
						todate.hour,
						todate.minute,
						todate.second))
			if len(conditions) == 0:
				cond = ""
			else:
				cond = "WHERE (%s)" % conditions[0]
				for condition in conditions[1:]:
					cond += " AND (%s)" % condition
			self.l.log(self.l.DEBUG, "<%d> Search WHERE clause is: %s" %
					(id, cond))

			# connect to database
			conn = self.db.getConn()
			cur = conn.cursor()

			cur.execute("SELECT id, name, path, mimetype, filetype, crdate, "
						"filesize FROM files %s" % cond, condvalues)
			# get meta-info from database
			self.db.releaseConn(conn)

			self.l.log(self.l.DEBUG, "<%d> Number of records in cursor: %d" %
					(id, cur.rowcount))

			# Create an instance of FileSearch_i and an FileSearch object ref
			searchobj = FileSearch_i(id, cur, self.l)
			self.search_objects.put(searchobj)
			searchref = self.corba_refs.rootpoa.servant_to_reference(searchobj)
			return searchref

		except ccReg.FileManager.InternalError, e:
			raise
		except pgdb.DatabaseError, e:
			self.l.log(self.l.ERR, "<%d> Database error: %s" % (id, e))
			raise ccReg.FileManager.InternalError("Database error")
		except Exception, e:
			self.l.log(self.l.ERR, "<%d> Unexpected exception caugth: %s:%s" %
					(id, sys.exc_info()[0], e))
			raise ccReg.FileManager.InternalError("Unexpected error")


class FileSearch_i (ccReg__POA.FileSearch):
	"""
	Class encapsulating results of search.
	"""

	# statuses of search object
	ACTIVE = 1
	CLOSED = 2
	IDLE = 3

	def __init__(self, id, cursor, log):
		"""
		Initializes search object.
		"""
		self.l = log
		self.id = id
		self.cursor = cursor
		self.status = self.ACTIVE
		self.crdate = time.time()
		self.lastuse = self.crdate
		self.lastrow = cursor.fetchone()

	def getNext(self, count):
		"""
		Get result of search.
		"""
		try:
			self.l.log(self.l.INFO, "<%d> Get search result request received." %
					self.id)

			# check count
			if count < 1:
				self.l.log(self.l.WARNING, "Invalid count of domains requested "
						"(%d). Default value (1) is used." % count)
				count = 1

			# check status
			if self.status != self.ACTIVE:
				self.l.log(self.l.WARNING, "<%d> Search object is not active "
						"anymore." % self.id)
				raise ccReg.FileSearch.NotActive()

			# update last use timestamp
			self.lastuse = time.time()

			# get 'count' results
			filelist = []
			for i in range(count):
				if not self.lastrow:
					break
				(id, name, path, mimetype, filetype, crdate, filesize) = \
						self.lastrow
				# corect filetype if None
				if filetype == None:
					filetype = 0
				self.lastrow = self.cursor.fetchone()
				filelist.append( ccReg.FileInfo(id, name, path, mimetype,
					filetype, crdate, filesize) )

			self.l.log(self.l.DEBUG, "<%d> Number of records returned: %d." %
					(self.id, len(filelist)))
			return filelist

		except ccReg.FileSearch.NotActive, e:
			raise
		except Exception, e:
			self.l.log(self.l.ERR, "<%d> Unexpected exception: %s:%s" %
					(self.id, sys.exc_info()[0], e))
			raise ccReg.FileSearch.InternalError("Unexpected error")

	def destroy(self):
		"""
		Mark object as ready to be destroyed.
		"""
		try:
			if self.status != self.ACTIVE:
				self.l.log(self.l.WARNING, "<%d> An attempt to close non-active "
						"search." % self.id)
				return

			self.status = self.CLOSED
			self.l.log(self.l.INFO, "<%d> Search closed." % self.id)
			# close db cursor
			self.cursor.close()
		except Exception, e:
			self.l.log(self.l.ERR, "<%d> Unexpected exception: %s:%s" %
					(self.id, sys.exc_info()[0], e))
			raise ccReg.FileSearch.InternalError("Unexpected error")


class FileUpload_i (ccReg__POA.FileUpload):
	"""
	Class encapsulating results of search.
	"""

	# statuses of search object
	ACTIVE = 1
	CLOSED = 2
	IDLE = 3

	def __init__(self, id, dbid, f, conn, log):
		"""
		Initializes upload object.
		"""
		self.l = log
		self.id = id
		self.dbid = dbid
		self.fd = f
		self.conn = conn
		self.status = self.ACTIVE
		self.crdate = time.time()
		self.lastuse = self.crdate
		self.size = 0

	def __dbUpdateFileSize(self, conn, id, size):
		"""
		Update file size field in file table.
		"""
		cur = conn.cursor()
		cur.execute("UPDATE files SET filesize = %d WHERE id = %d", [size, id])
		cur.close()

	def upload(self, data):
		"""
		Upload part of a file stored in data.
		"""
		try:
			self.l.log(self.l.INFO, "<%d> Upload chunk of file request received "
					"(%d bytes)." % (self.id, len(data)))
			# check status
			if self.status != self.ACTIVE:
				self.l.log(self.l.WARNING, "<%d> Upload object is not active "
						"anymore." % self.id)
				raise ccReg.FileUpload.NotActive()
			# update last use timestamp
			self.lastuse = time.time()

			# append uploaded data to existing one
			self.size += len(data)
			self.fd.write(data)

		except ccReg.FileUpload.NotActive, e:
			raise
		except Exception, e:
			self.l.log(self.l.ERR, "<%d> Unexpected exception: %s:%s" %
					(self.id, sys.exc_info()[0], e))
			raise ccReg.FileUpload.InternalError("Unexpected error")

	def finalize_upload(self):
		"""
		Finalize upload of a file and mark object as ready to be destroyed.
		"""
		try:
			if self.status != self.ACTIVE:
				self.l.log(self.l.WARNING, "<%d> An attempt to close non-active"
						" upload object." % self.id)
				return

			self.__dbUpdateFileSize(self.conn, self.dbid, self.size)
			self.fd.close()
			self.status = self.CLOSED
			# commit changes in database
			self.conn.commit()
			# XXX close should not be called directly
			self.conn.close()
			self.l.log(self.l.INFO, "<%d> Upload closed." % self.id)
			return self.dbid

		except pgdb.DatabaseError, e:
			self.l.log(self.l.ERR, "<%d> Database error: %s" % (self.id, e))
			raise ccReg.FileUpload.InternalError("Database error")
		except Exception, e:
			self.l.log(self.l.ERR, "<%d> Unexpected exception: %s:%s" %
					(self.id, sys.exc_info()[0], e))
			raise ccReg.FileUpload.InternalError("Unexpected error")


class FileDownload_i (ccReg__POA.FileDownload):
	"""
	Class encapsulating results of search.
	"""

	# statuses of search object
	ACTIVE = 1
	CLOSED = 2
	IDLE = 3

	def __init__(self, id, fd, log):
		"""
		Initializes download object.
		"""
		self.l = log
		self.id = id
		self.fd = fd
		self.status = self.ACTIVE
		self.crdate = time.time()
		self.lastuse = self.crdate

	def download(self, nbytes):
		"""
		Download part of a file from filesystem.
		"""
		try:
			self.l.log(self.l.INFO, "<%d> Download chunk of file request "
					"received (%d bytes)." % (self.id, nbytes))
			# check status
			if self.status != self.ACTIVE:
				self.l.log(self.l.WARNING, "<%d> Download object is not active "
						"anymore." % self.id)
				raise ccReg.FileDownload.NotActive()
			# update last use timestamp
			self.lastuse = time.time()

			# read data from file and return them
			return self.fd.read(nbytes)

		except ccReg.FileDownload.NotActive, e:
			raise
		except Exception, e:
			self.l.log(self.l.ERR, "<%d> Unexpected exception: %s:%s" %
					(self.id, sys.exc_info()[0], e))
			raise ccReg.FileDownload.InternalError("Unexpected error")

	def finalize_download(self):
		"""
		Finalize download of a file and mark object as ready to be destroyed.
		"""
		try:
			if self.status != self.ACTIVE:
				self.l.log(self.l.WARNING, "<%d> An attempt to close non-active"
						" download object." % self.id)
				return

			self.fd.close()
			self.status = self.CLOSED
			self.l.log(self.l.INFO, "<%d> Download closed." % self.id)

		except Exception, e:
			self.l.log(self.l.ERR, "<%d> Unexpected exception: %s:%s" %
					(self.id, sys.exc_info()[0], e))
			raise ccReg.FileUpload.InternalError("Unexpected error")

def init(logger, db, conf, joblist, corba_refs):
	"""
	Function which creates, initializes and returns servant FileManager.
	"""
	# Create an instance of FileManager_i and an FileManager object ref
	servant = FileManager_i(logger, db, conf, joblist, corba_refs)
	return servant, "FileManager"

