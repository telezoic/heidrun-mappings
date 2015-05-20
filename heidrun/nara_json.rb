def nara_catalog_uri(id)
  "http://catalog.archives.gov/id/#{id.node}"
end

# See object and preview mappings
def make_obj_uri(obj)
  URI::escape(obj.node['@url'])  # Can have space characters
end
def make_obj_dcformat(obj)
  obj.node['@mime']
end
def make_preview_uri(obj)
  URI::escape(obj.node['@url'])  # Can also have space characters
end
def make_preview_dcformat(obj)
  obj.node['@mime']
end

# Return a string suitable for sourceResource.contributor or
# sourceResource.publisher.
#
# @see #make_contributor
# @see #make_publisher
# @param contributor_array [Krikri::JsonParser::Value]
# @return [String, RDF::Literal]
def contributor_term_name(contributor_array)
  node = contributor_array.node
  contributors = node.fetch('organizationalContributor',
                            node['personalContributor'])
  contributors = [contributors] unless contributors.is_a? Array

  yield(contributors)

  return contributors.first['contributor']['termName'] \
    unless contributors.empty?

  # FIXME:  It's not clear how to indicate the concept of "nothing" to
  # `providedLabel` as a return value from this function.
  # `RDF::Literal.new(nil)` avoids the exception
  #    <quote>
  #    value must be an RDF URI, Node, Literal, or a valid datatype.
  #    See RDF::Literal.
  #        You provided nil
  #    </quote>
  # ... but it results in a providedLabel of ''.  I want the same result as
  # if record.find() did not match anything, but it's not clear how to achieve
  # that.
  RDF::Literal.new(nil)
end

# Return a string for sourceResource.contributor
#
# Use <contributorType>Most Recent</contributorType> if multiple
# <contributor-display> values.
# Reject <contributorType>Publisher</contributorType>.
#
#  <organizationalContributorArray> OR <personalContributorArray>
#    <organizationalContributor> OR <personalContributor>
#      <contributor>
#        <termName>[VALUE]</termName>
#      </contributor>
#      <contributorType>
#        <termName>[VALUE]</termName>
#      </contributorType>
#    </organizationalContributor> OR </personalContributor>
#  </organizationalContributorArray> OR </personalContributorArray>
#
# @see #contributor_term_name
# @return [String, RDF::Literal]
def make_contributor(contributor_array)
  contributor_term_name(contributor_array) do |contributors|
    # Always reject 'Publisher' and use 'Most Recent' if more than one
    contributors.select! do |c|
      c if c['contributorType']['termName'] != 'Publisher'
    end
    if contributors.count > 1
      contributors.select! do |c|
        c if c['contributorType']['termName'] == 'Most Recent'
      end
    end
  end
end

# Return a string for sourceResource.publisher
#
# **note these are contingent on the value of contributorType/termName
# being ""Publisher""
#
# <organizationalContributorArray>
#  <organizationalContributor>
#  <contributor>
#  <termName>[VALUE]</termName>
#  </contributor>
#  <contributorType>
#  <termName>Publisher</termName>
#  </contributorType>
#  </organizationalContributor>
#  </organizationalContributorArray>
#
#  <personalContributorArray>
#  <personalContributor>
#  <contributor>
#  <termName>[VALUE]</termName>
#  </contributor>
#  <contributorType>
#  <termName>Publisher</termName>
#  </contributorType>
#  </personalContributor>
#  </personalContributorArray>
#
# @see #contributor_term_name
# @return [String, RDF::Literal]
def make_publisher(contributor_array)
  contributor_term_name(contributor_array) do |contributors|
    contributors.select! do |c|
      c if c['contributorType']['termName'] == 'Publisher'
    end
  end
end

