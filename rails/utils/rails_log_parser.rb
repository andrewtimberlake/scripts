
log_directory = File.join(File.dirname(__FILE__), '/../lib/')

module RailsLog
  class Processor
    def self.process(input)
      waiting_for_time = false

      summary = Hash.new{|h,k| h[k] = []}
      info = {}
      while line = input.gets
        if waiting_for_time
          if line[0..11] == 'Completed in'
            if line =~ /^Completed\s*in\s*([^\s]+)\s*\(View:\s*(\d+),\s*DB:\s*(\d+)\)\s*\|\s*(\d+)\s*\w+\s*\[([^\]]+)\]/i
              info.merge!({:processing_time => $1, :view_time => $2, :db_time => $3, :status => $4, :url => $5})
              summary["#{info[:controller]}##{info[:action]}"] << info[:processing_time].to_i
            elsif line =~ /Completed\s*in\s*([^\s]+)\s*\([^\)]+\)\s*\|\s*Rendering:\s*([\d\.]+)\s*\([^\)]+\)\s*\|\s*DB:\s*([\d\.]+)\s*\([^\)]+\)\s*\|\s*(\d+)\s*\w+\s*\[([^\]]+)\]/i
              info.merge!({:processing_time => ($1.to_f * 100).to_i, :view_time => ($2.to_f * 100).to_i, :db_time => ($3.to_f * 100).to_i, :status => $4, :url => $5})
              summary["#{info[:controller]}##{info[:action]}"] << info[:processing_time].to_i
            end
            waiting_for_time = false
          end
        else
          if line[0..9] == 'Processing'
            if line =~ /^Processing\s*([^#]+)#([^\s]+)\s*\(for\s*([^\s]+)\s*at\s*([^\)]+)\)\s*\[(\w+)\]/i
              info = {:controller => $1, :action => $2, :ip => $3, :datetime => $4, :method => $4}
              waiting_for_time = true
            end
          end
        end
      end

      stats = []
      summary.keys.each do |k|
        values = summary[k]
        sum, max, min, avg, median = 0
        if values.length > 0
          values.sort!
          sum = values.inject(0){|sum,i| sum += i}
          max = values[-1]
          min = values[0]
          avg = sum / values.length
          median = values.length % 2 == 0 ? (values[1/2-1] + values[1/2]) / 2 : values[(values.length + 1) / 2 - 1]
        end
        stats << Stats.new(k, values.size, sum, max, min, avg, median)
      end
      stats
    end
  end

  class Stats
    attr_accessor :uri, :count, :sum, :max, :min, :avg, :median
    def initialize(uri, count, sum, max, min, avg, median)
      @uri = uri
      @count = count
      @sum = sum
      @max = max
      @min = min
      @avg = avg
      @median = median
    end
  end

  def self.run
    sort_by_key = nil
    result_limit = 0
    ARGV.each_with_index do |arg,i|
      if ['--sort', '-s'].include?(arg)
        sort_by_key = ARGV[i+1]
      elsif ['--limit', '-l'].include?(arg)
        result_limit = ARGV[i+1].to_i
      elsif ['--help', '-h'].include?(arg)
        print_usage
        exit
      end
    end

    file = ARGV.size > 0 ? ARGV[-1] : nil
    stats = nil
    if !file.nil? && File.exists?(file)
      File.open(file, 'r') do |f|
        stats = Processor.process f
      end
    else
      stats = Processor.process STDIN
    end
    
    stats_array = [] 
    sort_by_key = 'median' unless !sort_by_key.nil? && stats[0].respond_to?(sort_by_key)
    stats.sort_by{ |s| s.send(sort_by_key) }.reverse.each do |s|
      #puts "#{s.uri} - count:#{s.count} - sum:#{s.sum} - max:#{s.max} - min:#{s.min} - avg:#{s.avg} - median:#{s.median}"
      stats_array << [s.uri, s.count, s.sum, s.max, s.min, s.avg, s.median]
    end
    stats_array = stats_array[0..result_limit-1] if result_limit > 0
    stats_array.tabalize(['Uri', 'Calls', 'Total Time', 'Max', 'Min', 'Avg', 'Median'], [:left, :right, :right, :right, :right, :right, :right])
  end

  def self.print_usage
    puts <<-END
ruby #{File.basename(__FILE__)} [options] [FILE]

Parses a rails log file and prints out call time information by controller#action pair.
With no FILE, or when FILE is -, read standard input.

options:
  --help | -h            Print this help screen
  --sort | -s <key>      Sort the results by key
                         valid keys are:
                            count  - The total number of calls
                            sum    - The total call time
                            max    - The maximum call time
                            min    - The minimum call time
                            avg    - The average call time
                            median - The median call time (default)
  --limit | -l <limit>   Limit the number of results displayed

examples:

  ruby #{File.basename(__FILE__)} --sort count < $RAILS_ROOT/logs/development.log

  gunzip -c $RAILS_ROOT/logs/development.log.gz | ruby #{File.basename(__FILE__)} --sort count --limit 20 -

END
    exit
  end
end

class Array
  def tabalize(headings, justifications = nil, out = STDOUT)
    raise ArgumentError.new('only works on an array of arrays') if size > 0 && ![0].is_a?(Array)
    raise ArgumentError.new('headings, justifications and array elements must all have the same number of elements') if size > 0 && (headings.size != [0].size) && (!justifications.nil? && (headings.size != justifications.size))
    sizes = Array.new(headings.size, 0)
    headings.each_with_index do |h,i|
      sizes[i] = [sizes[i], h.to_s.length].max
    end
    each do |row|
      row.each_with_index do |e, i|
        sizes[i] = [sizes[i], e.to_s.length].max
      end
    end

    print_tablalize_lines(out, sizes)

    out.write "| "
    sizes.each_with_index do |s, i|
      out.write " | " if i > 0
      out.write headings[i].ljust(s, ' ')
    end
    out.write " |\n"

    print_tablalize_lines(out, sizes)

    each do |row|
      out.write "| "
      sizes.each_with_index do |s, i|
        out.write " | " if i > 0
        out.write row[i].to_s.send("#{justifications[i].to_s[0..0]}just", s, ' ')
      end
      out.write " |\n"
    end

    print_tablalize_lines(out, sizes)
  end

private
  def print_tablalize_lines(out, sizes)
    out.write '+-'
    sizes.each_with_index do |s, i|
      out.write "-+-" if i > 0
      out.write "".ljust(s, '-')
    end
    out.write "-+\n"
  end
end

RailsLog.run
