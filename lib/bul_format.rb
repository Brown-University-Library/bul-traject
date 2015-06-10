# given a record, find the bib_format code
#based on https://github.com/billdueber/traject_umich_format/blob/master/lib/traject/umich_format/bib_format.rb

=begin
Prefix Brown codes with b.
BTD = Thesis/Dissertation

Brown VuFind code
https://bitbucket.org/bul/traject-indexer/src/5d3308001783849a33827def6a5f04081510d940/docs/vufind_format.bsh?at=formats

=end
class Format
  attr_reader :record, :code, :type, :level, :fixed

  def initialize(record)
    #Default blacklight index.properties.
    #format = 007[0-1]:000[6-7]:000[6], (map.format), first
    @record = record
    ldr = record.leader
    @type = ldr[6].downcase
    @level  = ldr[7].downcase
    #http://www.loc.gov/marc/bibliographic/bd008.html
    @fixed = record['008'].value[21]
    @code = self.primary(@type, @level, fixed)
  end

  def primary(type, lev, fixed)
    code = format_code(type, lev)

    #Special logic
    if dissertation == true
      return "BTD"
    elsif three_d_object(type) == true
      return "B3D"
    elsif archival_material(type) == true
      return "BAM"
    elsif computer_file(type) == true
      return "CF"
    end

    #Check for videos
    if code == "VM"
      if video() == true
        return "BV"
      end
    end

    #Scores
    if code == "MU"
      if @type == 'c'
        return "MS"
      end
    end

    #MU will be local sound recording
    if code == "MU"
      return "BSR"
    end

    #Serials are Brown periodicals
    if code == "SE"
      return "BP"
    end

    #JCB items with old style codes - consider books.
    if (type == "a") and (level == "p")
      return "BK"
    end

    #Return default code if none is found.
    return code || 'XX'

  end

  def format_code(type, lev)
    #From https://github.com/billdueber/traject_umich_format
    return 'BK' if bibformat_bk(type, lev)
    return "CF" if bibformat_cf(type, lev)
    return "VM" if bibformat_vm(type, lev)
    return "MU" if bibformat_mu(type, lev)
    return "MP" if bibformat_mp(type, lev)
    return "SE" if bibformat_se(type, lev)
    return "MX" if bibformat_mx(type, lev)
    #Extra check for serial
    return "SE" if lev == 's'
  end

  #Return MARC 007s as array
  def phys_desc
    out = []
    found_007 = @record.fields('007').each do |field|
      out << field.value
    end
    return out
  end

  #Return true if 502 contains Brown Univ.
  def dissertation
    @record.fields('502').each do |f|
      values = [f['a'], f['c']]
      values.each do |value|
        if value.nil?
          next
        end
        if (/brown univ/ === value.downcase)
          return true
        end
      end
    end
    return nil
  end

  #Return true if item is a journal.
  def journal(format_code, fixed)
    if format_code == 'SE'
      #Check for these codes in fixed field 23
      #See: https://github.com/billdueber/traject_umich_format/blob/144dda6197881712d97eb9013ebf9b038a914cb5/lib/traject/umich_format/bib_types.rb#L320
      if [' ','d','l','m','p','w','|'].include?(fixed)
        return true
      end
    end
    return nil
  end

  #Return true if item is a newspaper.
  def newspaper(format_code, fixed)
    if format_code == 'SE'
      if fixed == 'n'
        return true
      end
    end
  return nil
  end

  #Return true if item is a archival material.
  def archival_material(type)
    if type == 't'
      return true
    elsif type == 'p'
      return true
    else
      return nil
    end
  end

  #Check 007[0] for video.
  def video
    phys_desc().each do |val|
      if (val.include? "v") or (val.include? "m")
        return true
      end
    end
    return false
    #Inspect location codes for common format abbrvs.
    # record.fields('945').each do |item|
    #   item.subfields.each do |sf|
    #     if sf.code == 'l'
    #       val = sf.value.strip
    #       #esv - online video recording
    #       #dvd or dv in codes for dvds.
    #       if val.match('[:alpha:]+(dvd|dv$)|esv')
    #         puts '**'
    #         return true
    #       elsif val.match('[:alpha:]+vid|')
    #         puts '***', val
    #         return true
    #       end
    #     end
    #   end
    # end
    # return nil
  end

  #Return true if this is a 3D objects.
  def three_d_object(type)
    return type == 'r'
  end

  #Return true if this is a computer file
  def computer_file(type)
    return type == 'm'
  end

  #computer files, videos, sound recordings, maps
  def bibformat_bk(type, lev)
    %w[a t].include?(type) && %w[a c d m].include?(lev)
  end

  def bibformat_cf(type, lev)
    (type == 'm') && %w[a b c d i m s].include?(lev)
  end

  def bibformat_vm(type, lev)
    %w[g k o r].include?(type) && %w[a b c d i m s].include?(lev)
  end

  def bibformat_mu(type, lev)
    %w[c d i j].include?(type) && %w[a b c d i m s].include?(lev)
  end

  def bibformat_mp(type, lev)
    %w[e f].include?(type) && %w[a b c d i m s].include?(lev)
  end

  def bibformat_se(type, lev)
    (type == 'a') && %w[b s i].include?(lev)
  end

  def bibformat_mx(type, lev)
    %w[b p].include?(type) && %w[a b c d m s].include?(lev)
  end
end