# Return string for sourceResource.identifier
#
# <variantControlNumberArray>
#  <variantControlNumber>
#  <number>[VALUE1]</number>
#  <type>
#  <termName>[VALUE2]</termName>
#  </type>
#  </variantControlNumber>
#  </variantControlNumberArray>
# [combine as:  VALUE2: VALUE1
#
# @param variant_control_num [Krikri::JsonParser::Value]
# @return [String]
def make_identifier(variant_control_num)
  node = variant_control_num.node
  # The 'type' property can be missing.
  # See https://catalog.archives.gov/api/v1?naIds=65523&pretty=true&resultTypes=item,fileUnit&objects.object.@objectSortNum=1
  type = (node.include? 'type') ? node['type']['termName'] : nil
  [type, node['number']].compact.join ': '
end

# Return a string for sourceResource.relation
#
# <parentFileUnit>
#  <title>VALUE1</title>
#  <parentSeries>
#    <title>VALUE2</title>
#    <parentRecordGroup>
#      <title>VALUE3</title>
#    </parentRecordGroup>
#  </parentSeries>
#  </parentFileUnit>
#  [should be combed as VALUE3""; ""VALUE2""; ""VALUE1]
#
#  OR
#
#  <parentFileUnit>
#  <title>VALUE1</title>
#  <parentSeries>
#    <title>VALUE2</title>
#    <parentCollection>
#      <title>VALUE3</title>
#    </parentCollection>
#  </parentSeries>
#  </parentFileUnit>
#  [should be combed as VALUE3""; ""VALUE2""; ""VALUE1]"
#
# @param parent_file_unit [Krikri::JsonParser::Value]
# @return [String]
def make_relation(parent_file_unit)
  node = parent_file_unit.node
  title = node['title']
  ps = node['parentSeries']
  parent_srs_title = ps['title']
  group_or_coll = ps.fetch('parentRecordGroup', ps['parentCollection'])
  group_coll_title = group_or_coll['title']
  "#{group_coll_title}; #{parent_srs_title}; #{title}"
end

# Return a string for sourceResource.description
#
# <generalNoteArray>
# <generalNote>
# <note>[VALUE]</note>
# </generalNote>
# </generalNoteArray>
#
# <scopeAndContentNote>[VALUE]</scopeAndContentNote>
#
# @param element [Krikri::JsonParser::Value]
# @return [String]
def make_description(element)
  node = element.node
  (node.is_a? String) ? node : node['note']
end

# <useRestriction>
#   <note>VALUE1</note>
#   <specificUseRestrictionArray>
#     <specificUseRestriction>
#       <termName xmlns=""http://description.das.nara.gov/"">VALUE2</termName>
#     </specificUseRestriction>
#   </specificUseRestrictionArray>
#   <status>
#     <termName xmlns=""http://description.das.nara.gov/"">VALUE3</termName>
#   </status>
# </useRestriction>
#
# These should be combined as "VALUE2: VALUE1 VALUE3"
#
# @param element [Krikri::JsonParser::Value]
# @return [String]
def make_rights(use_restriction)
  node = use_restriction.node
  note = node.fetch('note', nil)
  sura = node.fetch('specificUseRestrictionArray', nil)
  status = node.fetch('status', nil)
  l_and_r_parts = \
    [specific_rights_part(sura), genl_rights_part(note, status)].compact
  l_and_r_parts.join ': '
end

# @see #make_rights
def specific_rights_part(specific_use_restriction_array)
  return nil if specific_use_restriction_array.nil?
  sur = specific_use_restriction_array['specificUseRestriction']
  sur = [sur] unless sur.is_a? Array
  terms = sur.map { |el| el['termName'] }
  terms.join ', '
end

# @see #make_rights
def genl_rights_part(note, status)
  [note, status['termName']].compact.join ' '
end


