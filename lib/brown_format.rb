require 'traject'
require 'traject/umich_format'

#Extend the UMichFormat classifier and customize for Brown usage.
#See codes: https://github.com/billdueber/traject_umich_format
class BrownFormat < Traject::UMichFormat

  #Return a single value format for use in bento box.
  def primary
    ft = format_and_types
    #Grab leader values.
    #This is a bit redudant since these are captured on
    #initialization but will want to use here.
    ldr = record.leader
    type = ldr[6]

    #Serials and newspapers are newspapers
    if ft.include?('SE') && ft.include?('AN')
      return "AN"
    end
    #Serials and journals are journals
    if ft.include?('SE') && ft.include?('AJ')
      return "AJ"
    end
    #Conference publication
    #if ft.include?('BK') && ft.include?('XC')
    #  return "BRUXC"
    #end
    #Videos
    if ft.include?('VM') && ft.include?('VD')
      return "BV"
    end
    #Scores should be scores only.
    if ft.include?('MS')
      return "MS"
    end
    #Audio - if doesn't include audo music consider non-music recordings.
    if ft.include?('MU') && !(ft.include?('RM'))
      return "BRUNMR"
    end

    #Archives manuscript.
    if ft.include?('BK') && (archival_material(type) == true)
      return "BAM"
    end

    #If we are still here, return the first UMich bib format.
    return ft[0]
  end

  def format_and_types
    types = @types.dup
    types.unshift bib_format
    types
  end

  # Marked as newspaper.
  def newspaper?
    found_008_21_n = record.fields('008').find do |field|
      field.value.slice(20) == "n"
    end
    return true if found_008_21_n
  end

  #Return true if item is a archival material.
  def archival_material(type)
    if type == 't'
      return true
    elsif type == 'p'
      return true
    else
      return false
    end
  end

end
