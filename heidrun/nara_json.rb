def nara_catalog_uri(id)
  "http://catalog.archives.gov/id/#{id}"
end

##
# The parent hierarchy for NARA's archival description allows:
# `parentRecordGroup` OR `parentSeries.parentRecordGroup` OR
# `parentFileUnit.parentRecordGroup` OR
# `parentFileUnit.parentSeries.parentRecordGroup'
#
# All of these combinations are allowable with `parentCollection` as well.
#
# The resulting titles should be concatinated in reverse order; i.e. 
# the JSON nests the hierarchy in reverse order.
#
# @yieldparam parent [Krikri::Parser::Value]
# @yieldreturn [String]
make_relation = lambda do |parent|
  top_titles = parent['title']

  mid_group  = parent['parentSeries']
  mid_titles = mid_group.field('title')

  bot_titles = mid_group.field('parentRecordGroup | parentCollection', 'title')

  bot_titles = parent['parentRecordGroup'].field('title') if 
    bot_titles.empty?    
  bot_titles = parent['parentCollection'].field('title') if
    bot_titles.empty?
  
  [bot_titles.values.first, mid_titles.values.first, top_titles.values.first]
    .compact.join('; ')
end

##
# Let `useRestriction.note` be `VALUE1`, 
# `useRestriction.specificUseRestrictionArray.specificUseRestriction.termName` 
# be `VALUE2` and `useRestriction.status.termName` be `VALUE3`.
#
# These should be combined as `"#{VALUE2}: `#{VALUE1} #{VALUE3}"`.
#
# @param element [Krikri::JsonParser::Value]
# @return [String]
make_rights = lambda do |use_restriction|
  note   = use_restriction['note'].values.first
  sura   = use_restriction['specificUseRestrictionArray'].field('termName')
  status = use_restriction['status'].field('termName').values

  use_restrictions = sura.empty? ? nil : sura.values.join(', ')
  general_rights   = [note, status].flatten.compact.join(' ')

  [use_restrictions, general_rights].compact.join ': '
end

##
# Reconstruct a formatted date string from a date node.
# 
# The date node containing `year`, `month` and/or `day`; Date qualifiers are
# sometimes added from a qualifier field
#
# @param node [Hash]
# @return [String]
format_date = lambda do |date|
  date_str = [date['year'].values.first, 
              date['month'].values.first, 
              date['day'].values.first]
             .compact.map { |e| "%02d" % e }.join '-'
  return if date_str.empty?
  qualifier = date['dateQualifier'].field('termName').values.first

  return date_str if qualifier.nil?
  (qualifier == '?') ? "#{date_str}#{qualifier}" : "#{qualifier} #{date_str}"
end

