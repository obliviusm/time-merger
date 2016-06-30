class FilesReader
  def initialize filenames
    @filenames = filenames
  end

  def open_files
    @files = []
    @filenames.each do |filename|
      file = File.open(filename, "r")
      @files.push file
    end
  end

  def close_files
    @files.each do |file|
      file.close
    end
  end

  def file_read_by_lines file
    file_by_lines = []
    @batch_max_size.times do
      if file.eof?
        return file_by_lines
      end
      line = file.readline
      file_by_lines.push line
    end
    file_by_lines
  end

  def cut_back_to_allowed_dates files_by_lines, last_allowed_date
    files_by_allowed_lines = []
    files_by_lines.each_with_index do |file_by_lines, i|
      allowed_lines, not_allowed_lines = file_by_lines.partition do |line|
        line.split(":")[0] <= last_allowed_date
      end
      files_by_allowed_lines.push allowed_lines
      # move cursor in file back to last allowed date
      sym_length = not_allowed_lines.map{ |line| line.length }.inject(0, :+)
      @files[i].seek -(sym_length), IO::SEEK_CUR
    end
    files_by_allowed_lines
  end

  def limit_lines_to_allowed_dates files_by_lines
    last_dates = files_by_lines.map do |file_by_lines|
      file_by_lines.last.split(":")[0]
    end
    last_allowed_date = last_dates.min
    cut_back_to_allowed_dates files_by_lines, last_allowed_date
  end

  def each_batch batch_max_size
    @batch_max_size = batch_max_size

    while !@files.map(&:eof?).all? do
      files_by_lines = []
      @files.each do |file|
        file_by_lines = file_read_by_lines file
        files_by_lines.push file_by_lines
      end
      files_by_lines.reject!(&:empty?)
      files_by_lines = limit_lines_to_allowed_dates files_by_lines

      yield files_by_lines
    end
  end
end
