#!/usr/bin/ruby

require 'rubygems'
require 'sinatra'
require 'erb'
require 'geo_ruby'
require 'OSM/StreamParser'
require 'OSM/Export/Shp'
require 'zip/zip'
require 'zip/zipfilesystem'
require 'zippy'

def osm_to_shape(osmfilename, rulefilename, outfilename)
  rulefilename = "styles/#{rulefilename}.oxr"
  mapper = OSM::Export::Shp.new(outfilename)
  mapper.instance_eval(File.read(rulefilename), rulefilename)
  parser = OSM::Export::Parser.new(osmfilename, mapper)
  parser.parse
  mapper.commit
end

def zip_shapefile(dirname)
  # t = Tempfile.new("shpzip")
  Zippy.create('temp.zip') do |zip|
    Dir[dirname+'/*'].each do |filename|
      zip[filename] = File.open(filename)
    end
  end
  return File.open('temp.zip') 
end

get '/' do
  erb :index
end

post '/upload' do
  return erb(:nofileerror) if params[:osmfile].nil?

  t = Tempfile.new("osmfile", '.')
  File.open(t.path,"wb") do |f|
    f.write(params[:osmfile][:tempfile].read)
  end

  Dir.mktmpdir('shp', '.') do |tmpdir|
    osm_to_shape(t.path, params[:osmstyle], tmpdir)
    z = zip_shapefile(tmpdir)
    puts z.path
    send_file(z.path, 
              :type => 'application/zip', 
              :disposition => 'attachment', 
              :filename => "shapefile.zip")
    z.close
  end
end

get '/upload' do
  erb :nofileerror
end
