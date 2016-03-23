Krikri::Mapper.define(:tn_mods, :parser => Krikri::ModsParser) do
  provider :class => DPLA::MAP::Agent do
    uri 'http://dp.la/api/contributor/tn'
    label 'Digital Library of Tennessee'
  end

  dataProvider :class => DPLA::MAP::Agent do
    providedLabel record.field('mods:recordInfo', 'mods:recordContentSource')
  end

  isShownAt :class => DPLA::MAP::WebResource do
    uri record.field('mods:location', 'mods:url')
        .match_attribute(:usage) { |attr| attr.downcase.starts_with? 'primary' }
        .match_attribute(:access, 'object in context')
    dcformat record.field('mods:physicalDescription',
                          'mods:internetMediaType')
    rights record.field('mods:accessCondition')
            .match_attribute(:displayLabel, 'Digital Object Rights')
  end

  object :class => DPLA::MAP::WebResource do
    uri record.field('mods:location', 'mods:url')
         .match_attribute(:access, 'raw object')
  end

  preview :class => DPLA::MAP::WebResource do
    uri record.field('mods:location', 'mods:url')
         .match_attribute(:access, 'preview')
  end

  originalRecord :class => DPLA::MAP::WebResource do
    uri record_uri
  end

  sourceResource :class => DPLA::MAP::SourceResource do
    alternative record.field('mods:titleInfo','mods:title')
                      .match_attribute(:type, 'alternative')

    collection :class => DPLA::MAP::Collection,
               :each => record.field('mods:relatedItem')
                              .match_attribute(:type, 'host')
                              .match_attribute(:displayLabel, 'Project'),
               :as => :coll do
      title coll.field('mods:titleInfo', 'mods:title')
      description coll.field('mods:abstract')
    end

    contributor :class => DPLA::MAP::Agent,
                :each => record.field('mods:name')
                        .select { |name| name['mods:role']
                                  .field('mods:roleTerm')
                                  .map { |v| v.value.downcase }
                                  .include?('contributor') },
                :as => :contrib do
      providedLabel contrib.field('mods:namePart')
    end

    creator :class => DPLA::MAP::Agent,
            :each => record.field('mods:name')
                    .select { |name| name['mods:role']
                              .field('mods:roleTerm')
                              .map { |v| v.value.downcase }
                              .include?('creator') },
            :as => :creator_role do
      providedLabel creator_role.field('mods:namePart')
    end

    date :class => DPLA::MAP::TimeSpan,
         :each => record.field('mods:originInfo'),
         :as => :created do

      providedLabel created.field('mods:dateCreated').match_attribute(:keyDate, 'yes')
                     .reject_attribute(:point)

      self.begin created.field('mods:dateCreated').match_attribute(:point, 'start')
      self.end created.field('mods:dateCreated').match_attribute(:point, 'end')
    end

    description record.field('mods:abstract')

    extent record.field('mods:physicalDescription', 'mods:extent')

    dcformat record.field('mods:physicalDescription', 'mods:form')

    # TN has `valueURI` as an authority attribute here, we think we have
    # no place to put this, under MAPv4
    genre record.field('mods:genre').match_attribute(:authority, 'aat')

    identifier record.field('mods:identifier')

    language :class => DPLA::MAP::Controlled::Language,
             :each => record.field('mods:language', 'mods:languageTerm')
                            .match_attribute(:type, 'code')
                            .match_attribute(:authority, 'iso639-2b'),
             :as => :lang do
      providedLabel lang
    end

    spatial :class => DPLA::MAP::Place,
            :each => record.field('mods:subject')
                    .select { |val| val.child?('mods:geographic') ||
                              val.child?('mods:cartographics') },
            :as => :place do

      providedLabel place.field('mods:geographic')
      lat place.field('mods:cartographics', 'mods:coordinates')

      # We need this to select the 'valueURI' attribute. We can't yet use
      # or publish this data, so we can pick it up on the next harvest.
      #
      # exactMatch place.field('mods:geographic')
    end

    publisher :class => DPLA::MAP::Agent,
              :each => record.field('mods:originInfo','mods:publisher'),
              :as => :origin_publisher do
      providedLabel origin_publisher
    end

    relation record.field('mods:relatedItem')
            .reject_attribute(:type, 'isReferencedBy')
            .reject_attribute(:type, 'references')
            .reject_attribute(:displayLabel, 'Project')
            .field('mods:titleInfo')
            .fields('mods:url', 'mods:title')

    isReplacedBy record.field('mods:relatedItem')
                .match_attribute(:type, 'isReferencedBy')
                .field('mods:titleInfo')
                .fields('mods:url', 'mods:title')

    replaces record.field('mods:relatedItem')
            .match_attribute(:type, 'references')
            .field('mods:titleInfo')
            .fields('mods:url', 'mods:title')

    rights record.field('mods:accessCondition')
            .reject_attribute(:displayLabel, 'Digital Object Rights')

    subject :class => DPLA::MAP::Concept,
            :each => record.field('mods:subject')
                    .reject { |v| v.child?('mods:geographic') }
                    .reject { |v| v.child?('mods:temporal') }
                    .reject { |v| v.child?('mods:cartographics') },
            :as => :subject do
      providedLabel subject
    end

    temporal :class => DPLA::MAP::TimeSpan,
             :each => record.field('mods:subject', 'mods:temporal'),
             :as => :date_string do
      providedLabel date_string
    end

    title record.field('mods:titleInfo')
           .reject_attribute(:type, 'alternative')
           .field('mods:title')

    dctype record.map { |r|
      if r.child?('mods:typeOfResource')
        r['mods:typeOfResource'].map(&:value)
      else
        r['mods:format'].map(&:value)
      end
    }.first
  end
end
