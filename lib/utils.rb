
#Identify whether a given record is suppressed.  Local system uses
#field 998 subfield e with a value of n to indicate the item is
#suppressed.
def suppressed(record)
    f998 = record['998']
    f998.subfields.find do |sf|
        if (sf.code == "e")
            if (sf.value == "n")
                return true
            end
        end
    end
    return false
end