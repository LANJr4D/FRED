#!/usr/bin/python
# -*- coding: utf-8 -*-
from copy import deepcopy
import types
import traceback
from logging import debug
import cherrypy

from fred_webadmin.webwidgets.gpyweb.gpyweb import WebWidget, form
from fields import Field
from formlayouts import TableFormLayout
from fred_webadmin.webwidgets.utils import ErrorDict, ErrorList, ValidationError, SortedDict
from fred_webadmin.utils import LateBindingProperty

NON_FIELD_ERRORS = '__all__'

class DeclarativeFieldsMetaclass(WebWidget.__metaclass__):
    """
    Metaclass that converts Field attributes to a dictionary called
    'base_fields', taking into account parent class 'base_fields' as well.
    """
    def __new__(cls, name, bases, attrs):
        fields = [(field_name, attrs.pop(field_name)) for field_name, obj in attrs.items() if isinstance(obj, Field)]
        fields.sort(lambda x, y: cmp(x[1].creation_counter, y[1].creation_counter))

        # If this class is subclassing another Form, add that Form's fields.
        # Note that we loop over the bases in *reverse*. This is necessary in
        # order to preserve the correct order of fields.
        for base in bases[::-1]:
            if hasattr(base, 'base_fields'):
                fields = base.base_fields.items() + fields

        attrs['base_fields'] = SortedDict(fields)
        for i, (field_name, field) in enumerate(attrs['base_fields'].items()):
            field.name_orig = field.name = field_name
            field.order = i

        new_class = type.__new__(cls, name, bases, attrs)
        return new_class
    
class BaseForm(form):
    # This is the main implementation of all the Form logic. Note that this
    # class is different than Form. See the comments by the Form class for more
    # information. Any improvements to the form API should be made to *this*
    # class, not to the Form class
    nperm_names = []
    name_postfix = ''
    def __init__(self, data=None, files=None, auto_id='id_%s', prefix=None,
                 initial=None, error_class=ErrorList, label_suffix=':', layout_class=TableFormLayout, 
                 is_nested = False, empty_permitted=False, *content, **kwd):
        super(BaseForm, self).__init__(*content, **kwd)
        
        if not is_nested:
            self.tag = u'form'
        else:
            self.tag = u''
        self.is_bound = data is not None or files is not None
        self.data = data or {}
        self.files = files or {}
        self.auto_id = auto_id
        self.prefix = prefix
        self.initial = initial or {}
        self.error_class = error_class
        self.label_suffix = label_suffix
        self._errors = None # Stores the errors after clean() has been called.
        self.layout_class = layout_class
        self.is_nested = is_nested
        self.empty_permitted = empty_permitted
        self._changed_data = None
        # The base_fields class attribute is the *class-wide* definition of
        # fields. Because a particular *instance* of the class might want to
        # alter self.fields, we create self.fields here by copying base_fields.
        # Instances should always modify self.fields; they should not modify
        # self.base_fields.
        self.fields = None
        self.filter_base_fields()
        self.build_fields()
        self.set_fields_values()
    
    def filter_base_fields(self):
        """ Filters base fields against user negative permissions, so if 
            the user has nperm on the field we delete it from base_fields.
        """
        if self.nperm_names:
            user = cherrypy.session.get('user', None)
            if user is None:
                self.base_fields = SortedDict({})
            else:
                object_name = self.get_object_name()
                filtered_base_fields = SortedDict(
                    [(name, field) for name, field in self.base_fields.items()
                     if not user.check_nperms(['%s.%s.%s' % (nperm_name, object_name, field.get_nperm()) for nperm_name in self.nperm_names], 'one')
                    ]
                )
                self.base_fields = filtered_base_fields
    
    @classmethod
    def get_object_name(cls):
        return cls.__name__[:-len(cls.name_postfix)].lower()
    
    def build_fields(self):
        self.fields = self.base_fields.deepcopy()
        for field in self.fields.values():
            field.owner_form = self
            field.name = self.add_prefix(field.name_orig)
        
    def set_fields_values(self):
        # setting initials is independent on whether form is bound or not:
        for field in self.fields.values():
            data = self.initial.get(field.name_orig, field.initial)
            if callable(data):
                data = data()
            if data is not None:
                field.initial = data

        if not self.is_bound:
            if self.initial:
                for field in self.fields.values():
                    if field.initial is not None:
                        field.value_is_from_initial = True
                        field.value = field.initial
        else:
            for field in self.fields.values():
                field.value = field.value_from_datadict(self.data)
        
    def __iter__(self):
        for field in self.fields.values():
            yield field

    def __getitem__(self, name):
        "Returns a field with the given name."
        try:
            field = self.fields[name]
        except KeyError:
            raise KeyError('Key %r not found in Form' % name)
        return field

    def _get_errors(self):
        "Returns an ErrorDict for the data provided for the form"
        try:
            if self._errors is None:
                self.full_clean()
            return self._errors
        except AttributeError:
            raise RuntimeError('Camouflaged AttributeError from _get_errors, original error: \n %s' % unicode(traceback.format_exc()))
            
    errors = property(_get_errors)

    def is_valid(self):
        """
        Returns True if the form has no errors. Otherwise, False. If errors are
        being ignored, returns False.
        """
