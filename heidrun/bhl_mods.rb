# -*- coding: utf-8 -*-
# dcterms:contributor
#   <name (any type)><namePart> WHEN <role><roleTerm (any type)> = contributor
contributor_map = lambda do |r|
  r['mods:name'].select { |name| name['mods:role'].map(&:value).first.strip == 'contributor' }
    .field('mods:namePart')
end

# dcterms:creator
#   <name (any type)><namePart> WHEN <role><roleTerm> = creator
creator_map = lambda do |r|
  r['mods:name'].select { |name| name['mods:role'].map(&:value).first.strip == 'creator' }
    .field('mods:namePart')
end

# dcterms:title
#   <titleInfo><title> when there is no type attribute on <titleInfo>,
#     i.e. excluding <titleInfo type="abbreviated>
title_map = lambda do |r|
  title_infos = r['mods:titleInfo'].select { |ti| ti.node.attribute_nodes.count == 0 }
  title_infos.field('mods:title')
end

Krikri::Mapper.define(:bhl_mods, :parser => Krikri::ModsParser) do
  provider :class => DPLA::MAP::Agent do
    uri 'http://dp.la/api/contributor/bhl'
    label 'Biodiversity Heritage Library'
  end

  # edm:dataProvider
  #   <note type=”ownership”>
  dataProvider :class => DPLA::MAP::Agent do
    providedLabel record.field('mods:note')
      .match_attribute(:type, 'ownership')
  end

  # edm:isShownAt
  #   <location><url access="raw object" usage=”primary”>
  isShownAt :class => DPLA::MAP::WebResource do
    uri record.field('mods:location', 'mods:url')
              .match_attribute(:access, 'raw object')
              .match_attribute(:usage, 'primary')
  end

  # edm:preview
  #   <location><url access="object in context" usage=”primary display”>
  preview :class => DPLA::MAP::WebResource do
    uri record.field('mods:location', 'mods:url')
              .match_attribute(:access, 'object in context')
              .match_attribute(:usage, 'primary display')
    dcformat record.field('mods:physicalDescription', 'mods:internetMediaType')
  end

  sourceResource :class => DPLA::MAP::SourceResource do
    # dcterms:contributor
    #   <name (any type)><namePart> WHEN <role><roleTerm (any type)> = contributor
    contributor :class => DPLA::MAP::Agent do
      providedLabel record.map(&contributor_map).flatten
    end

    # dcterms:creator
    #   <name (any type)><namePart> WHEN <role><roleTerm> = creator
    creator :class => DPLA::MAP::Agent do
      providedLabel record.map(&creator_map).flatten
    end

    # dc:date
    #   <originInfo><dateOther type=”issueDate” keyDate=”yes”> 
    date :class => DPLA::MAP::TimeSpan,
         :each => record.field('mods:originInfo', 'mods:dateOther')
                        .match_attribute(:type, 'issueDate')
                        .match_attribute(:keyDate, 'yes'),
         :as => :created do
      providedLabel created
    end

    # dcterms:description
    #   <note type=”content”>
    description record.fields('mods:note')
      .match_attribute(:type, 'content')

    # dc:format
    #   <physicalDescription><form authority=”marcform”>
    dcformat record.field('mods:physicalDescription', 'mods:form')
      .match_attribute(:authority, 'marcform')

    # edm:hasType
    #   <genre authority=”marcgt”>
    genre :class => DPLA::MAP::Concept,
          :each => record.field('mods:genre')
                         .match_attribute(:authority, 'marcgt'),
            :as => :genre do
      providedLabel genre
    end

    # dcterms:identifier
    #   <identifier>
    identifier record.field('mods:identifier')

    # dcterms:language
    #   <language><languageTerm authority=”iso639-2b” type=”text”>
    language :class => DPLA::MAP::Controlled::Language,
             :each => record.field('mods:language', 'mods:languageTerm')
                            .match_attribute(:type, 'text')
                            .match_attribute(:authority, 'iso639-2b'),
             :as => :lang do
      providedLabel lang
    end

    # dcterms:spatial
    #   <subject><geographic>
    spatial :class => DPLA::MAP::Place,
            :each => record.field('mods:subject', 'mods:geographic'),
            :as => :place do
      providedLabel place
    end

    # dcterms:publisher
    #   originInfo><publisher>
    publisher :class => DPLA::MAP::Agent,
              :each => record.fields('mods:originInfo', 'mods:publisher'),
              :as => :publisher do
      providedLabel publisher
    end

    # dc:relation
    #   <relatedItem><titleInfo><title>
    relation record.field('mods:relatedItem', 'mods:titleInfo', 'mods:title')

    # dc:rights
    #   <accessCondition>
    rights record.field('mods:accessCondition')

    # dcterms:subject
    #   <subject><topic>
    subject :class => DPLA::MAP::Concept,
            :each => record.field('mods:subject', 'mods:topic'),
            :as => :subject do
      providedLabel subject
    end

    # dcterms:temporal
    #   <subject><temporal>
    temporal :class => DPLA::MAP::TimeSpan,
             :each => record.field('mods:subject', 'mods:temporal'),
             :as => :date_string do
      providedLabel date_string
    end

    # dcterms:title
    #   <titleInfo><title> when there is no type attribute on <titleInfo>,
    #     i.e. excluding <titleInfo type="abbreviated>
    title record.map(&title_map).flatten

    # dcterms:type
    #   <typeOfResource>
    dctype record.field('mods:typeOfResource')
  end
end