# @see #make_date_provided_label
# @see #make_begin_date
# @see #make_end_date
#
# @param node [Hash]
# @return [String]
def date_string(node)
  return "" if node.nil?
  ymd = [
    node.fetch('year', nil), node.fetch('month', nil), node.fetch('day', nil)
  ].compact.map { |e| "%02d" % e }.join '-'
  qualifier_node = node.fetch('dateQualifier', false)

  return ymd unless qualifier_node

  qualifier = qualifier_node['termName']
  (qualifier == '?') ? "#{ymd}#{qualifier}" : "#{qualifier} #{ymd}"
end

# Date and temporal fields
#
# FIXME:
#
# This may be wrong.  The original comment in this file was:
#
# <quote>
#   *Check for coverage dates first and if they are missing, then check for
#   other dates. These are ORs, not ANDs. Do not display all.
#   **NOT <hierarchy-item-inclusive-dates>
# </quote>
#
# ... But it looks to me like coverageDates is supposed to represent
# "aboutness" as dcterms:temporal, and the other ones are supposed to represent
# a publication, production, or copyright date as dc:date.
#
# This needs verification.
#
# <coverageDates>
#   <coverageEndDate>
#     <dateQualifier>[VALUE]</dateQualifier>
#     <day>[VALUE]</day>
#     <month>[VALUE]</month>
#     <year>[VALUE]</year>
#   </coverageEndDate>
#   <coverageStartDate>
#     <dateQualifier>[VALUE]</dateQualifier>
#     <day>[VALUE]</day>
#     <month>[VALUE]</month>
#     <year>[VALUE]</year>
#   </coverageStartDate>
# </coverageDates>
#
# <copyrightDateArray>
#   <proposableQualifiableDate>
#     <dateQualifier>[VALUE]</dateQualifier>
#     <day>[VALUE]</day>
#     <month>[VALUE]</month>
#     <year>[VALUE]</year>
#   </proposableQualifiableDate>
# </copyrightDateArray>
#
# <productionDateArray>
#   <proposableQualifiableDate>
#     <dateQualifier>[VALUE]</dateQualifier>
#     <day>[VALUE]</day>
#     <month>[VALUE]</month>
#     <year>[VALUE]</year>
#   </proposableQualifiableDate>
# </productionDateArray>
#
# <broadcastDateArray>
#   <proposableQualifiableDate>
#     <dateQualifier/>[VALUE]</dateQualifier>
#     <day>[VALUE]</day>
#     <month>[VALUE]</month>
#     <year>[VALUE]</year>
#     <logicalDate>[VALUE]</logicalDate>
#   </proposableQualifiableDate>
# </broadcastDateArray>
#
# <releaseDateArray>
#   <proposableQualifiableDate>
#     <dateQualifier>[VALUE]</dateQualifier>
#     <day>[VALUE]</day>
#     <month>[VALUE]</month>
#     <year>[VALUE]</year>
#     <logicalDate>[VALUE]</logicalDate>
#   </proposableQualifiableDate>
# </releaseDateArray>
#
# A record can have both dc:date and dcterms:temporal values, like
# coverageDates and broadcastDateArray in
# https://catalog.archives.gov/api/v1?pretty=true&resultTypes=item%2CfileUnit&objects.object.@objectSortNum=1&naIds=5860128

# Return a string suitable for sourceResource.date.providedLabel
#
def make_date_provided_label(date)
  date_string(date.node)
  # node = date.node['proposableQualifiableDate']
  # node = [node] unless node.is_a? Array
  # node.map { |n| date_string(n) }
end

# Return a string for sourceResource.temporal.begin
#
def make_begin_date(dates)
  date_string(dates.node['coverageStartDate'])
end

# Return a string for sourceResource.temporal.end
#
def make_end_date(dates)
  date_string(dates.node['coverageEndDate'])
end

