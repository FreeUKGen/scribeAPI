require 'iiif_translator'
class IiifController < ApplicationController
  include IiifTranslator
  
  
  def index
    site_collection = IIIF::Presentation::Collection.new
    site_collection['@id'] = url_for({:controller => 'iiif', :action => 'index', :only_path => false})
    site_collection.label = "IIIF resources avaliable on this NYPL/Zooniverse Scribe installation"
    
    Project.each do |project|
      site_collection.collections << iiif_collection_from_project(project, false)  
    end
    
    render :text => JSON.pretty_generate(JSON.parse(site_collection.to_json(pretty: true), :content_type => "application/json"))
  end

  def collection
    project = Project.where(:key => params[:key]).first
    render :text => JSON.pretty_generate(JSON.parse(iiif_collection_from_project(project).to_json(pretty: true), :content_type => "application/json"))
  end  
  
  
  def manifest
    group = Group.where(:key => params[:key]).first
    
    render :text => JSON.pretty_generate(JSON.parse(iiif_manifest_from_group(group, true).to_json(pretty: true), :content_type => "application/json"))
  end
  
  def facsimile
    root_subject = Subject.find(params[:id])

    render :text => JSON.pretty_generate(JSON.parse(iiif_annotation_for_facsimile(root_subject).to_json(pretty: true), :content_type => "application/json"))
  end
  
  def annotation_list
    root_subject = Subject.find(params[:id])
    
    render :text => JSON.pretty_generate(JSON.parse(iiif_annotation_list_from_root_subject(root_subject).to_json(pretty: true), :content_type => "application/json"))
  end
  
  def annotation
    root_subject = Subject.find(params[:root_id])
    subject = Subject.find(params[:id])
    
  end
  
private
  
  
end
