#!/usr/bin/env ruby
require_relative 'files_reader.rb'

filenames = ["files/1.txt", "files/2.txt", "files/3.txt"]
filename_out = "res.txt"
BATCH_SIZE = 100_000 # lines

def filelines_to_hashes files_by_lines
  files_by_hash_lines = []
  files_by_lines.each do |file_by_lines|
    file_by_hash_lines = {}
    file_by_lines.each do |line|
      date, num = line.split(":")
      file_by_hash_lines[date] = num.to_i
    end
    files_by_hash_lines.push file_by_hash_lines
  end
  files_by_hash_lines
end

def unite_hashes files_by_hash_lines
  while files_by_hash_lines.length > 1 do
    files_by_hash_lines[0].merge!(files_by_hash_lines.delete_at(1)) do |key, oldval, newval|
      newval + oldval
    end
  end
  files_by_hash_lines[0].sort.to_h
end

def save_merged_files sorted_hash, filename_out
  File.open(filename_out, "a+") do |f|
    sorted_hash.each do |date, num|
      line = "#{date}:#{num}"
      f.puts line
    end
  end
end

files_reader = FilesReader.new(filenames)
files_reader.open_files
files_reader.each_batch(BATCH_SIZE) do |files_by_lines|
  files_by_hash_lines = filelines_to_hashes files_by_lines
  sorted_hash = unite_hashes files_by_hash_lines
  save_merged_files sorted_hash, filename_out
end
files_reader.close_files
