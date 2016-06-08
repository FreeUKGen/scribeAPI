require 'iiif/presentation'
require 'iiif_translator'

namespace :project do


  # TODO: Change this to use the CSV library to actually create the file, and to print the line to add to groups.csv
  
  module IiifParams 
    THUMBNAIL_RESOLUTION='100,100'
    SUBJECT_RESOLUTION="#{IiifTranslator::SCRIBE_WIDTH},"
    SUBJECT_OFFSET='full'
  end
  
  def service_to_full_url(service_id)
    "#{service_id}/#{IiifParams::SUBJECT_OFFSET}/#{IiifParams::SUBJECT_RESOLUTION}/0/default.jpg"
  end
  
  def service_to_thumb_url(service_id)
    "#{service_id}/full/#{IiifParams::THUMBNAIL_RESOLUTION}/0/default.jpg"
  end
  
  def process_canvas(canvas, index, archive_id, csv)
    # TODO: This should split left & right pages into separate subjects (probably crop too)
    canvas_id = canvas['@id']
    canvas_label =  canvas.label

    # may be useful for pruning non-record frames    
    canvas_width =         canvas.width
    canvas_height =        canvas.height
    
    resource_id =          canvas.images.first['resource']['@id'] 
    resource_format =      canvas.images.first['resource']['format'] 
    service_id =           canvas.images.first['resource']['service']['@id']

    row = []
    # order,file_path,thumbnail,capture_uuid,page_uri,book_uri,source_rotated,width,height,source_x,source_y,source_w,source_h
    # order,
    row << index
    # file_path,
    row << service_to_full_url(service_id)
    # thumbnail,
    row << service_to_thumb_url(service_id)
    # capture_uuid,
    row << "#{archive_id}-#{index}"
    # page_uri,
    # TODO: We want something better than an URI with fragment here
    row << "https://archive.org/details/#{archive_id}#page/n#{index}"
     # book_uri,
    row << "https://archive.org/details/#{archive_id}"
    # source_rotated
    row << 0.00
    # width,
    row << canvas_width
    # height,
    row << canvas_height
    # source_x,
    row << 0
    # source_y,
    row << 0
    # source_w,
    row << canvas_width
    # source_h
    row << canvas_height
    
    csv << row
  end
  


  def transform_archive_work(project_key, archive_id)
    manifest_url = "https://iiif.archivelab.org/iiif/#{archive_id}/manifest.json"
    group_key = archive_id.underscore
        
    connection = open(manifest_url)
    manifest_json = connection.read
    service = IIIF::Service.parse(manifest_json)
  
    subjects_dir = Rails.root.join('project', project_key, 'subjects')
    group_file = Rails.root.join subjects_dir, "group_#{group_key}.csv"
    
    
    # headers the ingestor pays attention to are
    # set_key (will autogenerate otherwise)
     # thumbnail       = data['thumbnail']
      # name            = data['name']
      # meta_data       = data.except('group_id', 'file_path', 'retire_count', 'thumbnail', 'width','height', 'order')

    CSV.open(group_file, "wb", :headers => :first_row) do |csv|
      csv << [
        'order',
        'file_path',
        'thumbnail',
        'capture_uuid',
        'page_uri',
        'book_uri',
        'source_rotated',
        'width',
        'height',
        'source_x',
        'source_y',
        'source_w',
        'source_h'
      ]
      service.sequences.first.canvases.each_with_index do |canvas,i|
        process_canvas(canvas, i, archive_id, csv)
      end      
      
      print "Add the following line to groups.csv:\n"
      # key,name,description,cover_image_url,external_url,retire_count
      group_sample_canvas = service.sequences.first.canvases[(service.sequences.first.canvases.length / 3).to_i]
      group_thumbnail = service_to_thumb_url(group_sample_canvas.images.first['resource']['service']['@id'])
      print [group_key, service.label,service.label,group_thumbnail,"http://archive.org/stream/#{archive_id}",2].to_csv
    end    
  
  
  
  end


  desc "Create subject CSV file from Internet Archive identifiers"
  task :subject_from_archive, [:project_key,:archive_id] => :environment do |task, args|
    transform_archive_work(args[:project_key],args[:archive_id])
  end




end
