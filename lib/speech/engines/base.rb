# -*- encoding: binary -*-
module Speech
  module Engines
    class Base
      attr_accessor :file, :rate, :captured_json, :score, :verbose, :segments, :chunks, :chunk_size,
        :max_results, :language

      def initialize(file, options = {})
        self.file            = file
        self.captured_json   = {}
        self.score           = 0.0
        self.segments        = 0
        self.chunks          = []
        self.chunk_size      = options[:chunk_size].to_i if options.key?(:chunk_size)
        self.verbose         = !!options[:verbose] if options.key?(:verbose)
        self.max_results     = 2
        self.language        = "en-US"
      end

      def to_text(max = 2, lang = "en-US")
        to_json(max, lang)
        chunks.map {|ch| ch.best_text}.compact.join(" ")
      end

      def to_json(max = 2, lang = "en-US")
        self.max_results = max
        self.language    = lang
        
        reset!
        
        chunks.each do |chunk|
          build(chunk)
          convert_chunk(chunk, chunk_options)
          yield chunk if block_given?
        end
        
        self.score /= self.segments
        return {"chunks" => chunks.map {|ch| ch.captured_json}}
      end

      protected

      def reset!
        self.score    = 0.0
        self.segments = 0
        self.chunks   = Speech::AudioSplitter.new(file, splitter_options).split
      end
      
      def build(chunk)
        raise "Implement inside engine."
      end
      
      def splitter_options(options = {})
        {chunk_size: chunk_size, verbose: verbose}.merge(options).reject {|k,v| v.blank?}
      end

      def chunk_options(options = {})
        {verbose: verbose}.merge(options).reject {|k,v| v.blank?}
      end

      def convert_chunk(chunk, options = {})
        raise "Implement inside engine."
      end
    end
  end
end