Krikri::Mapper.define(:nara_json, :parser => Krikri::JsonParser) do
  provider :class => DPLA::MAP::Agent do
    uri 'http://dp.la/api/contributor/nara'
    label 'National Archives and Records Administration'
  end

  dataProvider :class => DPLA::MAP::Agent do
    providedLabel record.field('description', 'item | itemAv | fileUnit',
                               'physicalOccurrenceArray',
                               'itemPhysicalOccurrence |' \
                                 'itemAvPhysicalOccurrence |' \
                                 'fileUnitPhysicalOccurrence',
                               'referenceUnitArray', 'referenceUnit',
                               'name')
  end

  isShownAt :class => DPLA::MAP::WebResource do
    uri record.field('naId').first_value.map { |id| nara_catalog_uri(id) }
  end

  object :class => DPLA::MAP::WebResource do
    uri record.field('objects', 'object', 'file').first_value
              .map { |o| make_obj_uri(o) }
    dcformat record.field('objects', 'object', 'file').first_value
                   .map { |o| make_obj_dcformat(o) }
  end

  preview :class => DPLA::MAP::WebResource do
    uri record.field('objects', 'object', 'thumbnail').first_value
              .map { |o| make_preview_uri(o) }
    dcformat record.field('objects', 'object', 'thumbnail').first_value
                   .map { |o| make_preview_dcformat(o) }
  end

  originalRecord :class => DPLA::MAP::WebResource do
    uri record_uri
  end

  sourceResource :class => DPLA::MAP::SourceResource do

    # <parentRecordGroup> OR <parentCollection>
    #   <naId>[VALUE]</naId>
    #   <title>[VALUE]</title>
    #   <recordGroupNumber>[VALUE]</recordGroupNumber>
    # </parentRecordGroup> OR </parentCollection>
    collection :class => DPLA::MAP::Collection do
      title record.field('description', 'item | itemAv | fileUnit',
                         'parentSeries',
                         'parentRecordGroup | parentCollection', 'title')
    end

    contributor :class => DPLA::MAP::Agent do
      providedLabel record.field('description', 'item | itemAv | fileUnit',
                                 'organizationalContributorArray |' \
                                   'personalContributorArray')
                          .map { |el| make_contributor(el) }
    end

    # *Use <contributorType>Most Recent</contributorType> if multiple <contributor-display> values.
    #
    # FIXME:  the instruction on the line above doesn't make sense with the
    #         structure of this element in the original data. Verify?
    #
    # <creatingOrganizationArray> OR <creatingIndividualArray>
    #   <creatingOrganization> OR <creatingIndividual>
    #     <creator>
    #       <termName>[VALUE]</termName>
    #     </creator>
    #   </creatingOrganization> OR </creatingIndividual>
    # </creatingOrganizationArray> OR </creatingIndividualArray>
    creator :class => DPLA::MAP::Agent do
      providedLabel record.field('description', 'item | itemAv | fileUnit',
                                 'parentSeries',
                                 'creatingOrganizationArray |' \
                                   'creatingIndividualArray',
                                 'creatingOrganization | creatingIndividual',
                                 'creator', 'termName')
    end


    # FIXME:
    #
    # When proposableQualifiableDate is an array, you get a `date` that looks
    # like this:
    #
    #     <http://purl.org/dc/elements/1.1/date> [
    #   a <http://www.europeana.eu/schemas/edm/TimeSpan>;
    #   <http://dp.la/about/map/providedLabel> "1948-03-03",
    #     "1948-02-11"
    # ],  [
    #   a <http://www.europeana.eu/schemas/edm/TimeSpan>;
    #   <http://dp.la/about/map/providedLabel> "1948-03-03",
    #     "1948-02-11"
    # ],  [
    #   a <http://www.europeana.eu/schemas/edm/TimeSpan>;
    #   <http://dp.la/about/map/providedLabel> "1948-03-03",
    #     "1948-02-11"
    # ];
    #
    # See https://catalog.archives.gov/api/v1?naIds=20765&pretty=true&resultTypes=item,fileUnit&objects.object.@objectSortNum=1
    #
    # I expect `each`, below, to give me each of the proposableQualifiableDate
    # objects one time only, but when when I examine the execution in `pry` it
    # enters #make_data_provided_label nine times.  I expect it to enter that
    # method only three times.  It goes through the three elements of
    # proposedQualifiableDate in the correct order, three times.
    #
    date :class => DPLA::MAP::TimeSpan,
         :each => record.field('description', 'item | itemAv | fileUnit',
                               'copyrightDateArray |' \
                                 'productionDateArray | broadcastDateArray |' \
                                 'releaseDateArray',
                                 'proposableQualifiableDate'),
         :as => :dc_date do
      providedLabel dc_date.map { |d| make_date_provided_label(d) }
      # self.begin dc_date.map { |d| make_date_provided_label(d) }
      # self.end { |d| make_date_provided_label(d) }
    end

    temporal :class => DPLA::MAP::TimeSpan,
             :each => record.field('description', 'item | itemAv | fileUnit',
                                   'coverageDates'),
             :as => :dates do
      # providedLabel dates.map { |d| make_date_provided_label(d) }
      self.begin dates.map { |d| make_begin_date(d) }
      self.end dates.map { |d| make_end_date(d) }
    end

    description record.field('description', 'item | itemAv | fileUnit',
                             'scopeAndContentNote | generalNoteArray',
                             'generalNote')
                      .map { |d| make_description(d) }

    # <extent>[VALUE]</extent>
    extent record.field('description', 'item | itemAv | fileUnit', 'extent')

    # <specificRecordsTypeArray>
    #  <specificRecordsType>
    #  <termName>[VALUE]</termName>
    # </specificRecordsType>
    # <specificRecordsTypeArray>"
    dcformat record.field('description', 'item | itemAv | fileUnit',
                          'specificRecordsTypeArray', 'specificRecordsType',
                          'termName')

    identifier record.field('description', 'item | itemAv | fileUnit',
                            'variantControlNumberArray',
                            'variantControlNumber')
                     .map { |vcn| make_identifier(vcn) }

    # <languageArray>
    # <language>
    # <termName>[VALUE]</termName>
    # </language>
    # </languageArray>
    language :class => DPLA::MAP::Controlled::Language do
      providedLabel record.field('description', 'item | itemAv | fileUnit',
                                 'languageArray', 'language', 'termName')
    end

    # <geographicReferenceArray>
    #  <geographicPlaceName>
    #  <termName>[VALUE]</termName>
    #  </geographicPlaceName>
    # </geographicReferenceArray>
    spatial :class => DPLA::MAP::Place do
      providedLabel record.field('description', 'item | itemAv | fileUnit',
                                 'geographicReferenceArray',
                                 'geographicPlaceName', 'termName')
    end

    publisher :class => DPLA::MAP::Agent do
      providedLabel record.field('description', 'item | itemAv | fileUnit',
                                 'organizationalContributorArray |' \
                                   'personalContributorArray')
                          .map { |el| make_publisher(el) }
    end

    relation record.field('description', 'item | itemAv | fileUnit',
                          'parentFileUnit')
                   .map { |el| make_relation(el) }

    rights record.field('description', 'item | itemAv | fileUnit',
                        'useRestriction')
                 .map { |el| make_rights(el) }

    # <topicalSubjectArray>
    # <topicalSubject>
    # <termName>[VALUE]</termName>
    # </topicalSubject>
    # </topicalSubjectArray>
    subject :class => DPLA::MAP::Concept do
      providedLabel record.field('description', 'item | itemAv | fileUnit',
                                 'topicalSubjectArray', 'topicalSubject',
                                 'termName')
    end

    title record.field('description', 'item | itemAv | fileUnit', 'title')

    # <generalRecordsTypeArray>
    #  <generalRecordsType>
    #  <termName>[VALUE]</termName>
    #  </generalRecordsType>
    #  </generalRecordsTypeArray>
    #
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