#        import ipdb; ipdb.set_trace()
        return self.is_bound and not bool(self.errors)

    def add_prefix(self, field_name):
        """
        Returns the field name with a prefix appended, if this Form has a
        prefix set.

        Subclasses may wish to override.
        """
        return self.prefix and ('%s-%s' % (self.prefix, field_name)) or field_name

    def render(self, indent_level=0):
        self.content = [] # empty previous content (if render would be called moretimes, there would be multiple forms instead one )
        self.add(self.layout_class(self))
        return super(BaseForm, self).render(indent_level)

    def non_field_errors(self):
        """
        Returns an ErrorList of errors that aren't associated with a particular
        field -- i.e., from Form.clean(). Returns an empty ErrorList if there
        are none.
        """
        result = self.errors.get(NON_FIELD_ERRORS, None)
        if not result:
            result = self.errors[NON_FIELD_ERRORS] = self.error_class()
        return result

    def is_empty(self, exceptions=None):
        """
        Returns True if this form has been bound and all fields that aren't
        listed in exceptions are empty.
        """
        # TODO: This could probably use some optimization
        exceptions = exceptions or []
        for name, field in self.fields.items():
            if name in exceptions:
                continue
            # value_from_datadict() gets the data from the dictionary.
            # Each widget type knows how to retrieve its own data, because some
            # widgets split data over several HTML fields.
            # HACK: ['', ''] and [None, None] deal with SplitDateTimeWidget. This should be more robust.
            if field.value not in (None, '', ['', ''], [None, None]):
                return False
        return True

    def full_clean(self):
        """
        Cleans all of self.data and populates self._errors and
        self.cleaned_data.
        """
        self._errors = ErrorDict()
        if not self.is_bound: # Stop further processing.
            return
        self.cleaned_data = {}
        if self.empty_permitted and not self.has_changed():
            self.cleaned_data = None
            return
        for name, field in self.fields.items():
            self.clean_field(name, field)
        try:
            self.cleaned_data = self.clean()
        except ValidationError, e:
            self._errors[NON_FIELD_ERRORS] = e.messages
        if self._errors:
            delattr(self, 'cleaned_data')

    def clean_field(self, name, field):
        try:
            value = field.clean()
            self.cleaned_data[name] = value
            if hasattr(self, 'clean_%s' % name):
                value = getattr(self, 'clean_%s' % name)()
                self.cleaned_data[name] = value
        except ValidationError, e:
            self._errors[name] = e.messages
            if name in self.cleaned_data:
                del self.cleaned_data[name]

    def clean(self):
        """
        Hook for doing any extra form-wide cleaning after Field.clean() been
        called on every field. Any ValidationError raised by this method will
        not be associated with a particular field; it will have a special-case
        association with the field named '__all__'.
        """
        return self.cleaned_data
    
    def has_changed(self):  
        """
        Returns True if data differs from initial.
        """
        return bool(self.changed_data)
    
    def _get_changed_data(self):
        if self._changed_data is None:
            self._changed_data = []
            # XXX: For now we're asking the individual widgets whether or not the
            # data has changed. It would probably be more efficient to hash the
            # initial data, store it in a hidden field, and compare a hash of the
            # submitted data, but we'd need a way to easily get the string value
            # for a given field. Right now, that logic is embedded in the render
            # method of each widget.
            for name, field in self.fields.items():
                data_value = field.value_from_datadict(self.data)
                initial_value = self.initial.get(name, field.initial)
                if field._has_changed(initial_value, data_value):
                    self._changed_data.append(name)
        return self._changed_data
    changed_data = LateBindingProperty(_get_changed_data)
    
    def reset(self):
        """Return this form to the state it was in before data was passed to it."""
        self.data = {}
        self.is_bound = False
        self._errors = None

    def is_multipart(self):
        """
        Returns True if the form needs to be multipart-encrypted, i.e. it has
        FileInput. Otherwise, False.
        """
        for field in self.fields.values():
            if field.widget.needs_multipart_form:
                return True
        return False
    
    @classmethod
    def get_nperms(cls):
        if cls.nperm_names:
            nperms = []
            for field in cls.base_fields.values():
                field_nperm = field.get_nperm()
                field_nperms = ['%s.%s.%s' % (
                    nperm_name, cls.get_object_name(), field_nperm) for \
                    nperm_name in cls.nperm_names]
                nperms.extend(field_nperms)
            return nperms
        else:
            return []

class Form(BaseForm):
    """ A collection of Fields, plus their associated data.
    """
    # This is a separate class from BaseForm in order to abstract the way
    # self.fields is specified. This class (Form) is the one that does the
    # fancy metaclass stuff purely for the semantic sugar -- it allows one
    # to define a form using declarative syntax.
    # BaseForm itself has no way of designating self.fields.
    __metaclass__ = DeclarativeFieldsMetaclass

