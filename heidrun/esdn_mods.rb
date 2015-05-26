Krikri::Mapper.define(:esdn_mods, :parser => Krikri::ModsParser) do
  provider :class => DPLA::MAP::Agent do
    uri 'http://dp.la/api/contributor/esdn'
    label 'Empire State Digital Network'
  end

  dataProvider :class => DPLA::MAP::Agent do
    providedLabel record.field('mods:note').match_attribute(:type, 'ownership')
  end

  isShownAt :class => DPLA::MAP::WebResource do
    uri record.field('mods:location', 'mods:url')
         .match_attribute(:usage, 'primary display')
         .match_attribute(:access, 'object in context')
  end

  preview :class => DPLA::MAP::WebResource do
    uri record.field('mods:location', 'mods:url')
         .match_attribute(:access, 'preview')
  end

  originalRecord :class => DPLA::MAP::WebResource do
    uri record_uri
  end

  sourceResource :class => DPLA::MAP::SourceResource do
    alternative record.field('mods:titleInfo')
                      .match_attribute(:type, 'alternative')
                      .field('mods:title')

    ##
    # TODO: implement collection/set harvester and enrichment to complete
    # the metadata required for collections. This just grabs the set's
    # identifier from the OAI-PMH setSpec in the record header.
    collection :class => DPLA::MAP::Collection,
               :each => header.field('xmlns:setSpec'),
               :as => :coll do
      title coll
    end

    contributor :class => DPLA::MAP::Agent,
                :each => record.field('mods:name')
                        .select { |name| name['mods:role'].map(&:value).include?('contributor') },
                :as => :contrib do
      providedLabel contrib.field('mods:namePart')
    end

    creator :class => DPLA::MAP::Agent,
            :each => record.field('mods:name')
                    .select { |name| name['mods:role'].map(&:value).include?('creator') },
            :as => :creator_role do
      providedLabel creator_role.field('mods:namePart')
    end

    date :class => DPLA::MAP::TimeSpan,
         :each => record.field('mods:originInfo'),
         :as => :created do
      providedLabel created.field('mods:dateCreated').match_attribute(:keyDate, 'yes')
                     .reject { |date| date.attribute? :point }
      self.begin created.field('mods:dateCreated').match_attribute(:point, 'start')
      self.end created.field('mods:dateCreated').match_attribute(:point, 'end')
    end

    description record.field('mods:note').match_attribute(:type, 'content')

    extent record.field('mods:physicalDescription', 'mods:extent')

    # non-DCMIType values from type will be handled in enrichment
    dcformat record.field('mods:physicalDescription', 'mods:form')

    genre record.field('mods:physicalDescription', 'mods:form')

    identifier record.field('mods:identifier')

    language :class => DPLA::MAP::Controlled::Language,
             :each => record.field('mods:language', 'mods:languageTerm'),
             :as => :lang do
      prefLabel lang
    end

    spatial :class => DPLA::MAP::Place,
            :each => record.field('mods:subject', 'mods:geographic'),
            :as => :place do
      providedLabel place
    end

    publisher :class => DPLA::MAP::Agent,
              :each => record.field('mods:originInfo'),
              :as => :publisher do
      providedLabel publisher.field('mods:publisher')
    end

    relation record.field('mods:relatedItem', 'mods:titleInfo', 'mods:title')

    rights record.field('mods:accessCondition')

    subject :class => DPLA::MAP::Concept,
            :each => record.field('mods:subject'),
            :as => :subject do
      providedLabel subject
    end

    # Note: this rejects all mods:titleInfo elements where the @type
    # attribute is present. Discussed w/ Gretchen and Tom on 5/26/15. 
    title record.field('mods:titleInfo')
                .reject { |t| t.attribute? :type }
                .field('mods:title')

    # Selecting DCMIType-only values will be handled in enrichment
    dctype record.field('mods:typeOfResource')
  end
end
