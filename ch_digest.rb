require 'csv'
require 'optparse'
require 'ostruct'
require 'pathname'

module CHDigest
  class Reader
    module Transforms
      module_function \
      def id
        [[1, 'id']]
      end
      
      module_function \
      def name
        [[2, 'name']]
      end
      
      module_function \
      def type
        [[3, 'type']]
      end
      
      module_function \
      def labels
        [
          [4, 'Client', extract_subfield('client')],
          [5, 'Severity', extract_severity],
          [12, 'agency', extract_subfield('agency')],
          [13, 'source', extract_subfield('Source')],
          [14, 'Cause', extract_subfield('Cause')],
          [15, 'layer', extract_subfield('layer')],
        ]
      end
      
      module_function \
      def created_at
        [[6, 'created_at']]
      end
      
      module_function \
      def started_at
        [[7, 'started_at']]
      end
      
      module_function \
      def completed_at
        [[8, 'completed_at']]
      end
      
      module_function \
      def state
        [[9, 'state']]
      end
      
      module_function \
      def epic
        [[10, 'epic']]
      end
      
      module_function \
      def project
        [[11, 'project']]
      end
      
      module_function \
      def requester
        [[16, 'requester']]
      end
      
      module_function \
      def owners
        [[17, 'owners']]
      end
      
      module_function \
      def description
        [[18, 'description']]
      end
      
      private
      def self.extract_subfield(sfname)
        lambda do |val|
          next if val.nil?
          val.split(/;\s*/).collect_concat do |sf|
            sfname_i, sfval_i = sf.split(/:\s*/, 2)
            (sfname_i == sfname) ? [sfval_i] : []
          end.first
        end
      end
      
      def self.extract_severity
        lambda do |val|
          sfval = extract_subfield('severity').call(val)
          sfval ? "SV#{sfval}" : nil
        end
      end
    end
    
    module RankingGroups
      SPEC_ORDER = 1
      REMNANT = 2
    end
    
    def initialize(csv_data)
      super()
      @csv = CSV.new(csv_data)
      @headers = @csv.shift
      @column_xforms = self.class.row_format(@headers)
    end
    
    def self.row_format(headers)
      headers.each_with_index.map do |col_name, i|
        col_mname = col_name.downcase.to_sym
        begin
          col_mapping = Transforms.send(col_mname)
        rescue NoMethodError
          UntransformedColumn.new(col_name, i)
        else
          TransformedColumn.new(col_mapping)
        end
      end
    end
    
    class TransformedColumn
      def initialize(xform_mapping)
        super()
        @xform_mapping = xform_mapping
      end
    
      attr_reader :xform_mapping
    
      def columns
        xform_mapping.map do |rank, output_name, xform|
          [RankingGroups::SPEC_ORDER, rank, output_name]
        end
      end
    
      def call(val, i)
        xform_mapping.map do |rank, output_name, xform|
          sival = xform ? xform.call(val) : val
          [RankingGroups::SPEC_ORDER, rank, sival]
        end
      end
    end
    
    class UntransformedColumn
      def initialize(col_name, rank)
        super()
        @col_name = col_name
        @rank = rank
      end
    
      attr_reader :col_name, :rank
    
      def columns
        [[RankingGroups::REMNANT, @rank, @col_name]]
      end
    
      def call(val, i)
        [[RankingGroups::REMNANT, i, val]]
      end
    end
    
    def headers
      @column_xforms.each_with_index.collect_concat do |xform, i|
        xform.columns
      end.sort.map {|g, r, name| name}
    end
    
    def shift
      return unless row = @csv.shift
      keyed_data = row.each_with_index.collect_concat do |val, i|
        @column_xforms[i].call(val, i)
      end
      keyed_data.sort!
      keyed_data.map {|g, r, v| v}
    end
    
    def each
      while row = shift
        yield row
      end
      nil
    end
    include Enumerable
  end
  
  def self.parse_args(args)
    args = args.dup
    opts = OpenStruct.new
    
    OptionParser.new do |parser|
      parser.banner = "Usage: #{__FILE__} [options] SOURCE.csv DEST.csv"
    end.parse!(args)
    
    if args.length != 2
      $stderr.puts "Invoke with exactly two file path positional arguments"
      exit 2
    end
    
    [opts, Pathname(args[0]), Pathname(args[1])]
  end
  
  def self.main(args)
    opts, inpath, outpath = parse_args(args)
    
    inpath.open do |infile|
      reader = Reader.new(infile)
      CSV.open(outpath.to_s, 'wb') do |writer|
        writer << reader.headers
        reader.each {|row| writer << row}
      end
    end
  end
end

CHDigest.main(ARGV) if __FILE__ == $0