Krikri::Mapper.define(:nara_json, :parser => Krikri::JsonParser) do
  provider :class => DPLA::MAP::Agent do
    uri 'http://dp.la/api/contributor/nara'
    label 'National Archives and Records Administration'
  end

  dataProvider :class => DPLA::MAP::Agent, 
               :each => record.field('description', 'item | itemAv | fileUnit',
                                     'physicalOccurrenceArray',
                                     'itemPhysicalOccurrence |' \
                                     'itemAvPhysicalOccurrence |' \
                                     'fileUnitPhysicalOccurrence',
                                     'referenceUnitArray', 'referenceUnit',
                                     'name'),
               :as => :agent do
    providedLabel agent
  end

  isShownAt :class => DPLA::MAP::WebResource do
    uri record.field('naId').first_value.map { |id| nara_catalog_uri(id.value) }
  end

  object :class => DPLA::MAP::WebResource,
         :each => record.field('objects', 'object', 'file')
                 .select { |file| file.child?('@url') }.first_value,
         :as => :file_obj do
    uri file_obj.field('@url').first_value.map { |url| URI.escape(url.value) }
    dcformat file_obj.field('@mime').first_value
  end

  preview :class => DPLA::MAP::WebResource,
         :each => record.field('objects', 'object', 'thumbnail').first_value
                 .select { |file| file.child?('@url') },
         :as => :file_obj do
    uri file_obj.field('@url').first_value.map { |url| URI.escape(url.value) }
    dcformat file_obj.field('@mime').first_value
  end

  originalRecord :class => DPLA::MAP::WebResource do
    uri record_uri
  end

  sourceResource :class => DPLA::MAP::SourceResource do
    collection :class => DPLA::MAP::Collection,
               # @note: the [] in `fields` matches the empty path (i.e. it calls 
               #   `#field` with no arguments)
               :each => record.field('description', 'item | itemAv | fileUnit')
                       .fields(['parentFileUnit', 'parentSeries'], 'parentSeries', [])
                       .field('parentRecordGroup | parentCollection', 'title'),
               :as => :collection_title do
      title collection_title
    end

    contributor :class => DPLA::MAP::Agent,
                :each => record.field('description', 'item | itemAv | fileUnit',
                                      'organizationalContributorArray | ' \
                                      'personalContributorArray',
                                      'organizationalContributor | ' \
                                      'personalContributor')
                        .reject { |c| c['contributorType'].field('termName')
                                  .values.include?('Publisher') }
                        .field('contributor'),
                :as => :contributor do
      providedLabel contributor.field('termName')
    end
    
    creator :class => DPLA::MAP::Agent,
            :each => record.field('description', 'item | itemAv | fileUnit',
                                  'parentSeries',
                                  'creatingOrganizationArray |' \
                                  'creatingIndividualArray',
                                  'creatingOrganization | creatingIndividual',
                                  'creator', 'termName'),
            :as => :creator_name do
      providedLabel creator_name
    end

    date :class => DPLA::MAP::TimeSpan,
         :each => record.field('description', 'item | itemAv | fileUnit')
                 .if.field('coverageDates')
                 .else { |vs| vs.field('copyrightDateArray | productionDateArray |'\
                                       'broadcastDateArray | releaseDateArray', 
                                       'proposableQualifiableDate') },
         :as => :dates do
      # use `&format_date` to process date nodes into strings
      # `providedLabel` will be "" for `coverageDates` nodes with Begin/End
      providedLabel dates.map(&format_date)
      self.begin dates.field('coverageStartDate').map(&format_date)
      self.end dates.field('coverageEndDate').map(&format_date)
    end

    description record.field('description', 'item | itemAv | fileUnit')
                 .fields('scopeAndContentNote',
                         ['generalNoteArray', 'generalNote', 'note'])

    extent record.field('description', 'item | itemAv | fileUnit', 'extent')

    dcformat record.field('description', 'item | itemAv | fileUnit',
                          'specificRecordsTypeArray', 'specificRecordsType',
                          'termName')

    identifier record.field('description', 'item | itemAv | fileUnit',
                            'variantControlNumberArray',
                            'variantControlNumber')
                .map { |vcn| [vcn['type'].field('termName').values.first,
                              vcn['number'].values.first].compact.join(': ') }

    language :class => DPLA::MAP::Controlled::Language,
             :each => record.field('description', 'item | itemAv | fileUnit',
                                   'languageArray', 'language'),
             :as => :lang do
      providedLabel lang.field('termName')
    end

    spatial :class => DPLA::MAP::Place, 
            :each => record.field('description', 'item | itemAv | fileUnit',
                                  'geographicReferenceArray',
                                  'geographicPlaceName'),
            :as => :place do
    
      providedLabel place.field('termName')
    end

    publisher :class => DPLA::MAP::Agent,
              :each => record.field('description', 'item | itemAv | fileUnit',
                                    'organizationalContributorArray | ' \
                                    'personalContributorArray',
                                    'organizationalContributor | ' \
                                    'personalContributor')
                      .select { |c| c['contributorType'].field('termName')
                                .values.include?('Publisher') }
                      .field('contributor'),
              :as => :agent do
      providedLabel agent.field('termName')
    end

    relation record.field('description', 'item | itemAv | fileUnit')
              .fields('parentFileUnit', 
                      'parentSeries', 
                      'parentRecordGroup', 
                      'parentCollection')
              .map(&make_relation)
                   

    rights record.field('description', 'item | itemAv | fileUnit', 
                        'useRestriction').map(&make_rights)

    subject :class => DPLA::MAP::Concept,
            :each => record.field('description', 'item | itemAv | fileUnit',
                                  'topicalSubjectArray', 'topicalSubject'),
            :as => :concept do
      providedLabel concept.field('termName')
    end

    title record.field('description', 'item | itemAv | fileUnit', 'title')

    # # to enrich:
    # Architectural and Engineering Drawings (image)
    # Artifacts (physical object)
    # Data Files (dataset)
    # Maps and Charts (image)
    # Moving Images (moving image)
    # Photographs and Other Graphic Materials (image)
    # Sound Recordings (sound)
    # Textual Records (text)
    # Web Pages (interactive resource)
    dctype record.field('description', 'item | itemAv | fileUnit',
                        'generalRecordsTypeArray', 'generalRecordsType',
                        'termName')
  end
end
