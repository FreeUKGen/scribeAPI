module IiifTranslator
  SCRIBE_WIDTH=1500

  
  def iiif_annotation_for_facsimile(root_subject)
    image_resource = IIIF::Presentation::ImageResource.create_image_api_image_resource(
      {
        :service_id => service_from_standard_location(root_subject.location['standard']), 
        :resource_id => service_from_standard_location(root_subject.location['standard']),
        # :height => page.base_height,
        # :width => page.base_width,
        :profile => 'http://library.stanford.edu/iiif/image-api/1.1/compliance.html#level2',
                
       })
       
    image_resource.service['@context'] = 'http://iiif.io/api/image/1/context.json'
    annotation = IIIF::Presentation::Annotation.new
    annotation.resource = image_resource
    
    annotation
  end  
 
  def iiif_collection_from_project(project, long=true)
    iiif_collection = IIIF::Presentation::Collection.new
    iiif_collection.label = project.title
    iiif_collection['@id'] = iiif_collection_id_from_project(project)
    
    if long
      project.groups.each do |group|
        iiif_collection.manifests << iiif_manifest_from_group(group, false)            
      end
    end

    iiif_collection  
  end
  
  def iiif_collection_id_from_project(project)
    url_for({:controller => 'iiif', :action => 'collection', :key => project.key, :only_path => false})
  end

  def iiif_manifest_from_group(group, long=true)
    seed = { 
             '@id' => iiif_manifest_id_from_group(group), 
             'label' => group.name
            }
    manifest = IIIF::Presentation::Manifest.new(seed)

    if long
      sequence = IIIF::Presentation::Sequence.new
      sequence.label = 'subjects with classifications'
    
      group.subjects.where(:secondary_subject_count.gt => 0, :type => 'root').each do |root_subject|
        canvas = iiif_canvas_from_root_subject(root_subject)
        sequence.canvases << canvas
      end
      manifest.sequences << sequence
    end

    manifest    
  end
  
  def iiif_manifest_id_from_group(group)
    url_for({:controller => 'iiif', :action => 'manifest', :key => group.key, :only_path => false})    
  end
  
 
 
  def service_from_standard_location(standard_location)
    # eg https://iiif.archivelab.org/iiif/NYC_Marriage_Index_Brooklyn_1919$52/full/1500,/0/default.jpg
    standard_location.sub(/full.*default.jpg/, '')
  end
  
  def canvas_id_from_standard_location(standard_location)
    # eg https://iiif.archivelab.org/iiif/NYC_Marriage_Index_Brooklyn_1919$52/full/1500,/0/default.jpg
    standard_location.sub(/full.*default.jpg/, '')
  end
  
  def iiif_canvas_from_root_subject(root_subject)
    annotation = iiif_annotation_for_facsimile(root_subject)

    
    canvas = IIIF::Presentation::Canvas.new
    canvas.label = root_subject.order
    canvas.width = root_subject.meta_data['source_w'].to_i
    canvas.height = root_subject.meta_data['source_w'].to_i
    canvas['@id'] = canvas_id_from_standard_location(root_subject.location['standard'])
    
    annotation['on'] = canvas['@id']
    annotation['@id'] = url_for({:controller => 'iiif', :action => 'facsimile', :id => root_subject.id, :only_path => false})
    canvas.images << annotation
 
 
    canvas.other_content << iiif_annotation_list_from_root_subject(root_subject, false)

    canvas    
  end
  
  
  def iiif_region_from_subject(subject)
    base = canvas_id_from_standard_location(subject.parent_subject.location['standard'])
 #   region = '100,100'

#    canvas_id_from_page(page) + "#xywh=0,0,#{page.base_width},#{page.base_height}"  
    factor = subject.parent_subject.meta_data['source_w'].to_f / SCRIBE_WIDTH
    x = subject.region['x']
    y = subject.region['y']
    w = subject.region['width']
    h = subject.region['height']
    
    # projection = [x,y,w,h].map { |e| (e.to_f * factor * 1.5).to_i.to_s }
    projection = [x,y,w,h].map { |e| (e.to_f).to_i.to_s }
 
    "#{base}#xywh=#{projection.join(',')}"
  end

  def has_transcript?(subject)
    subject.classifications.count > 0    
  end
  
  def transcript_from_subject(subject)
    subject.classifications.first.annotation['value']
  end

  def iiif_annotation_id_from_subject(subject)
    url_for({ :controller => 'iiif', 
              :action => 'transcript', 
              :root_id => subject.parent_subject.id.to_s, 
              :id => subject.id.to_s,
              :name => subject.type, 
              :only_path => false})
  end
  
  def iiif_annotation_from_subject(subject)
    annotation = IIIF::Presentation::Annotation.new
    annotation['on'] = iiif_region_from_subject(subject)
    annotation['@id'] = iiif_annotation_id_from_subject(subject)
    annotation.resource = IIIF::Presentation::Resource.new({'@id' => "#{subject.type}_#{subject.id}", '@type' => "cnt:ContentAsText"})
    annotation.resource["format"] =  "text/plain"
    
    transcript = transcript_from_subject(subject)
    annotation.resource["chars"] = transcript

    annotation
  end
  
  def iiif_annotation_list_from_root_subject(root_subject, long=true)   
    annotation_list = IIIF::Presentation::AnnotationList.new
    annotation_list['@id'] = url_for({:controller => 'iiif', :action => 'annotation_list', :id => root_subject.id, :only_path => false})

    if long
      # loop through all derivative subjects
      root_subject.child_subjects.each do |subject|
        if has_transcript?(subject)
          annotation_list.resources << iiif_annotation_from_subject(subject)
        end
      end      
    end
    
    annotation_list
  end

end