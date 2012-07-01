import types
import codecs
import exceptions

class UnsupportedEncodingError(Exception):
    pass

class DecodeError(Exception):
    pass

class CorbaParser(object):

    def __init__(self, decoder = 'ascii'):
        object.__init__(self)
        self.BasicTypes = (
                types.BooleanType,
                types.FloatType, 
                types.IntType, 
                types.LongType
                )
        self.IterTypes = (
                types.TupleType,
                types.ListType
                )
        try:
            codecs.lookup(decoder)
            self.decoder = decoder
        except (codecs.LookupError,), (val, no):
            raise UnsupportedEncodingError(val, no)

    def parse(self, answer):
        if type(answer) in types.StringTypes:
            try:
                answer.decode('ascii')
                return answer
            except UnicodeDecodeError:
                return answer.decode(self.decoder)
        if type(answer) in self.BasicTypes:
            return answer
        elif type(answer) in self.IterTypes:
            return [ self.parse(x) for x in answer ]
        elif type(answer) == types.InstanceType:
            ret = {}
            # EXTRA: types which needs extra treating should be evaluated first
            # special case - "CORBA.EnumItem" type
            # probably omniORB specific ('EnumItem' can be implemented as type, not only as class)
            if answer.__class__.__name__ == 'EnumItem':
                return self.parse(answer._n)
            # EXTRA: end
            for name in dir(answer):
                item = getattr(answer, name)
                # EXTRA: types which needs extra treating should be evaluated first
                # special case - "CORBA.Any" type
                # probably omniORB specific ('Any' can be implemented as type, not only as class)
                if answer.__class__.__name__ == 'Any' and (name == 'value') and (type(item) == types.MethodType):
                    return self.parse(item())
                # EXTRA: end
                if name.startswith('__'): continue # internal python methods / attributes
                if type(item) in types.StringTypes:
                    try:
                        item.decode('ascii')
                        ret[name] = item
                    except UnicodeDecodeError:
                        ret[name] = item.decode(self.decoder)
                if type(item) in self.BasicTypes:
                    ret[name] = item
                if name.startswith('_'): continue # internal module defined methods / attributes
                if type(item) == types.MethodType: continue # methods - don't call them
                if type(item) == types.InstanceType:
                    ret[name] = self.parse(item)
                if type(item) in self.IterTypes:
                    ret[name] = [ self.parse(x) for x in item ]
            return ret
